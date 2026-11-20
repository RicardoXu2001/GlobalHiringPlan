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
const hotMetal = ['#392638', '#673748', '#a35151', '#d97859', '#ffad76', '#ffd9a9', '#fff3d9'];
for (const [name, source, palette, options = {}, clip] of [
  ['tissue_hit', 'impacts/hit-spark', ['#271932','#492C42','#783F57','#BD6579','#E98591','#F6B2AC','#DFE8D5'],
    { light: 0.06 }, [0, 8]],
  ['metal_hit', 'impacts/hit-spark', ['#1B2837','#394659','#72634C','#C9895C','#FFBE75','#FFE0AB','#DFE8D5'],
    { light: 0.06 }, [0, 7]],
  ['shield_contact', 'impacts/parry', ['#182430','#3C505C','#596776','#909B9C','#B6C8CC','#D0DDD8','#DFE8D5'],
    { light: 0.04 }, [0, 8]],
  ['heavy_contact', 'impacts/crit-hit', ['#1B2837','#3C505C','#596776','#909B9C','#C9895C','#E6AC78','#FFE0AB','#DFE8D5'],
    { light: 0.07 }, [0, 12]],
  ['organ_collect', 'pickups/collect-burst', ['#102738','#244454','#237C83','#57E4CE','#DFE8D5']],
  ['pounce_rake', 'melee/claw-swipe', ['#35213a', '#60334f', '#883d60', '#b65174', '#e1768c', '#ffa8a4', '#ffcfb6', '#fff0dc'],
    { sparks: ['#ffc2ad', '#ff967d', '#e1768c', '#b65174'] }, [1, 14]],
  ['wrench_arc', 'melee/sword-slash', hotMetal,
    { radius: 39, sparks: ['#fff3d9', '#ffc58e', '#dc795c', '#a35151'] }, [1, 13]],
  ['shield_slam', 'impacts/ground-slam', hotMetal,
    { reach: 72, stone: '#415566' }, [0, 21]],
]) {
  const fx = await loadEffect(source);
  const frames = renderFrames(fx, { actor: !clip, options: { palette, light: 0.18, seed: 9, ...options } });
  if (clip) {
    frames.frames = frames.frames.slice(...clip);
    frames.n = frames.frames.length;
  }
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
