extends Control
## 界面只读取模拟状态、发送动作；所有金额与时间由 simulation.gd 维护。
const Simulation = preload("res://simulation.gd")
const SAVE_PATH = "user://hiring-v2.json"
var game = Simulation.new()
var accumulator = 0.0
var active_tab = "spread"
var view = "board"
var modal = ""
var hud: Label
var finance_hud: Label
var region_info: Label
var news: Label
var pause_button: Button
var speed_button: Button
var bubble_button: Button
var upgrade_buttons = {}
var shade: ColorRect
var dialog: VBoxContainer
var region_buttons = {}
var order_buttons = {}
var tool_buttons = {}
var nav_buttons = {}
var world: Control
var board: Control
var finance: Control
var board_status: Label
var order_status: Label
var progress: ProgressBar
var work_button: Button
var deliver_button: Button
var hire_button: Button
var auto_button: Button
var recruit_button: Button
var preference_button: Button
var team_info: Label
var finance_report: Label
var finance_summary: Label
var ledger: Label
var save_blocked = false
var legacy_save = false

func _ready():
	var app_theme = Theme.new()
	var font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "SimSun"])
	app_theme.default_font = font
	app_theme.default_font_size = 16
	for type in ["Label", "Button"]:
		app_theme.set_color("font_color", type, Color("243b35"))
	app_theme.set_color("font_disabled_color", "Button", Color("697b73"))
	for pair in [["normal", "fff9e9"], ["hover", "ffe18a"], ["pressed", "bde5ce"], ["disabled", "e6e8dc"]]:
		app_theme.set_stylebox(pair[0], "Button", box(pair[1]))
	theme = app_theme
	label_at(self, "牛马公司", Vector2(32, 16), Vector2(320, 42), 30)
	label_at(self, "全球招聘计划 / OPC 与现金流原型 v0.2.1", Vector2(34, 65), Vector2(760, 26), 16)
	for i in range(3):
		var id = ["board", "world", "finance"][i]
		nav_buttons[id] = button_at(self, ["订单看板", "世界地图", "现金流"][i], Vector2(570 + i * 110, 28), Vector2(102, 44), change_view.bind(id))
	pause_button = button_at(self, "暂停 [空格]", Vector2(924, 28), Vector2(130, 44), toggle_pause)
	speed_button = button_at(self, "1×", Vector2(1066, 28), Vector2(64, 44), change_speed)
	button_at(self, "重开", Vector2(1142, 28), Vector2(104, 44), request_restart)
	hud = label_at(self, "", Vector2(50, 109), Vector2(1170, 32), 21)
	finance_hud = label_at(self, "", Vector2(50, 148), Vector2(1170, 30), 16)
	make_board()
	make_world()
	make_finance()
	news = label_at(self, "", Vector2(38, 667), Vector2(1200, 40), 15)
	shade = ColorRect.new()
	shade.color = Color(0.08, 0.15, 0.12, 0.7)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel = PanelContainer.new()
	panel.position = Vector2(300, 142)
	panel.size = Vector2(680, 420)
	panel.add_theme_stylebox_override("panel", box("fff9e9", 24))
	shade.add_child(panel)
	dialog = VBoxContainer.new()
	dialog.add_theme_constant_override("separation", 16)
	panel.add_child(dialog)
	if FileAccess.file_exists(SAVE_PATH) and not game.load_game(SAVE_PATH):
		save_blocked = true
		game.state.log = "新版本存档无法读取，原文件已保留。确认重开后才会覆盖。"
	legacy_save = not FileAccess.file_exists(SAVE_PATH) and FileAccess.file_exists("user://hiring-v1.json")
	refresh()

func box(color: String, padding: int = 8) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(color)
	style.border_color = Color("436b5c")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

func label_at(parent: Node, text: String, pos: Vector2, dimensions: Vector2, font_size: int) -> Label:
	var label = Label.new()
	label.text = text
	label.position = pos
	label.size = dimensions
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func button_at(parent: Node, text: String, pos: Vector2, dimensions: Vector2, action: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.position = pos
	button.size = dimensions
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func make_board():
	board = Control.new()
	add_child(board)
	label_at(board, "创业接单", Vector2(50, 206), Vector2(300, 36), 26)
	board_status = label_at(board, "", Vector2(50, 246), Vector2(790, 30), 15)
	for i in range(game.content.orders.size()):
		var order = game.content.orders[i]
		var y = 285 + i * 76
		label_at(board, order.name, Vector2(54, y), Vector2(390, 30), 20)
		label_at(board, "%s · 工作量%d · 启动%s · 报酬%s" % [order.desc, order.work, game.money(order.fee), game.money(order.reward)], Vector2(54, y + 34), Vector2(620, 28), 14)
		order_buttons[order.id] = button_at(board, "接下这单", Vector2(696, y + 4), Vector2(150, 50), act.bind(game.accept_order.bind(order.id)))
	order_status = label_at(board, "", Vector2(50, 522), Vector2(795, 32), 18)
	progress = ProgressBar.new()
	progress.position = Vector2(50, 562)
	progress.size = Vector2(795, 22)
	board.add_child(progress)
	work_button = button_at(board, "自己开工", Vector2(50, 598), Vector2(230, 40), act.bind(game.toggle_work))
	deliver_button = button_at(board, "交付收款", Vector2(296, 598), Vector2(230, 40), act.bind(game.deliver))
	label_at(board, "公司与工具", Vector2(914, 206), Vector2(304, 36), 25)
	team_info = label_at(board, "", Vector2(914, 248), Vector2(304, 54), 15)
	for i in range(game.content.tools.size()):
		var tool = game.content.tools[i]
		var button = button_at(board, tool.name, Vector2(914, 312 + i * 56), Vector2(304, 44), act.bind(game.buy_tool.bind(tool.id)))
		button.tooltip_text = tool.desc
		tool_buttons[tool.id] = button
	hire_button = button_at(board, "", Vector2(914, 432), Vector2(304, 44), act.bind(game.hire_first))
	auto_button = button_at(board, "", Vector2(914, 488), Vector2(304, 44), act.bind(game.toggle_auto))
	recruit_button = button_at(board, "", Vector2(914, 544), Vector2(304, 44), act.bind(game.toggle_recruiting))
	preference_button = button_at(board, "", Vector2(914, 600), Vector2(304, 40), act.bind(game.change_preference))

func make_world():
	world = Control.new()
	add_child(world)
	for region in game.content.regions:
		var point = map_point(region)
		var button = button_at(world, region.name, point - Vector2(48, 20), Vector2(96, 48), select_region.bind(region.id))
		button.add_theme_font_size_override("font_size", 14)
		region_buttons[region.id] = button
	region_info = label_at(world, "", Vector2(912, 206), Vector2(314, 136), 18)
	var tabs = [["招聘传播", "spread"], ["职场文化", "culture"], ["全球适应", "adapt"]]
	for i in range(tabs.size()):
		button_at(world, tabs[i][0], Vector2(908 + i * 109, 350), Vector2(101, 36), switch_tab.bind(tabs[i][1]))
	for card in game.content.cards:
		var index = 0
		for other in game.content.cards:
			if other.id == card.id:
				break
			if other.tab == card.tab:
				index += 1
		var button = button_at(world, card.name, Vector2(908, 400 + index * 55), Vector2(320, 46), act.bind(game.purchase.bind(card.id)))
		button.tooltip_text = card.desc
		upgrade_buttons[card.id] = button
	bubble_button = button_at(world, "简历 +3 点", Vector2.ZERO, Vector2(124, 34), act.bind(game.collect_bubble))
	bubble_button.add_theme_font_size_override("font_size", 15)
	bubble_button.add_theme_stylebox_override("normal", box("ffd66b"))

func make_finance():
	finance = Control.new()
	add_child(finance)
	label_at(finance, "现金流 · 阅读时自动暂停", Vector2(50, 206), Vector2(780, 40), 26)
	label_at(finance, "三周预估：固定当前人数，只算已交付应收与预计费用；未来新单不计入。", Vector2(50, 256), Vector2(790, 48), 15)
	finance_report = label_at(finance, "", Vector2(50, 310), Vector2(790, 130), 19)
	label_at(finance, "最近账目", Vector2(50, 448), Vector2(790, 30), 21)
	ledger = label_at(finance, "", Vector2(50, 486), Vector2(790, 164), 14)
	label_at(finance, "工资与储备", Vector2(914, 206), Vector2(304, 36), 25)
	finance_summary = label_at(finance, "", Vector2(914, 258), Vector2(304, 380), 17)

func map_point(region: Dictionary) -> Vector2:
	var x = {"westNA": 108, "eastNA": 240, "westEU": 431, "eastEU": 567}.get(region.id, region.x)
	return Vector2(40 + x * 0.82, 196 + region.y * 0.73)

func _draw():
	draw_style_box(box("eadfbf"), Rect2(32, 100, 1214, 84))
	draw_style_box(box("dfede2"), Rect2(32, 194, 846, 460))
	draw_style_box(box("fff9e9"), Rect2(894, 194, 352, 460))
	if view != "world":
		return
	var continents = [
		[50,150,97,100,162,91,224,115,266,154,245,203,219,211,189,253,148,256,123,298,84,266,88,217,54,204],
		[213,302,272,311,308,349,301,401,278,447,251,510,224,467,211,414,188,366],
		[394,121,462,95,505,112,551,91,606,104,657,87,715,107,776,107,835,126,909,148,915,198,867,232,830,213,790,243,744,229,709,258,659,237,618,258,568,229,534,244,495,218,450,232,421,206,391,182],
		[428,263,512,257,566,303,572,362,543,402,521,467,478,459,441,414,410,344],
		[777,407,845,395,903,423,920,460,883,493,817,481,771,452]]
	for shape in continents:
		var polygon = PackedVector2Array()
		for i in range(0, shape.size(), 2):
			polygon.append(Vector2(40 + shape[i] * 0.82, 196 + shape[i+1] * 0.73))
		draw_colored_polygon(polygon, Color("c5d9b6"))
		polygon.append(polygon[0])
		draw_polyline(polygon, Color("96b59a"), 1.5, true)
	for region in game.content.regions:
		for id in region.links:
			if region.id > id:
				continue
			var active = game.state.area[region.id].count > 0 and game.state.area[id].count > 0
			draw_line(map_point(region), map_point(game.region_by_id(id)), Color("537f63") if active else Color("a9c4ad"), 2.5 if active else 1, true)

func _process(delta: float):
	if modal != "" or view == "finance" or game.state.paused or not game.can_act():
		return
	accumulator += delta * game.state.speed
	var changed = false
	while accumulator >= 1.0:
		accumulator -= 1.0
		game.tick()
		changed = true
		if game.state.eventOpen or not game.state.outcome.is_empty():
			accumulator = 0.0
			break
	if changed:
		if int(game.state.day) % 10 == 0 or game.state.eventOpen or not game.state.outcome.is_empty():
			persist()
		refresh()

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE and modal == "" and view != "finance":
		toggle_pause()
		get_viewport().set_input_as_handled()

func act(action: Callable):
	if modal != "" or view == "finance":
		return
	action.call()
	persist()
	refresh()

func select_region(id: String):
	game.state.selected = id
	refresh()

func begin(id: String):
	game.start(id)
	accumulator = 0.0
	view = "board"
	persist()
	refresh()

func switch_tab(tab: String):
	active_tab = tab
	refresh()

func change_view(id: String):
	view = id
	refresh()

func toggle_pause():
	if not game.running() or game.state.eventOpen or view == "finance":
		return
	game.state.paused = not game.state.paused
	persist()
	refresh()

func change_speed():
	game.state.speed = {1: 2, 2: 4, 4: 1}[int(game.state.speed)]
	persist()
	refresh()

func request_restart():
	modal = "confirm"
	refresh()

func restart():
	save_blocked = false
	game.reset()
	modal = ""
	view = "board"
	accumulator = 0.0
	persist()
	refresh()

func choose_event(index: int):
	game.choose(index)
	persist()
	refresh()

func persist():
	if save_blocked:
		return
	var error = game.save_game(SAVE_PATH)
	if error != OK:
		game.state.log = "保存失败（%s），请检查存储空间；当前对局仍可继续。" % error_string(error)

func _notification(what: int):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		persist()
		get_tree().quit()

func refresh():
	var state = game.state
	hud.text = "现金 %s    应收 %s    下次账单 %s（%d日后）    第%d财务周 / 第%d日" % [game.money(state.cash), game.money(game.receivable_total()), game.money(game.next_bill()), game.days_to_bill(), int(state.day) / 60 + 1, state.day]
	finance_hud.text = "雇员 %.1f    招聘点 %d    全球入职 %.1f%%    曝光%d%% / 反制%d%%    %s" % [game.headcount(), state.points, game.headcount()/game.total_population*100, state.awareness, state.resistance, risk_text()]
	finance_hud.add_theme_color_override("font_color", Color("a3422e") if state.arrears > 0 or state.cash < game.next_bill() else Color("243b35"))
	pause_button.text = "阅读中暂停" if view == "finance" else ("继续 [空格]" if state.paused else "暂停 [空格]")
	pause_button.disabled = not game.running() or state.eventOpen or view == "finance"
	speed_button.text = "%d×" % state.speed
	for id in nav_buttons:
		nav_buttons[id].add_theme_stylebox_override("normal", box("ffd66b" if view == id else "fff9e9"))
	world.visible = view == "world"
	board.visible = view == "board"
	finance.visible = view == "finance"
	refresh_board()
	refresh_world()
	refresh_finance()
	news.text = state.log
	refresh_dialog()
	queue_redraw()

func risk_text() -> String:
	if game.state.arrears > 0:
		return "欠款%s · 救援剩%d日" % [game.money(game.state.arrears), maxi(0, game.state.rescueUntil - game.state.day)]
	return "工资储备不足：可接短单或暂停招聘" if game.state.cash < game.next_bill() else "当前现金可覆盖下一次账单"

func refresh_board():
	var state = game.state
	board_status.text = "本周剩余 %d / %d 工作量 · %d日后刷新 · 订单按市场需求供应" % [maxi(0, game.market_capacity() - state.marketUsed), game.market_capacity(), game.days_to_bill()]
	for order in game.content.orders:
		var button = order_buttons[order.id]
		button.disabled = not game.can_act() or not game.order_available(order.id)
		var reason = game.order_block_reason(order.id)
		button.text = "需要工作台" if "工作台" in reason else ("额度不足" if "额度" in reason else ("现金不足" if "现金不足" in reason else "接下这单"))
		button.tooltip_text = reason if not reason.is_empty() else "市场需求每财务周刷新；已接单执行中时不能重复接单。"
	var has_order = not state.order.is_empty()
	progress.max_value = game.order_by_id(state.order.id).work if has_order else 1.0
	progress.value = state.order.progress if has_order else 0.0
	order_status.text = "%s · %.1f / %d 工作量" % [game.order_by_id(state.order.id).name, state.order.progress, progress.max_value] if has_order else game.automatic_status()
	work_button.text = "暂停手头工作" if state.working else "自己开工"
	work_button.disabled = not game.can_act() or not has_order or progress.value >= progress.max_value
	deliver_button.disabled = not game.can_act() or not has_order or progress.value < progress.max_value
	deliver_button.text = "交付待回款" if has_order and game.order_by_id(state.order.id).delay > 0 else "交付收款"
	team_info.text = "创始人 1 · 雇员 %.1f\n周薪 %s/人 · 基础费 %s/周" % [game.headcount(), game.money(game.content.economy.weeklyWage), game.money(game.content.economy.baseCost)]
	for tool in game.content.tools:
		var button = tool_buttons[tool.id]
		button.text = "%s · %s" % [tool.name, "已启用" if game.tool_owned(tool.id) else game.money(tool.cost)]
		button.disabled = not game.can_act() or game.tool_owned(tool.id) or state.cash < tool.cost or (tool.has("req") and not game.tool_owned(tool.req))
	hire_button.text = "首位员工已入职" if state.firstHire else "首雇准备 · %s" % game.money(game.content.economy.hireCost)
	hire_button.disabled = not game.can_act() or state.firstHire or state.cash < game.content.economy.hireCost
	hire_button.tooltip_text = "支付一次入职准备费，新增员工开始计薪并自动执行订单。"
	auto_button.text = "自动接单：开" if state.autoOrders else "自动接单：关"
	auto_button.disabled = not game.can_act() or not state.firstHire or not game.tool_owned("workflow")
	auto_button.tooltip_text = "需要首位员工与接单流程；收费订单会预留下一次账单。"
	recruit_button.text = "地图招聘：开" if state.recruiting else "地图招聘：关"
	recruit_button.disabled = not game.can_act() or not state.firstHire
	preference_button.text = "接单偏好：%s" % game.order_by_id(state.preference).name
	preference_button.tooltip_text = "优先接此类订单；额度或资金不足时补接更小订单，不改变偏好。"
	preference_button.disabled = not game.can_act() or not game.tool_owned("workflow")

func refresh_world():
	var state = game.state
	var selected = game.region_by_id(state.selected)
	var count = state.area[state.selected].count
	region_info.text = "%s · %s\n入职：%.1f / %d（%d%%）\n网络：%d / 12 · %s\n%s" % [selected.name, selected.trait, count, selected.pop, count/selected.pop*100, game.covered(), "招聘中" if state.recruiting else "招聘已暂停", "先回看板完成首雇。" if not state.firstHire else "新增员工会增加工资，也会带来业务产能。"]
	for region in game.content.regions:
		var area = state.area[region.id]
		var button = region_buttons[region.id]
		button.text = "%s\n%s" % [region.name, "%d%%" % (area.count/region.pop*100) if area.count > 0 else "等待简历"]
		button.add_theme_stylebox_override("normal", box("ffd66b" if state.selected == region.id else ("bde5ce" if area.count > 0 else "fff9e9")))
	bubble_button.visible = not state.bubble.is_empty() and state.outcome.is_empty()
	if bubble_button.visible:
		bubble_button.position = map_point(game.region_by_id(state.bubble)) + Vector2(-25, -65)
	for card in game.content.cards:
		var button = upgrade_buttons[card.id]
		var locked = card.has("req") and not game.owned(card.req)
		button.visible = card.tab == active_tab
		button.text = "%s · %s" % [card.name, "已启用" if game.owned(card.id) else "%d 点" % card.cost]
		button.disabled = not state.started or game.owned(card.id) or locked or state.points < card.cost or not state.outcome.is_empty()

func refresh_finance():
	var state = game.state
	finance_report.text = "到期日          已知回款          预计账单          期末现金 / 缺口\n"
	for row in game.forecast():
		finance_report.text += "第%d日       %s       %s       %s\n" % [row.due, game.money(row.receipts), game.money(row.bill), game.money(row.balance)]
	ledger.text = ""
	for i in range(maxi(0, state.ledger.size() - 7), state.ledger.size()):
		var entry = state.ledger[i]
		ledger.text += "第%d日  %s%s  %s  → 余额%s\n" % [entry.day, "+" if entry.amount > 0 else "", game.money(entry.amount), entry.label, game.money(entry.balance)]
	finance_summary.text = "现金：%s\n应收：%s\n欠款：%s\n\n下次账单：%s\n距结算：%d模拟日\n本周在岗累计：%.1f人日\n\n%s\n\n订单先回款，再付同日账单。\n工资按在岗时间累计。\n暂停新增招聘仍需支付工资。\n关闭此页恢复原暂停状态。" % [game.money(state.cash), game.money(game.receivable_total()), game.money(state.arrears), game.money(game.next_bill()), game.days_to_bill(), state.payrollUnits, risk_text()]

func refresh_dialog():
	var state = game.state
	shade.visible = modal == "confirm" or not state.started or state.eventOpen or not state.outcome.is_empty()
	if not shade.visible:
		modal = ""
		return
	for node in dialog.get_children():
		dialog.remove_child(node)
		node.queue_free()
	if modal == "confirm":
		dialog_label("重新创业？", 28)
		dialog_label("本次现金、订单、员工与升级将被新局覆盖。", 18)
		dialog_button("重新开局", restart)
		dialog_button("继续当前局", func(): modal = ""; refresh())
	elif not state.started:
		modal = "start"
		dialog_label("公司现在就你一个人。", 28)
		dialog_label("选起点 → 接单、开工、交付 → 升级工具 → 雇人自动化\n开启地图招聘后，沿路线扩张，给地球人人发工牌。\n反制100%或欠款两周未补齐会失败；现金流面板自动暂停。", 16)
		if legacy_save or save_blocked:
			dialog_label("旧版招聘存档保留；本版使用独立经济存档。" if legacy_save else "原存档读取失败并已保留；确认新局后覆盖。", 14)
		for id in ["eastAsia", "westEU", "westNA"]:
			dialog_button("从%s创业 · 初始%s" % [game.region_by_id(id).name, game.money(game.content.economy.company.initialCash)], begin.bind(id))
	elif not state.outcome.is_empty():
		modal = "result"
		dialog_label("全球人人入职！" if state.outcome.win else "工牌计划中止", 28)
		dialog_label("第%d日 · 入职%d / %d · 交付%d单\n现金%s · 欠款%s\n%s" % [state.day, game.headcount(), game.total_population, state.completed, game.money(state.cash), game.money(state.arrears), state.outcome.body], 18)
		dialog_button("重新创业", restart)
	else:
		modal = "event"
		var event = game.content.events[state.eventIndex]
		dialog_label(event.title, 25)
		dialog_label(event.body, 18)
		for i in range(event.choices.size()):
			var choice = event.choices[i]
			dialog_button("%s\n%s" % [choice.name, choice.detail], choose_event.bind(i))

func dialog_label(text: String, font_size: int):
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	dialog.add_child(label)

func dialog_button(text: String, action: Callable):
	var button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	button.pressed.connect(action)
	dialog.add_child(button)
