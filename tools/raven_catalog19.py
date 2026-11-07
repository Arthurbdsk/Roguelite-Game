"""Local, reproducible catalog. Never republishes the complete asset pack.

Usage: python tools/raven_catalog19.py [--integrate]
The selected atlas is built exclusively from the IDs in data/icon_catalog.json.
Larger source images differ in invisible RGB; compare premultiplied pixels.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import argparse, hashlib, json, re, html

ROOT=Path(__file__).resolve().parents[1]
SOURCE=Path.home()/"Downloads/Free - Raven Fantasy Icons"
OUT=ROOT/"build/raven_catalog"

def visible(image):
    image=image.convert("RGBA")
    return Image.alpha_composite(Image.new("RGBA",image.size),image).convert("RGB").tobytes(),image.getchannel("A").tobytes()

def category(n):
    if n<=192:return "Recursos, moedas, ferramentas e objetos"
    if n<=384:return "Materiais, poções, símbolos e variações"
    if n<=592:return "Comidas, bebidas e ingredientes"
    if n<=720:return "Atributos e símbolos de interface"
    if n<=1440:return "Magias, elementos e status"
    if n<=1808:return "Armas e variações de material"
    return "Armaduras, acessórios e equipamentos"

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--integrate',action='store_true');args=parser.parse_args()
    OUT.mkdir(parents=True,exist_ok=True)
    files=sorted((SOURCE/'Separated Files/16x16').glob('*.png'),key=lambda p:int(re.search(r'\d+',p.stem).group()))
    rows=[];different=[]
    for p in files:
        n=int(p.stem[2:]);a=Image.open(p).convert('RGBA')
        for size,prefix in [(32,'fb'),(64,'fc')]:
            b=Image.open(SOURCE/f'Separated Files/{size}x{size}'/f'{prefix}{n}.png')
            if visible(a.resize((size,size),Image.Resampling.NEAREST))!=visible(b):different.append([n,size])
        rows.append({'file':p.name,'id':n,'category':category(n),'page':(n-1)//192+1,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
    for page,start in enumerate(range(0,len(files),192),1):
        image=Image.new('RGB',(1280,1080),'#172334');draw=ImageDraw.Draw(image)
        for i,p in enumerate(files[start:start+192]):
            x=i%16*80;y=i//16*90;draw.rectangle((x+4,y+3,x+75,y+71),fill='#303c4e')
            a=Image.open(p).convert('RGBA').resize((64,64),Image.Resampling.NEAREST);image.paste(a,(x+8,y+5),a);draw.text((x+10,y+74),p.name,fill='white')
        image.save(OUT/f'page-{page:02}.png')
    (OUT/'items.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf8')
    sheet=Image.open(SOURCE/'Full Spritesheet/16x16.png').convert('RGBA')
    sheet_matches=all(visible(sheet.crop((i%16*16,i//16*16,i%16*16+16,i//16*16+16)))==visible(Image.open(p)) for i,p in enumerate(files))
    big32=Image.open(SOURCE/'Full Spritesheet/32x32.png')
    summary={'logical_icons':len(files),'includes_recolors':True,'distinct_files':len({r['sha256'] for r in rows}),'larger_visible_differences':different,'base_resolution':16,'independent_icons_not_animation':True,'sheet_matches_separate':sheet_matches,'rpg_maker_matches_full32':visible(big32)==visible(Image.open(SOURCE/'RPG Maker MV and MZ/IconSet.png')),'full32_nearest':visible(big32)==visible(sheet.resize(big32.size,Image.Resampling.NEAREST)),'full64_nearest':visible(Image.open(SOURCE/'Full Spritesheet/64x64.png'))==visible(sheet.resize((1024,8768),Image.Resampling.NEAREST))}
    (OUT/'summary.json').write_text(json.dumps(summary,indent=2),encoding='utf8')
    body=''.join(f'<section><h2>Página {p}</h2><img loading="lazy" src="page-{p:02}.png" alt="Catálogo fa{(p-1)*192+1} a fa{min(p*192,len(files))}"></section>' for p in range(1,(len(files)+191)//192+1))
    (OUT/'index.html').write_text('<!doctype html><html lang="pt-BR"><meta charset="utf-8"><title>Catálogo Raven local</title><style>body{background:#142238;color:#f2ecda;font:18px sans-serif;margin:24px}img{max-width:100%;image-rendering:pixelated}section{margin:32px 0}a{color:#eed270}</style><h1>Raven Fantasy Icons</h1><p>2.192 arquivos-base, incluindo recolorações. Base 16 × 16. As versões maiores são ampliações nearest da mesma arte. Catálogo local de seleção, não redistribuir como pacote de assets.</p><p><a href="items.json">Índice com arquivo, categoria e página</a> · <a href="https://clockworkraven.itch.io/raven-fantasy-icons">Origem e licença</a></p>'+body+'</html>',encoding='utf8')
    if args.integrate:
        catalog=json.loads((ROOT/'data/icon_catalog.json').read_text(encoding='utf8'))
        ids=sorted({int(row['source_file'][2:-4]) for row in catalog.values() if row.get('origin')=='Clockwork Raven'})
        dest=ROOT/'assets/raven';dest.mkdir(exist_ok=True)
        for old in dest.glob("fa*.tres"):
            if int(old.stem[2:]) not in ids:old.unlink()
        atlas=Image.new('RGBA',(256,((len(ids)+7)//8)*32))
        for i,n in enumerate(ids):
            atlas.paste(Image.open(SOURCE/'Separated Files/16x16'/f'fa{n}.png').convert('RGBA').resize((32,32),Image.Resampling.NEAREST),(i%8*32,i//8*32))
            (dest/f'fa{n}.tres').write_text('[gd_resource type="AtlasTexture" load_steps=2 format=3]\n[ext_resource type="Texture2D" path="res://assets/raven/selected.png" id="1"]\n[resource]\natlas = ExtResource("1")\nregion = Rect2(%d, %d, 32, 32)\nfilter_clip = true\n'%(i%8*32,i//8*32),encoding='utf8')
        atlas.save(dest/'selected.png')
        for row in catalog.values():
            if row.get('origin')!='Clockwork Raven':continue
            tile=Image.open(SOURCE/'Separated Files/16x16'/row['source_file']).convert('RGBA').resize((32,32),Image.Resampling.NEAREST)
            raw=bytearray(tile.tobytes())
            for p in range(0,len(raw),4):
                if raw[p+3]==0:raw[p:p+3]=b'\0\0\0'
            row['pixel_sha256']=hashlib.sha256(raw).hexdigest()
        (ROOT/'data/icon_catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
        print('SELECTED',len(ids),'ATLAS',atlas.size,'BYTES',(dest/'selected.png').stat().st_size)
    print(json.dumps(summary))
if __name__=='__main__':main()
