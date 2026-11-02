extends SceneTree
## 机制和界面规则回归；真实画面与系统输入另由原生窗口验收。
const Simulation = preload("res://simulation.gd")
var failures = []
var win_day = 0
var hire_day = 0
var automation_day = 0

func check(condition: bool, message: String):
	if not condition:
		failures.append(message)
		push_error(message)

func _init():
	call_deferred("run_checks")

func advance(game, days: int):
	for i in range(days):
		game.tick()

func finance_days(game, days: int):
	# 独立验证固定人数的结算；不运行招聘增减。
	for i in range(days):
		game.state.day += 1
		game.tick_economy()

func accounting(game):
	check(game.state.cash == game.content.economy.company.initialCash + game.state.cashIn - game.state.cashOut, "现金必须与实际收支守恒")
	check(game.state.cash >= 0, "现金不能隐式透支")
	check(game.valid_save(snapshot(game)), "当前合法状态必须可以保存恢复")

func snapshot(game) -> Dictionary:
	var value = game.state.duplicate(true)
	value.rngState = str(game.rng.state)
	return JSON.parse_string(JSON.stringify(value))

func run_checks():
	var game = Simulation.new()
	game.start("eastAsia")
	check(game.headcount() == 0 and game.state.cash == 4000, "OPC应从零雇员和40元启动")
	check(not game.accept_order("enterprise"), "未升级不可承接大单")
	check(game.accept_order("quick") and not game.accept_order("quick"), "只允许一个进行中订单")
	game.toggle_work()
	game.state.paused = true
	advance(game, 20)
	check(game.state.day == 0 and game.state.order.progress == 0 and game.state.cash == 4000, "暂停不推进工作或扣费")
	game.state.paused = false
	advance(game, 12)
	check(game.state.order.progress == 12 and game.state.cash == 4000, "完成工作后等待主动交付")
	check(game.deliver() and game.state.cash == 7000 and not game.deliver(), "交付只收款一次")
	check(game.buy_tool("desk") and game.state.cash == 1000 and not game.buy_tool("desk"), "现金升级扣款且不可重复")
	check(game.accept_order("batch") and game.state.cash == 500, "批量单扣5元启动费")
	game.toggle_work()
	advance(game, 18)
	check(game.deliver() and game.receivable_total() == 10500 and game.state.cash == 500, "延期订单应收不是现金")
	check(not game.purchase("remote"), "组织能力仍需前置")
	check(game.purchase("referral") and game.state.points == 0 and not game.purchase("referral"), "招聘点升级扣点与防重复")
	var save_path = "res://tests/test-save.json"
	check(game.save_game(save_path) == OK, "存档写入失败")
	var loaded = Simulation.new()
	check(loaded.load_game(save_path) and snapshot(game) == snapshot(loaded), "存档保留订单、应收、工具与随机状态")
	advance(game, 15)
	advance(loaded, 15)
	check(game.state.cash == 11000 and game.receivable_total() == 0, "第45日只回款105元一次")
	check(snapshot(game) == snapshot(loaded), "重载后的结算与随机结果一致")
	advance(loaded, 1)
	check(loaded.state.cash == 11000, "到期回款不能重复领取")
	var broken = snapshot(game)
	broken.cash += 1
	check(not game.valid_save(broken), "拒绝不守恒的资金档")
	broken = snapshot(game)
	broken.order = {"id": "missing", "serial": 1, "progress": 0}
	check(not game.valid_save(broken), "拒绝未知订单")
	broken = snapshot(game)
	broken.speed = 1.5
	check(not game.valid_save(broken), "拒绝非整数速度")
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string('{"version":1}')
	file.close()
	var before = snapshot(loaded)
	check(not loaded.load_game(save_path) and before == snapshot(loaded), "旧版存档不误迁移或覆盖当前状态")
	DirAccess.remove_absolute(save_path)
	accounting(game)

	var normal = fixed_staff()
	normal.state.orderSerial = 1
	normal.state.receivables.append({"serial": 1, "name": "已交付合同", "amount": 6000, "due": 60})
	check(normal.forecast()[0].balance == 3200, "固定10人：40+60-60工资-8运营=32元")
	finance_days(normal, 60)
	check(normal.state.cash == 3200 and normal.state.arrears == 0, "同日先到账再支付6800分账单")
	check(normal.state.weeks[0].wages == 6000 and normal.state.weeks[0].operations == 800, "工资和地区费用可独立复算")
	accounting(normal)

	var delayed = fixed_staff()
	delayed.state.orderSerial = 1
	delayed.state.receivables.append({"serial": 1, "name": "延迟合同", "amount": 6000, "due": 75})
	finance_days(delayed, 60)
	check(delayed.state.arrears == 2800 and delayed.state.rescueUntil == 180, "延期产生28元缺口与固定两周救援期")
	finance_days(delayed, 15)
	check(delayed.state.cash == 3200 and delayed.state.arrears == 0 and delayed.state.rescueUntil == 0, "实际回款优先补齐欠款")
	accounting(delayed)

	var overgrown = fixed_staff()
	overgrown.state.area.eastAsia.count = 30.0
	finance_days(overgrown, 60)
	check(overgrown.state.arrears == 14800, "过度扩张：30人工资180元加8元运营，缺148元")
	var deadline = overgrown.state.rescueUntil
	finance_days(overgrown, 30)
	overgrown.receive(100, "部分回款")
	finance_days(overgrown, 30)
	check(overgrown.state.rescueUntil == deadline, "部分回款与再次欠款不刷新救援期限")
	finance_days(overgrown, 60)
	check(not overgrown.state.outcome.is_empty() and not overgrown.state.outcome.win, "两周后未补齐欠款进入失败结算")
	accounting(overgrown)

	var market = fixed_staff()
	market.state.tools = {"desk": true, "workflow": true}
	market.state.autoOrders = true
	market.state.marketUsed = market.market_capacity()
	market.tick()
	check(market.state.order.is_empty() and market.state.cashIn == 0, "无市场需求不能自动凭空赚钱")
	market.state.marketUsed = 0
	market.spend(int(market.state.cash), "测试支出")
	market.tick()
	check(not market.state.order.is_empty(), "无启动费的短单不被资金储备规则锁死")
	var hires = market.headcount()
	market.toggle_recruiting()
	advance(market, 10)
	check(market.headcount() > hires, "主动开启招聘后接回原地图增长")
	market.toggle_recruiting()
	var stopped = market.headcount()
	advance(market, 10)
	check(market.headcount() <= stopped, "关闭新增招聘仍保留流失与工资")

	# 回归：偏好90工作量企业单，但只剩30额度时，应补接12工作量短单。
	var fallback = fixed_staff()
	fallback.receive(1000000, "测试资金")
	fallback.state.tools = {"desk": true, "workflow": true}
	fallback.state.autoOrders = true
	fallback.state.preference = "enterprise"
	fallback.state.marketUsed = fallback.market_capacity() - 30
	check(fallback.order_available("quick", true) and not fallback.order_available("enterprise", true), "剩30额度时短单可接、大单不可接")
	fallback.accept_automatic()
	check(not fallback.state.order.is_empty() and fallback.state.order.id == "quick", "大单额度不足时自动补接小单")
	var receipts_before = fallback.state.cashIn
	finance_days(fallback, 5)
	check(fallback.state.completed == 2 and fallback.state.cashIn - receipts_before == 6000, "30额度应完成两笔短单并到账60元")
	check(fallback.state.marketUsed == fallback.market_capacity() - 6 and fallback.state.order.is_empty(), "余6额度时应停止，不超额生成订单")
	finance_days(fallback, 55)
	check(fallback.state.marketUsed == 0, "财务周结束应刷新需求额度")
	finance_days(fallback, 1)
	check(not fallback.state.order.is_empty() and fallback.state.order.id == "enterprise", "额度刷新后恢复优先接企业单")
	check(fallback.state.preference == "enterprise", "补接小单不应改写玩家偏好")
	accounting(fallback)
	var cash_fallback = fixed_staff()
	cash_fallback.state.tools = {"desk": true, "workflow": true}
	cash_fallback.state.autoOrders = true
	cash_fallback.state.preference = "enterprise"
	cash_fallback.spend(int(cash_fallback.state.cash), "测试资金耗尽")
	cash_fallback.accept_automatic()
	check(not cash_fallback.state.order.is_empty() and cash_fallback.state.order.id == "quick", "资金需留工资时补接零启动费短单，避免自动接单锁死")

	var winner = play(false)
	check(not winner.state.outcome.is_empty() and winner.state.outcome.win, "经营与招聘合流后的稳健路线应能全球入职")
	check(winner.headcount() == winner.total_population and winner.state.arrears == 0, "胜利须全员入职且无欠款")
	win_day = winner.state.day
	accounting(winner)
	var loser = play(true)
	check(not loser.state.outcome.is_empty() and not loser.state.outcome.win, "高压路线仍能触发失败")
	accounting(loser)
	winner.reset()
	check(not winner.state.started and winner.headcount() == 0 and winner.state.cash == 4000 and winner.state.tools.is_empty() and winner.state.receivables.is_empty(), "重开恢复完整OPC初态")

	# 使用真实场景验证面板暂停和快进循环；此项不代替系统鼠标/键盘证据。
	var ui = load("res://main.tscn").instantiate()
	root.add_child(ui)
	ui.restart()
	ui.begin("westEU")
	ui.game.accept_order("quick")
	ui.game.toggle_work()
	ui.change_view("finance")
	ui._process(120.0)
	check(ui.game.state.day == 0 and ui.game.state.order.progress == 0, "财务阅读面板冻结时间与工作")
	ui.change_view("board")
	ui._process(1.0)
	check(ui.game.state.day == 1 and ui.game.state.order.progress == 1, "关闭财务面板恢复原运行状态")
	ui.game.state.paused = true
	check(ui.game.deliver() == false and ui.game.can_act(), "暂停可安排经营动作，工作进度仍停止")
	ui.change_view("finance")
	ui.change_view("board")
	ui._process(10.0)
	check(ui.game.state.day == 1 and ui.game.state.paused, "原本已暂停时不被财务面板恢复为运行")
	ui.game.state.paused = false
	ui.game.state.speed = 4
	ui._process(20.0)
	check(ui.game.state.day == 81 and ui.game.state.weeks.size() == 1, "4倍跨过周结时点不漏账")
	ui.game.receive(20000, "测试资本")
	ui.game.hire_first()
	ui.game.state.day = 209
	ui._process(2.0)
	check(ui.game.state.day == 210 and ui.game.state.eventOpen and ui.accumulator == 0, "快进遇既有事件即停，不继续跨日")
	ui.game.choose(0)
	ui.game = fixed_staff()
	ui.game.state.tools = {"desk": true, "workflow": true}
	ui.game.state.autoOrders = true
	ui.game.state.preference = "enterprise"
	ui.game.state.marketUsed = ui.game.market_capacity() - 6
	ui.game.state.day = 59
	ui.refresh()
	check("刷新" in ui.order_status.text and "1日后" in ui.order_status.text, "所有订单额度不足时界面须明确等待原因与刷新时间")
	check(ui.order_buttons.quick.disabled and "额度" in ui.order_buttons.quick.tooltip_text, "禁用的订单按钮应说明额度不足")
	ui.restart()
	ui.free()

	var report = {"status": "PASS" if failures.is_empty() else "FAIL", "failures": failures,
		"stableRouteDay": win_day, "recklessRouteDay": loser.state.day, "firstHireDay": hire_day, "automationDay": automation_day,
		"engine": Engine.get_version_info().string, "runtime": "Godot Windows headless",
		"suites": ["OPC接单/工具/首雇/自动化与招聘", "订单偏好回退、额度耗尽/周刷新、资金不足与等待提示", "现金守恒、同日回款、工资与三周预估", "普通/延期/过度扩张、固定救援期限", "暂停/快进/事件/财务面板", "订单/应收/随机存档、防重复与坏档保护", "全地图胜负与重开"],
		"scope": "机制与场景逻辑；真实画面和系统输入须由原生窗口证据补充"}
	var output = FileAccess.open("res://../qa/evidence/mechanisms.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func fixed_staff():
	var game = Simulation.new()
	game.start("eastAsia")
	game.state.firstHire = true
	game.state.area.eastAsia.count = 10.0
	return game

func play(reckless: bool):
	var game = Simulation.new()
	game.start("eastAsia")
	var route = ["coffee", "slogan", "referral", "headhunt", "remote", "campus"] if reckless else ["referral", "headhunt", "remote", "coffee", "flex", "local", "legal", "roundtable", "campus", "shares", "globalHR"]
	for i in range(3000):
		if not game.state.outcome.is_empty():
			break
		if game.state.eventOpen:
			game.choose(1 if reckless or game.state.resistance <= 45 else 0)
		if not game.tool_owned("desk"):
			game.buy_tool("desk")
		if not game.state.firstHire and game.state.cash >= game.content.economy.hireCost + game.next_bill() + 2000:
			game.hire_first()
			if not reckless:
				hire_day = game.state.day
		if game.state.firstHire and not game.tool_owned("workflow") and game.state.cash >= 12000 + game.next_bill() * 2:
			game.buy_tool("workflow")
			game.toggle_auto()
			if not reckless:
				automation_day = game.state.day
		if not game.state.recruiting and game.state.autoOrders and game.state.cash >= game.next_bill() * 3:
			game.toggle_recruiting()
		if not game.state.autoOrders:
			if game.state.order.is_empty():
				game.accept_order("quick")
			if not game.state.order.is_empty():
				if game.state.order.progress >= game.order_by_id(game.state.order.id).work:
					game.deliver()
				elif not game.state.working:
					game.toggle_work()
		if not game.state.bubble.is_empty():
			game.collect_bubble()
		if i % 10 == 0:
			for id in route:
				if not game.owned(id):
					game.purchase(id)
					break
		game.tick()
	return game
