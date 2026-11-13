# ART-2 模块与动作制作记录

资源：[09 行走](09-walk.png) · [09 动作](09-actions.png) · [工厂模块](factory-kit.png) · [扑击体动作](husk-motion.png) · [感染工人动作](worker-motion.png) · [免疫守卫动作](sentinel-motion.png)。

2026-11-12。用户纠正整图替换的做法，确认需求是模块化场景与真实动作。以下六张新母稿由内置 image_gen 制作；四向定妆和整房间图仅作为造型／材质参考。运行使用 64 个角色／敌人姿态帧和 12 个独立模块；原 PNG 不做编辑，索引脚本只输出区域、脚点、握持点与 SpriteFrames。

## husk-motion.png

```text
Use case: identity-preserve. Production ANIMATED PIXEL SPRITE SHEET for this exact failed-hatch husk enemy. The reference locks anatomy, slate-steel plates, dusty rose sinews, low four-legged stance, violet spine crystals and hard pixel material finish. Create exactly TWELVE full-body animation poses in a strict FOUR-COLUMN by THREE-ROW grid on genuine transparent alpha. Identical cells, consistent scale, one creature per cell, no labels, lines, shadows, haze, particles or scenery. All physical limbs fit within their own cells.
Frames read left-to-right then top-to-bottom: 1-4 one four-frame creeping walk cycle with alternating articulated planted legs and lifted feet, moving right in the same three-quarter camera; 5 crouching windup with front legs tucking and spine lowering; 6 strongest compressed anticipation; 7 extended airborne pounce with all limbs actually repositioned; 8 front-foot landing and recovery; 9 recoil from a hit with torso twisting and legs bracing; 10 recovery from hit; 11 collapse with legs buckling; 12 dead flattened body on side with folded legs, crystals still attached. Preserve identity in every frame. This must depict genuine different anatomy poses, not scaled or rotated copies of the idle.
Detailed crafted pixel art with discrete steel bevels, organic shade clusters and consistent upper-left lighting, readable at about 54x38 game units. Match the approved reference's quality. No smooth painting, no bloom, no glow outside the body, no extra limbs.
```

## worker-motion.png

```text
Use case: identity-preserve. Production ANIMATED PIXEL SPRITE SHEET for this exact infected maintenance worker enemy. Keep the approved hunched worker identity, worn helmet and clothing, wrench, slate-steel fragments, exposed dusty-rose infected tendons and adult proportions. Output exactly TWELVE separate whole-body animation poses in a strict FOUR-COLUMN by THREE-ROW grid on TRUE TRANSPARENT ALPHA. Equal cells and stable scale/ground baseline; all extremities and the wrench stay inside their cells. No text, grid, particles, fog, shadows or background. Three-quarter FRONT-RIGHT camera, consistent lighting and identity.
Read left-to-right then top-to-bottom: frames 1-4 one creeping walk cycle with genuinely alternating planted legs and lifted boots, wrench carried low; 5 pulls the wrench backward and twists shoulders in anticipation; 6 high overhead windup with bent knees; 7 powerful downward wrench strike with a planted forward step and torso twist; 8 follow-through recovering balance; 9 recoils from a hit with arms displaced and knees bracing; 10 returns to guard; 11 knee buckles and torso collapses; 12 lies genuinely collapsed on the ground with bent limbs and dropped wrench beside the hand.
Hard discrete pixel clusters, finely readable cloth folds and metal bevels, deep steel-blue shadows and restrained rose tissue, not smooth illustration. Exactly twelve DIFFERENT articulated poses of the same enemy, not rotated or squeezed idle copies.
```

## sentinel-motion.png

```text
Use case: identity-preserve. Production ANIMATED PIXEL SPRITE SHEET for this exact immune sentinel: broad slate-steel two-shield humanoid, visible rose muscle/tendons, compact helmet, exposed restrained heart/core, heavy articulated legs. Match the approved reference identity, material finish and proportions.
Create exactly TWELVE separate full-body poses in a strict FOUR-COLUMN by THREE-ROW regular grid on genuine transparent alpha. Identical cells, stable character scale and ground baseline, no text, dividing lines, particles, mist, glow or scenery. All shields, hands and feet must fit within their own cells. Same three-quarter FRONT-RIGHT camera throughout.
Read left-to-right then top-to-bottom: 1-4 one heavy four-frame guarded walk cycle, alternating planted armored feet with knees flexing and both shields carried; 5 raises both shield arms to prepare; 6 deep compressed defensive windup with shields drawn inward; 7 strong forward/downward shield slam with a planted foot and shifted torso; 8 pulls arms outward into exposed-core recovery, revealing a small cyan mechanical weak-point marker; 9 flinch from a core hit with torso recoil and shields displaced; 10 recovery guard; 11 knees buckle as body collapses and shield arms sag; 12 genuinely fallen on its side, folded limbs, both shields still physically attached. Distinct articulated poses, never resize/rotate an idle figure to simulate motion.
Highly crafted pixel clusters, blue steel bevel highlights, restrained dusty-rose tissue, dark recessed joints, tiny amber service marks, no smooth paint or bloom. Keep every component physically consistent across frames.
```


## 09-walk.png

```text
Use case: identity-preserve. Asset type: ACTUAL GAME WALK-CYCLE SPRITE SHEET for an original oblique 2D pixel action game. The attached image is the APPROVED CHARACTER IDENTITY AND MATERIAL reference. Preserve 09's helmet, headlamp, gray steel-blue maintenance jacket, dark work trousers, belt pouches, cyan chest badge and adult proportions. This is animation production, not a portrait sheet.
Output exactly TWELVE separate full-body poses on genuine transparent alpha, arranged in a strict SIX-COLUMN by TWO-ROW regular grid. Each cell has identical dimensions and padding; every character has the SAME height and stable foot baseline in its cell, centered. No labels, grid lines, shadows, glow, scenery or typography. Leave transparent gutters between cells.
Top row: 6 consecutive frames of one seamless walking cycle facing FRONT-RIGHT at three-quarter angle, progressing left-to-right: right contact, right-down passing, right-up, left contact, left-down passing, left-up. Bottom row: the same six walking phases viewed BACK-RIGHT. Clearly alternate planted feet, bend knees, lift the trailing boot, subtly turn pelvis and shoulders. Hands are held in a stable two-handed equipment-carry position in front of waist, with bent elbows and EMPTY hands, so a separate equipped weapon can attach. Do not include any weapon.
Medium: beautifully crafted precise pixel sprites with deliberate hard pixel clusters, discrete steel and cloth shading, clearly readable folds, seams and bevel highlights. Work at a coherent low-resolution sprite density appropriate to a 48x72 logical source frame, presented enlarged with nearest-neighbor pixel edges, not smooth illustration. Keep the approved design's material sophistication, without microtexture noise or lighting haze. Exactly twelve consistent poses, all extremities visible, no overlapping cells, no alternate costumes or identities.
```

## 09-actions.png

```text
Use case: identity-preserve. Asset type: production CHARACTER ACTION sprite sheet. Input image is the approved identity and material reference for 09. Preserve exactly his helmet/headlamp, short dark hair, gray-blue maintenance jacket, rolled cuffs, cyan chest badge, belt and asymmetric pouches, dark trousers, adult build, and detailed discrete pixel shading.
Create SIXTEEN separated full-body animation key poses in an exact FOUR-COLUMN, FOUR-ROW grid on genuine transparent alpha. Identical cell dimensions, consistent character size and foot/ground baseline per cell. Each row reads left to right, no text or lines, no floor shadow, no glow, no effects, no scenery. Figure always faces three-quarter FRONT-RIGHT. Every limb and every falling pose must fit inside its own cell with ample transparent margin. Only the character; EMPTY HANDS, NO WEAPONS, because equipped tools will attach at runtime.
Row 1, four strong MELEE action poses: counter-turn windup with bent knees and hands drawn back; planted forward step with torso twisting and both hands cutting forward; big follow-through with shoulders and hips changed; recovery into upright guard. Show an actual whole-body action, not the same stance with shifted arms.
Row 2, four RANGED action poses: relaxed carry, raise both empty hands into an aimed brace, recoil into bent elbows and rear leg, recover guard. Consistent handhold, no finger clutter.
Row 3, four DODGE poses: low preparation, low extended forward dash with trailing bent leg, front-foot landing with compressed knee, rise to guard.
Row 4, four HURT AND FALL poses: backward stagger with arms thrown away from impact, knee buckles and torso falls sideways, hip and elbow contact ground, fully collapsed lying on side with knees bent and helmet still on. The final frame is genuinely horizontal anatomy, not a rotated standing figure.
Crafted pixel sprites, clean hard pixel clusters and limited discrete steel/cloth shade steps at the same density as the approved image. No smooth render, no airbrush, no duplication of poses or identity drift.
```

## factory-kit.png

```text
Use case: stylized-concept. Asset type: MODULAR PIXEL TILE KIT for an actual oblique 2D game, not an illustration or room background. The reference is approved ONLY for slate-steel bevels, precise pixel material finish, organic conduit accents and light hierarchy. Create twelve independent reusable construction parts on TRUE TRANSPARENT ALPHA in an exact 4-column by 3-row regular grid. Equal cell dimensions, generous empty gutters, one whole isolated module in each cell, all parts fit, no scenery connecting cells, no cast shadows, no labels or text.
Row1 left-to-right: (1) seamless top-view blue steel FLOOR PLATE square, low-contrast broad surface, a few large seams at borders; (2) alternate seamless floor plate with a recessed service hatch, same dimensions; (3) BACK WALL BAY, front-facing steel panel with a dark octagonal recessed opening and tiny amber service light, straight flat bottom; (4) closed ventilation wall bay of identical height/width, layered steel housing.
Row2: (1) tall thin VERTICAL SUPPORT COLUMN with layered bevel plates and 2 tiny amber strips; (2) HORIZONTAL STEEL CONDUIT straight segment with collars at both ends; (3) 90 degree bent conduit elbow; (4) short waist-high FOREGROUND RAILING with two square posts and horizontal bars, transparent openings.
Row3: (1) thick removable RECTANGULAR MACHINE ARMOR PLATE with layered blue-steel bevel and bolts; (2) short PISTON ASSEMBLY, separated dark cylinder and bright exposed rod visibly designed to extend; (3) small HEART IN A STEEL RESTRAINT CAGE with dusty rose valves; (4) standalone compact amber SERVICE LAMP in a dark metal housing.
Style: disciplined high-quality PIXEL ART, hard clusters, discrete upper-left highlights and cool shadow steps, precise readable crafted engineering, no smooth rendering or bloom. All modules use the same pixel density and matching perspective as the reference. The floor modules are flat orthographic top faces; wall and machinery modules have shallow visible top edges suited to the game's fixed oblique camera. No full room, no people, no monsters, no decorative floating particles.
```

