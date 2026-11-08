"""PC-only, windowed editor runtime against immutable before/after release PCKs.
Native release metrics are measured separately by benchmark14.py.
"""
from pathlib import Path
import subprocess,os,json,ctypes,time,hashlib
import benchmark14
r=Path(__file__).resolve().parents[1]; out=r/'build/audit24';out.mkdir(exist_ok=True,parents=True)
isolated=Path.home()/'AppData/Local/HordasPC24Benchmark';isolated.mkdir(parents=True,exist_ok=True)
for tag,exe in [('before',r/'build/Hordas-0.23.0/Hordas-0.23.0.exe'),('after',r/'build/Hordas-0.24.0/Hordas-0.24.0.exe')]:
 target=out/('bench-'+tag)
 target.with_suffix('.json').unlink(missing_ok=True)
 with (out/('bench-'+tag+'.log')).open('w',encoding='utf8') as log:
  p=subprocess.Popen([str(Path.home()/'Downloads/Godot_v4.7.2-stable_win64.exe'),'--path',str(isolated),'--main-pack',str(exe),'--script',str(r/'tests/benchmark24.gd'),'--','--self-test','--profile-slot=bench24_'+tag],cwd=isolated,env={**os.environ,'BENCH22_OUTPUT':str(target)},stdout=log,stderr=log)
  handle=benchmark14.kernel.OpenProcess(0x410,False,p.pid);peak=0;started=time.monotonic()
  try:
   while p.poll() is None:
    if time.monotonic()-started>100:subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],capture_output=True);raise RuntimeError('Benchmark timed out, inspect log')
    info=benchmark14.Counters();info.cb=ctypes.sizeof(info)
    if handle and benchmark14.psapi.GetProcessMemoryInfo(handle,ctypes.byref(info),info.cb):peak=max(peak,info.WorkingSetSize)
    time.sleep(.1)
  finally:
   if handle:benchmark14.kernel.CloseHandle(handle)
  if p.returncode:raise RuntimeError('Benchmark failed, inspect log')
 if 'ERROR:' in (out/('bench-'+tag+'.log')).read_text(encoding='utf8'):raise RuntimeError('Benchmark emitted errors, inspect log')
 report=json.loads(target.with_suffix('.json').read_text(encoding='utf8'));report['runtime']='Godot editor executing the shipped PCK in an empty resource directory, not native release FPS';report['exe_sha256']=hashlib.sha256(exe.read_bytes()).hexdigest();report['rss_peak_bytes']=peak;report['wall_seconds']=time.monotonic()-started;target.with_suffix('.json').write_text(json.dumps(report,indent=2),encoding='utf8');print(tag,report['results'],flush=True)
