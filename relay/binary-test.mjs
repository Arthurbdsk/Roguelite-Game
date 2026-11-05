import {test} from 'node:test';
import assert from 'node:assert/strict';
import {WebSocket} from 'ws';
import {createRelay} from './server.mjs';
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function peer(url){const ws=new WebSocket(url),inbox=[];ws.on('message',(raw,binary)=>inbox.push(binary?Buffer.from(raw):JSON.parse(raw)));await new Promise(r=>ws.once('open',r));return {ws,inbox,send:x=>ws.send(JSON.stringify(x))};}
async function until(p,predicate){for(let i=0;i<200;i++){const at=p.inbox.findIndex(predicate);if(at>=0)return p.inbox.splice(at,1)[0];await sleep(10);}throw Error('Timeout');}
test('bounded latest complete snapshot, reliable critical priority, native host authority and protocol',async()=>{
 const relay=createRelay({port:0});const a=await relay.listen();const url=`ws://127.0.0.1:${a.port}`;const h=await peer(url),c=await peer(url),bad=await peer(url);
 try{
  h.send({type:'create',protocol:2,game_version:'codec-test',name:'Host'});const joined=await until(h,m=>m.type==='joined');c.send({type:'join',protocol:2,game_version:'codec-test',name:'Client',code:joined.code});await until(c,m=>m.type==='joined');
  bad.send({type:'join',game_version:'codec-test',name:'Old',code:joined.code});assert.match((await until(bad,m=>m.type==='error')).reason,/Protocolos/);
  h.send({type:'ready',ready:true});c.send({type:'ready',ready:true});await sleep(20);h.send({type:'start'});await until(c,m=>m.type==='start');
  const serverClient=[...relay.wss.clients][1];let congested=true;Object.defineProperty(serverClient,'bufferedAmount',{get:()=>congested?70000:0,configurable:true});
  for(let i=0;i<30;i++){const b=Buffer.from([72,20,100,0,0,0,i]);h.ws.send(b);}
  h.send({type:'events',data:[{data:{type:'chest',amount:125}}]});await sleep(50);assert(!c.inbox.some(Buffer.isBuffer));congested=false;await sleep(50);
  const messages=c.inbox.filter(m=>Buffer.isBuffer(m)||m.type==='events');assert.equal(messages[0].type,'events');const snapshots=messages.filter(Buffer.isBuffer);assert.equal(snapshots.length,1);assert.equal(snapshots[0][6],29);
  c.ws.send(Buffer.from([72,20,100,0,0,0,1]));const close=await new Promise(r=>c.ws.once('close',code=>r(code)));assert.equal(close,1008);
 }finally{h.ws.terminate();c.ws.terminate();bad.ws.terminate();await relay.close();}
});
test('protocol health, protected metrics and map load timeout can retry',async()=>{
 const relay=createRelay({port:0,metricsToken:'fixture-only'});const a=await relay.listen();const base=`http://127.0.0.1:${a.port}`;const peers=[];
 try{
  assert.equal((await (await fetch(base+'/health')).json()).protocol,2);
  assert.equal((await fetch(base+'/metrics')).status,404);
  assert.equal((await fetch(base+'/metrics',{headers:{Authorization:'Bearer fixture-only'}})).status,200);
  const h=await peer(base.replace('http:','ws:'));peers.push(h);h.send({type:'create',protocol:2,game_version:'0.14.0',name:'Host'});const joined=await until(h,m=>m.type==='joined');
  for(let i=0;i<3;i++){const c=await peer(base.replace('http:','ws:'));peers.push(c);c.send({type:'join',protocol:2,game_version:'0.14.0',name:'P'+i,code:joined.code});await until(c,m=>m.type==='joined');}
  for(const p of peers)p.send({type:'ready',ready:true});await until(h,m=>m.type==='lobby'&&m.players.length===4&&m.players.every(p=>p.ready));h.send({type:'start'});await until(h,m=>m.type==='prepare');
  for(const p of peers.slice(0,3))p.send({type:'loaded'});await sleep(20);assert.equal(relay.rooms.get(joined.code).started,false);
  relay.rooms.get(joined.code).loadingSince=Date.now()-30001;assert.match((await until(h,m=>m.type==='error')).reason,/carregamento/);assert.equal((await until(h,m=>m.type==='lobby'&&m.players.length===4&&m.players.every(p=>!p.ready))).players.length,4);
  for(const p of peers)p.send({type:'ready',ready:true});await until(h,m=>m.type==='lobby'&&m.players.every(p=>p.ready));h.send({type:'start'});await until(h,m=>m.type==='prepare');for(const p of peers)p.send({type:'loaded'});assert.equal((await until(h,m=>m.type==='start')).players.length,4);
 }finally{for(const p of peers)p.ws.terminate();await relay.close();}
});
