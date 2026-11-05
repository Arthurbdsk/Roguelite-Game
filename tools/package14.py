"""Package the relay allowlist, checksums and reproducible long-session evidence."""
from pathlib import Path
import hashlib,json,zipfile
ROOT=Path(__file__).resolve().parents[1]
build=ROOT/'build'
dest=ROOT/'docs/benchmarks'
run=1793907692011
report=json.loads((ROOT/f'test_output/network14-{run}.json').read_text(encoding='utf8'))
for i,event in enumerate(report['diagnostics']):
    if 'peer' in event:event['peer']='host' if event.get('host') else 'client-'+str(i)
clients=[]
for i in range(4):
    lines=(ROOT/f'test_output/coop-{run}-{i}.runtime.log').read_text(encoding='utf8').splitlines()
    metric=json.loads(next(line.split('NETWORK14_METRICS ',1)[1] for line in lines if line.startswith('NETWORK14_METRICS ')))
    clients.append({'index':i,'metrics':metric,'evidence':[line for line in lines if line.startswith(('SOAK_DURATION','SOAK_CAMPAIGN','COOP_MATCH_PEER_PASS'))]})
report['participants']=clients
report['note']='Local processes, one rendered; not internet validation. Candidate predates final spawn placement and cadence corrections.'
(dest/'soak30_local.json').write_text(json.dumps(report,indent=2),encoding='utf8')
files=['relay/Dockerfile','relay/.dockerignore','relay/compose.yaml','relay/Caddyfile','relay/.env.example','relay/server.mjs','relay/package.json','relay/package-lock.json','tools/configure_relay.py','docs/ONLINE_0_14.md']
with zipfile.ZipFile(build/'Relay-0.14.0.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for name in files:archive.write(ROOT/name,name)
assets=[build/'Hordas-0.14.0/Hordas-0.14.0.exe',build/'Hordas-DEV-0.14.0/Hordas-DEV-0.14.0.exe',build/'Relay-0.14.0.zip']
(build/'SHA256SUMS-0.14.0.txt').write_text(''.join(hashlib.sha256(path.read_bytes()).hexdigest()+'  '+path.name+'\n' for path in assets),encoding='utf8')
print('Packaged',*[path.name for path in assets])
