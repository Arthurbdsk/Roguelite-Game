import http from 'node:http';
import {randomInt,randomUUID} from 'node:crypto';
import {WebSocketServer,WebSocket} from 'ws';
import {pathToFileURL} from 'node:url';
import {resolve} from 'node:path';
import {appendFileSync,existsSync} from 'node:fs';

export function createRelay({port=8080,host='127.0.0.1',maxRooms=100,onDiagnostic=()=>{}}={}) {
  const rooms=new Map(), peers=new Map();
  const server=http.createServer((req,res)=>{res.writeHead(req.url==='/health'?200:404,{'Content-Type':'application/json'});res.end(JSON.stringify(req.url==='/health'?{ok:true,protocol:1}:{}));});
  const wss=new WebSocketServer({server,maxPayload:524288,perMessageDeflate:false});
  const send=(ws,msg)=>{if(ws.readyState!==WebSocket.OPEN)return;if(ws.bufferedAmount>=1048576){onDiagnostic({event:'slow_connection',buffered:ws.bufferedAmount});ws.close(1013,'Slow connection');return;}ws.send(JSON.stringify(msg));};
  server.maxConnections=512;
  const broadcast=(room,msg)=>{for(const p of room.members.values())send(p.ws,msg);};
  const lobby=room=>broadcast(room,{type:'lobby',code:room.code,host:room.host,players:[...room.members.values()].map(p=>({id:p.id,name:p.name,ready:p.ready,skills:p.skills}))});
  function leave(p) {
    if(!p.room)return;
    const room=p.room;p.room=null;room.members.delete(p.id);
    if(p.id===room.host){for(const other of room.members.values()){other.room=null;send(other.ws,{type:'closed',reason:'O criador da sala desconectou.'});}rooms.delete(room.code);}
    else if(room.members.size){broadcast(room,{type:'left',id:p.id});if(!room.started)lobby(room);}
  }
  wss.on('connection',ws=>{
    const p={id:randomUUID(),ws,room:null,name:'',ready:false,skills:{},window:Date.now(),tokens:600,byteTokens:16*1048576,alive:true,connectedAt:Date.now(),maxPayload:0};peers.set(ws,p);
    ws.on('pong',()=>p.alive=true);
    ws.on('message',raw=>{
      p.maxPayload=Math.max(p.maxPayload,raw.length);
      // Proxies can deliver several seconds of legitimate traffic in one burst.
      // Bound sustained traffic while allowing that backlog to drain.
      const now=Date.now(),elapsed=Math.max(0,now-p.window)/1000;p.window=now;
      p.tokens=Math.min(600,p.tokens+elapsed*120)-1;
      p.byteTokens=Math.min(16*1048576,p.byteTokens+elapsed*8*1048576)-raw.length;
      if(p.tokens<0||p.byteTokens<0){onDiagnostic({event:'rate_limit',peer:p.id,age_ms:now-p.connectedAt});ws.close(1008,'Rate limit');return;}
      let m;try{m=JSON.parse(raw.toString());}catch{return send(ws,{type:'error',reason:'Mensagem inválida.'});}
      if(!m||typeof m!=='object'||Array.isArray(m))return;
      const fail=reason=>send(ws,{type:'error',reason});
      if(m.type==='create'||m.type==='join') {
        if(p.room)return fail('Você já está em uma sala.');
        const name=typeof m.name==='string'?m.name.trim().normalize('NFC'):'';
        if(!name||[...new Intl.Segmenter('pt',{granularity:'grapheme'}).segment(name)].length>8||/[\p{Cc}\p{Cf}\p{Cs}]/u.test(name))return fail('Nome deve ter entre 1 e 8 caracteres visíveis.');
        let room;
        if(m.type==='create'){
          if(rooms.size>=maxRooms)return fail('Serviço de salas ocupado.');
          const alphabet='ABCDEFGHJKLMNPQRSTUVWXYZ23456789';let code;
          do{code=Array.from({length:6},()=>alphabet[randomInt(alphabet.length)]).join('');}while(rooms.has(code));
          room={code,host:p.id,started:false,members:new Map()};rooms.set(code,room);
        }else{
          const code=typeof m.code==='string'?m.code.trim().toUpperCase():'';
          if(!/^[A-HJ-NP-Z2-9]{6}$/.test(code)||!rooms.has(code))return fail('Código inválido ou sala encerrada.');
          room=rooms.get(code);if(room.started)return fail('A partida já começou.');if(room.members.size>=4)return fail('Sala cheia.');
        }
        p.name=name;p.skills=Object.fromEntries(Object.entries(m.skills||{}).filter(([k,v])=>/^[a-z_]{1,30}$/.test(k)&&Number.isInteger(v)&&v>=0&&v<=2).slice(0,16));
        p.room=room;p.ready=false;room.members.set(p.id,p);send(ws,{type:'joined',id:p.id,code:room.code,host:room.host});lobby(room);return;
      }
      const room=p.room;if(!room)return fail('Entre em uma sala primeiro.');
      if(m.type==='leave'){leave(p);return;}
      if(m.type==='ready'&&!room.started){p.ready=m.ready===true;lobby(room);return;}
      if(m.type==='start'){
        if(p.id!==room.host)return fail('Somente o criador pode iniciar.');
        if(room.started)return fail('A partida já começou.');
        if([...room.members.values()].some(member=>!member.ready))return fail('Todos precisam estar prontos.');
        room.started=true;room.run=randomUUID();broadcast(room,{type:'start',run:room.run,players:[...room.members.values()].map(member=>({id:member.id,name:member.name,skills:member.skills}))});return;
      }
      if(!room.started)return;
      if(m.type==='action'&&p.id!==room.host){send(room.members.get(room.host).ws,{type:'action',from:p.id,data:m.data});return;}
      if(m.type==='events'&&p.id===room.host&&Array.isArray(m.data)&&m.data.length<=4096){
        for(const member of room.members.values())if(member.id!==p.id){
          const data=m.data.filter(entry=>entry&&typeof entry==='object'&&(!entry.to||entry.to===member.id)).map(entry=>entry.data);
          if(data.length)send(member.ws,{type:'events',data});
        }
        return;
      }
      if(['event','delta'].includes(m.type)&&p.id===room.host){
        for(const member of room.members.values())if(member.id!==p.id&&(!m.to||m.to===member.id))send(member.ws,{type:m.type,data:m.data});
      }
    });
    ws.on('close',(code,reason)=>{onDiagnostic({event:'close',peer:p.id,code,reason:reason.toString(),age_ms:Date.now()-p.connectedAt,host:p.room?.host===p.id,max_payload:p.maxPayload});leave(p);peers.delete(ws);});
    ws.on('error',error=>onDiagnostic({event:'socket_error',peer:p.id,code:error.code,message:error.message}));
  });
  const heartbeat=setInterval(()=>{for(const [ws,p]of peers){if(!p.alive){onDiagnostic({event:'heartbeat_timeout',peer:p.id,age_ms:Date.now()-p.connectedAt});ws.terminate();continue;}p.alive=false;ws.ping();}},15000);heartbeat.unref();
  return {server,rooms,wss,listen:()=>new Promise(resolve=>server.listen(port,host,()=>resolve(server.address()))),close:()=>new Promise(resolve=>{clearInterval(heartbeat);for(const ws of peers.keys())ws.terminate();wss.close(()=>server.close(resolve));})};
}
if(process.argv[1]&&pathToFileURL(resolve(process.argv[1])).href===import.meta.url){
 const directory=resolve('..','test_output');
 const onDiagnostic=event=>{const line=JSON.stringify({time:new Date().toISOString(),...event});console.log(line);if(existsSync(directory)){try{appendFileSync(resolve(directory,'relay-runtime.jsonl'),line+'\n');}catch{}}};
 const relay=createRelay({port:Number(process.env.PORT||8080),host:process.env.HOST||'127.0.0.1',onDiagnostic});relay.listen().then(a=>console.log(`Relay ${a.address}:${a.port}`));
}
