"""Verify actual pixel data against the released PC sprites, not node scales alone."""
from pathlib import Path
import json,hashlib
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
def check(root=ROOT):
 reference=json.loads((root/'data/mobile/pc_visual_reference.json').read_text(encoding='utf8'))
 failures=[]
 for name,record in reference['characters'].items():
  path=root/record['texture'].removeprefix('res://')
  with Image.open(path) as image:
   image=image.convert('RGBA')
   pixels=bytearray(image.tobytes())
   for i in range(0,len(pixels),4):
    if pixels[i+3]==0:pixels[i:i+3]=b'\0\0\0'
   if list(image.size)!=record['image'] or hashlib.sha256(pixels).hexdigest()!=record['rgba_sha256']:failures.append(name+': '+record['texture'])
 if failures:raise SystemExit('PC visual reference mismatch: '+', '.join(failures))
 print('VISUAL_ASSETS011_PASS',len(reference['characters']),'actual PC sprite references')
 return reference
if __name__=='__main__':check()
