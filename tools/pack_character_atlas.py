"""Technical atlas packing: uniform nearest resampling, binary alpha and foot-pivot alignment."""
from PIL import Image
from pathlib import Path
import argparse,statistics
p=argparse.ArgumentParser();p.add_argument('source');p.add_argument('target');p.add_argument('--cols',type=int,default=8);p.add_argument('--rows',type=int,default=4);p.add_argument('--height',type=int,default=40);p.add_argument('--width',type=int,default=80);p.add_argument('--cellheight',type=int,default=64);a=p.parse_args()
im=Image.open(a.source).convert('RGBA');cw=im.width/a.cols;ch=im.height/a.rows
cells=[im.crop((round(x*cw),round(y*ch),round((x+1)*cw),round((y+1)*ch))) for y in range(a.rows) for x in range(a.cols)]
bounds=[c.getchannel('A').point(lambda n:255 if n>=112 else 0).getbbox() for c in cells]
scale=a.height/statistics.median(b[3]-b[1] for b in bounds[:4] if b)
out=Image.new('RGBA',(a.width*len(cells),a.cellheight))
for i,c in enumerate(cells):
 c=c.resize((round(c.width*scale),round(c.height*scale)),Image.Resampling.NEAREST)
 c.putalpha(c.getchannel('A').point(lambda n:255 if n>=112 else 0))
 c=c.quantize(colors=48,method=Image.Quantize.FASTOCTREE).convert('RGBA')
 b=c.getbbox()
 if not b:continue
 pixels=c.load();xs=[x for y in range(max(b[1],b[3]-3),b[3]) for x in range(b[0],b[2]) if pixels[x,y][3]>0]
 foot=statistics.median(xs) if xs else (b[0]+b[2])/2
 frame=Image.new('RGBA',(a.width,a.cellheight));frame.alpha_composite(c,(round(a.width/2-foot),a.cellheight-4-b[3]));out.alpha_composite(frame,(i*a.width,0))
Path(a.target).parent.mkdir(parents=True,exist_ok=True);out.save(a.target)
print(a.target,out.size)
