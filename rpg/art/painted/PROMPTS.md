# ART-2 生成记录

2026-11-12。用户确认首批精灵图后，使用内置 image_gen 重绘。源 PNG 保存在本目录；Godot AtlasTexture 仅索引透明边界，没有重采样修改源图。

批准基准：09、短弧、免疫守卫、心核接驳装置；[确认记录](../../../design/visual-targets/sprite-review-v1/REVIEW.md)及[首批提示词](../../../design/visual-targets/sprite-review-v1/PROMPTS.md)。实际显示尺寸与动画边界以 [ART-2](../../../design/ART_DIRECTION.md) 为准，生成提示词不代表所有目标已逐像素验收。

## 资源索引

| 类别 | 本批母稿 |
| --- | --- |
| 09 | [四视图](hero.png) |
| 武器 | [短弧](arc.png)、[探针长枪](probe.png)、[压力铆枪](nailer.png) |
| 小怪 | [失败孵化体](husk.png)、[感染工人](infected.png)、[免疫守卫](sentinel.png) |
| Boss | [压维守卫](boss.png) |
| 中心装置 | [空槽](graft-empty.png)、[心核接入](graft-full.png) |
| 场景物件 | [门开闭](door.png)、[终端](terminal.png) |
| 装备 | [加固护具](plating.png)、[回路电容](capacitor.png) |
| 房间 | [接收／中心](intake-room.png)、[转运](transport-room.png)、[生体拘束](bio-room.png)、[肺叶](lung-room.png) |

四份批准母稿直接继承首批文件，其余 14 份的生成／编辑提示词如下。`index_painted.py` 只读图片 Alpha，写出 18 份区域资源与 `regions.json`，不会修改母稿。

## probe.png

```text
Use case: stylized-concept. Production sprite for our original Night Shift Circuit game. The input is an APPROVED STYLE/IDENTITY reference, not a layout to copy. Match its exact premium pixel-art finish: slate-blue beveled steel, organized fasteners and dark recessed joints, dusty rose organic cable, tiny functional amber accents, hard stepped pixel clusters and upper-left highlights. No smooth 3D render, airbrush, background, typography, labels, UI or watermark. Exactly ONE full object on genuine transparent alpha with generous empty margin. All extremities must be visible. Use a single coherent logical pixel grid and 3-4 discrete shade steps per material. This will be used as an actual oblique 2D game sprite, so prioritize readable silhouette over microtexture.
Create the PROBE LANCE: a long slim industrial telescopic spear / maintenance probe in horizontal inventory profile pointing RIGHT. Compact rear grip and wrist brace at left, long straight segmented steel shaft, a few exposed small pneumatic joints, one tidy loop of rose conduit below the rear, a three-pronged sharp surgical probe head at right with a SMALL pink-white contact tip. Distinct from a gun: no bulky magazine, no large cyan blade. Overall long-to-thin silhouette, about 7:1, engineering craftsmanship like the approved electric cutter. No floor shadow.
```

## nailer.png

```text
Use case: stylized-concept. Production sprite for our original Night Shift Circuit game. The input is an APPROVED STYLE/IDENTITY reference, not a layout to copy. Match its exact premium pixel-art finish: slate-blue beveled steel, organized fasteners and dark recessed joints, dusty rose organic cable, tiny functional amber accents, hard stepped pixel clusters and upper-left highlights. No smooth 3D render, airbrush, background, typography, labels, UI or watermark. Exactly ONE full object on genuine transparent alpha with generous empty margin. All extremities must be visible. Use a single coherent logical pixel grid and 3-4 discrete shade steps per material. This will be used as an actual oblique 2D game sprite, so prioritize readable silhouette over microtexture.
Create the PRESSURE NAILER: a compact gas-powered industrial nail pistol, horizontal side/three-quarter profile pointing RIGHT. Square practical slate-steel receiver with bevels and small amber caution inset, a visible short pressure cylinder above, solid pistol grip, short squared barrel and nail guide at right, one small curved rose pressure hose attached to a brass coupling underneath. No energy blade, no muzzle flash. Chunky compact 2:1 silhouette, readable trigger gap and weight. Match the approved cutter's material density. No floor shadow.
```

## husk.png

```text
Edit this game sprite with one precise correction: remove ALL gray fog, soft halo, haze and diffuse cast shadow surrounding the creature. Preserve the creature's exact anatomy, crouching pose, four limbs, steel plates, organic sinews, violet spine growths and pixel detail. Every pixel outside the opaque creature and its physical extremities must be genuinely fully transparent. Leave no atmospheric glow or semitransparent gray cloud; violet highlights stay INSIDE the crystal shapes only. This is a clean production sprite cutout on true transparent alpha, with crisp stepped silhouette and generous empty margins. Do not redesign the creature or add anything.
```

## infected.png

```text
Use case: stylized-concept. Production sprite for our original Night Shift Circuit game. The input is an APPROVED STYLE/IDENTITY reference, not a layout to copy. Match its exact premium pixel-art finish: slate-blue beveled steel, organized fasteners and dark recessed joints, dusty rose organic cable, tiny functional amber accents, hard stepped pixel clusters and upper-left highlights. No smooth 3D render, airbrush, background, typography, labels, UI or watermark. Exactly ONE full object on genuine transparent alpha with generous empty margin. All extremities must be visible. Use a single coherent logical pixel grid and 3-4 discrete shade steps per material. This will be used as an actual oblique 2D game sprite, so prioritize readable silhouette over microtexture.
Create one INFECTED NIGHT WORKER enemy, same costume family as the approved 09 but clearly a different figure. Slightly elevated front-three-quarter game view facing down-right, full body. Hunched crooked posture, battered steel hardhat shadows the eyes, torn gray maintenance jacket, asymmetric slate cargo trousers and heavy work boots. One arm holds a long simple spanner low and outward. The opposite shoulder, neck and forearm have dusty rose exposed tendon bundles joined by tiny steel clamps, with just a pinpoint violet infection deep in the shoulder. Keep face anonymous, not 09's handsome face, no soldier armor. Distinct threatening leaning silhouette, visible elbow bends and grounded feet; damaged cloth has coherent seams, not random noise. No detached effects or blood.
```

## boss.png

```text
Create ONE production sprite on genuine transparent alpha for the PRESSURE WARDEN boss of our original Night Shift Circuit game. These are approved STYLE references, not edit targets. Match their premium steel-and-living-flesh pixel art, discrete stepped clusters, upper-left light, slate-steel bevels, dusty rose tendons and tiny amber machinery marks. Front slightly elevated 2D game view, almost symmetrical facade. One entire boss about three worker-heights tall, huge grounded silhouette: a living heart enclosed by an octagonal industrial pressure cage, two giant articulated piston arms with heavy flat hammer fists resting near its base, exposed rose circulation tubes wrapping shoulder gantries, a compact overhead pressure cylinder and a small optical slot. It is a fixed industrial guardian, not another humanoid soldier. Heart and hinges must read through armor gaps. Clear negative space around articulated arms, all fittings purposeful. The chest core is low enough to be attacked from the front. No background, floor, cast shadow, labels, UI, bars, detached particles, fog, glows or extra versions. Make a beautiful original hand-authored PIXEL ART sprite, sharp opaque stepped edges, selective material highlights, no smooth 3D render or atmospheric painting. Generous transparent margin around ALL arms and feet.
```

## graft-empty.png

```text
Edit the supplied APPROVED heart graft station sprite. Keep its exact shape, viewpoint, steel framework, base, side pump, scaffold, control console, pixel-art materials, scale and lighting. Change ONLY the central cradle from a heart-loaded state to the EMPTY state: remove the heart and its central fleshy organ vessels inside the octagonal opening, show a clean dark cavity open through to transparent background with four idle metal couplers, retaining the outside rose service tubes around the frame. Make the small cyan monitor show quiet straight status marks rather than a heartbeat. This is the pre-graft state of the exact same machine, not a new design. Genuine transparent alpha everywhere outside the object and through the empty central opening. No fog, bloom, ground plane, shadow, words, checkerboard, UI or extra copies. Preserve crisp pixel clusters and stepped contour. All feet, tubes and gantry fully inside generous transparent margins.
```

## door.png

```text
One polished industrial access-door game prop sheet on genuine transparent alpha, same Night Shift Circuit steel pixel-art style as the approved reference. Exactly TWO versions of the SAME door side by side with a wide clear gutter: left CLOSED steel segmented shutter, right OPEN with the shutter retracted into its upper housing and a dark empty portal opening transparent through the frame. Matching outer dimensions, foot baseline, front slightly elevated oblique RPG camera, upright rectangular facade. Each doorway has chamfered layered slate-blue structural jambs, small amber side inspection lamps, a few restrained caution stripes on the lower sill, visible hinges/rails and bolts in organized clusters. Crisp hard pixel bevels and upper-left material shading, readable frame around the opening. Keep all external feet and fittings inside margins. No floor, room, shadows, human, organs, UI, writing, labels, checkerboard, glow fog, 3D render or smooth vector strokes. Two isolated sprites only, no captions. This is a same-object closed/open state sheet, not a full environment.
```

## intake-room.png

```text
Use case: stylized-concept. A PRODUCTION GAMEPLAY BACKGROUND for Night Shift Circuit, landscape EXACT 16:9, 1920x1080 composition. The supplied images are APPROVED STYLE references, not compositions to copy. Beautiful high-detail pixel art with organized steel bevels, hard discrete shade bands, tiny purposeful fasteners, dusty rose flesh at machine interfaces, controlled amber path lamps, and dark cool foundations. No painterly blur, 3D render, UI, typography, people, enemies, loose items or standalone interactable objects.
CAMERA/PLAYABILITY LOCK: a fixed slightly elevated oblique FRONT view, upright back wall, horizontal floor seams, NOT diamond isometric, NOT side scrolling, NOT a cinematic depth corridor with vanishing point far away. The player arena is a large clean rectangular steel floor spanning x=16%-84% and y=38%-83% of the frame. Its LOWER and UPPER edges are HORIZONTAL. This entire rectangle MUST stay unobstructed and walkable with subdued texture. Back wall machinery occupies y=14%-37%, side structural borders stay OUTSIDE x=16%-84%. Leave a quiet bottom border below y=84% and dark vignette outside the room outline. Top 0%-13% is dark architecture for an overlay HUD. Back wall has a few dark recessed access niches; DO NOT paint doors, operating consoles or a boss in them, those are separate sprites. No pillars, chests or obstacles on the walking rectangle.
MATERIAL/FOCUS: broad dark #102738/#244454 floor masses with restrained segmented metal seams, #49616B/#829499 bevel highlights mostly on wall/rail edges, a few small #FFC46B side lamps, #492C42/#9C626C organic pipes where requested. Keep floor darker and quieter than character sprites; no giant glow or high-contrast checkerboard floor. More precise craftsmanship than a blocky graybox, but no random noise. Draw a full opaque background, not a transparent cutout.
ROOM IDENTITY: A maintained industrial receiving / preparation hall. Elegant layered slate-steel wall panels, cable trays, ribbed upper gantry, ventilation grilles, clipped conduit runs and three dark wall niches. Slight asymmetric signs of age. Minimal exposed organic material: one or two short rose service couplings only. Side amber lamps guide the arena boundary. Spacious calm service room, suitable for adding a graft station and shop consoles later; no station, console or person painted into this background.
```

## bio-room.png

```text
Use case: stylized-concept. A PRODUCTION GAMEPLAY BACKGROUND for Night Shift Circuit, landscape EXACT 16:9, 1920x1080 composition. The supplied images are APPROVED STYLE references, not compositions to copy. Beautiful high-detail pixel art with organized steel bevels, hard discrete shade bands, tiny purposeful fasteners, dusty rose flesh at machine interfaces, controlled amber path lamps, and dark cool foundations. No painterly blur, 3D render, UI, typography, people, enemies, loose items or standalone interactable objects.
CAMERA/PLAYABILITY LOCK: a fixed slightly elevated oblique FRONT view, upright back wall, horizontal floor seams, NOT diamond isometric, NOT side scrolling, NOT a cinematic depth corridor with vanishing point far away. The player arena is a large clean rectangular steel floor spanning x=16%-84% and y=38%-83% of the frame. Its LOWER and UPPER edges are HORIZONTAL. This entire rectangle MUST stay unobstructed and walkable with subdued texture. Back wall machinery occupies y=14%-37%, side structural borders stay OUTSIDE x=16%-84%. Leave a quiet bottom border below y=84% and dark vignette outside the room outline. Top 0%-13% is dark architecture for an overlay HUD. Back wall has a few dark recessed access niches; DO NOT paint doors, operating consoles or a boss in them, those are separate sprites. No pillars, chests or obstacles on the walking rectangle.
MATERIAL/FOCUS: broad dark #102738/#244454 floor masses with restrained segmented metal seams, #49616B/#829499 bevel highlights mostly on wall/rail edges, a few small #FFC46B side lamps, #492C42/#9C626C organic pipes where requested. Keep floor darker and quieter than character sprites; no giant glow or high-contrast checkerboard floor. More precise craftsmanship than a blocky graybox, but no random noise. Draw a full opaque background, not a transparent cutout.
ROOM IDENTITY: A heart-pump antechamber inside a living factory. Rich layered steel wall supports cage dusty-rose vascular trunks and branching tendons in the TOP wall zone. Small bolted clamps connect organic pipes to mechanical manifolds. Dark organic masses stay behind the steel ribs, not on the clear walking floor. One central recessed octagonal niche at the back for a separate guardian sprite; it is empty. Moody but navigable; warm rose flesh contrasts with cool steel without turning the whole room red.
```

## transport-room.png

```text
Use case: stylized-concept. A PRODUCTION GAMEPLAY BACKGROUND for Night Shift Circuit, landscape EXACT 16:9, 1920x1080 composition. The supplied images are APPROVED STYLE references, not compositions to copy. Beautiful high-detail pixel art with organized steel bevels, hard discrete shade bands, tiny purposeful fasteners, dusty rose flesh at machine interfaces, controlled amber path lamps, and dark cool foundations. No painterly blur, 3D render, UI, typography, people, enemies, loose items or standalone interactable objects.
CAMERA/PLAYABILITY LOCK: a fixed slightly elevated oblique FRONT view, upright back wall, horizontal floor seams, NOT diamond isometric, NOT side scrolling, NOT a cinematic depth corridor with vanishing point far away. The player arena is a large clean rectangular steel floor spanning x=16%-84% and y=38%-83% of the frame. Its LOWER and UPPER edges are HORIZONTAL. This entire rectangle MUST stay unobstructed and walkable with subdued texture. Back wall machinery occupies y=14%-37%, side structural borders stay OUTSIDE x=16%-84%. Leave a quiet bottom border below y=84% and dark vignette outside the room outline. Top 0%-13% is dark architecture for an overlay HUD. Back wall has a few dark recessed access niches; DO NOT paint doors, operating consoles or a boss in them, those are separate sprites. No pillars, chests or obstacles on the walking rectangle.
MATERIAL/FOCUS: broad dark #102738/#244454 floor masses with restrained segmented metal seams, #49616B/#829499 bevel highlights mostly on wall/rail edges, a few small #FFC46B side lamps, #492C42/#9C626C organic pipes where requested. Keep floor darker and quieter than character sprites; no giant glow or high-contrast checkerboard floor. More precise craftsmanship than a blocky graybox, but no random noise. Draw a full opaque background, not a transparent cutout.
ROOM IDENTITY: A utilitarian organic cargo-transfer room. Paired mechanical conveyance ducts and suspended maintenance rails along the BACK wall, thick steel couplers, one exposed rose conduit following an existing rail. Broad low-texture floor plates, a short recessed drainage strip near each side boundary OUTSIDE the central walk rectangle. Layered asymmetrical engineering detail across the back wall, open center. No conveyor belt crossing the playable floor, no crates or other collision objects.
```

## lung-room.png

```text
Use case: stylized-concept. A PRODUCTION GAMEPLAY BACKGROUND for Night Shift Circuit, landscape EXACT 16:9, 1920x1080 composition. The supplied images are APPROVED STYLE references, not compositions to copy. Beautiful high-detail pixel art with organized steel bevels, hard discrete shade bands, tiny purposeful fasteners, dusty rose flesh at machine interfaces, controlled amber path lamps, and dark cool foundations. No painterly blur, 3D render, UI, typography, people, enemies, loose items or standalone interactable objects.
CAMERA/PLAYABILITY LOCK: a fixed slightly elevated oblique FRONT view, upright back wall, horizontal floor seams, NOT diamond isometric, NOT side scrolling, NOT a cinematic depth corridor with vanishing point far away. The player arena is a large clean rectangular steel floor spanning x=16%-84% and y=38%-83% of the frame. Its LOWER and UPPER edges are HORIZONTAL. This entire rectangle MUST stay unobstructed and walkable with subdued texture. Back wall machinery occupies y=14%-37%, side structural borders stay OUTSIDE x=16%-84%. Leave a quiet bottom border below y=84% and dark vignette outside the room outline. Top 0%-13% is dark architecture for an overlay HUD. Back wall has a few dark recessed access niches; DO NOT paint doors, operating consoles or a boss in them, those are separate sprites. No pillars, chests or obstacles on the walking rectangle.
MATERIAL/FOCUS: broad dark #102738/#244454 floor masses with restrained segmented metal seams, #49616B/#829499 bevel highlights mostly on wall/rail edges, a few small #FFC46B side lamps, #492C42/#9C626C organic pipes where requested. Keep floor darker and quieter than character sprites; no giant glow or high-contrast checkerboard floor. More precise craftsmanship than a blocky graybox, but no random noise. Draw a full opaque background, not a transparent cutout.
ROOM IDENTITY: The entry to a lung chamber in a body-factory. Two large muted dusty-rose pulmonary bellows held in steel rib cages in the TOP wall zone, connected by a central ventilation manifold and clamped pale tendon tubes. Carefully beveled bolted steel on side supports. The bellows are visible through broad dark apertures, not luminous. Absolutely clear rectangular steel walking arena below them, as specified, with only low-contrast plate seams. Quiet cyan indicators and paired amber boundary lamps, no fog obscuring the ground.
```

## terminal.png

```text
Use case: stylized-concept. One original production game sprite in EXACTLY the approved reference's premium steel pixel-art style. Dark slate-blue broad plate faces, carefully stepped bevel highlights, organized fasteners, tiny amber tabs and compact cyan functional accents. Upper-left lighting, discrete pixel clusters and hard shade bands. Genuine TRANSPARENT alpha around the object, no atmosphere, floor, cast shadow, halo, writing, border, labels or UI. Entire object visible with generous empty margin, not cropped. No smooth 3D render or vector illustration.
A compact standing maintenance console from a slightly elevated front three-quarter RPG game camera. Chamfered low pedestal, tilted rectangular cyan display, three solid square physical keys below, protected steel base and a small tidy rose conduit down its rear. Clear dark screen bezel with a few abstract cyan status bars, no letters or numerals. It is a freestanding waist-high interactive terminal, not a whole room or large machine. One complete console only.
```

## plating.png

```text
Use case: stylized-concept. One original production game sprite in EXACTLY the approved reference's premium steel pixel-art style. Dark slate-blue broad plate faces, carefully stepped bevel highlights, organized fasteners, tiny amber tabs and compact cyan functional accents. Upper-left lighting, discrete pixel clusters and hard shade bands. Genuine TRANSPARENT alpha around the object, no atmosphere, floor, cast shadow, halo, writing, border, labels or UI. Entire object visible with generous empty margin, not cropped. No smooth 3D render or vector illustration.
A single wearable reinforced industrial chest-armor equipment item, inventory icon front three-quarter view: a compact steel-blue protective breastplate with dark recessed central inset, layered shoulder attachment hooks, a few bolts, a cyan small power/status tab and restrained amber reinforcement marks. Broad readable shield-like silhouette and convincing bevels, grounded practical work equipment. Not a person or a hand-held shield. One item only.
```

## capacitor.png

```text
Use case: stylized-concept. One original production game sprite in EXACTLY the approved reference's premium steel pixel-art style. Dark slate-blue broad plate faces, carefully stepped bevel highlights, organized fasteners, tiny amber tabs and compact cyan functional accents. Upper-left lighting, discrete pixel clusters and hard shade bands. Genuine TRANSPARENT alpha around the object, no atmosphere, floor, cast shadow, halo, writing, border, labels or UI. Entire object visible with generous empty margin, not cropped. No smooth 3D render or vector illustration.
A single industrial circuit-capacitor module equipment item, inventory icon front three-quarter view. Compact vertical slate-blue rectangular casing with chamfered steel corners, three turquoise charge bars behind a dark inset front window, two exposed brass terminals at top and a short tidy rose service cable with a coupling at its lower edge. Readable compact 2:3 block silhouette, exquisite restrained pixel bevels and precise structure. No lightning, glow haze or separate sparks. One complete item only.
```

