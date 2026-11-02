# 本次构建说明 · v0.2

targetFinish: 可试玩、可修改、可交接的 Godot OPC 与现金流原型。
experienceProfile: 地图驱动的实时扩张策略，允许暂停思考，以全球人人入职为终局。

必读：PRODUCT_BRIEF.md、GAME_DESIGN.md、ART_DIRECTION.md，以及根目录策划案第4.5–4.6节。

玩家承诺：从一人接单、现金投资和首雇，逐步自动化，再沿原12地区招聘网络扩张。相同订单、工资和回款规则贯穿开局与地图经营。
核心动词：接单、开工与交付、投资、雇佣与扩张、应对。
招牌时刻：第一次交付真实增加现金；首雇后本人停工仍可完成业务；地图招聘带来工资与需求变化；欠款结算显示原因并可重新创业。

范围：一个OPC模板、三档订单、工作台/接单流程两工具、首雇、自动执行/交付与按偏好接单、原12地区/12能力/4事件、现金/应收/工资/运营费/三周预估/欠款救援、暂停快进、存档与完整胜负。
非目标：贷款、经济周期、方针、资本市场、独立Windows包、正式音画与发行。
财务周和人数计费口径见godot/README.md，数值为当前可调原型参数。

toolchain:
- targetPlatform: Windows x64
- targetRuntime: Godot Windows 桌面
- testedRuntime: Godot 4.5.1 Windows开发运行；机制与场景逻辑另在Windows headless验证
- engine / runtimeVersion: Godot 4.5.1.stable.official.f62fdbde1
- packageManager: none

commands（仓库根目录执行，其他机器替换引擎路径）：
- install: NONE（使用本机Godot）
- buildOrExport: NOT_AVAILABLE（独立导出与模板未配置）
- start: & ./godot/运行原型.ps1
- verify: & ./godot/验证.ps1

verification.completeRun: ../qa/verification.json#completeRun。
机制回归和原生鼠标键盘窗口路径分别记录，旧v0.1窗口证据不能替代本版验收。当前结论与完整路径见qa/QA_REPORT.md。
限制：独立包/干净机器、真人完整获胜及20–25分钟节奏待验；经济为共享订单与固定工资的最小模型，未实现贷款/危机/方针。
