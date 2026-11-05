import http from 'node:http';
import {randomInt,randomUUID} from 'node:crypto';
import {WebSocketServer,WebSocket} from 'ws';
import {pathToFileURL} from 'node:url';
import {resolve} from 'node:path';
import {appendFileSync,existsSync} from 'node:fs';

export function createRelay({port=8080,host='127.0.0.1',maxRooms=100,onDiagnostic=()=>{},metricsToken=process.env.METRICS_TOKEN||""}={}) {
  const rooms=new Map(), peers=new Map();
  const server=http.createServer((req,res)=>{
    const health=req.url==='/health',authorized=req.url==='/metrics'&&metricsToken&&req.headers.authorization===`Bearer ${metricsToken}`;
    res.writeHead(health||authorized?200:404,{'Content-Type':'application/json','Cache-Control':'no-store'});
    res.end(JSON.stringify(health?{ok:true,protocol:2,supported:[1,2],rooms:rooms.size}:authorized?{rooms:rooms.size,peers:[...peers.values()].map(p=>({id:p.id,...p.metrics,transport_bytes:p.ws.bufferedAmount,critical_bytes:p.criticalBytes,snapshot_bytes:p.snapshot?.data.length||0,snapshot_age_ms:p.snapshot?Date.now()-p.snapshot.born:0}))}:{}));
  });
  const wss=new WebSocketServer({server,maxPayload:524288,perMessageDeflate:false});
  const rawSend=(p,data,binary=false)=>{if(p.ws.readyState!==WebSocket.OPEN)return;p.metrics.tx_bytes+=Buffer.byteLength(data);p.ws.send(data,{binary},err=>{if(err)onDiagnostic({event:'send_error',peer:p.id,message:err.message});});};
  const send=(ws,msg)=>{
    const p=peers.get(ws);if(!p||ws.readyState!==WebSocket.OPEN)return;
    const data=JSON.stringify(msg),bytes=Buffer.byteLength(data);
    if(p.critical.length||ws.bufferedAmount>65536){
      p.critical.push({data,born:Date.now()});p.criticalBytes+=bytes;
      if(p.criticalBytes>1048576){onDiagnostic({event:'critical_queue_limit',peer:p.id});ws.close(1013,'Slow connection');}
    }else rawSend(p,data);
  };
  const drain=setInterval(()=>{const now=Date.now();for(const room of rooms.values())if(room.loading&&now-room.loadingSince>30000){room.loading=false;for(const p of room.members.values())p.ready=false;broadcast(room,{type:'error',reason:'Tempo de carregamento esgotado. Tente iniciar novamente.'});lobby(room);}for(const p of peers.values()){
    if(p.ws.readyState!==WebSocket.OPEN)continue;
    if(p.critical[0]&&now-p.critical[0].born>10000||p.snapshot&&now-p.snapshot.born>10000){onDiagnostic({event:'queue_timeout',peer:p.id});p.ws.close(1013,'Queue timeout');continue;}
    while(p.critical.length&&p.ws.bufferedAmount<65536){const m=p.critical.shift();p.criticalBytes-=Buffer.byteLength(m.data);rawSend(p,m.data);}
    if(!p.critical.length&&p.snapshot&&p.ws.bufferedAmount<65536){const m=p.snapshot;p.snapshot=null;p.metrics.max_queue_age_ms=Math.max(p.metrics.max_queue_age_ms,now-m.born);rawSend(p,m.data,true);}
  }},10);drain.unref();
  server.maxConnections=512;
  const broadcast=(room,msg)=>{for(const p of room.members.values())send(p.ws,msg);};
  const lobby=room=>broadcast(room,{type:'lobby',challenge:room.challenge||0,map:room.map||'courtyard',code:room.code,host:room.host,players:[...room.members.values()].map(p=>({id:p.id,name:p.name,ready:p.ready,skills:p.skills,gold_remainder:p.goldRemainder||0}))});
  function leave(p) {
    if(!p.room)return;
    const room=p.room;p.room=null;room.members.delete(p.id);
    if(p.id===room.host){for(const other of room.members.values()){other.room=null;send(other.ws,{type:'closed',reason:'O criador da sala desconectou.'});}rooms.delete(room.code);}
    else if(room.members.size){broadcast(room,{type:'left',id:p.id});if(!room.started){room.loading=false;for(const member of room.members.values())member.ready=false;lobby(room);}}
  }
  wss.on('connection',ws=>{
    const p={id:randomUUID(),ws,room:null,name:'',ready:false,skills:{},window:Date.now(),tokens:600,byteTokens:16*1048576,alive:true,connectedAt:Date.now(),maxPayload:0,protocol:1,critical:[],criticalBytes:0,snapshot:null,metrics:{tx_bytes:0,rx_bytes:0,replaced:0,max_queue_age_ms:0,rtt_ms:0}};peers.set(ws,p);
    ws.on('pong',data=>{p.alive=true;if(data.length===8)p.metrics.rtt_ms=Date.now()-Number(data.readBigUInt64BE());});
    ws.on('message',(raw,isBinary)=>{
      p.metrics.rx_bytes+=raw.length;
      p.maxPayload=Math.max(p.maxPayload,raw.length);
      // Proxies can deliver several seconds of legitimate traffic in one burst.
      // Bound sustained traffic while allowing that backlog to drain.
      const now=Date.now(),elapsed=Math.max(0,now-p.window)/1000;p.window=now;
      p.tokens=Math.min(600,p.tokens+elapsed*120)-1;
      p.byteTokens=Math.min(16*1048576,p.byteTokens+elapsed*8*1048576)-raw.length;
      if(p.tokens<0||p.byteTokens<0){onDiagnostic({event:'rate_limit',peer:p.id,age_ms:now-p.connectedAt});ws.close(1008,'Rate limit');return;}
      if(isBinary){
        const room=p.room;
        if(p.protocol!==2||!room?.started||p.id!==room.host||raw.length<7||raw[0]!==72||raw[1]!==20||raw.readUInt32LE(2)>4194304){ws.close(1008,'Invalid snapshot');return;}
        for(const member of room.members.values())if(member.id!==p.id){
          if(member.snapshot)member.metrics.replaced++;
          // Complete snapshots have no baseline dependency. Only unsent state is replaced.
          member.snapshot={data:raw,born:member.snapshot?.born||Date.now()};
        }
        return;
      }
      let m;try{m=JSON.parse(raw.toString());}catch{return send(ws,{type:'error',reason:'Mensagem inválida.'});}
      if(!m||typeof m!=='object'||Array.isArray(m))return;
      const fail=reason=>send(ws,{type:'error',reason});
      if(m.type==='create'||m.type==='join') {
        if(m.protocol!==undefined&&m.protocol!==2)return fail('Protocolo incompatível. Atualize o jogo.');
        p.protocol=m.protocol===2?2:1;
        if(p.room)return fail('Você já está em uma sala.');
        const name=typeof m.name==='string'?m.name.trim().normalize('NFC'):'';
        if(!name||[...new Intl.Segmenter('pt',{granularity:'grapheme'}).segment(name)].length>8||/[\p{Cc}\p{Cf}\p{Cs}]/u.test(name))return fail('Nome deve ter entre 1 e 8 caracteres visíveis.');
        let room;
        if(m.type==='create'){
          if(rooms.size>=maxRooms)return fail('Serviço de salas ocupado.');
          const alphabet='ABCDEFGHJKLMNPQRSTUVWXYZ23456789';let code;
          do{code=Array.from({length:6},()=>alphabet[randomInt(alphabet.length)]).join('');}while(rooms.has(code));
          room={code,host:p.id,started:false,members:new Map(),protocol:p.protocol,build:typeof m.game_version==='string'?m.game_version:'legacy'};rooms.set(code,room);
        }else{
          const code=typeof m.code==='string'?m.code.trim().toUpperCase():'';
          if(!/^[A-HJ-NP-Z2-9]{6}$/.test(code)||!rooms.has(code))return fail('Código inválido ou sala encerrada.');
          room=rooms.get(code);if(room.started||room.loading)return fail('A partida já começou.');if(room.members.size>=4)return fail('Sala cheia.');
          if(room.protocol!==p.protocol)return fail('Protocolos diferentes. Atualize o jogo.');
          if(room.build!==(typeof m.game_version==='string'?m.game_version:'legacy'))return fail('Versões diferentes. Todos devem usar o mesmo executável atualizado.');
        }
        p.name=name;p.goldRemainder=Number.isFinite(m.gold_remainder)?Math.max(0,Math.min(.999999,m.gold_remainder)):0;p.skills=Object.fromEntries(Object.entries(m.skills||{}).filter(([k,v])=>/^[a-z_]{1,30}$/.test(k)&&Number.isInteger(v)&&v>=0&&v<=5).slice(0,16));
        if(m.type==='create')room.challenge=Math.max(0,Math.min(Number.isInteger(m.challenge)?m.challenge:0,p.skills.challenge||0,5));
        p.room=room;p.ready=false;room.members.set(p.id,p);send(ws,{type:'joined',id:p.id,code:room.code,host:room.host});lobby(room);return;
      }
      if(m.type==='ping'){send(ws,{type:'pong',stamp:m.stamp});return;}
      const room=p.room;if(!room)return fail('Entre em uma sala primeiro.');
      if(m.type==='leave'){leave(p);return;}
      if(m.type==='map'&&p.id===room.host&&!room.started&&!room.loading){if(['courtyard','library','fields'].includes(m.map)){room.map=m.map;for(const member of room.members.values())member.ready=false;lobby(room);}return;}
      if(m.type==='challenge'&&p.id===room.host&&!room.started&&!room.loading){room.challenge=Math.max(0,Math.min(Number.isInteger(m.value)?m.value:0,p.skills.challenge||0,5));for(const member of room.members.values())member.ready=false;lobby(room);return;}
      if(m.type==='loaded'&&room.loading){p.loaded=true;if([...room.members.values()].every(member=>member.loaded)){room.loading=false;room.started=true;broadcast(room,{type:'start',challenge:room.challenge||0,map:room.map||'courtyard',run:room.run,players:[...room.members.values()].map(member=>({id:member.id,name:member.name,skills:member.skills,gold_remainder:member.goldRemainder||0}))});}return;}
      if(m.type==='ready'&&!room.started){p.ready=m.ready===true;lobby(room);return;}
      if(m.type==='start'){
        if(p.id!==room.host)return fail('Somente o criador pode iniciar.');
        if(room.started)return fail('A partida já começou.');
        if([...room.members.values()].some(member=>!member.ready))return fail('Todos precisam estar prontos.');
        if(!['0.7.0','0.8.0','0.9.0','0.10.0','0.11.0','0.12.0','0.13.0','0.14.0'].includes(room.build.replace(/-dev$/,''))){room.started=true;room.run=randomUUID();broadcast(room,{type:'start',challenge:room.challenge||0,map:room.map||'courtyard',run:room.run,players:[...room.members.values()].map(member=>({id:member.id,name:member.name,skills:member.skills,gold_remainder:member.goldRemainder||0}))});return;}
        if(room.loading)return;room.loading=true;room.loadingSince=Date.now();room.run=randomUUID();for(const member of room.members.values())member.loaded=false;broadcast(room,{type:'prepare',map:room.map||'courtyard'});return;
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
    ws.on('close',(code,reason)=>{onDiagnostic({event:'close',peer:p.id,code,reason:reason.toString(),age_ms:Date.now()-p.connectedAt,host:p.room?.host===p.id,max_payload:p.maxPayload,metrics:p.metrics,critical_bytes:p.criticalBytes,remaining_snapshot:p.snapshot?.data.length||0});leave(p);peers.delete(ws);});
    ws.on('error',error=>onDiagnostic({event:'socket_error',peer:p.id,code:error.code,message:error.message}));
  });
  const heartbeat=setInterval(()=>{for(const [ws,p]of peers){if(!p.alive){onDiagnostic({event:'heartbeat_timeout',peer:p.id,age_ms:Date.now()-p.connectedAt});ws.terminate();continue;}p.alive=false;const stamp=Buffer.alloc(8);stamp.writeBigUInt64BE(BigInt(Date.now()));ws.ping(stamp);}},15000);heartbeat.unref();
  return {server,rooms,wss,listen:()=>new Promise(resolve=>server.listen(port,host,()=>resolve(server.address()))),close:()=>new Promise(resolve=>{clearInterval(heartbeat);clearInterval(drain);for(const ws of peers.keys())ws.terminate();wss.close(()=>server.close(resolve));})};
}
if(process.argv[1]&&pathToFileURL(resolve(process.argv[1])).href===import.meta.url){
 const directory=resolve('..','test_output');
 const onDiagnostic=event=>{const line=JSON.stringify({time:new Date().toISOString(),...event});console.log(line);if(existsSync(directory)){try{appendFileSync(resolve(directory,'relay-runtime.jsonl'),line+'\n');}catch{}}};
 const relay=createRelay({port:Number(process.env.PORT||8080),host:process.env.HOST||'127.0.0.1',onDiagnostic});relay.listen().then(a=>console.log(`Relay ${a.address}:${a.port}`));
}
