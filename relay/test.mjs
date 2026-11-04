import {test} from 'node:test';
import assert from 'node:assert/strict';
import {WebSocket} from 'ws';
import {createRelay} from './server.mjs';

async function client(url){
 const ws=new WebSocket(url), inbox=[];const listeners=[];
 ws.on('message',raw=>{const m=JSON.parse(raw);const waiter=listeners.find(x=>x.predicate(m));if(waiter){listeners.splice(listeners.indexOf(waiter),1);waiter.resolve(m);}else inbox.push(m);});
 await new Promise((ok,bad)=>{ws.once('open',ok);ws.once('error',bad);});
 return {ws,send:m=>ws.send(JSON.stringify(m)),next:(type,predicate=()=>true,timeout=2000)=>new Promise((resolve,reject)=>{
  const matches=m=>m.type===type&&predicate(m);const i=inbox.findIndex(matches);if(i>=0)return resolve(inbox.splice(i,1)[0]);
  const waiter={predicate:matches,resolve:m=>{clearTimeout(timer);resolve(m);}};listeners.push(waiter);const timer=setTimeout(()=>{listeners.splice(listeners.indexOf(waiter),1);reject(Error('Timeout '+type));},timeout);
 })};
}
test('real sockets: room codes, four peers, ready, routing, host authority and disconnect',async()=>{
 const relay=createRelay({port:0});const address=await relay.listen();const url=`ws://127.0.0.1:${address.port}`;const clients=[];
 try{
  const h=await client(url);clients.push(h);h.send({type:'create',name:'          '});assert.match((await h.next('error')).reason,/Nome/);
  h.send({type:'create',name:'123456789'});assert.match((await h.next('error')).reason,/Nome/);
  h.send({type:'create',name:' Host '});const joined=await h.next('joined');assert.match(joined.code,/^[A-HJ-NP-Z2-9]{6}$/);
  await h.next('lobby',m=>m.players.length===1);
  for(let i=0;i<3;i++){const c=await client(url);clients.push(c);c.send({type:'join',code:joined.code,name:i===0?'a\u0301'.repeat(8):`P${i}`});await c.next('joined');}
  const lobby=await h.next('lobby',m=>m.players.length===4);assert.equal(lobby.players.length,4);assert.equal(lobby.players[1].name.length,8);
  const extra=await client(url);clients.push(extra);extra.send({type:'join',code:'BAD',name:'X'});assert.match((await extra.next('error')).reason,/inválido/);
  extra.send({type:'join',code:joined.code,name:'X'});assert.match((await extra.next('error')).reason,/cheia/);
  clients[1].send({type:'start'});assert.match((await clients[1].next('error')).reason,/criador/);
  h.send({type:'start'});assert.match((await h.next('error')).reason,/prontos/);
  for(const c of clients.slice(0,4))c.send({type:'ready',ready:true});
  await h.next('lobby',m=>m.players.length===4&&m.players.every(p=>p.ready));h.send({type:'start'});const start=await h.next('start');assert.equal(start.players.length,4);
  for(const c of clients.slice(1,4))assert.equal((await c.next('start')).run,start.run);
  extra.send({type:'join',code:joined.code,name:'X'});assert.match((await extra.next('error')).reason,/começou/);
  clients[1].send({type:'event',data:{cheat:true}});await assert.rejects(h.next('event',()=>true,100));
  clients[1].send({type:'action',from:joined.id,data:{sequence:1,movement:[0,1]}});const action=await h.next('action');assert.notEqual(action.from,joined.id);assert.deepEqual(action.data.movement,[0,1]);
  h.send({type:'event',to:action.from,data:{id:'reward-1',gold:10}});assert.equal((await clients[1].next('event')).data.id,'reward-1');await assert.rejects(clients[2].next('event',()=>true,100));
  clients[1].send({type:'events',data:[{data:{cheat:true}}]});await assert.rejects(h.next('events',()=>true,100));
  h.send({type:'events',data:[{data:{id:'shared'}},{to:action.from,data:{id:'private'}}]});
  assert.deepEqual((await clients[1].next('events')).data.map(e=>e.id),['shared','private']);
  assert.deepEqual((await clients[2].next('events')).data.map(e=>e.id),['shared']);
  clients[1].ws.close();assert.equal((await h.next('left')).id,action.from);
  h.ws.close();assert.match((await clients[2].next('closed')).reason,/criador/);assert.equal(relay.rooms.size,0);
 }finally{for(const c of clients)c.ws.terminate();await relay.close();}
});

test('buffered network burst stays connected; sustained flood is still bounded',async()=>{
 const relay=createRelay({port:0});const address=await relay.listen();
 const h=await client(`ws://127.0.0.1:${address.port}`),c=await client(`ws://127.0.0.1:${address.port}`);
 try{
  h.send({type:'create',name:'Host'});const joined=await h.next('joined');
  c.send({type:'join',code:joined.code,name:'Guest'});await c.next('joined');
  h.send({type:'ready',ready:true});c.send({type:'ready',ready:true});
  await h.next('lobby',m=>m.players.length===2&&m.players.every(p=>p.ready));
  h.send({type:'start'});await c.next('start');
  for(let i=0;i<180;i++)h.send({type:'delta',data:{sequence:i}});
  assert.equal((await c.next('delta',m=>m.data.sequence===179)).data.sequence,179);
  assert.equal(h.ws.readyState,WebSocket.OPEN);
  const closed=new Promise(resolve=>h.ws.once('close',resolve));
  for(let i=0;i<700;i++)h.send({type:'delta',data:{sequence:180+i}});
  assert.equal(await closed,1008);
 }finally{h.ws.terminate();c.ws.terminate();await relay.close();}
});
