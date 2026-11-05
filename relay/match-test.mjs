import {spawn} from 'node:child_process';
import {readFile,rm,mkdir,writeFile} from 'node:fs/promises';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createRelay} from './server.mjs';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..'),godot=process.env.GODOT_EXE||`${process.env.USERPROFILE}/Downloads/Godot_v4.7.2-stable_win64_console.exe`;
const children=[],stamp=Date.now(),scenario=process.argv.includes('--disconnect')?'disconnect':'combat';
const codeFile=resolve(root,`test_output/coop-match-${stamp}-${scenario}.txt`);
const packedArgument=process.argv.find(v=>v.startsWith('--packed='));
const runtime=packedArgument?['--main-pack',resolve(packedArgument.slice('--packed='.length))]:['--path',root];
const harnessName=process.argv.includes('--dev')?'dev_network11':process.argv.includes('--campaign')?'campaign_network10':process.argv.includes('--permanent')?'permanent_network9':'coop_match';
const harness=packedArgument?resolve(root,`tests/${harnessName}.gd`):`res://tests/${harnessName}.gd`;
const relay=createRelay({port:0});const address=await relay.listen();
const externalArgument=process.argv.find(v=>v.startsWith('--relay-url='));
const endpoint=externalArgument?externalArgument.slice('--relay-url='.length):`ws://127.0.0.1:${address.port}`;
const endpointArgs=process.argv.includes('--embedded-endpoint')?[]:[`--relay=${endpoint}`];
await mkdir(resolve(root,'test_output'),{recursive:true});
function peer(index,args){const child=spawn(godot,['--headless','--log-file',resolve(root,`test_output/coop-${stamp}-${index}.runtime.log`),...runtime,'--script',harness,'--',...endpointArgs,`--index=${index}`,`--profile-slot=cooptest${stamp}_${index}`,...args],{cwd:packedArgument?dirname(resolve(packedArgument.slice('--packed='.length))):root,windowsHide:true});children.push(child);let out='';child.stdout.on('data',d=>out+=d);child.stderr.on('data',d=>out+=d);return new Promise((ok,bad)=>{child.on('error',bad);child.on('close',async code=>{await writeFile(resolve(root,`test_output/coop-${scenario}-peer-${index}.log`),out);console.log(out.trim());if(code===0&&out.includes('COOP_MATCH_PEER_PASS')&&!out.includes('ERROR:'))ok();else bad(Error(`Match peer ${index} failed ${code}`));});});}
try{
 const extra=process.argv.filter(v=>v==='--disconnect'||v.startsWith('--soak-seconds=')||v.startsWith('--map='));
 await rm(codeFile,{force:true});const host=peer(0,['--host',`--code-file=${codeFile}`,...extra]);
 let code='';for(let i=0;i<100;i++){try{code=await readFile(codeFile,'utf8');if(code)break;}catch{}await new Promise(r=>setTimeout(r,50));}
 if(!code)throw Error('Host did not publish a room code');
 const results=await Promise.allSettled([host,...Array.from({length:3},(_,i)=>peer(i+1,[`--room=${code}`,...extra]))]);
 for(const result of results)if(result.status==='rejected')throw result.reason;
 console.log(harnessName==='dev_network11'?'FOUR_PLAYER_DEV_PASS: owner builds, host-only commands, phases, walls, restarts and untouched saves':harnessName==='campaign_network10'?'FOUR_PLAYER_CAMPAIGN_PASS: continuation, guardian, walls, chain, True Form and final settlement':harnessName==='permanent_network9'?'FOUR_PLAYER_PERMANENT_PASS: individual bonuses, lobby challenge, host-authorized return, individual banked gold':'FOUR_PLAYER_MATCH_PASS: real game, movement, scaling, private choices, shared loot, rescue, load, team defeat and persisted gold');
}finally{for(const child of children)if(child.exitCode===null)child.kill();await relay.close();await rm(codeFile,{force:true});}
