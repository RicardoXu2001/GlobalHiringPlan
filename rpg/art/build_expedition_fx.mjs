// Bake existing PixelFX recipes; preserve upstream MIT credit in combat/PIXELFX_NOTICE.md.
import { writeFileSync, mkdirSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';
const art = fileURLToPath(new URL('./', import.meta.url));
const checkout = resolve(art, '../../.runtime/pixelfx-tools');
const { loadEffect, renderFrames, spriteSheet, contactSheet } = await import(pathToFileURL(join(checkout, 'tools/lib/fxlib.mjs')));
const output = join(art, 'expedition');
mkdirSync(output, { recursive: true });
const previews = resolve(art, '../../.runtime/combat-fx-review');
mkdirSync(previews, { recursive: true });
const textures = [], regions = [], animations = [];
for (const [name, source, palette] of [
  ['tissue_hit', 'impacts/hit-spark', ['#07141F','#492C42','#9C626C','#FF526D','#DFE8D5']],
  ['organ_collect', 'pickups/collect-burst', ['#102738','#244454','#237C83','#57E4CE','#DFE8D5']],
]) {
  const fx = await loadEffect(source);
  const frames = renderFrames(fx, { options: { palette, light: 0.18, seed: 9 } });
  const sheet = spriteSheet(fx, frames, name);
  writeFileSync(join(output, name + '.png'), sheet.png);
  writeFileSync(join(previews, name + '.png'), contactSheet(fx, frames, { max: 12, zoom: 2 }));
  textures.push(`[ext_resource type="Texture2D" path="res://art/expedition/${name}.png" id="${name}"]`);
  const entries = sheet.json.frames.map(({frame: {x,y,w,h}}, i) => {
    const key = `${name}_${i}`;
    regions.push(`[sub_resource type="AtlasTexture" id="${key}"]\natlas = ExtResource("${name}")\nregion = Rect2(${x}, ${y}, ${w}, ${h})\nfilter_clip = true`);
    return `{"duration": 1.0, "texture": SubResource("${key}")}`;
  });
  animations.push(`{"frames": [${entries.join(', ')}], "loop": false, "name": &"${name}", "speed": 30.0}`);
  console.log(`${name}: ${entries.length} frames, recipe ${source}`);
}
writeFileSync(join(output, 'effects.tres'), ['[gd_resource type="SpriteFrames" format=3]', ...textures, ...regions, `[resource]\nanimations = [${animations.join(',\n')}]`].join('\n\n') + '\n');
