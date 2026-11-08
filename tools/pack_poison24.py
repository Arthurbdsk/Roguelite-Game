"""Pack original water effects into the existing 16-frame renderer contract."""
from pathlib import Path
from PIL import Image
import statistics
im=Image.open('assets/v24/sources/poison_pool.png').convert('RGBA')
cells=[im.crop((round(x*im.width/4),round(y*im.height/4),round((x+1)*im.width/4),round((y+1)*im.height/4))) for y in range(4) for x in range(4)]
for c in cells:c.putalpha(c.getchannel('A').point(lambda v:255 if v>=170 else 0))
boxes=[c.getbbox() for c in cells[4:12]]
# The source is a ground plane. Normalize its common footprint to the circular
# damage region once, never resize individual loop frames independently.
box=tuple(round(statistics.median(b[i] for b in boxes)) for i in range(4))
out=Image.new('RGBA',(1024,64))
for i,c in enumerate(cells):
 c=c.crop(box).resize((64,64),Image.Resampling.NEAREST)
 c=c.quantize(colors=24,method=Image.Quantize.FASTOCTREE).convert('RGBA')
 out.alpha_composite(c,(64*i,0))
out.save('assets/v24/poison_pool.png')
print('assets/v24/poison_pool.png',out.size,'common footprint',box)
