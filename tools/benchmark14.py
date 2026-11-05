"""Windowed release comparison. Run without other game/test processes competing."""
import argparse, ctypes, hashlib, json, os, subprocess, time
from pathlib import Path
from ctypes import wintypes
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'test_output'
class Counters(ctypes.Structure):
    _fields_=[('cb',wintypes.DWORD),('PageFaultCount',wintypes.DWORD)]+[(name,ctypes.c_size_t) for name in ['PeakWorkingSetSize','WorkingSetSize','QuotaPeakPagedPoolUsage','QuotaPagedPoolUsage','QuotaPeakNonPagedPoolUsage','QuotaNonPagedPoolUsage','PagefileUsage','PeakPagefileUsage','PrivateUsage']]
kernel=ctypes.WinDLL('kernel32',use_last_error=True)
kernel.OpenProcess.argtypes=[wintypes.DWORD,wintypes.BOOL,wintypes.DWORD]
kernel.OpenProcess.restype=wintypes.HANDLE
kernel.CloseHandle.argtypes=[wintypes.HANDLE]
psapi=ctypes.WinDLL('psapi',use_last_error=True)
psapi.GetProcessMemoryInfo.argtypes=[wintypes.HANDLE,ctypes.POINTER(Counters),wintypes.DWORD]
def run(exe,tag):
    env=dict(os.environ,HORDAS_BENCH_OUTPUT=str(OUT))
    memory={};OUT.mkdir(exist_ok=True)
    with (OUT/f'benchmark14_{tag}.stdout.log').open('w',encoding='utf8') as log:
        process=subprocess.Popen([str(exe.resolve()),'--log-file',str(OUT/f'benchmark14_{tag}.runtime.log'),'--','--profile-slot=benchmark14',f'--benchmark14={tag}'],cwd=ROOT,env=env,stdout=log,stderr=log)
        handle=kernel.OpenProcess(0x410,False,process.pid)
        started=time.monotonic()
        try:
            while process.poll() is None:
                if time.monotonic()-started>240:process.kill();raise RuntimeError('Benchmark timeout')
                info=Counters();info.cb=ctypes.sizeof(info)
                if handle and psapi.GetProcessMemoryInfo(handle,ctypes.byref(info),info.cb):
                    try:scenario=(OUT/f'benchmark14_{tag}.current').read_text().strip()
                    except OSError:scenario='loading'
                    memory[scenario]=max(memory.get(scenario,0),info.WorkingSetSize/1048576)
                time.sleep(.05)
        finally:
            if handle:kernel.CloseHandle(handle)
        if process.returncode:raise RuntimeError(f'Benchmark exit {process.returncode}')
    report=json.loads((OUT/f'benchmark14_{tag}.json').read_text())
    report['exe_sha256']=hashlib.sha256(exe.read_bytes()).hexdigest()
    report['duration_wall_seconds']=time.monotonic()-started
    report['rss_peak_mb']=memory
    report['rss_source']='Windows GetProcessMemoryInfo WorkingSetSize, sampled 20Hz'
    (OUT/f'benchmark14_{tag}.json').write_text(json.dumps(report,indent=2),encoding='utf8')
    print(tag,[(r['scenario'],r['frame_ms']) for r in report['results']],flush=True)
    return report
if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--before',type=Path,default=ROOT/'build/baseline14.exe')
    parser.add_argument('--after',type=Path,default=ROOT/'build/Hordas-0.14.0/Hordas-0.14.0.exe')
    args=parser.parse_args()
    before=run(args.before,'before_final');after=run(args.after,'after_final')
    (OUT/'benchmark14_comparison.json').write_text(json.dumps({'before':before,'after':after},indent=2),encoding='utf8')
