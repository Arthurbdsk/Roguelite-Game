"""Native Android DOWN/MOVE/UP while XP opens a real upgrade screen."""
from pathlib import Path
import argparse,subprocess,json,time
root=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--android-request',action='store_true');args=p.parse_args();assert args.android_request
assert subprocess.check_output(['git','branch','--show-current'],cwd=root,text=True).strip()=='codex/android-mobile'
adb=Path.home()/'AppData/Local/HordasAndroidToolchain/sdk/platform-tools/adb.exe';out=root/'build/choice012';out.mkdir(exist_ok=True)
private='/data/user/0/com.socialy.hordas.qa/files/'
def a(*args):return subprocess.check_output([str(adb),'-s','emulator-5554',*args],timeout=40,stderr=subprocess.DEVNULL)
def state():return json.loads(a('shell','cat',private+'choice012-state.json'))
def wait(phase):
 for _ in range(100):
  try:
   d=state()
   if d['phase']==phase and (phase!='held' or d.get('card_ready',False)):return d
  except (subprocess.CalledProcessError,json.JSONDecodeError):pass
  time.sleep(.1)
 raise RuntimeError('Native choice phase timeout '+phase)
results=[];held=False;at=[440,840]
try:
 a('wait-for-device')
 for context in ['solo','host','client']:
  a('shell','am','force-stop','com.socialy.hordas.qa');a('shell','rm','-f',private+'choice012-state.json',private+'choice012-arm')
  f=out/'qa_request.json';f.write_text(json.dumps({'mode':'choice012','context':context}));a('push',str(f),'/data/local/tmp/choice012-request.json');a('shell','cp','/data/local/tmp/choice012-request.json',private+'qa_request.json');a('shell','monkey','-p','com.socialy.hordas.qa','-c','android.intent.category.LAUNCHER','1')
  d=wait('joystick');at=d['joystick'];a('shell','input','motionevent','DOWN',*map(str,at));held=True
  d=wait('held');assert d['blocked'] and d['disabled'] and d['contacts']>0 and d['passed'],d
  at=d['card'];a('shell','input','motionevent','MOVE',*map(str,at));time.sleep(.6);d=state();assert d['phase']=='held' and d['passed'] and d['disabled'],d
  a('shell','input','motionevent','UP',*map(str,at));held=False;d=wait('fresh_required');time.sleep(.3);d=state();assert d['phase']=='fresh_required' and d['passed'] and not d['blocked'],d
  a('shell','touch',private+'choice012-arm');time.sleep(.1);a('shell','input','tap',*map(str,at));d=wait('complete');assert d['passed'],d
  results.append(d);print('NATIVE_HELD_CHOICE_PASS',context,flush=True)
finally:
 if held:a('shell','input','motionevent','UP',*map(str,at))
(out/'native-results.json').write_text(json.dumps({'passed':True,'device':'Android 15 API35 emulator','input':'real Android DOWN/MOVE/UP and new tap','results':results},indent=2));print('NATIVE_CHOICE012_PASS',flush=True)
