"""Build/check a platform-independent gameplay identity. No Android operations."""
from pathlib import Path
import argparse, hashlib, json, re
ROOT = Path(__file__).resolve().parents[1]
VERSION = '0.25.2'
MAIN_FUNCTIONS = ['enemy_base_health', 'enemy_health_factor', 'enemy_spawn_stats', 'spawn_enemy', 'enemy_scale', 'enemy_killed', 'clear_run', 'weapon_hit']
NETWORK_FUNCTIONS = ['host_tick', 'actor_states', 'apply_delta', 'apply_event', 'settle', 'finish']
def functions(text, names):
    result = []
    for name in names:
        match = re.search(r'^func '+name+r'\(.*?(?=^func |\Z)', text, re.M | re.S)
        if not match: raise RuntimeError('Missing shared gameplay function: '+name)
        result.append(match.group(0).strip())
    return '\n'.join(result)
def manifest(root=ROOT):
    files = {}
    paths = []
    for folder in ['data/enemies', 'data/weapons', 'data/upgrades', 'data/encounters', 'data/bosses', 'scripts/entities', 'scripts/bosses', 'scripts/world', 'scripts/progression', 'scripts/data', 'scenes/maps']:
        paths += [p for p in (root/folder).rglob('*') if p.suffix in ['.gd', '.tres', '.tscn', '.json']]
    paths += [p for p in (root/'scripts/combat').glob('*.gd') if p.name != 'new_weapon_visuals17.gd']
    paths += [p for p in (root/'data').glob('*.json') if p.name not in ['gameplay_manifest.json', 'mobile_build.json', 'icon_catalog.json']]
    paths += [root/p for p in ['data/network/coop.tres','scripts/network/coop_rules.gd','scripts/network/coop_wire.gd','scripts/network/snapshot_codec.gd','scripts/progression/run_mastery.gd']]
    for p in sorted(set(paths)):
        if not p.is_file(): raise RuntimeError('Missing gameplay source: '+str(p))
        source = p.read_text(encoding='utf-8-sig').replace('\r\n','\n')
        files[p.relative_to(root).as_posix()] = hashlib.sha256(source.encode()).hexdigest()
    for path, names in [('scripts/main.gd',MAIN_FUNCTIONS),('scripts/network/coop_session.gd',NETWORK_FUNCTIONS)]:
        source=functions((root/path).read_text(encoding='utf-8-sig'),names)
        files[path+'#shared'] = hashlib.sha256(source.encode()).hexdigest()
    digest=hashlib.sha256(json.dumps(files,sort_keys=True,separators=(',',':')).encode()).hexdigest()
    return {'version':VERSION,'protocol':2,'content_sha256':digest,'compatibility_id':VERSION+'+'+digest[:16],'files':files}
def check(root=ROOT):
    path=root/'data/gameplay_manifest.json'
    actual=manifest(root)
    if not path.is_file() or json.loads(path.read_text())!=actual:raise RuntimeError('Gameplay identity is stale; run tools/gameplay_manifest.py --write after reviewing changes')
    return actual
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--write',action='store_true');args=parser.parse_args()
    result=manifest() if args.write else check()
    if args.write:(ROOT/'data/gameplay_manifest.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
    print('GAMEPLAY_MANIFEST_PASS',result['compatibility_id'],len(result['files']),'sources')
