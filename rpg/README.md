# 牛马公司 · 夜班回路

《夜班回路》0.1 是 RPG 的首个可玩切片。Windows 本机可双击[试玩启动器](../试玩重构版.cmd)，它会查找仓库上两级目录的 Godot 4.5.1。也可用 Godot 4.5.1 导入本目录的 [project.godot](project.godot)，等待图片导入完成后按 F5。

| 操作 | 键位 |
| --- | --- |
| 移动 | WASD |
| 交互 / 开门 / 查看记录 | E，靠近提示点 |
| 选择模块 | 1 / 2，或点击按钮 |
| 攻击 | J 向面朝方向攻击，或鼠标左键瞄准 |
| 闪避 | 空格，沿当前移动方向 |
| 暂停 / 关闭弹窗 | Esc |

短弧「棘齿切割器」用骨白宽刃近身劈开弱点。探针「脉冲测距枪」用青色窄束命中远处开板口。撞上护板会弹开灰白火花并发出短促金属声。红框出现后离开落点，看到青色护板抬起再打。停机后靠近右侧日志终端。

主动确认回溯时写入 B-17 检查点，进入旁路读完供给记录后再次保存。标题的「继续调查」从最新检查点继续。战败重试重开当前轮，「重新调查」清除切片进度。存档使用 Godot 的 `user://night-shift.cfg`，应用数据目录为 `BossCompanyRebuild`。

暂停页提供 100%、125%、150% 文字大小及低动效开关。场景图和精灵使用 ART-1.0 色板，运行直接读取已存的 PNG。需要改图时可用 Python 和 Pillow 执行 `python rpg/art/draw_pixels.py`。

## 像素特效制作

[当前战斗资源](art/combat/effects.tres)来自本项目编写的 PixelFX 绘制程序。运行 `node rpg/art/build_combat_fx.mjs` 可重做刀痕、脉冲、两类命中与格挡的透明精灵表，并生成本地逐帧预览。Godot 直接播放导出的资源。

[PixelFX](https://github.com/patch-gg/pixelfx) 用于离线生成特效精灵表。本机源码位于 `.runtime/pixelfx-tools/`，固定在 `044e12a45dc9cc312cec50ee606dfc98afe5adc2`。工具使用 Node.js 18 或更新版本。在仓库根目录复现探针命中方向的导出样例：

```powershell
$opts = '{"palette":["#07141F","#102738","#244454","#237C83","#57E4CE","#829499","#DFE8D5"],"stone":"#49616B","light":0.25}'
node .runtime/pixelfx-tools/tools/render.mjs impacts/bullet-impact --sheet --no-actor --opts $opts --out .runtime/pixelfx-preview
```

样例生成透明 PNG、帧数据 JSON 和预览图。进入 Godot 的特效使用最近邻采样，按 JSON 的帧矩形、时长与锚点配置。审查以游戏内像素尺寸为准，保留红色预警的形状与对比度，遵循 [ART-1.0](../design/ART_DIRECTION.md)。分发采用的资产时保留 [LICENSE](https://github.com/patch-gg/pixelfx/blob/044e12a45dc9cc312cec50ee606dfc98afe5adc2/LICENSE) 和[上游署名](https://github.com/patch-gg/pixelfx/blob/044e12a45dc9cc312cec50ee606dfc98afe5adc2/NOTICE.md)。

在仓库根目录运行 `& ./rpg/验证.ps1` 可复现 Godot 实机渲染与注入输入路径。[游戏策划案](../design/GAME_DESIGN.md) · [构建说明](../design/BUILD_BRIEF.md) · [QA 报告](../qa/QA_REPORT.md)
