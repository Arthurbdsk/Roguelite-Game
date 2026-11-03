import {spawn} from 'node:child_process';
import {readFile,rm} from 'node:fs/promises';
import {resolve} from 'node:path';
import {createRelay} from './server.mjs';
const root=resolve('..'),godot=process.env.GODOT_EXE||`${process.env.USERPROFILE}/Downloads/Godot_v4.7.2-stable_win64_console.exe`;
const codeFile=resolve(root,'test_output/room-test-code.txt'),children=[];
const relay=createRelay({port:0});const address=await relay.listen();
function peer(args){const child=spawn(godot,['--headless','--path',root,'--script','res://tests/room_peer.gd','--',`--relay=ws://127.0.0.1:${address.port}`,...args],{cwd:root,windowsHide:true});children.push(child);let out='';child.stdout.on('data',d=>out+=d);child.stderr.on('data',d=>out+=d);return new Promise((ok,bad)=>{child.on('error',bad);child.on('close',code=>{console.log(out.trim());if(code===0&&out.includes('GODOT_ROOM_PEER_PASS')&&!out.includes('ERROR:'))ok();else bad(Error(`Peer failed ${code}`));});});}
try{
 await rm(codeFile,{force:true});const host=peer(['--host','--name=Host',`--code-file=${codeFile}`]);
 let code='';for(let i=0;i<100;i++){try{code=await readFile(codeFile,'utf8');if(code)break;}catch{}await new Promise(r=>setTimeout(r,50));}
 if(!code)throw Error('Host did not publish a room code');
 await Promise.all([host,...Array.from({length:3},(_,i)=>peer([`--name=Guest${i}`,`--room=${code}`]))]);
 console.log('FOUR_GODOT_INSTANCES_PASS: actual code join, ready, start, host event and client actions');
}finally{for(const child of children)if(child.exitCode===null)child.kill();await relay.close();await rm(codeFile,{force:true});}
