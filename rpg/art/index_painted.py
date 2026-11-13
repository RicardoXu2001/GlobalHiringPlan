"""Read transparent bounds and write Godot regions; never resample or modify the PNG masters."""
from pathlib import Path
from PIL import Image
import json

ROOT = Path(__file__).parent / 'painted'
regions = {}

def atlas(name, source, cell=None):
    im = Image.open(ROOT / source).convert('RGBA')
    cell = cell or (0, 0, im.width, im.height)
    alpha = im.getchannel('A').crop(cell)
    bounds = alpha.point(lambda value: 255 if value >= 128 else 0).getbbox()
    assert bounds, f'No opaque sprite: {source}'
    x, y = bounds[0] + cell[0], bounds[1] + cell[1]
    w, h = bounds[2] - bounds[0], bounds[3] - bounds[1]
    regions[name] = {'source': source, 'region': [x, y, w, h]}
    (ROOT / (name + '.tres')).write_text(
        '[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n'
        f'[ext_resource type="Texture2D" path="res://art/painted/{source}" id="1"]\n\n'
        '[resource]\natlas = ExtResource("1")\n'
        f'region = Rect2({x}, {y}, {w}, {h})\nfilter_clip = true\n', encoding='utf-8')

hero = Image.open(ROOT / 'hero.png')
w, h = hero.size
for name, cell in zip(['hero-down-right','hero-down-left','hero-up-right','hero-up-left'],
                     [(0,0,w//2,h//2),(w//2,0,w,h//2),(0,h//2,w//2,h),(w//2,h//2,w,h)]):
    atlas(name, 'hero.png', cell)
door = Image.open(ROOT / 'door.png')
w, h = door.size
atlas('door-closed', 'door.png', (0,0,w//2,h))
atlas('door-open', 'door.png', (w//2,0,w,h))
for name in ['arc','probe','nailer','husk','infected','sentinel','boss','graft-empty','graft-full','terminal','plating','capacitor']:
    atlas(name, name + '.png')
(ROOT / 'regions.json').write_text(json.dumps(regions, indent=2) + '\n', encoding='utf-8')
print(f'Indexed {len(regions)} atlas regions from unmodified masters.')
