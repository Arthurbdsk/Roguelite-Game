from PIL import Image,ImageDraw
from pathlib import Path
import math,random
p=Path('assets/effects');p.mkdir(exist_ok=True)
def sheet(name,w,h,n,paint):
 im=Image.new('RGBA',(w*n,h))
 for f in range(n):
  a=Image.new('RGBA',(w,h));paint(ImageDraw.Draw(a),f);im.alpha_composite(a,(w*f,0))
 im.save(p/(name+'.png'))
def coin(d,f):
 r=[5,4,2,1,2,4,5,5][f];x=7
 d.ellipse((x-r,1,x+r,12),fill='#854017');d.ellipse((x-r,1,x+r,10),fill='#ffb82c')
 if r>1:
  d.ellipse((x-r+1,2,x+r-1,9),outline='#fff09b',fill='#e79a16');d.line((x-r+1,7,x+r-1,3),fill='#fff5b0',width=1)
 else:d.line((x,2,x,9),fill='#fff09b')
sheet('coin',16,16,8,coin)
def fire(d,f):
 rng=random.Random(f+40)
 for x in range(2,24):
  for y in range(7,18):
   if rng.random()<x/32 and abs(y-12)<(x/7):d.point((x,y),fill=rng.choice(['#a62b19','#e84a1c','#ff9a22']))
 d.polygon([(19,9),(24,7),(28,9),(29,12),(27,16),(23,17),(19,15)],fill='#f46420')
 d.ellipse((21,9,28,15),fill='#ffbe36');d.rectangle((24,10,27,13),fill='#fff2aa')
sheet('fire',32,24,6,fire)
def impact(d,f):
 rng=random.Random(100+f)
 for i in range(25):
  angle=rng.random()*math.tau;r=(f+1)*1.5+rng.random()*3;x=12+math.cos(angle)*r;y=12+math.sin(angle)*r
  d.rectangle((int(x),int(y),int(x)+1,int(y)+1),fill=['#fff2aa','#ffb32d','#f05c22','#9e311d'][min(3,f//2)])
sheet('impact',24,24,7,impact)
def flask(d,f):
 d.rectangle((8,1,13,3),fill='#965334');d.rectangle((9,4,12,7),fill='#79dbe0');d.polygon([(8,7),(13,7),(17,12),(17,19),(14,22),(7,22),(4,19),(4,12)],fill='#12637c')
 d.polygon([(8,9),(13,9),(15,13),(15,18),(13,20),(8,20),(6,18),(6,13)],fill='#65d8db');d.rectangle((7,13,14,18),fill='#39b94b');d.rectangle((8,12,13,19),fill='#172638')
 d.rectangle((9,13,12,16),fill='#eee4af');d.point((9,14),fill='#172638');d.point((12,14),fill='#172638');d.rectangle((10,17,11,18),fill='#eee4af');d.line((6,12,6,16),fill='#dcfff4')
sheet('flask',24,24,1,flask)
def pool(d,f):
 pts=[]
 for i in range(32):
  a=i*math.tau/32;r=29-(i*7%4);pts.append((32+int(math.cos(a)*r),32+int(math.sin(a)*r)))
 d.polygon(pts,fill='#304a29',outline='#859c45')
 for i in range(24):
  x=10+(i*17)%43;y=10+(i*23)%43
  if (x-32)**2+(y-32)**2<650:
   d.rectangle((x,y,x+3,y+1),fill='#526d34')
   if (i+f)%4==0:d.rectangle((x,y-2,x+2,y),outline='#a1b95a')
sheet('pool',64,64,6,pool)
def splash(d,f):
 rng=random.Random(32)
 for i in range(20):
  a=rng.random()*math.tau;r=(f+1)*rng.uniform(1,3);x=16+int(math.cos(a)*r);y=16+int(math.sin(a)*r)-int(math.sin(f/6*math.pi)*4)
  d.rectangle((x,y,x+1,y+1),fill='#73d4d6' if i%3==0 else '#72ac49')
sheet('splash',32,32,7,splash)
