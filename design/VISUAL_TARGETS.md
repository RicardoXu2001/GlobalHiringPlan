# RPG 美术目标与实机 · ART-2

targetFinish: 可在 Windows Godot 中完整游玩的重构切片，采用 ART-2 精细像素场景、角色、HUD 与反馈。

2026-11-12。用户确认[首批四份样稿](visual-targets/sprite-review-v1/REVIEW.md)的风格，但否定整图式替换。当前目标是以模块化场景与真实动作实现同样的钢铁／组织材质和检修员造型。生产标准以[美术圣经](ART_DIRECTION.md)为准。

## 当前目标与证据

两张项目参考：[生体工厂原型板](visual-targets/夜班回路：生体工厂原型板.png)、[武器原型板](visual-targets/夜班回路：武器原型原型板_gbc.png)。它们用于风格与设计语法参考，不直接裁切作为精灵。

| 检查重点 | 当前 Godot 1280×720 实机 | 判读要求 |
| --- | --- | --- |
| 首屏 | [标题](../qa/title.png) | 左侧文字保护区，右侧供给架与小人物，材质统一 |
| 地面与敌群 | [拘束侧室](../qa/expedition-room3.png) | 低纹理走道、不同敌形、清楚脚点 |
| Boss 与预警 | [守卫预警](../qa/expedition-guardian-warn.png) | 血肉背景不冒充危险，警红边框高于装饰特效 |
| 中心状态 | [心核接驳](../qa/expedition-graft.png) | 同一装置保留钢架与锚点，心核接入可辨 |
| 武器与装备 | [武器铺](../qa/expedition-shop.png)、[选装](../qa/weapons.png) | 实物图等比缩放，图标和文字都在容器内 |
| 动作与结果 | [短弧](../qa/combat-arc.png)、[受伤](../qa/player-hurt.png)、[倒地](../qa/player-dead.png) | 新精灵与现有 PixelFX 配合，反馈不改变规则窗口 |

当前已索引 64 个角色／敌人姿态帧及 12 个独立场景模块；门和 Boss 机械部件独立运动，世界按脚点排序。原整房间图与静态人物母稿退出世界绘制。[实际输入动态预览](../qa/modular-motion.gif)。当前仍需精修完整方向动作、握持、重复模块与像素一致性，不将样稿确认或机器通过当作最终视觉验收。测试覆盖与未验证项见 [QA 报告](../qa/QA_REPORT.md)。

## 后续批次的否决条件

- 回到基础几何拼装，缺少结构、接口与可辨材质。
- 背景细节强于人物或地面危险，光晕盖住轮廓。
- 同类资产突然改变人物比例、相机角度或金属／组织的明暗语言。
- 依靠颜色区分全部敌人，或把肉色当作伤害边界。
- 原尺寸图片撑出 UI、长武器拉伸，中文缩成不可读小字。
- 将尚未制作的完整七组、终极 Boss 或完整全方向动作写成已完成。

## 历史目标

`art-direction-board.png`、`01-title.png`、`02-exploration.png`、`03-pressure.png` 及 `draw_studies.py` 为 ART-1.0 的原创布局草图，保留作构图历史；它们的几何精细度与 16 色限制已被 ART-2 替代。

早期用户参考截图只提供光色、块面与尺度关系，原图不收入生产资源。当前母稿由内置 image_gen 结合项目参考生成并保留，提示词见 [生产记录](../rpg/art/modular/PROMPTS.md)与[首批记录](visual-targets/sprite-review-v1/PROMPTS.md)。发行前仍需完成最终资产与字体的来源确认；本文件不将生成或自动化验证当作发行权结论。
