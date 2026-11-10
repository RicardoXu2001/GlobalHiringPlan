// Bake Night Shift's combat art with the pinned PixelFX renderer.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const art = fileURLToPath(new URL('./', import.meta.url));
const root = resolve(art, '../..');
const checkout = resolve(process.argv[2] ?? join(root, '.runtime/pixelfx-tools'));
const output = join(art, 'combat');
const previews = join(root, '.runtime/combat-fx-review');
const importTool = (path) => import(pathToFileURL(join(checkout, path)));
const { Rng, clamp, hex, smooth } = await importTool('src/core/index.js');
const { renderFrames, spriteSheet, contactSheet } = await importTool('tools/lib/fxlib.mjs');

const colors = {
  ink: hex('#07141F'), steel: hex('#244454'), slate: hex('#49616B'),
  mist: hex('#829499'), bone: hex('#DFE8D5'), brass: hex('#897451'),
  teal: hex('#237C83'), cyan: hex('#57E4CE'),
};

function sweep(p, t) {
  const front = -1.06 + 2.12 * clamp((t + 0.039) / 0.065);
  const tail = -1.06 + 2.12 * smooth(0.060, 0.24, t);
  const heat = 1 - smooth(0.065, 0.24, t);
  if (heat <= 0 || front <= tail) return;
  p.shade(19, -55, 55, 55, (x, y, out) => {
    const angle = Math.atan2(y, x);
    const radius = Math.hypot(x, y);
    if (angle < tail || angle > front || radius > 54) return;
    const u = (angle - tail) / (front - tail);
    const thickness = Math.sin(Math.PI * u) ** 0.65 * (3 + heat * 8);
    const edge = 54 - radius;
    if (edge > thickness) return;
    out.c = edge < 2.5 && t < 0.12 ? colors.bone
      : edge < thickness * 0.6 ? colors.mist : colors.teal;
    out.a = heat * Math.min(1, u * 5);
  });
  if (t < 0.12) {
    const x = Math.cos(front - 0.13) * 51, y = Math.sin(front - 0.13) * 51;
    p.line(x - 3, y - 3, x + 3, y + 3, colors.bone, heat);
    p.glow(x, y, 5, colors.mist, heat * 0.16);
  }
}

function pulse(p, t) {
  const fade = 1 - smooth(0.045, 0.165, t);
  if (fade <= 0) return;
  const head = 108;
  const tail = Math.round(head * smooth(0.05, 0.16, t));
  p.rect(tail, -1, head - tail + 1, 3, colors.teal, fade);
  p.line(tail, 0, head, 0, t < 0.062 ? colors.bone : colors.cyan, fade);
  p.glowLine(tail, 0, head, 0, 4, colors.cyan, fade * 0.13);
  if (t < 0.065) {
    p.rect(-2, -4, 5, 8, colors.teal);
    p.rect(-4, -1, 9, 3, colors.cyan);
    p.rect(0, -1, 4, 3, colors.bone);
    p.line(head - 8, -2, head, -2, colors.cyan, fade);
  }
}

function contact(kind) {
  const guard = kind === 'guard';
  const heavy = kind === 'arc_hit';
  const glow = guard ? colors.mist : heavy ? colors.bone : colors.cyan;
  const rng = new Rng(heavy ? 340 : guard ? 207 : 489);
  const sparks = Array.from({ length: guard ? 6 : heavy ? 13 : 9 }, () => ({
    angle: guard ? Math.PI + rng.range(-0.95, 0.95) : rng.range(-Math.PI, Math.PI),
    length: rng.range(0.42, 1) * (guard ? 15 : heavy ? 26 : 19),
    life: rng.range(0.11, guard ? 0.18 : 0.26),
  }));
  return (p, t) => {
    if (t < 0.065) {
      if (guard) {
        p.line(-4, -5, 4, 5, colors.mist);
        p.line(-4, 5, 4, -5, colors.mist);
      } else if (heavy) {
        p.poly([[-12, 6], [-4, -2], [-7, -9], [1, -4], [12, -7], [6, 1], [11, 8], [0, 4]], colors.mist);
        p.poly([[-8,4], [6,-6], [9,-5], [6,-2], [-7,6]], colors.bone);
      } else {
        p.poly([[-10, 0], [0, -6], [10, 0], [0, 6]], colors.cyan);
        p.poly([[-5, 0], [0, -3], [5, 0], [0, 3]], colors.bone);
      }
      if (!guard) p.glow(0, 0, 6, glow, 0.18);
    }
    for (const spark of sparks) {
      if (t >= spark.life) continue;
      const age = t / spark.life, distance = 3 + spark.length * (1 - (1 - age) ** 3);
      const x = Math.cos(spark.angle), y = Math.sin(spark.angle);
      const trail = (1 - age) * (heavy ? 7 : 5);
      p.line(x * (distance - trail), y * (distance - trail), x * distance, y * distance,
        age < 0.46 ? glow : colors.mist, (1 - age) ** 0.8);
    }
  };
}

function cutter(p) {
  p.poly([[-10,-3],[-3,-3],[0,-8],[9,-8],[10,-4],[8,3],[4,7],[1,7],[-2,3],[-10,3]], colors.ink);
  p.rect(-9,-2,8,4,colors.brass);
  p.poly([[-3,1],[1,-7],[8,-7],[9,-4],[7,2],[4,6],[2,6]],colors.slate);
  p.line(1,-6,8,-6,colors.bone);
  p.line(8,-5,7,1,colors.mist);
  for (const [x,y] of [[7,1],[5,3],[3,5]]) p.rect(x,y,2,2,colors.bone);
  p.rect(-2,-2,3,2,colors.cyan);
}

function rangefinder(p) {
  p.poly([[-10,-4],[5,-4],[5,-2],[10,-2],[10,3],[2,3],[2,7],[-5,7],[-5,3],[-10,3]], colors.ink);
  p.rect(-9,-3,14,5,colors.slate);
  p.rect(-4,2,5,4,colors.brass);
  p.rect(4,-1,5,3,colors.bone);
  p.rect(-7,-2,8,1,colors.mist);
  for (const x of [-5,-2,1]) p.rect(x,-1,1,3,colors.cyan);
}

mkdirSync(output, { recursive: true });
mkdirSync(previews, { recursive: true });
const clips = [
  ['sweep', [128,128], [64,64], 0.27, sweep],
  ['pulse', [128,24], [12,12], 0.20, pulse],
  ['arc_hit', [64,64], [32,32], 0.30, contact('arc_hit')],
  ['probe_hit', [64,64], [32,32], 0.30, contact('probe_hit')],
  ['guard', [64,64], [32,32], 0.20, contact('guard')],
  ['cutter', [24,24], [12,12], 0, cutter],
  ['rangefinder', [24,24], [12,12], 0, rangefinder],
];

const textures = [], regions = [], animations = [];
for (const [id, size, origin, duration, draw] of clips) {
  const meta = { name: id, size, origin, duration, loop: false, fps: 30, bg: 'dark', options: {} };
  const fx = { id: `night-shift/${id}`, meta, mod: { meta, draw } };
  const frames = renderFrames(fx);
  const atlas = spriteSheet(fx, frames, id);
  writeFileSync(join(output, `${id}.png`), atlas.png);
  if (duration === 0) continue;
  const alpha = (frame) => frame.clear.some((byte, i) => i % 4 === 3 && byte > 0);
  if (!alpha(frames.frames[0]) || alpha(frames.frames.at(-1))) {
    throw new Error(`${id}: attack must start visibly and fade to empty`);
  }
  const margin = 6;
  const expanded = renderFrames(fx, { margin });
  const spills = expanded.frames.some(({ clear }) => clear.some((byte, i) => {
    if (i % 4 !== 3 || byte === 0) return false;
    const pixel = Math.floor(i / 4);
    const x = pixel % expanded.w, y = Math.floor(pixel / expanded.w);
    return x < margin || y < margin || x >= expanded.w - margin || y >= expanded.h - margin;
  }));
  if (spills) throw new Error(`${id}: visible pixels overflow the frame`);
  writeFileSync(join(previews, `${id}.png`), contactSheet(fx, frames, { max: 16, zoom: 2 }));
  textures.push(`[ext_resource type="Texture2D" path="res://art/combat/${id}.png" id="${id}"]`);
  const entries = atlas.json.frames.slice(0, -1).map(({ frame: { x, y, w, h } }, i) => {
    const key = `${id}_${i}`;
    regions.push(`[sub_resource type="AtlasTexture" id="${key}"]\natlas = ExtResource("${id}")\nregion = Rect2(${x}, ${y}, ${w}, ${h})\nfilter_clip = true`);
    return `{"duration": 1.0, "texture": SubResource("${key}")}`;
  });
  animations.push(`{"frames": [${entries.join(', ')}], "loop": false, "name": &"${id}", "speed": 30.0}`);
  console.log(`${id}: ${entries.length} frames, ${size.join('×')}`);
}

writeFileSync(join(output, 'effects.tres'),
  ['[gd_resource type="SpriteFrames" format=3]', ...textures, ...regions,
    `[resource]\nanimations = [${animations.join(',\n')}]`].join('\n\n') + '\n');
for (const file of ['LICENSE', 'NOTICE.md']) {
  writeFileSync(join(output, `PIXELFX_${file}`), readFileSync(join(checkout, file)));
}
