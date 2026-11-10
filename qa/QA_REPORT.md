# 《夜班回路》0.1 · Windows 验证

2026-11-10。Windows，Godot 4.5.1 stable，OpenGL Compatibility，NVIDIA RTX 4060 Laptop GPU，1280×720。执行 `& ./rpg/验证.ps1`，退出码 0。启动、渲染、输入、核心循环、结果、重开六项通过。机器事实见 [verification.json](verification.json)，状态记录见 [run.json](run.json)。

- 从干净的应用数据目录进入标题，按 Enter 开始，使用 WASD 和 E 查门。第一轮在 B-17 被拒。
- 选择探针进入车间，通过空格闪避离开纵列，使用左键命中开板口，5 点耐久停机。读日志后取消一次回溯，确认未写检查点。再确认后回到开局，模块重置，证据写入。
- 重新实例化主场景，读回磁盘检查点。原先拒绝通行的门可以进入，结算签收记录回读探针。重新调查恢复初态。
- 短弧路线原地留在落点里，三次受击后失败，迭代仍为 01。重试后近身引出横扫，离开红框并用短弧停机。

运行截图：[标题](title.png)、[探索](exploration.png)、[Boss 预警](combat.png)、[结算](outcome.png)。

战斗更新覆盖探针空射、撞护板、命中弱点，以及短弧命中。空射和格挡保留 24 点结构强度，两种弱点命中分别扣 4 点和 8 点。还通过暂停菜单打开低动效并验证攻击输入。[武器选装](weapons.png) · [格挡与预警叠加](combat-block.png) · [探针命中](combat-probe.png) · [短弧命中](combat-arc.png)

输入来自 Godot 注入的键鼠事件。实际键鼠设备、1080p、不同 DPI、字号布局、音效主观感受、独立 Windows 包和真人节奏仍待验证。完整战役、随机地图与最终 Boss 在后续范围。
