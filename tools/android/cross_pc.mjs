// Explicit manual mixed-platform test, never part of PC validation.
import {spawn,execFile} from 'node:child_process';
import {promisify} from 'node:util';
import {readFile,writeFile,mkdir,rm} from 'node:fs/promises';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
const run=promisify(execFile),root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
if(!process.argv.includes('--android-request'))throw Error('Explicit Android request required');
const user=process.env.USERPROFILE,adb=`${user}/AppData/Local/HordasAndroidToolchain/sdk/platform-tools/adb.exe`,godot=`${user}/Downloads/Godot_v4.7.2-stable_win64_console.exe`;
const pc=resolve(root,'../Jogo Teste/build/Hordas-0.20.0/Hordas-0.20.0.exe'),harness=resolve(root,'tests/mobile_cross_pc.gd'),codeFile=resolve(root,'build/mixed-room.txt');
const children=[],outputs=[],touches=[];await rm(codeFile,{force:true});
await run(adb,['wait-for-device']);await run(adb,['shell','am','force-stop','com.socialy.hordas.qa']);
function peer(index,args){return new Promise((ok,bad)=>{
 const child=spawn(godot,['--headless','--main-pack',pc,'--script',harness,'--','--self-test',`--profile-slot=mobilecross${Date.now()}_${index}`,`--index=${index}`,'--relay=wss://hordas-relay.onrender.com',...args],{cwd:dirname(pc),windowsHide:true});children.push(child);let out='';
 child.stdout.on('data',chunk=>{const s=chunk.toString();out+=s;process.stdout.write(s);
  if(s.includes('MOBILE_REVIVE_READY'))touches.push(run(adb,['shell','input','swipe','1930','755','1930','755','6500'],{timeout:15000}));
  if(s.includes('MOBILE_BACKGROUND_READY'))touches.push(run(adb,['shell','input','keyevent','3'],{timeout:10000}));
 });child.stderr.on('data',chunk=>out+=chunk.toString());child.on('error',bad);child.on('close',async code=>{outputs[index]=out;await writeFile(resolve(root,`build/mixed-pc${index}.log`),out);if(code===0&&out.includes('MOBILE_CROSS_PC_PASS')&&!out.includes('ERROR:'))ok();else bad(Error(`Peer ${index} failed ${code}: ${out.slice(-1600)}`));});
});}
try{
 const host=peer(0,['--host',`--code-file=${codeFile}`]);host.catch(()=>{});let code='';
 for(let i=0;i<2200;i++){try{code=await readFile(codeFile,'utf8');if(code)break;}catch{}await new Promise(r=>setTimeout(r,50));}
 if(!code)throw Error('No public room code');
 const p1=peer(1,[`--room=${code}`]),p2=peer(2,[`--room=${code}`]);p1.catch(()=>{});p2.catch(()=>{});
 const request=resolve(root,'build/qa_request.json');await writeFile(request,JSON.stringify({mode:'network',room:code,relay:'wss://hordas-relay.onrender.com'}));
 await run(adb,['push',request,'/data/local/tmp/hordas-qa-request.json']);await run(adb,['shell','mkdir','-p','/data/user/0/com.socialy.hordas.qa/files']);await run(adb,['shell','cp','/data/local/tmp/hordas-qa-request.json','/data/user/0/com.socialy.hordas.qa/files/qa_request.json']);await run(adb,['shell','chmod','644','/data/user/0/com.socialy.hordas.qa/files/qa_request.json']);
 await run(adb,['logcat','-c']);await run(adb,['shell','monkey','-p','com.socialy.hordas.qa','-c','android.intent.category.LAUNCHER','1']);
 const results=await Promise.allSettled([host,p1,p2]);await Promise.allSettled(touches);
 const {stdout:log}=await run(adb,['logcat','-d','-t','8000'],{maxBuffer:12*1024*1024});await writeFile(resolve(root,'build/mixed-android.log'),log);
 for(const result of results)if(result.status==='rejected')throw result.reason;
 if(!log.includes('ANDROID_QA_NETWORK_PASS')||log.includes('ANDROID_QA_FAIL')||log.includes('SCRIPT ERROR'))throw Error('Android checks failed; see mixed-android.log');
 console.log('MIXED_ANDROID_PC_PASS: Android emulator plus three frozen PC0.20 processes, public WSS, individual choice, real held-touch revive, background departure.');
}finally{for(const child of children)if(child.exitCode===null)child.kill();}
