"""Original native-resolution skeletons and gold. Python + Pillow, no filtering.

Six frames per skeleton: four steps, anticipation, attack/recovery.
This generator adds assets without regenerating or changing existing artwork.
"""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / 'assets'
C = {'ink':'#0b1014','shadow':'#7d7965','bone':'#d7c9a1','light':'#eee0b8',
     'mid':'#aca487','iron':'#39464a','edge':'#6b7470','rust':'#b65f42',
     'hood':'#2a2639','cloth':'#4a3d5c','eye':'#e89161','wood':'#8b6247'}

def skeleton(archer=False):
    atlas = Image.new('RGBA', (32*6,36))
    for f in range(6):
        im = Image.new('RGBA',(32,36)); d=ImageDraw.Draw(im)
        bob = int(f in (1,3)); lift = -2 if f==4 else (1 if f==5 else 0)
        def line(points,c,w=1): d.line(points,fill=C.get(c,c),width=w)
        def rect(box,c): d.rectangle(box,fill=C.get(c,c))
        def poly(points,c): d.polygon(points,fill=C.get(c,c))
        # Tibias, knee joints and articulated feet remain separate from the cape.
        for x, step in [(12, int(f==1)),(18,int(f==3))]:
            line([(x,23),(x-1,27-step),(x,32-step)],'ink',4)
            line([(x,23),(x-1,27-step),(x,32-step)],'mid',2)
            rect((x-2,32-step,x+2,33-step),'ink')
            line([(x-1,32-step),(x+1,32-step)],'bone')
        if archer:
            poly([(11,12+bob),(19,12+bob),(22,26),(17,28),(13,25),(8,27)],'ink')
            poly([(12,13+bob),(18,13+bob),(20,24),(17,26),(13,23),(10,25)],'hood')
            line([(18,14+bob),(19,23)],'cloth')
            # Quiver and arrows extend above the shoulder.
            line([(21,11),(22,22)],'wood',3)
            for x in (20,22,24):
                line([(x,6),(x-1,14)],'mid')
                line([(x-1,6),(x+1,6)],'bone')
        # Rib cage: outlined ivory arcs separated by the dark intercostal gaps.
        rect((10,13+bob,19,22+bob),'ink')
        line([(15,13+bob),(15,24)],'shadow',2)
        for y in (14,17,20):
            line([(11,y+bob),(13,y+1+bob),(18,y+bob)],'mid',2)
            line([(11,y+bob),(13,y+bob)],'bone')
        line([(12,24),(18,24)],'bone',2)
        # Skull and jaw.
        poly([(11,3+bob),(18,3+bob),(20,6+bob),(19,11+bob),(17,13+bob),(12,12+bob),(10,9+bob)],'ink')
        poly([(12,4+bob),(17,4+bob),(19,6+bob),(18,10+bob),(12,10+bob),(11,8+bob)],'mid')
        rect((12,4+bob,16,6+bob),'bone')
        rect((12,7+bob,13,8+bob),'ink'); rect((16,7+bob,18,8+bob),'ink')
        rect((13,8+bob,13,8+bob),'eye');rect((17,8+bob,17,8+bob),'eye')
        line([(14,10+bob),(14,11+bob)],'ink')
        rect((13,11+bob,17,12+bob),'bone')
        for x in (14,16): rect((x,12+bob,x,12+bob),'shadow')
        if archer:
            poly([(9,8+bob),(10,3+bob),(14,1+bob),(19,3+bob),(21,9+bob),(19,11+bob),(19,6+bob),(16,4+bob),(12,5+bob),(11,10+bob)],'hood')
            line([(10,6+bob),(11,3+bob),(14,2+bob),(18,3+bob)],'cloth')
            # Bow silhouette, taut string and drawing hand in preparation.
            bx = 25 if f != 5 else 26
            line([(18,15+bob),(22,16+bob),(bx,19+bob)],'ink',4)
            line([(18,15+bob),(22,16+bob),(bx,19+bob)],'mid',2)
            line([(bx-1,10),(bx+2,13),(bx+3,19),(bx+2,25),(bx-1,28)],'ink',3)
            line([(bx-1,10),(bx+1,13),(bx+2,19),(bx+1,25),(bx-1,28)],'wood')
            draw_x = 18 if f==4 else bx-1
            line([(bx-1,10),(draw_x,19),(bx-1,28)],'light')
            line([(11,16+bob),(draw_x,19)],'mid',2)
            if f != 5:
                line([(draw_x-1,19),(31,19)],'bone')
                poly([(31,19),(29,17),(29,21)],'light')
        else:
            # Rusted shoulder, small buckler, and a bright blade on the right.
            poly([(8,13+bob),(11,11+bob),(13,14+bob),(11,16+bob),(8,15+bob)],'iron')
            line([(8,13+bob),(11,12+bob),(12,14+bob)],'edge')
            line([(10,16+bob),(7,20),(8,24)],'mid',2)
            poly([(4,19),(9,18),(11,23),(8,27),(4,25)],'ink')
            poly([(5,20),(8,19),(10,23),(8,25),(5,24)],'iron')
            rect((7,21,8,23),'rust')
            hand=(23,18+lift)
            line([(19,15+bob),(21,17),(hand[0],hand[1])],'ink',4)
            line([(19,15+bob),(21,17),(hand[0],hand[1])],'bone',2)
            tip=(30,15) if f==5 else (26,3+lift)
            line([hand,tip],'ink',4)
            line([hand,tip],'mid',2)
            line([(hand[0],hand[1]-1),(tip[0],tip[1])],'light')
            line([(21,hand[1]),(26,hand[1]+1)],'rust',2)
            line([(22,hand[1]+2),(21,hand[1]+4)],'wood',2)
        atlas.alpha_composite(im,(f*32,0))
    atlas.save(OUT / ('skeleton_archer.png' if archer else 'skeleton_sword.png'))

skeleton(False); skeleton(True)
coins=Image.new('RGBA',(32,8))
for f,w in enumerate((5,3,1,3)):
    im=Image.new('RGBA',(8,8));d=ImageDraw.Draw(im);left=4-w//2
    d.rectangle((left-1,1,left+w,6),fill='#0b1014')
    d.rectangle((left,1,left+w-1,6),fill='#9d642f')
    d.rectangle((left,1,left+w-1,4),fill='#dfb969')
    d.line((left,1,left+w-1,1),fill='#fff0ae')
    if w>2:d.line((left+1,2,left+1,4),fill='#fff0ae')
    coins.alpha_composite(im,(f*8,0))
coins.save(OUT/'gold.png')
print('Skeletons 192x36 (6 frames 32x36); gold 32x8 (4 frames 8x8).')
