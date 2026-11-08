"""Explicit, one-release Android metadata update. Never called from PC scripts."""
from pathlib import Path
import argparse,json,subprocess
root=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser();parser.add_argument('--android-request',action='store_true');args=parser.parse_args()
assert args.android_request and subprocess.check_output(['git','branch','--show-current'],cwd=root,text=True).strip()=='codex/android-mobile'
pc=root.parent/'Jogo Teste'
p=root/'project.godot';s=p.read_text().replace('0.20.0-android.1','0.25.0-android.2').replace('compatible_game_version="0.20.0"','compatible_game_version="0.25.0"');p.write_text(s)
pc_lines=(pc/'export_presets.cfg').read_text().splitlines()
include=next(line for line in pc_lines if line.startswith('include_filter=')).replace('network.cfg,','')[:-1]+',data/mobile_build.json"'
exclude=next(line for line in pc_lines if line.startswith('exclude_filter='))
p=root/'export_presets.cfg';s=p.read_text().replace('0.20.0-android.1','0.25.0-android.2').replace('Hordas-Android-0.20.0-1','Hordas-Android-0.25.0-2').replace('version/code=1','version/code=2');lines=s.splitlines();result=[];qa=False
for line in lines:
 if line=='[preset.1]':qa=True
 if line.startswith('include_filter='):line=include
 if line.startswith('exclude_filter='):line=exclude if qa else exclude[:-1]+',scripts/mobile/qa.gd,scripts/mobile/crossplay25_qa.gd"'
 result.append(line)
p.write_text('\n'.join(result)+'\n')
p=root/'scripts/core/profile.gd';s=p.read_text().replace('"effects": 0.7, "shake": true','"effects": 0.35, "shake": false');p.write_text(s)
p=root/'tools/android/export_android.py';s=p.read_text().replace('Hordas-Android-0.20.0-1','Hordas-Android-0.25.0-2');s=s.replace('import argparse, hashlib, json, os, subprocess, sys','import argparse, hashlib, json, os, subprocess, sys\nsys.path.insert(0,str(Path(__file__).resolve().parents[1]))\nfrom gameplay_manifest import check');s=s.replace("if branch!='codex/android-mobile':raise SystemExit('Use the isolated codex/android-mobile worktree.')","if branch!='codex/android-mobile':raise SystemExit('Use the isolated codex/android-mobile worktree.')\ncheck(ROOT)");p.write_text(s)
commit=subprocess.check_output(['git','rev-parse','codex/pc-art24'],cwd=root,text=True).strip()
commits=subprocess.check_output(['git','log','--reverse','--format=%H','4b6e2e5..'+commit],cwd=root,text=True).splitlines()
data={'mobile_version':'0.25.0-android.2','android_version_code':2,'base_pc_version':'0.25.0','base_pc_commit':commit,'incorporated_pc_commits':commits,'previous_mobile_commit':'d21c73d542584b83c798e54d8bcc810e999a2f87','protocol':2,'compatible_game_version':'0.25.0','compatibility_id':json.loads((root/'data/gameplay_manifest.json').read_text())['compatibility_id'],'application_id':'com.socialy.hordas.android','authorized_update':'2026-11-08','maintenance':'Frozen after this delivery; new explicit Android request required.'}
(root/'data/mobile_build.json').write_text(json.dumps(data,indent=2)+'\n')
print('ANDROID25_METADATA_PASS base',commit)
