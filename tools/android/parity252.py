"""Native Android parity verification, only under explicit Android authorization."""
from pathlib import Path
import argparse,json,subprocess,time,math
parser=argparse.ArgumentParser();parser.add_argument('--android-request',action='store_true');args=parser.parse_args();assert args.android_request
root=Path(__file__).resolve().parents[2];out=root/'build/update252';out.mkdir(exist_ok=True)
adb=Path.home()/'AppData/Local/HordasAndroidToolchain/sdk/platform-tools/adb.exe'
def run(*args):return subprocess.check_output([str(adb),'-s','emulator-5554',*map(str,args)],timeout=90)
request=out/'request.json';request.write_text('{"mode":"parity252"}')
run('shell','am','force-stop','com.socialy.hordas.android');run('shell','am','force-stop','com.socialy.hordas.qa')
run('install','-r',root/'build/Hordas-Android-0.25.2-4-QA.apk')
run('shell','rm','-f','/data/user/0/com.socialy.hordas.qa/files/parity252-result.json')
run('push',request,'/data/local/tmp/hordas252-request.json');run('shell','cp','/data/local/tmp/hordas252-request.json','/data/user/0/com.socialy.hordas.qa/files/qa_request.json');run('shell','chmod','644','/data/user/0/com.socialy.hordas.qa/files/qa_request.json')
run('logcat','-c');run('shell','monkey','-p','com.socialy.hordas.qa','-c','android.intent.category.LAUNCHER','1')
for _ in range(45):
 time.sleep(1)
 p=subprocess.run([str(adb),'shell','cat','/data/user/0/com.socialy.hordas.qa/files/parity252-result.json'],capture_output=True)
 if p.returncode==0:
  native=json.loads(p.stdout);break
else:
 (out/'logcat.txt').write_bytes(run('logcat','-d'));raise RuntimeError('Native parity did not complete; inspect logcat')
(out/'native.json').write_text(json.dumps(native,indent=2));assert native['passed'],native['failures']
pc=json.loads((root.parent/'Jogo Teste/build/parity252-public-pc.json').read_text())
fields=0
exact=pc==native['combat']
def compare(a,b,path=''):
 global fields
 if isinstance(a,dict):
  assert a.keys()==b.keys(),path
  for k in a:compare(a[k],b[k],path+'/'+k)
 elif isinstance(a,list):
  assert len(a)==len(b),path
  for i,(x,y) in enumerate(zip(a,b)):compare(x,y,path+'/'+str(i))
 elif isinstance(a,(int,float)) and not isinstance(a,bool):fields+=1;assert math.isclose(a,b,rel_tol=1e-7,abs_tol=1e-5),(path,a,b)
 else:fields+=1;assert a==b,(path,a,b)
compare(pc,native['combat'])
report={'passed':True,'exact_json_equivalence':exact,'compared_values':fields,'weapon_cases':len(pc['weapons']),'enemy_cases':len(pc['enemies']),'spawn_cases':len(pc['rates']),'identity':native['identity'],'visuals':native['visuals'],'physical_device':False}
(out/'comparison.json').write_text(json.dumps(report,indent=2));(out/'native.png').write_bytes(run('exec-out','screencap','-p'));run('shell','am','force-stop','com.socialy.hordas.qa')
print('NATIVE_PARITY252_PASS',json.dumps(report))
