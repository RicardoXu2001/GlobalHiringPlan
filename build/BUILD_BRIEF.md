# 本次构建说明

targetFinish: 可试玩、可修改、可交接的 Godot 招聘原型。
experienceProfile: 地图驱动的实时扩张策略，允许暂停思考，以全球人人入职为终局。

必读：`PRODUCT_BRIEF.md`、`GAME_DESIGN.md`、`ART_DIRECTION.md`。
范围：12地区、3起点、12升级、4职场事件、招聘点、反制、胜负、暂停快进、存档重开；规则与画面沿用批准的现有原型。
下一阶段：统一模拟时间上的经营合流，再接贷款、危机与方针。交接任务见根目录 `本周任务与接手清单.md`。

toolchain:

- targetPlatform: Windows x64
- targetRuntime: Godot Windows 桌面
- testedRuntime: Godot 4.5.1 Windows 开发运行；机制另在 Windows headless 验证
- engine / runtimeVersion: Godot 4.5.1.stable.official.f62fdbde1
- packageManager: none

commands（在仓库根目录执行，其他机器替换引擎路径）：

```powershell
# install: NONE（使用本机已有 Godot）
# buildOrExport: NOT_AVAILABLE（对应导出模板尚未准备）
& 'C:/Users/xudic/Desktop/R/Game/Godot_v4.5.1-stable_win64.exe' --path ./godot
# verify（机制权威回归）
& ./godot/验证.ps1
```

verification.completeRun: `../qa/verification.json#completeRun`。
实机窗口验证与机制回归分别记录。机制回归通过不证明一条完整的真实输入胜负路径，详见QA报告。

限制：独立EXE与干净机器、真人完整胜负和20–25分钟节奏、正式素材与新增经营尚未验证／实现。
资源导出包含JSON文件的依据：[Godot 4.5 FileAccess](https://docs.godotengine.org/en/4.5/classes/class_fileaccess.html)；实际导出验收待开展。
