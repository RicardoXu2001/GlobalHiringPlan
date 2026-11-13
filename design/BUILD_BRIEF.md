# 夜班回路 · 0.2.1 · 模块与动作修正

targetFinish: 可在 Windows Godot 中完整游玩的重构切片，采用 ART-2 精细像素场景、角色、HUD 与反馈。

范围与规则见[产品范围](PRODUCT_BRIEF.md)、[游戏策划](GAME_DESIGN.md)，视觉标准见[美术圣经](ART_DIRECTION.md)。

experienceProfile: hybrid

## 必须保真

原序章：选模块 → 闪避／攻击压力机 → 停机取证 → 主动确认回溯 → 保留原件进入 B-17 → 结果与重开。只有主动回溯提交迭代；战败、退出继续和常规返中心各有独立语义。

远征：选武器 → 三个小怪关 → 压维守卫 → 带心核与 30 工料返中心 → 接驳 → 买铆枪／强化／有限刷新 → 保存继续 → 肺叶入口遭遇 → 结果与重开。输入保持 WASD、E、J／鼠标左键、空格和 Esc。

- 通关奖励只结算一次；返中心不提交故事迭代。
- 心核只接驳一次，带来 +1 伤害；首次武器位强化 +2，换装保留等级。
- 商品 12、强化 10、刷新 6 且每批仅一次；首版一个装备位，护具与电容互换。
- 退出继续保留库存与提交状态，未完成遭遇从入场检查点恢复；死亡使本次远征失效。

招牌时刻：钢架包裹的活体心核接入中心并开始搏动；09 带着新铆枪与原强化等级再次出发。标题以左侧检修记录和右侧供给架形成构图；其他模式继承同一钢铁／组织材质、暗底与功能光。

## 当前范围与资产

保留原序章、首组四关、一次中心循环与肺叶入口。当前用 12 个独立场景模块与程序部件组装房间，按脚点处理绘制顺序。09 使用 28 个姿态帧，三类小怪各使用 12 个；Boss 护板、锤臂、活塞与心核分别运动，现有 PixelFX 继续运行。

`rpg/art/modular/` 为当前场景模块及角色动作资源，`index_modular.py` 仅重建区域、脚点、握持点与 SpriteFrames。`painted/` 保留样稿参考及武器／装备图；禁止再把整房间图、静态人物母稿作为最终世界替换。完整方向动作、握持与帧间精修，以及其余六组、其他器官、终极 Boss、全套宣传／加载资产仍待后续制作。

## 运行与验证

| 项目 | 当前事实 |
| --- | --- |
| targetPlatform / targetRuntime | Windows 桌面、Godot 原生游戏、中文、横屏键鼠、离线单人 |
| testedRuntime | Windows、Godot 4.5.1 stable、OpenGL Compatibility、RTX 4060 Laptop GPU、1280×720 |
| engine / runtimeVersion | Godot 4.5.1 stable |
| packageManager | none；运行不依赖 Python、Node 或生成服务 |
| install | 无需安装运行依赖；本机已有 Godot 4.5.1 |
| buildOrExport | 本轮在 Godot 中导入资源运行，独立 Windows 导出尚未交付 |
| start | 根目录双击 `试玩重构版.cmd`，或导入 `rpg/project.godot` 后 F5 |
| verify | 仓库根目录执行 `& ./rpg/验证.ps1` |
| completeRun | [qa/verification.json#completeRun](../qa/verification.json)，原序章＋首组远征 |

世界逻辑 640×360，实际渲染 1280×720；世界与 UI 使用相同的整数显示倍数与居中位置。碰撞、移动、攻击距离、交互点和经济规则不随画面提升改变。小于原生尺寸时允许等比缩小，细节可读性待专项校准。

离线资产工具：`python rpg/art/index_modular.py` 重建区域；`node rpg/art/build_combat_fx.mjs` 与 `node rpg/art/build_expedition_fx.mjs` 重建 PixelFX。Python／Pillow、Node 仅用于制作。两张用户原型板用于参考，不直接裁切。提示词见[生产记录](../rpg/art/modular/PROMPTS.md)。

当前六项机器事实与限制见 [QA 报告](../qa/QA_REPORT.md)。真人平衡、多 DPI、全屏、全部字号、完整逐帧动画、全战役及独立包均不由本轮通过结论覆盖。
