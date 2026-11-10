# 夜班回路 · 首个运行切片

targetFinish: 可在 Windows Godot 中完整游玩的重构切片，采用 ART-1.0 像素场景、角色、HUD 与反馈。

范围、游戏规则与资产分别见 [产品范围](PRODUCT_BRIEF.md)、[游戏策划案](GAME_DESIGN.md) 和 [美术圣经](ART_DIRECTION.md)。

experienceProfile: hybrid

保真顺序：接入并选择模块 → 躲避和攻击 → 停机取证 → 玩家确认回溯 → 用原件进 B-17。只有主动回溯提交迭代，重试和退出继续各有单独入口。状态与故事证据一起可见。

Windows 桌面、Godot 4.5.1、中文、横屏键鼠、离线单人。世界 640×360 最近邻整数放大，UI 独立排版。像素图层、局部光与工厂音效均在本地运行，回溯采用引擎内短转场。用 Godot 导入 [rpg/project.godot](../rpg/project.godot)，或运行 [试玩启动器](../试玩重构版.cmd)。在仓库根目录执行 `& ./rpg/验证.ps1` 复现验证。[机器事实](../qa/verification.json)

实际运行环境为 Windows、Godot 4.5.1 stable、OpenGL Compatibility、RTX 4060 Laptop GPU、1280×720。测试入口用 Godot 的键鼠事件走通流程，保留标题、探索、战斗和结果帧。正式资产精修、真人平衡和独立包待验。[QA 报告](../qa/QA_REPORT.md)
