// Explicit Android QA, never a PC release dependency. Uses a dedicated emulator.
import {spawn,execFile} from 'node:child_process';
import {promisify} from 'node:util';
import {readFile,writeFile,mkdir,rm} from 'node:fs/promises';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
const exec=promisify(execFile),root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
if(!process.argv.includes('--android-request'))throw Error('Explicit Android request required');
const androidHost=process.argv.includes('--android-host'),session=String(Date.now()),label=androidHost?'android-host':'pc-host',out=resolve(root,'build/update25');await mkdir(out,{recursive:true});
const adb=resolve(process.env.USERPROFILE,'AppData/Local/HordasAndroidToolchain/sdk/platform-tools/adb.exe'),godot=resolve(process.env.USERPROFILE,'Downloads/Godot_v4.7.2-stable_win64_console.exe');
const pc=resolve(root,'../Jogo Teste/build/Hordas-0.25.0/Hordas-0.25.0.exe'),harness=resolve(root,'tests/crossplay25_pc.gd'),fixture=resolve(root,'scripts/mobile/crossplay25_qa.gd'),roomFile=resolve(out,`room-${session}.json`);
const children=[],tasks=[];let touched=false,backgrounded=false;
const delay=ms=>new Promise(r=>setTimeout(r,ms));
const a=(args,options={})=>exec(adb,['-s','emulator-5554',...args],{timeout:30000,maxBuffer:16*1024*1024,...options});
async function react(text){
 if(text.includes('CROSS25_TOUCH_READY')&&!touched){touched=true;console.log('ADB_HELD_TOUCH_START');tasks.push(a(['shell','input','swipe','1914','753','1914','753','6500'],{timeout:15000}));}
 if(!androidHost&&text.includes('CROSS25_BACKGROUND_READY')&&!backgrounded){backgrounded=true;console.log('ADB_BACKGROUND_START');tasks.push((async()=>{await delay(1000);await a(['shell','input','keyevent','3']);await delay(1800);await a(['shell','monkey','-p','com.socialy.hordas.qa','-c','android.intent.category.LAUNCHER','1']);})());}
}
function peer(index,extra=[]){
 const child=spawn(godot,['--headless','--main-pack',pc,'--script',harness,'--','--self-test',`--index=${index}`,`--session=${session}`,`--fixture=${fixture}`,'--relay=wss://hordas-relay.onrender.com',...extra],{cwd:dirname(pc),windowsHide:true});children.push(child);let output='';
 child.stdout.on('data',chunk=>{const s=chunk.toString();output+=s;react(s);});child.stderr.on('data',chunk=>output+=chunk.toString());
 return new Promise((ok,bad)=>{child.on('error',bad);child.on('close',async code=>{await writeFile(resolve(out,`${label}-pc${index}.log`),output);if(code===0&&output.includes('CROSS25_PEER_PASS')&&!output.includes('SCRIPT ERROR')&&!output.includes('CROSS25_FAIL')){console.log(`PC_PEER_PASS ${label} ${index}`);ok();}else bad(Error(`PC peer ${index} failed: ${output.slice(-5000)}`));});});
}
async function android(options){
 await a(['shell','am','force-stop','com.socialy.hordas.qa']);
 await a(['shell','rm','-f','/data/user/0/com.socialy.hordas.qa/files/cross25-room.json','/data/user/0/com.socialy.hordas.qa/files/cross25-result.json']);
 const local=resolve(out,`request-${session}.json`);await writeFile(local,JSON.stringify({mode:'cross25',host:androidHost,index:3,name:'Android',session,relay:'wss://hordas-relay.onrender.com',...options}));
 await a(['push',local,'/data/local/tmp/hordas25-request.json']);await a(['shell','cp','/data/local/tmp/hordas25-request.json','/data/user/0/com.socialy.hordas.qa/files/qa_request.json']);await a(['shell','chmod','644','/data/user/0/com.socialy.hordas.qa/files/qa_request.json']);
 await a(['logcat','-c']);await a(['shell','monkey','-p','com.socialy.hordas.qa','-c','android.intent.category.LAUNCHER','1']);
}
async function androidResult(){
 const until=Date.now()+210000;
 while(Date.now()<until){
  try{const {stdout}=await a(['shell','cat','/data/user/0/com.socialy.hordas.qa/files/cross25-result.json']);const result=JSON.parse(stdout);await writeFile(resolve(out,`${label}-android.json`),JSON.stringify(result,null,2));if(!result.passed)throw Error('Android reported failed checks: '+stdout);return result;}catch(e){if(String(e).includes('reported failed'))throw e;}
  await delay(600);
 }
 throw Error('Android result timeout');
}
try{
 await a(['wait-for-device']);let code='';let promises=[];
 if(androidHost){
  await android({});
  for(let i=0;i<240&&!code;i++){try{code=JSON.parse((await a(['shell','cat','/data/user/0/com.socialy.hordas.qa/files/cross25-room.json'])).stdout).room;}catch{}if(!code)await delay(400);}
  if(!code)throw Error('Android host did not create public room');
  promises=[0,1,2].map(i=>peer(i,[`--room=${code}`]));
 }else{
  const host=peer(0,['--host',`--code-file=${roomFile}`,'--background']);host.catch(()=>{});
  for(let i=0;i<240&&!code;i++){try{code=JSON.parse(await readFile(roomFile,'utf8')).room;}catch{}if(!code)await delay(400);}
  if(!code)throw Error('PC host did not create public room');
  promises=[host,peer(1,[`--room=${code}`]),peer(2,[`--room=${code}`])];await android({room:code});
 }
 for(const p of promises)p.catch(()=>{});
 const results=await Promise.allSettled([...promises,androidResult()]);await Promise.allSettled(tasks);
 for(const result of results)if(result.status==='rejected')throw result.reason;
 console.log('CROSSPLAY25_PASS '+label+' four participants via public WSS, new art, bestiary, owner kills, choices, physical held touch, phases and individual rewards');
}finally{
 const log=await a(['logcat','-d','-t','10000']).catch(()=>({stdout:''}));await writeFile(resolve(out,`${label}-logcat.txt`),log.stdout);
 for(const child of children)if(child.exitCode===null)child.kill();await rm(roomFile,{force:true});
}
