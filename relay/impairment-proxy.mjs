import net from 'node:net';
// TCP byte stream proxy. Delays and stalls preserve byte order: this is not UDP loss.
export async function createImpairmentProxy(target,{rtt=100,jitter=10,kbps=2048,stallEvery=0,seed=140031}={}){
 let state=seed>>>0;const random=()=>{state=(Math.imul(state,1664525)+1013904223)>>>0;return state/4294967296;};
 const sockets=new Set(),timers=new Set();const metrics={bytes:0,stalls:0,queue_peak:0};
 const server=net.createServer(client=>{
  const upstream=net.connect(target.port,target.address);sockets.add(client);sockets.add(upstream);client.setNoDelay(true);upstream.setNoDelay(true);
  function pipe(from,to){let next=0,count=0,pending=0,timer=null;const queue=[];
   function pump(){if(timer||!queue.length||to.destroyed)return;const job=queue[0];timer=setTimeout(()=>{timers.delete(timer);timer=null;queue.shift();pending-=job.chunk.length;if(!to.destroyed){to.write(job.chunk);if(pending<524288)from.resume();pump();}},Math.max(0,Math.ceil(job.due-Date.now())));timers.add(timer);}
   from.on('data',chunk=>{
    pending+=chunk.length;if(pending>1048576)from.pause();metrics.bytes+=chunk.length;metrics.queue_peak=Math.max(metrics.queue_peak,pending);
    const now=Date.now(),delay=Math.max(0,rtt/2+(random()*2-1)*jitter),transmission=chunk.length*8/kbps;
    next=Math.max(next,now+delay)+transmission;if(stallEvery&&++count%stallEvery===0){next+=200;metrics.stalls++;}
    queue.push({due:next,chunk});pump();
   });from.on('end',()=>{const end=()=>{if(!to.destroyed&&queue.length)setTimeout(end,20);else to.end();};end();});from.on('error',()=>to.destroy());from.on('close',()=>{sockets.delete(from);if(timer){clearTimeout(timer);timers.delete(timer);}to.destroy();});
  }
  pipe(client,upstream);pipe(upstream,client);
 });
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 return {address:server.address(),metrics,close:async()=>{for(const timer of timers)clearTimeout(timer);for(const socket of sockets)socket.destroy();await new Promise(resolve=>server.close(resolve));}};
}
