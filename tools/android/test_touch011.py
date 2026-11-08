"""Physical ADB swipes through native Android QA menus, isolated from public saves."""
from pathlib import Path
import argparse,subprocess,json,time
root=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--android-request',action='store_true');args=p.parse_args()
assert args.android_request,'Explicit Android authorization required'
assert subprocess.check_output(['git','branch','--show-current'],cwd=root,text=True).strip()=='codex/android-mobile'
adb=Path.home()/'AppData/Local/HordasAndroidToolchain/sdk/platform-tools/adb.exe'
out=root/'build/touch011';out.mkdir(exist_ok=True)
private='/data/user/0/com.socialy.hordas.qa/files/'
def a(*args):return subprocess.check_output([str(adb),'-s','emulator-5554',*args],timeout=40,stderr=subprocess.DEVNULL)
def put(name,value):
 local=out/name;local.write_text(json.dumps(value));a('push',str(local),'/data/local/tmp/'+name);a('shell','cp','/data/local/tmp/'+name,private+name)
def state():return json.loads(a('shell','cat',private+'scroll011-state.json'))
def prepare(page,target):
 nonce=str(time.time_ns());put('scroll011-command.json',{'page':page,'target':target,'nonce':nonce})
 for _ in range(100):
  try:
   s=state()
   if s['nonce']==nonce:return s
  except (subprocess.CalledProcessError,json.JSONDecodeError):pass
  time.sleep(.1)
 raise RuntimeError('Native menu fixture did not prepare '+page+' '+target)
a('wait-for-device');a('shell','am','force-stop','com.socialy.hordas.qa')
a('shell','rm','-f',private+'scroll011-command.json',private+'scroll011-state.json')
put('qa_request.json',{'mode':'scroll011'});a('shell','monkey','-p','com.socialy.hordas.qa','-c','android.intent.category.LAUNCHER','1')
results=[]
for page,target in [('upgrading','ChoiceScroll'),('upgrading','BuildScroll'),('tree','PermanentScroll'),('tree','PermanentDetailsScroll'),('collection','CollectionScroll'),('collection','CollectionDetails'),('bestiary','CreatureList'),('bestiary','CreatureDetails'),('settings','PageScroll'),('hub','PageScroll'),('maps','PageScroll'),('mobile_privacy','PageScroll'),('mobile_terms','PageScroll'),('updates','UpdatesScroll'),('keyboard','KeyboardScroll')]:
 s=prepare(page,target)
 if s['max']<=0:
  results.append({'page':page,'target':target,'fits_without_scroll':True});print('FITS',page,target,flush=True);continue
 a('shell','input','swipe',*[str(v) for v in s['point']+s['end']],'1100');time.sleep(.45);d=state()
 values=sorted(set(row[1] for row in d['trace']));partial=[v for v in values if 0<v<s['max']]
 ok=d['screen']==s['expected_screen'] and d['presses']==0 and d['value']>min(15,s['max']*.3) and d['started']==1 and len(partial)>=(1 if s['max']<30 else 3)
 row={'page':page,'target':target,'passed':ok,'offset':d['value'],'max':s['max'],'intermediate_offsets':partial,'native_scroll_started':d['started'],'native_scroll_ended':d['ended'],'accidental_presses':d['presses']};results.append(row);print('SWIPE',json.dumps(row),flush=True)
 (out/'native-scroll-results.json').write_text(json.dumps({'passed':all(r.get('passed',True) for r in results),'device':'Android 15 API35 emulator, real adb input swipe','results':results},indent=2))
 assert ok,row
s=prepare('upgrading','ChoiceScroll');a('shell','input','tap',*[str(v) for v in s['point']]);time.sleep(.4);d=state();assert d['screen']=='running' and d['presses']==1,d
report={'passed':True,'device':'Android 15 API35 emulator, real adb input swipe','results':results,'tap_selects_one_upgrade':True}
(out/'native-scroll-results.json').write_text(json.dumps(report,indent=2));print('NATIVE_TOUCH011_PASS',flush=True)
