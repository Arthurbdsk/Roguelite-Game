import {spawn} from 'node:child_process';
import {readFile,rm,mkdir,writeFile,copyFile} from 'node:fs/promises';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createRelay} from './server.mjs';
import {createImpairmentProxy} from './impairment-proxy.mjs';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..'),godot=process.env.GODOT_EXE||`${process.env.USERPROFILE}/Downloads/Godot_v4.7.2-stable_win64_console.exe`;
const children=[],stamp=Date.now(),scenario=process.argv.includes('--disconnect')?'disconnect':'combat';
const codeFile=resolve(root,`test_output/coop-match-${stamp}-${scenario}.txt`);
const packedArgument=process.argv.find(v=>v.startsWith('--packed='));
let packedPath=packedArgument?resolve(packedArgument.slice('--packed='.length)):null;
if(packedPath){await mkdir(resolve(root,'test_output/packs'),{recursive:true});const source=packedPath;packedPath=resolve(root,`test_output/packs/${stamp}.exe`);await copyFile(source,packedPath);}
const runtime=packedArgument?['--main-pack',packedPath]:['--path',root];
const harnessName=process.argv.includes('--normal13')?'coop_match13':process.argv.includes('--survival')?'survival_network13':process.argv.includes('--balance')?'balance_network12':process.argv.includes('--dev')?'dev_network11':process.argv.includes('--campaign')?'campaign_network10':process.argv.includes('--permanent')?'permanent_network9':'coop_match';
const harnessOverride=process.argv.find(a=>a.startsWith('--harness='));
const harness=harnessOverride?resolve(harnessOverride.slice(10)):packedArgument?resolve(root,`tests/${harnessName}.gd`):`res://tests/${harnessName}.gd`;
const diagnostics=[];const relay=createRelay({port:0,onDiagnostic:event=>{diagnostics.push(event);console.log("RELAY_DIAGNOSTIC",JSON.stringify(event));}});const address=await relay.listen();
const numberArg=(key,fallback)=>Number(process.argv.find(a=>a.startsWith(`--${key}=`))?.split('=')[1]??fallback);
const impaired=process.argv.some(a=>a.startsWith('--rtt='));
const proxy=impaired?await createImpairmentProxy(address,{rtt:numberArg('rtt',100),jitter:numberArg('jitter',10),kbps:numberArg('bandwidth-kbps',2048),stallEvery:numberArg('stall-every',0)}):null;
const actual=proxy?.address||address;
const externalArgument=process.argv.find(v=>v.startsWith('--relay-url='));
const endpoint=externalArgument?externalArgument.slice('--relay-url='.length):`ws://127.0.0.1:${actual.port}`;
const endpointArgs=process.argv.includes('--embedded-endpoint')?[]:[`--relay=${endpoint}`];
await mkdir(resolve(root,'test_output'),{recursive:true});
function peer(index,args){const child=spawn(godot,[...(process.argv.includes('--render-one')&&index===1?['--resolution','960x540','--max-fps','30']:['--headless']),'--log-file',resolve(root,`test_output/coop-${stamp}-${index}.runtime.log`),...runtime,'--script',harness,'--',...endpointArgs,`--index=${index}`,`--profile-slot=cooptest${stamp}_${index}`,...args],{cwd:packedArgument?dirname(packedPath):root,windowsHide:true});children.push(child);let out='';child.stdout.on('data',d=>out+=d);child.stderr.on('data',d=>out+=d);return new Promise((ok,bad)=>{child.on('error',bad);child.on('close',async code=>{await writeFile(resolve(root,`test_output/coop-${scenario}-peer-${index}.log`),out);console.log(out.trim());if(code===0&&out.includes('COOP_MATCH_PEER_PASS')&&!out.includes('ERROR:'))ok();else bad(Error(`Match peer ${index} failed ${code}`));});});}
try{
 const extra=process.argv.filter(v=>v==='--disconnect'||v.startsWith('--soak-seconds=')||v.startsWith('--soak-rate=')||v.startsWith('--map='));
 await rm(codeFile,{force:true});const host=peer(0,['--host',`--code-file=${codeFile}`,...extra]);host.catch(()=>{});
 // Free public hosting can wake for up to 90s. Keep the harness aligned with the game's preflight.
 const codeDeadline=Date.now()+(externalArgument?100000:10000);
 let code='';while(Date.now()<codeDeadline){try{code=await readFile(codeFile,'utf8');if(code)break;}catch{}await new Promise(r=>setTimeout(r,50));}
 if(!code)throw Error('Host did not publish a room code');
 const results=await Promise.allSettled([host,...Array.from({length:3},(_,i)=>peer(i+1,[`--room=${code}`,...extra]))]);
 for(const result of results)if(result.status==='rejected')throw result.reason;
 if(harnessOverride)console.log("FOUR_PLAYER_CUSTOM_PASS:",harness);else console.log(harnessName==='survival_network13'?'FOUR_PLAYER_SURVIVAL13_PASS: real sockets, personal chest rewards, full 225 family, timed siege, unanimous infinite after disconnect and original saves':harnessName==='balance_network12'?'FOUR_PLAYER_BALANCE12_PASS: real sockets, fixed targets, destructible crystals, map, horde stages, restart and original saves':harnessName==='dev_network11'?'FOUR_PLAYER_DEV_PASS: owner builds, host-only commands, phases, walls, restarts and untouched saves':harnessName==='campaign_network10'?'FOUR_PLAYER_CAMPAIGN_PASS: continuation, guardian, walls, chain, True Form and final settlement':harnessName==='permanent_network9'?'FOUR_PLAYER_PERMANENT_PASS: individual bonuses, lobby challenge, host-authorized return, individual banked gold':'FOUR_PLAYER_MATCH_PASS: real game, movement, scaling, private choices, shared loot, rescue, load, team defeat and persisted gold');
}finally{await writeFile(resolve(root,`test_output/network14-${stamp}.json`),JSON.stringify({stamp,args:process.argv.slice(2),diagnostics,impairment:proxy?.metrics},null,2));for(const child of children)if(child.exitCode===null)child.kill();if(proxy){console.log("TCP_IMPAIRMENT",JSON.stringify(proxy.metrics));await proxy.close();}await relay.close();await rm(codeFile,{force:true});if(packedPath)await rm(packedPath,{force:true});}
