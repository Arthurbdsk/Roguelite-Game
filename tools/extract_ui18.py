"""Extract only the two used fantasy UI elements from Arthur's authorized bundle."""
from pathlib import Path
from PIL import Image, ImageDraw
source=Image.open('C:/Users/Arthur/Downloads/UIBundleFree/freefantasy.png').convert('RGBA')
out=Path('assets/v18');out.mkdir(exist_ok=True)
button=source.crop((139,5,182,27));button.save(out/'button_wood.png')
panel=source.crop((84,69,155,162))
# Keep the package's wood/metal trim, integrate its interior with the existing blue palette.
d=ImageDraw.Draw(panel);d.rectangle((9,10,61,82),fill='#484f68')
panel.save(out/'panel_medieval.png')
print('UI18_TWO_ELEMENTS_EXTRACTED')
