# 游戏开发 Agent 技能索引

上游目录核对于 2026-11-20。仓库有 **79 个专门技能**，覆盖 12 个引擎与框架，另有 `router` 负责识别引擎和选择技能。表内「已装」表示本机 Codex 用户目录在核对当日已有该技能，共 14 项。可用 `Ctrl+F` 搜索技能名。 [上游完整目录](https://github.com/gamedev-skills/awesome-gamedev-agent-skills#catalog)

## 按《夜班回路》的任务查找

| 要做的事 | 优先打开的技能 |
| --- | --- |
| 校准短弧、探针和铆枪的接触帧、顿帧与闪避衔接 | `game-feel`、`godot-animation`、`input-systems` |
| 调整命中、格挡、危险预警的声音层次 | `audio-design`、`godot-audio` |
| 校对 HUD、中枢交互、武器铺和低动效下的可读性 | `game-ui-ux`、`godot-ui-control` |
| 做 B-17 检修井，验证分支选择、回访与继续游戏 | `level-design`、`dialogue-systems`、`save-systems` |
| 做新敌人、追加攻击模式或试验武器强化 | `game-ai`、`prototype-fast`，动作细化时搭配 `godot-animation` |
| 扩充武器装备池、随机库存与远征构筑 | `godot-resources`、`rpg`、`roguelike`，需要复现随机结果时加 `procedural-gen` |
| 补规则回归、梳理场景引用 | `godot-gdscript-headless-testing`、`godot-nodes-scenes`，完整通关继续用项目现有的实机验证 |
| 制作并分发独立 Windows Demo | `godot-export`，上 Steam 时加 `steam-publish` |

项目目前使用 **Godot 4.5.1**，上游 Godot 示例以 **4.7** 为基线。采用示例前先核对 4.5 的 API。手感、预警可读性和音效平衡以现有实机流程及试玩为准。 [开发路线图](ROADMAP.md) · [试玩及验证说明](../rpg/README.md) · [Godot 4.5 文档](https://docs.godotengine.org/en/4.5/)

## 按需安装

在 Codex 里直接说「按项目的游戏开发技能索引，部署 `dialogue-systems` 和 `game-ai`」即可。已装的技能用 `$技能名` 调用，例如 `$game-feel`。

本机也可以在 PowerShell 用 Codex 自带的安装器。下面以两项为例，替换 `--path` 后的目录即可批量安装。目录可以从每行的源码链接取得，使用 `blob/main/` 后、`/SKILL.md` 前的部分。

```powershell
$skillRoot = Join-Path $env:USERPROFILE '.codex\skills'
$installer = Join-Path $skillRoot '.system\skill-installer\scripts\install-skill-from-github.py'
python $installer --repo gamedev-skills/awesome-gamedev-agent-skills --path skills/disciplines/dialogue-systems skills/disciplines/game-ai --dest $skillRoot --method download
```

安装命令只传待安装的技能。同名目录会使安装器报错。安装后核对目标目录中的 `SKILL.md`，下一轮即可调用。 [上游安装说明](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/docs/INSTALLATION.md)

## 技能路由器

| 技能 | 功能与主要用途 | 上游 |
| --- | --- | --- |
| `router` | 从 `project.godot`、`.uproject` 等识别目标引擎，再按任务挑选引擎、专项、类型和工作流技能。适合跨引擎项目或尚未确定要用哪项技能时。安装参数为 `--path router`。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/router/SKILL.md) |

## Godot 16 项

| 技能 | 功能与主要用途 | 上游 |
| --- | --- | --- |
| `godot-gdscript` | GDScript 静态类型、导出变量、异步等待和 Godot 3.x 迁移。适合写新脚本或排查类型与初始化问题。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-gdscript/SKILL.md) |
| `godot-nodes-scenes` | 场景树、实例化、生命周期和 Autoload。适合拆分场景、复用节点，以及检查失效的资源路径和 UID。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-nodes-scenes/SKILL.md) |
| `godot-signals-groups` | 类型化信号、Callable 连接、节点组与事件总线。适合把战斗事件接到 HUD、音效或关卡结算。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-signals-groups/SKILL.md) |
| `godot-2d-movement` | 用 `CharacterBody2D` 做俯视或平台移动、滑动、斜坡和单向平台。适合新控制器和碰撞移动问题。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-2d-movement/SKILL.md) |
| `godot-tilemap` | 配置 `TileMapLayer`、`TileSet`、图集、地形自动拼接与运行时换瓦片。适合网格化房间和地形编辑。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-tilemap/SKILL.md) |
| `godot-physics` | 选择物理体和 `Area`，配置碰撞层、遮罩、射线与 3D Jolt。适合接敌、障碍和触发范围排查。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-physics/SKILL.md) |
| `godot-ui-control`（已装） | 用 `Control`、容器、锚点、主题和焦点制作界面。适合 HUD、武器铺和不同窗口尺寸的布局检查。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-ui-control/SKILL.md) |
| `godot-animation`（已装） | 用 `SpriteFrames`、`AnimatedSprite2D`、`AnimationPlayer`、`AnimationTree` 和 Tween 组织动画。适合角色动作衔接和机械部件动画。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-animation/SKILL.md) |
| `godot-shaders` | 编写 2D、3D 和粒子着色器，检查编译。适合描边、局部受击和材质效果。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-shaders/SKILL.md) |
| `godot-3d-essentials` | 搭建 3D 摄像机、灯光、环境、材质和 `GridMap`。适合 Godot 3D 场景原型。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-3d-essentials/SKILL.md) |
| `godot-resources`（已装） | 用自定义 `Resource` 和 `.tres` 管理数据，处理资源共享、复制和后台加载。适合扩充武器、装备、敌人参数。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-resources/SKILL.md) |
| `godot-audio`（已装） | 配置音频播放节点、总线、循环和播放位置。适合接入战斗音效、空间音频和节拍同步。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-audio/SKILL.md) |
| `godot-multiplayer` | 用 ENet、RPC 和场景同步做多人连接与状态复制，提供双实例验证方法。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-multiplayer/SKILL.md) |
| `godot-export` | 配置导出模板、预设和命令行构建。适合 Windows 独立包和 Web 导出。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-export/SKILL.md) |
| `godot-csharp` | Godot .NET 项目的 C# 生命周期、导出属性、信号和 GDScript 互操作。适合 C# 节点开发。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-csharp/SKILL.md) |
| `godot-gdscript-headless-testing` | 用 `--headless` 跑 GDScript 断言和 CI，用退出码报告失败。适合装备规则、存档和状态转换回归。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-gdscript-headless-testing/SKILL.md) |

## 跨引擎专项 15 项

| 技能 | 功能与主要用途 | 上游 |
| --- | --- | --- |
| `create-game-assets` | 建立资产风格、尺寸、色板和输出规范，批量生产同一系列的角色、瓦片、图标和纹理，入游戏检查并记录授权。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/create-game-assets/SKILL.md) |
| `game-ai` | 在状态机、行为树、效用 AI 和 GOAP 之间选型，设计感知、追击、转向和寻路。适合敌人与 NPC 行为。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/game-ai/SKILL.md) |
| `ai-behavior-trees-utility-ai` | 实现行为树节点、黑板、装饰器和效用评分曲线。适合行为选项变多、简单状态机难表达时。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/ai-behavior-trees-utility-ai/SKILL.md) |
| `procedural-gen`（已装） | 用种子控制随机数，生成地图、地形或掉落，并检查生成约束。适合可复现商店库存、掉落和程序化地图。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/procedural-gen/SKILL.md) |
| `dialogue-systems` | 用 Ink、Yarn Spinner 或 JSON 组织分支、条件、变量和本地化 ID。适合对话选择影响后续状态的场景。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/dialogue-systems/SKILL.md) |
| `save-systems`（已装） | 设计存档数据、槽位和自动保存，处理原子写入、版本迁移与读取验证。适合检查点、继续游戏和旧档兼容。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/save-systems/SKILL.md) |
| `audio-design`（已装） | 规划音频总线、音量、响度与动态音乐，通过 ducking 自动压低背景声，给重复音效做变体。适合保持危险提示和武器反馈的层次。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/audio-design/SKILL.md) |
| `shader-programming` | 讲解溶解、描边、菲涅耳边光和后处理的着色器原理，提供 GLSL 与 HLSL 对照。适合跨引擎移植视觉效果。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/shader-programming/SKILL.md) |
| `physics-tuning` | 校准固定步长、插值、连续碰撞检测、阻尼与求解精度。适合处理穿透、抖动和不稳定的物理反馈。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/physics-tuning/SKILL.md) |
| `level-design`（已装） | 用角色移动尺度做灰盒、安排关卡节奏和路线，检查钥匙或能力门及软锁。适合 B-17 和后续遭遇制作。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/level-design/SKILL.md) |
| `input-systems`（已装） | 设计动作映射、缓冲输入、摇杆死区和改键冲突。适合闪避／攻击衔接、手柄与键位设置。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/input-systems/SKILL.md) |
| `game-feel`（已装） | 按事件强度组合顿帧、镜头震动、击退、缓动和局部反馈。适合校准命中、格挡、闪避和拾取。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/game-feel/SKILL.md) |
| `game-ui-ux`（已装） | 设计 HUD、菜单流程、界面缩放、安全区、手柄导航和可访问性。适合战斗信息和中枢整备界面。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/game-ui-ux/SKILL.md) |
| `camera-systems` | 设计 2D 跟随、死区和前视，以及第一人称、第三人称与分屏镜头。适合改构图或跟随行为。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/camera-systems/SKILL.md) |
| `performance-optimization` | 通过剖析定位 CPU 或 GPU 瓶颈，针对绘制调用、对象分配、回收或粒子开销优化。适合复现并解决卡顿。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/performance-optimization/SKILL.md) |

## 游戏类型 9 项

| 技能 | 功能与主要用途 | 上游 |
| --- | --- | --- |
| `platformer` | 设计土狼时间、跳跃缓冲、可变跳高、墙跳、陷阱和检查点。适合横版或其他以跳跃为核心的游戏。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/genres/platformer/SKILL.md) |
| `roguelike`（已装） | 设计单局结构、死亡重开、局外成长与种子。也覆盖传统回合制的行动顺序和视野。适合远征生命周期和随机可复现性。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/genres/roguelike/SKILL.md) |
| `rpg`（已装） | 设计属性修正、经验曲线、伤害公式、道具装备和任务。适合扩展武器及插件构筑。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/genres/rpg/SKILL.md) |
| `fps-shooter` | 处理即时射线与弹体、击杀用时、威力衰减、后坐、开镜灵敏度和命中同步。适合第一人称射击。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/genres/fps-shooter/SKILL.md) |
| `tower-defense` | 设计敌人路径、波次、塔的选敌规则、护甲克制与金币经济。适合关卡波次和塔防平衡。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/genres/tower-defense/SKILL.md) |
| `card-game` | 用数据表示卡牌，通过统一规则结算牌区、触发与洗牌。适合卡牌对战和局内构筑。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/genres/card-game/SKILL.md) |
| `visual-novel` | 设计剧情路线、结局、随处存档、阅读回顾、已读跳过和逐字显示。适合视觉小说。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/genres/visual-novel/SKILL.md) |
| `survival-crafting` | 设计采集、配方、科技树、负重、腐坏、生存需求和基地建设。适合生存制作循环。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/genres/survival-crafting/SKILL.md) |
| `puzzle` | 实现三消、推箱子等离散规则，处理撤销并用求解器验证关卡。适合规则严格的解谜玩法。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/genres/puzzle/SKILL.md) |

## 开发与发布流程 5 项

| 技能 | 功能与主要用途 | 上游 |
| --- | --- | --- |
| `game-jam` | 按比赛规则与交付时间控制范围，维护可砍功能清单并检查提交包。适合短周期比赛。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/workflows/game-jam/SKILL.md) |
| `prototype-fast`（已装） | 用灰盒、调试 HUD 和短试玩验证一个玩法问题，再决定保留、调整或舍弃。适合试做新敌人和武器强化。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/workflows/prototype-fast/SKILL.md) |
| `steam-publish` | 配置 SteamPipe depot、构建描述、`steamcmd` 上传、测试分支和商店审核。适合 Steam Demo 或正式发行。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/workflows/steam-publish/SKILL.md) |
| `itch-publish` | 用 `butler` 管理上传渠道、平台标签、版本与 CI，覆盖 HTML5 构建。适合 itch.io 试玩包。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/workflows/itch-publish/SKILL.md) |
| `game-docs` | 维护一页式 GDD、功能索引和短功能说明，并与实现同步。适合项目交接和小团队文档维护。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/workflows/game-docs/SKILL.md) |

## 其他引擎 34 项

以下技能适用于对应引擎的项目。《夜班回路》当前使用 Godot。

### Unity 9 项

| 技能 | 功能与主要用途 | 上游 |
| --- | --- | --- |
| `unity-csharp-scripting` | 编写 `MonoBehaviour`、处理生命周期、序列化和 `.meta`／GUID。适合 Unity 脚本开发和自动编译检查。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/unity/unity-csharp-scripting/SKILL.md) |
| `unity-input-system` | 配置 `.inputactions`、动作图、`PlayerInput` 和控制方案。适合键鼠、手柄与多套映射。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/unity/unity-input-system/SKILL.md) |
| `unity-physics` | 配置 2D／3D 刚体、碰撞、射线和关节。适合 Unity 物理交互。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/unity/unity-physics/SKILL.md) |
| `unity-animation` | 配置 Animator 状态、过渡、混合树、Avatar Mask、根运动和 IK。适合角色动画。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/unity/unity-animation/SKILL.md) |
| `unity-scriptableobjects` | 用 `ScriptableObject` 表示可复用配置、共享变量和事件通道。适合道具和角色参数数据化。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/unity/unity-scriptableobjects/SKILL.md) |
| `unity-tilemap-2d` | 配置 Tile Palette、Rule Tile、组合碰撞体和运行时改图。适合 Unity 2D 地图。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/unity/unity-tilemap-2d/SKILL.md) |
| `unity-navmesh` | 烘焙 `NavMeshSurface`，配置导航代理、跨区链接和动态重烘焙。适合 Unity AI 寻路。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/unity/unity-navmesh/SKILL.md) |
| `unity-build-pipeline` | 处理平台构建设置、IL2CPP、代码裁剪、Addressables 和 CI。适合构建流水线。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/unity/unity-build-pipeline/SKILL.md) |
| `unity-build-size` | 用 Build Report 找体积来源，按平台优化纹理、音频和模型。适合压缩安装包或下载体积。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/unity/unity-build-size/SKILL.md) |

### Unreal Engine 6 项

| 技能 | 功能与主要用途 | 上游 |
| --- | --- | --- |
| `unreal-blueprints` | 组织蓝图类、关卡蓝图、接口、事件和分发器。适合可视化玩法脚本。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/unreal/unreal-blueprints/SKILL.md) |
| `unreal-cpp-gameplay` | 使用 Gameplay Framework、C++ 反射和 GC 安全引用，处理命令行构建。适合 Unreal 原生玩法代码。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/unreal/unreal-cpp-gameplay/SKILL.md) |
| `unreal-enhanced-input` | 配置 Input Action、Mapping Context、触发事件与改键。适合 Unreal 输入和控制模式。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/unreal/unreal-enhanced-input/SKILL.md) |
| `unreal-behavior-trees` | 用行为树、黑板、EQS 和 StateTree 做 AI 决策，并实现自定义 C++ 任务。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/unreal/unreal-behavior-trees/SKILL.md) |
| `unreal-niagara` | 组织 Niagara 系统、发射器、用户参数与粒子边界，选择 CPU 或 GPU 模拟。适合实时 VFX。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/unreal/unreal-niagara/SKILL.md) |
| `unreal-packaging` | 用 `BuildCookRun` 做 Shipping 构建、烹饪和打包，定位 UAT 与 Cook 日志错误。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/unreal/unreal-packaging/SKILL.md) |

### Ebitengine 1 项

| 技能 | 功能与主要用途 | 上游 |
| --- | --- | --- |
| `ebitengine-game` | 用 Go 建立 2D 游戏循环、输入、像素缩放、文字和音频，并构建桌面、WASM 或移动版本。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/ebitengine/ebitengine-game/SKILL.md) |

### Web 引擎与渲染库 6 项

| 技能 | 功能与主要用途 | 上游 |
| --- | --- | --- |
| `phaser-core` | 配置 Phaser 游戏、Scene 生命周期和加载器。适合浏览器 2D 游戏基础及 Phaser 3 到 4 升级。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/web-engines/phaser-core/SKILL.md) |
| `phaser-arcade-physics` | 配置 Arcade Physics 物理体、速度、重力、碰撞和重叠检测。适合 2D 碰撞和弹体池。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/web-engines/phaser-arcade-physics/SKILL.md) |
| `pixijs-rendering` | 处理 PixiJS 异步初始化、资源、容器、精灵和指针拖动。适合 Web 2D 渲染与版本迁移。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/web-engines/pixijs-rendering/SKILL.md) |
| `threejs-scene-setup` | 搭建 three.js 场景、相机、渲染循环、窗口适配和轨道控制。适合 Web 3D 原型。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/web-engines/threejs-scene-setup/SKILL.md) |
| `threejs-gltf-loading` | 加载 glTF、配置模型和纹理解码，处理动画混合、骨骼克隆。适合接入 3D 角色和模型。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/web-engines/threejs-gltf-loading/SKILL.md) |
| `threejs-materials-lighting` | 设置材质、灯光、阴影、HDR 环境和色调映射。适合调校 Web 3D 的视觉表现。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/web-engines/threejs-materials-lighting/SKILL.md) |

### Bevy pygame LÖVE Defold 和 Roblox 12 项

| 技能 | 功能与主要用途 | 上游 |
| --- | --- | --- |
| `bevy-ecs` | 用 Rust Bevy 编写 ECS 组件、查询、系统调度、状态和观察器。适合数据驱动的 Bevy 游戏。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/other-engines/bevy-ecs/SKILL.md) |
| `pygame-core` | 组织 pygame-ce 事件、更新与绘制循环，处理时间步、精灵、矩形与无窗口测试。适合 Python 2D 游戏。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/other-engines/pygame-core/SKILL.md) |
| `love2d-core` | 用 Lua 的 LÖVE 回调、配置、文件系统和固定步长实现 2D 循环。适合像素游戏原型。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/other-engines/love2d-core/SKILL.md) |
| `defold-core` | 组织集合、游戏对象、输入焦点、消息、工厂与集合代理。适合 Defold 场景结构和 Bob 构建。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/other-engines/defold-core/SKILL.md) |
| `roblox-luau` | 使用 Roblox 服务、实例、脚本类型和 Luau 类型系统。适合 Studio 中的脚本与模块开发。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/other-engines/roblox-luau/SKILL.md) |
| `roblox-datastores` | 用 `DataStoreService` 实现读写、关闭保存、会话锁和排行榜。适合持久化玩家数据。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/other-engines/roblox-datastores/SKILL.md) |
| `roblox-ui` | 处理 `ScreenGui`、`UDim2`、布局、安全区、触屏与手柄焦点。适合 Roblox 多设备界面。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/other-engines/roblox-ui/SKILL.md) |
| `roblox-networking` | 设计 Remote 接口、服务器权威、限流、命中校验与复制。适合 Roblox 联机状态同步。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/other-engines/roblox-networking/SKILL.md) |
| `roblox-characters` | 处理角色生成、`Humanoid`、R6／R15、重生与工具。适合角色控制和装备。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/other-engines/roblox-characters/SKILL.md) |
| `roblox-physics` | 组织物理组件和约束，配置碰撞组、射线和网络所有权。适合物理交互。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/other-engines/roblox-physics/SKILL.md) |
| `roblox-studio-workflow` | 在现有 Roblox place 或 Rojo 项目中定位与编辑资源，选择 Studio 测试模式验证。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/other-engines/roblox-studio-workflow/SKILL.md) |
| `roblox-simulator-economy` | 估算放置、模拟器和大亨玩法的收入、成本曲线、重生节奏及抽取概率。适合经济平衡。 | [源码](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/other-engines/roblox-simulator-economy/SKILL.md) |
