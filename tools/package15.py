"""Save measured evidence and checksums for the 0.15.0 artifacts."""
from pathlib import Path
import json,hashlib
root=Path(__file__).resolve().parents[1];out=root/'test_output';dest=root/'docs/benchmarks'
frequency=json.loads((out/'15-frequency.json').read_text(encoding='utf8'))
(dest/'consumable_frequency_0_15.json').write_text(json.dumps(frequency,indent=2),encoding='utf8')
lines=(out/'15-load.log').read_text(encoding='utf8').splitlines()
load=json.loads(next(line.split('LOAD15 ',1)[1] for line in lines if line.startswith('LOAD15 ')))
load['completion']=next(line for line in lines if line.startswith('LOAD15_EXACT_XP'))
load['method']='Godot editor executable with rendered window; not native release FPS or four physical machines.'
(dest/'consumable_load_0_15.json').write_text(json.dumps(load,indent=2),encoding='utf8')
for report in sorted(out.glob('network14-*.json'),reverse=True):
 data=json.loads(report.read_text(encoding='utf8'));args=data.get('args',[])
 if not any('consumables_network15' in a for a in args) or not any('0.15.0' in a for a in args) or not any('relay-url=wss://hordas-relay.onrender.com' in a for a in args):continue
 records=[]
 for i in range(4):
  log=(out/f'coop-{data["stamp"]}-{i}.runtime.log').read_text(encoding='utf8')
  if 'COOP_MATCH_PEER_PASS' not in log or 'FAIL' in log:raise RuntimeError('Selected network run failed')
  records.append({'peer':i,'evidence':[line for line in log.splitlines() if line.startswith('COOP_MATCH_PEER_PASS')]})
 (dest/'consumable_network_0_15.json').write_text(json.dumps({'stamp':data['stamp'],'args':args,'peers':records,'method':'Four local processes through the public relay. Separate physical networks not tested.'},indent=2),encoding='utf8');break
else:raise RuntimeError('No matching public four-player test found')
assets=[root/'build/Hordas-0.15.0/Hordas-0.15.0.exe',root/'build/Hordas-DEV-0.15.0/Hordas-DEV-0.15.0.exe']
(root/'build/SHA256SUMS-0.15.0.txt').write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.name+'\n' for p in assets),encoding='utf8')
print('Evidence and artifact checksums saved.')
