"""Pack original generated grid art, preserving alpha and nearest pixels.

Uniform scale and a single fixed registration for the entire sheet. Attack
weapons and death poses never redefine the body pivot by their bounding box.
This is technical resampling/atlas packing, not drawing replacement art.
"""
import argparse, json, statistics
from pathlib import Path
from PIL import Image

p=argparse.ArgumentParser()
p.add_argument('source');p.add_argument('target');p.add_argument('--height',type=int,default=16)
p.add_argument('--cell',type=int,default=40);p.add_argument('--cols',type=int,default=4);p.add_argument('--rows',type=int,default=6)
p.add_argument('--flying',action='store_true')
a=p.parse_args()
im=Image.open(a.source).convert('RGBA')
cells=[im.crop((round(x*im.width/a.cols),round(y*im.height/a.rows),round((x+1)*im.width/a.cols),round((y+1)*im.height/a.rows))) for y in range(a.rows) for x in range(a.cols)]
for c in cells:c.putalpha(c.getchannel('A').point(lambda v:255 if v>=128 else 0))
bounds=[c.getbbox() for c in cells]
scale=a.height/statistics.median(b[3]-b[1] for b in bounds[:4] if b)
baseline=statistics.median(b[3] for b in bounds[:4] if b)
out=Image.new('RGBA',(a.cell*len(cells),a.cell))
for i,(c,b) in enumerate(zip(cells,bounds)):
 if not b:continue
 c=c.resize((max(1,round(c.width*scale)),max(1,round(c.height*scale))),Image.Resampling.NEAREST)
 c=c.quantize(colors=24,method=Image.Quantize.FASTOCTREE).convert('RGBA')
 # One common grid pivot. Never center the sword/wing silhouette per frame.
 x=round((a.cell-c.width)/2);y=round((a.cell-c.height)/2) if a.flying else a.cell-4-round(baseline*scale)
 out.alpha_composite(c,(i*a.cell+x,y))
target=Path(a.target);target.parent.mkdir(parents=True,exist_ok=True);out.save(target)
print(json.dumps({'file':str(target),'cell':a.cell,'frames':len(cells),'height':a.height,'scale':scale}))
