from pathlib import Path
import os,subprocess,time,json,hashlib,shutil
r=Path(__file__).resolve().parents[2];out=r/'build/update-qa';qa=Path(os.environ['APPDATA'])/'HordasUpdateQA';target=Path(os.environ['LOCALAPPDATA'])/'Hordas/Game/Hordas.exe';backup=target.with_name('Hordas.previous.exe')
assert str(target.resolve()).lower().endswith('hordas\\game\\hordas.exe')
if (qa/'profile.json').exists() and not (qa/'qa-owned').exists():raise RuntimeError('Existing unrelated QA profile')
qa.mkdir(exist_ok=True);(qa/'qa-owned').write_text('update test fixture')
def powershell(code):return subprocess.run(['powershell','-NoProfile','-Command',code],capture_output=True,text=True)
q=lambda p:str(p).replace("'","''")
check=powershell("Get-CimInstance Win32_Process | Where-Object {$_.ExecutablePath -eq '"+q(target)+"'} | Select-Object -ExpandProperty ProcessId")
assert not check.stdout.strip(),'Installed target is in use; leave it untouched'
previous=target.read_bytes() if target.exists() else None;previous_backup=backup.read_bytes() if backup.exists() else None
process=None
try:
 target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(out/'Hordas-QA-0.26.1.exe',target)
 resultfile=qa/'updates/result.txt'
 if resultfile.exists():resultfile.unlink()
 godot=Path.home()/'Downloads/Godot_v4.7.2-stable_win64_console.exe';isolated=out/'isolated';isolated.mkdir(exist_ok=True)
 with (out/'client.log').open('w',encoding='utf-8') as log:
  process=subprocess.Popen([str(godot),'--headless','--path',str(isolated),'--main-pack',str(out/'Hordas-QA-0.26.1.exe'),'--script',str(r/'tests/windows_update_e2e026.gd'),'--quit-after','60000','--','--self-test'],cwd=isolated,stdout=log,stderr=log)
  deadline=time.time()+600
  while process.poll() is None:
   if resultfile.exists() and resultfile.read_text()=='OK':break
   if 'SCRIPT ERROR' in (out/'client.log').read_text():raise RuntimeError((out/'client.log').read_text()[-2000:])
   if time.time()>deadline:raise RuntimeError('Client timeout')
   time.sleep(.5)
  code=process.returncode if process.returncode is not None else 0
 assert code==0 and 'E2E_DOWNLOADED' in (out/'client.log').read_text(),(out/'client.log').read_text()
 for _ in range(80):
  if resultfile.exists():break
  time.sleep(.5)
 assert resultfile.read_text()=='OK',resultfile.read_text() if resultfile.exists() else 'Helper timed out'
 before=json.loads((qa/'e2e-before.json').read_text());profile=qa/'profile.json';after=profile.read_bytes();assert json.loads(after)['gold']==321 and before['save_hash']==hashlib.sha256(after).hexdigest()
 assert target.read_bytes()==(out/'Hordas-QA-0.26.2.exe').read_bytes()
 report={'passed':True,'old':'0.26.1 QA','new':'0.26.2 QA','manifest_detected':True,'download':'public HTTPS temporary test CDN','downloaded_by_game':True,'authentication_and_hash':True,'restart_health_ack':True,'save_preserved':True,'fixture_gold':321,'isolated_user_data':True}
 (out/'e2e.json').write_text(json.dumps(report,indent=2));print('WINDOWS_UPDATE_E2E_PASS',json.dumps(report),flush=True)
finally:
 if process is not None and process.poll() is None:process.kill();process.wait()
 powershell("Get-CimInstance Win32_Process | Where-Object {$_.ExecutablePath -eq '"+q(target)+"' -and $_.CommandLine -like '*HordasUpdateQA*'} | ForEach-Object {Stop-Process -Id $_.ProcessId}")
 time.sleep(.5)
 if previous is not None:target.write_bytes(previous)
 elif target.exists():target.unlink()
 if previous_backup is not None:backup.write_bytes(previous_backup)
 elif backup.exists():backup.unlink()
