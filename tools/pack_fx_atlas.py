"""Pack fixed-centre FX cells with nearest sampling and binary alpha."""
from pathlib import Path
from PIL import Image
import argparse
p=argparse.ArgumentParser();p.add_argument('source');p.add_argument('target');p.add_argument('--cols',type=int,default=4);p.add_argument('--rows',type=int,default=1);p.add_argument('--size',type=int,default=32);p.add_argument('--icon');p.add_argument('--align-centers',action='store_true');a=p.parse_args()
im=Image.open(a.source).convert('RGBA');cw=im.width/a.cols;ch=im.height/a.rows
cells=[im.crop((round(x*cw),round(y*ch),round((x+1)*cw),round((y+1)*ch))) for y in range(a.rows) for x in range(a.cols)]
for c in cells:c.putalpha(c.getchannel('A').point(lambda n:255 if n>=112 else 0))
bounds=[c.getbbox() for c in cells if c.getbbox()]
box=(min(b[0] for b in bounds),min(b[1] for b in bounds),max(b[2] for b in bounds),max(b[3] for b in bounds))
scale=(a.size-2)/(max(max(b[2]-b[0],b[3]-b[1]) for b in bounds) if a.align_centers else max(box[2]-box[0],box[3]-box[1]))
out=Image.new('RGBA',(a.size*len(cells),a.size))
for i,c in enumerate(cells):
 b=c.getbbox() if a.align_centers else box
 c=c.resize((round(c.width*scale),round(c.height*scale)),Image.Resampling.NEAREST).quantize(colors=48,method=Image.Quantize.FASTOCTREE).convert('RGBA')
 at=(round(a.size/2-(b[0]+b[2])/2*scale),round(a.size/2-(b[1]+b[3])/2*scale))
 frame=Image.new('RGBA',(a.size,a.size));frame.alpha_composite(c,at);out.alpha_composite(frame,(a.size*i,0))
Path(a.target).parent.mkdir(parents=True,exist_ok=True);out.save(a.target);print(a.target,out.size)
if a.icon:out.crop((0,0,a.size,a.size)).resize((16,16),Image.Resampling.NEAREST).save(a.icon)
