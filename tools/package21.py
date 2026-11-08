"""Collect PC 0.21 evidence without touching the frozen Android worktree."""
from pathlib import Path
import hashlib,json,shutil
r=Path(__file__).resolve().parents[1]; src=r/'build/refinement21'; dest=r/'docs/refinement21';dest.mkdir(exist_ok=True,parents=True)
names=['refinement21','rune21','garlic21','variants21','presentation21','adjustments18','weapons16','limits7','permanent_data9','permanent_effects9','network_foundation','network_backpressure','spatial14','devourer','slimes','holy_water','water12','soldier20','orc20','death21','visual19']
tests=[]
for name in names:
 text=(src/(name+'.log')).read_text(encoding='utf8');ok='_PASS' in text and not any(s in text for s in ['SCRIPT ERROR','ERROR:','FAIL']);assert ok,name
 tests.append({'test':name,'passed':ok,'evidence':[s for s in text.splitlines() if '_PASS' in s]})
(dest/'tests.json').write_text(json.dumps(tests,indent=2),encoding='utf8')
for tag in ['before','after']:
 data=json.loads((src/('bench-'+tag+'.json')).read_text(encoding='utf8'));assert data['windowed'] and 'empty resource directory' in data['runtime']
 shutil.copy2(src/('bench-'+tag+'.json'),dest/('pck-'+tag+'.json'))
native_before=json.loads((r/'test_output/benchmark14_before_final.json').read_text(encoding='utf8'));native_after=json.loads((r/'test_output/benchmark14_pc21_delivery.json').read_text(encoding='utf8'))
public=r/'build/Hordas-0.21.0/Hordas-0.21.0.exe';dev=r/'build/Hordas-DEV-0.21.0/Hordas-DEV-0.21.0.exe'
assert native_after['exe_sha256']==hashlib.sha256(public.read_bytes()).hexdigest()
(dest/'native-comparison.json').write_text(json.dumps({'before':native_before,'after':native_after,'note':'Legacy diagnostic emitted retained-object/resource warnings at exit in both versions. Not a long-session leak check.'},indent=2),encoding='utf8')
for source,target in [('19-arena-fields.png','arena-fields.png'),('orc-courtyard-death.png','orc-death.png'),('variants-courtyard.png','variants.png'),('19-upgrading.png','upgrading.png'),('bench-before-courtyard.png','before.png'),('bench-after-courtyard.png','after.png')]:shutil.copy2(src/source,dest/target)
for report in sorted((r/'test_output').glob('network14-*.json'),reverse=True):
 data=json.loads(report.read_text(encoding='utf8'))
 if not any('refinement_network21' in a for a in data.get('args',[])):continue
 peers=[]
 for i in range(4):
  log=(r/f'test_output/coop-{data["stamp"]}-{i}.runtime.log').read_text(encoding='utf8');assert 'COOP_MATCH_PEER_PASS' in log and not any(s in log for s in ['FAIL','ERROR:'])
  peers.append({'peer':i,'evidence':[s for s in log.splitlines() if 'REFINEMENT21_' in s or 'COOP_MATCH_PEER_PASS' in s]})
 (dest/'network.json').write_text(json.dumps({'stamp':data['stamp'],'args':data['args'],'peers':peers,'method':'Four local Godot processes, shipped public PCK in an empty resource directory, one rendered client, public WSS relay. Not four physical networks.'},indent=2),encoding='utf8');break
else:raise RuntimeError('Matching four-player run missing')
artifacts=[]
for p in [public,dev]:
 m=json.loads((p.parent/'build_manifest.json').read_text(encoding='utf8'));assert hashlib.sha256(p.read_bytes()).hexdigest()==m['sha256'];artifacts.append(m)
(dest/'artifacts.json').write_text(json.dumps(artifacts,indent=2),encoding='utf8')
(r/'build/SHA256SUMS-0.21.0.txt').write_text(''.join(a['sha256']+'  '+a['file']+'\n' for a in artifacts),encoding='utf8')
print('PC21_EVIDENCE_PASS',len(tests),'local suites, four peers, before/after metrics, two immutable exports')
