"""Editable original pixel sprites, based on the Pinterest studies in VISUAIS_0_17.md.
No downloaded artwork is incorporated. Run with one weapon name at a time.
"""
from pathlib import Path
import math, sys
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1] / 'assets/v17'
INK = '#26202d'

def image(size):
    im = Image.new('RGBA', size)
    return im, ImageDraw.Draw(im)

def save(im, name):
    ROOT.mkdir(parents=True, exist_ok=True)
    im.save(ROOT / (name + '.png'))

def sheet(name, size, frames, paint):
    result = Image.new('RGBA', (size[0] * frames, size[1]))
    for frame in range(frames):
        im, draw = image(size)
        paint(draw, frame)
        result.alpha_composite(im, (frame * size[0], 0))
    save(result, name)

def garlic():
    im, d = image((32, 32))
    d.polygon([(14,2),(19,2),(18,8),(23,11),(27,17),(28,24),(24,29),(8,29),(4,25),(5,17),(10,11),(14,8)], fill=INK)
    d.polygon([(15,3),(18,3),(16,10),(22,12),(25,17),(26,24),(22,27),(9,27),(6,24),(7,17),(12,11),(15,9)], fill='#bba98d')
    d.polygon([(14,11),(18,11),(21,17),(21,25),(17,28),(12,26),(10,20)], fill='#f3e8c9')
    d.polygon([(11,13),(9,19),(9,24),(7,23),(8,17)], fill='#fff9e6')
    d.line([(16,12),(14,19),(14,25)], fill='#fff9e6', width=2)
    d.line([(20,14),(23,19),(23,24),(21,26)], fill='#dfd1b1', width=2)
    d.line([(14,28),(13,30),(17,29),(19,30)], fill='#947451')
    d.line([(16,3),(15,7)], fill='#d5c69f', width=1)
    save(im, 'garlic')
    def aura(d, f):
        # Pixel-stepped perimeter; no opaque disk over the ground.
        for ring in range(2):
            radius = 59 - ring*5
            pts = []
            for i in range(96):
                t = i*math.tau/96
                r = radius + (1 if (i+f*2)%12<4 else 0)
                pts.append((round((64+math.cos(t)*r)/2)*2, round((64+math.sin(t)*r)/2)*2))
            for i in range(96):
                if ring == 1 and (i+f*3)%16>8: continue
                d.line([pts[i],pts[(i+1)%96]], fill=(224,233,183,110 if ring==0 else 55), width=1)
        for i in range(10):
            t=i*math.tau/10+f*.07
            x,y=round(64+math.cos(t)*56),round(64+math.sin(t)*56)
            d.rectangle((x,y,x+1,y+1), fill=(255,244,205,170))
    sheet('garlic_aura',(128,128),6,aura)

def whip():
    im,d=image((32,32))
    pts=[(22,24),(27,19),(27,10),(22,5),(11,5),(5,10),(5,18),(11,23),(19,21),(22,15),(19,10),(12,10),(9,14),(12,17),(17,16)]
    d.line(pts,fill=INK,width=5);d.line(pts,fill='#9a522b',width=3);d.line(pts,fill='#e2a25b',width=1)
    d.line([(22,23),(17,29)],fill=INK,width=6);d.line([(22,23),(17,29)],fill='#70432c',width=4)
    d.line([(21,23),(17,28)],fill='#c28b51',width=1)
    for y in [24,26,28]:d.line((18,y,21,y),fill='#d6b469')
    save(im,'whip')
    def lash(d,f):
        lengths=[12,24,64,124,119,90,48,14]
        length=lengths[f]
        pts=[]
        for x in range(2,length,2):
            y=16+round(math.sin(x*.065-f*.65)*(7 if f<3 else 3))
            pts.append((x,y))
        if len(pts)>1:
            d.line(pts,fill=INK,width=5);d.line(pts,fill='#b9773d',width=3)
            d.line([(x,y-1) for x,y in pts],fill='#f1ca81',width=1)
            for i in range(3,len(pts),5):
                x,y=pts[i];d.point((x,y+1),fill='#6c3c24')
            x,y=pts[-1];d.rectangle((x-1,y-2,x+1,y+2),fill='#ffe7a4')
        if f in [3,4]:
            for x,y in [(120,6),(124,12),(121,24)]:d.line((x-2,y,x+1,y),fill='#ffecba')
    sheet('whip_lash',(128,32),8,lash)

def wand(kind):
    fire=kind=='fire_wand'
    im,d=image((32,32));d.line([(5,27),(23,9)],fill=INK,width=7)
    d.line([(5,27),(23,9)],fill='#6d4430',width=5);d.line([(5,26),(22,9)],fill='#cda773',width=2)
    for x,y in [(8,24),(12,20),(17,15)]:d.line((x-2,y-1,x+1,y+2),fill='#d8ba6b',width=2)
    d.polygon([(19,3),(26,2),(30,8),(25,15),(18,12),(17,7)],fill=INK)
    d.polygon([(20,4),(26,4),(28,8),(24,13),(19,11),(19,7)],fill='#a64f28' if fire else '#345aa0')
    d.polygon([(22,4),(26,5),(26,9),(22,12),(20,8)],fill='#ffb640' if fire else '#73daed')
    d.line([(22,5),(21,8),(23,9)],fill='#fff0b0' if fire else '#e4ffff',width=2)
    d.line([(18,6),(18,11),(22,15),(27,14)],fill='#d7b15b',width=2)
    save(im,kind)
    def missile(d,f):
        if fire:
            # Points right; the core stays centered at x=23, tail is cosmetic.
            d.polygon([(1,7+f%3),(12,8),(7,3),(19,6),(24,6),(29,10),(30,14),(26,18),(20,18),(12,16),(4,19),(9,13)],fill='#a94726')
            d.polygon([(7,10),(17,9),(15,6),(24,7),(28,11),(28,15),(24,17),(18,15),(11,16),(13,12)],fill='#ed842d')
            d.polygon([(17,9),(24,8),(27,11),(27,14),(24,16),(19,14),(15,14)],fill='#ffd66a')
            d.polygon([(22,9),(25,10),(26,13),(23,15),(20,12)],fill='#fff4cc')
            for i in range(3):
                x=2+(f*3+i*5)%12;y=5+(i*6+f*2)%15;d.point((x,y),fill='#f4aa47')
        else:
            d.polygon([(3,9),(13,9),(17,6),(23,7),(27,12),(22,17),(16,17),(12,14),(2,14),(7,12)],fill='#244f9d')
            d.polygon([(8,10),(16,10),(19,8),(23,9),(25,12),(22,15),(17,15),(14,13),(6,13)],fill='#58bdea')
            d.polygon([(18,10),(22,10),(23,12),(21,14),(18,13)],fill='#e5ffff')
            d.point((7+f%3,7),fill='#b4e6ff');d.point((4+f%4,16),fill='#68b9ed')
    sheet(kind+'_shot',(32,24),6,missile)
    def impact(d,f):
        colors=['#fff3c0','#ffc55a','#e98431'] if fire else ['#e8ffff','#89e3ff','#468dd7']
        for i in range(9):
            t=i*math.tau/9; r=2+f*1.35
            x=round(12+math.cos(t)*r);y=round(12+math.sin(t)*r)
            if (i+f)%4==0 and f>3:continue
            d.rectangle((x,y,x+(2 if f<3 else 1),y+1),fill=colors[i%3])
        if f<3:d.polygon([(12,7+f),(16-f,12),(12,16-f),(8+f,12)],fill=colors[0])
    sheet(kind+'_impact',(24,24),6,impact)

def runetracer():
    im,d=image((32,32))
    d.polygon([(16,1),(28,15),(16,30),(4,16)],fill=INK)
    d.polygon([(16,3),(26,15),(16,28),(6,16)],fill='#6265ae')
    d.polygon([(16,5),(23,15),(16,25),(9,16)],fill='#75dcdf')
    d.polygon([(16,6),(16,25),(9,16)],fill='#d2fff1')
    d.line([(17,11),(20,15),(16,20),(13,16),(17,11)],fill='#344b8f',width=2)
    d.point((8,15),fill='#ffffff');d.point((17,4),fill='#ffffff')
    save(im,'runetracer')
    def rune(d,f):
        d.polygon([(12,2),(18,12),(12,21),(5,12)],fill='#29335b')
        d.polygon([(12,3),(17,12),(12,20),(6,12)],fill='#7978c9')
        d.polygon([(12,4),(15,12),(12,18),(8,12)],fill='#73e2d7')
        d.polygon([(12,5),(12,17),(8,12)],fill='#c6fff1')
        d.line([(12,8),(14,12),(11,15)],fill='#426caa')
        if f%3==0:d.rectangle((17,4,18,5),fill='#e6deff')
    sheet('runetracer_shot',(24,24),6,rune)
    def trail(d,f):
        palette=['#6fb9cc','#b7a0d9','#e1c77b','#67ceba']
        for i in range(3):
            x=2+(i*3+f)%7;y=2+(i*2+f)%7
            d.rectangle((x,y,x+1,y+2),fill=palette[(i+f)%4])
    sheet('runetracer_trail',(12,12),6,trail)

if __name__=='__main__':
    kind=sys.argv[1]
    {'garlic':garlic,'whip':whip,'fire_wand':lambda:wand('fire_wand'),'magic_wand':lambda:wand('magic_wand'),'runetracer':runetracer}[kind]()
    print('Generated '+kind+' original transparent pixel sprites.')
