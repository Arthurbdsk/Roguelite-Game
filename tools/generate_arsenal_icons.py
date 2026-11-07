from PIL import Image,ImageDraw
for id in ['axe','boomerang','bombs','ice_wave']:
 im=Image.new('RGBA',(16,16));d=ImageDraw.Draw(im)
 if id=='axe':d.line((4,14,11,3),fill='#987344',width=3);d.polygon([(7,2),(14,1),(14,7),(9,8)],fill='#d8e2da',outline='#53667b')
 if id=='boomerang':d.line([(2,12),(8,3),(14,12)],fill='#c69d56',width=4);d.line([(3,11),(8,4),(13,11)],fill='#f0d692',width=1)
 if id=='bombs':d.ellipse((2,5,13,15),fill='#38414d',outline='#a7987b');d.line([(8,5),(8,2),(12,2)],fill='#d8a960');d.point((13,1),fill='#ffe4a1')
 if id=='ice_wave':
  for x,y in [(2,8),(5,3),(10,2),(13,7),(10,13),(4,13)]:d.polygon([(x,y-2),(x+2,y),(x,y+3),(x-1,y)],fill='#a1dfee')
 im.save('assets/icons/'+id+'.png')
