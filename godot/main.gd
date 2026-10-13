extends Control
## 表现与交互入口。所有规则在 simulation.gd，所有内容在 data/content.json。

const Simulation = preload("res://simulation.gd")
const SAVE_PATH = "user://hiring-v1.json"
var game = Simulation.new()
var accumulator = 0.0
var active_tab = "spread"
var modal = ""
var hud: Label
var region_info: Label
var news: Label
var pause_button: Button
var speed_button: Button
var bubble_button: Button
var upgrade_list: VBoxContainer
var shade: ColorRect
var dialog: VBoxContainer
var region_buttons = {}
var save_blocked = false

func _ready():
	var app_theme = Theme.new()
	var font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "SimSun"])
	app_theme.default_font = font
	app_theme.default_font_size = 16
	for type in ["Label", "Button"]:
		app_theme.set_color("font_color", type, Color("243b35"))
	app_theme.set_color("font_disabled_color", "Button", Color("697b73"))
	app_theme.set_stylebox("normal", "Button", box("fff9e9"))
	app_theme.set_stylebox("hover", "Button", box("ffe18a"))
	app_theme.set_stylebox("pressed", "Button", box("bde5ce"))
	app_theme.set_stylebox("disabled", "Button", box("e6e8dc"))
	theme = app_theme
	label_at(self, "牛马公司", Vector2(32, 18), Vector2(320, 44), 32)
	label_at(self, "全球招聘计划  /  Godot 单人起步版 v0.1", Vector2(34, 65), Vector2(640, 26), 16)
	pause_button = button_at(self, "暂停 [空格]", Vector2(924, 32), Vector2(130, 44), toggle_pause)
	speed_button = button_at(self, "1×", Vector2(1066, 32), Vector2(64, 44), change_speed)
	button_at(self, "重开", Vector2(1142, 32), Vector2(104, 44), request_restart)
	hud = label_at(self, "", Vector2(52, 110), Vector2(1170, 45), 23)
	for region in game.content.regions:
		var point = map_point(region)
		var button = button_at(self, region.name, point - Vector2(48, 20), Vector2(96, 48), select_region.bind(region.id))
		button.add_theme_font_size_override("font_size", 14)
		region_buttons[region.id] = button
	region_info = label_at(self, "", Vector2(912, 198), Vector2(314, 144), 18)
	var tabs = [["招聘传播", "spread"], ["职场文化", "culture"], ["全球适应", "adapt"]]
	for i in range(tabs.size()):
		button_at(self, tabs[i][0], Vector2(908 + i * 109, 350), Vector2(101, 36), switch_tab.bind(tabs[i][1]))
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(908, 398)
	scroll.size = Vector2(320, 238)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	upgrade_list = VBoxContainer.new()
	upgrade_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_list.add_theme_constant_override("separation", 8)
	scroll.add_child(upgrade_list)
	bubble_button = button_at(self, "简历 +3 点", Vector2.ZERO, Vector2(124, 34), collect)
	bubble_button.add_theme_font_size_override("font_size", 15)
	bubble_button.add_theme_stylebox_override("normal", box("ffd66b"))
	news = label_at(self, "", Vector2(38, 666), Vector2(1200, 36), 15)
	shade = ColorRect.new()
	shade.color = Color(0.08, 0.15, 0.12, 0.7)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel = PanelContainer.new()
	panel.position = Vector2(330, 176)
	panel.size = Vector2(620, 368)
	panel.add_theme_stylebox_override("panel", box("fff9e9", 24))
	shade.add_child(panel)
	dialog = VBoxContainer.new()
	dialog.add_theme_constant_override("separation", 18)
	panel.add_child(dialog)
	if FileAccess.file_exists(SAVE_PATH) and not game.load_game(SAVE_PATH):
		save_blocked = true
		game.state.log = "存档无法读取，原文件已保留。确认重开后才会覆盖。"
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

func map_point(region: Dictionary) -> Vector2:
	var x = {"westNA": 108, "eastNA": 240, "westEU": 431, "eastEU": 567}.get(region.id, region.x)
	return Vector2(40 + x * 0.82, 196 + region.y * 0.73)

func _draw():
	draw_style_box(box("eadfbf"), Rect2(32, 100, 1214, 68))
	draw_style_box(box("dfede2"), Rect2(32, 182, 846, 472))
	draw_style_box(box("fff9e9"), Rect2(894, 182, 352, 472))
	# 沿用 HTML 抽象大陆轮廓，全部使用原生 2D 图形。
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
	if modal != "" or not game.state.started or game.state.paused or game.state.eventOpen or not game.state.outcome.is_empty():
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
		if game.state.day % 10 == 0 or game.state.eventOpen or not game.state.outcome.is_empty():
			persist()
		refresh()

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE and modal == "":
		toggle_pause()
		get_viewport().set_input_as_handled()

func select_region(id: String):
	game.state.selected = id
	refresh()

func begin(id: String):
	game.start(id)
	accumulator = 0.0
	persist()
	refresh()

func buy(id: String):
	if game.purchase(id):
		persist()
	refresh()

func collect():
	game.collect_bubble()
	persist()
	refresh()

func switch_tab(tab: String):
	active_tab = tab
	refresh()

func toggle_pause():
	if not game.state.started or not game.state.outcome.is_empty() or game.state.eventOpen:
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
	hud.text = "全球入职  %.1f%%     招聘点  %d     曝光  %d%%     反制  %d%%     第 %d 天" % [game.headcount()/game.total_population*100, state.points, state.awareness, state.resistance, state.day]
	pause_button.text = "继续 [空格]" if state.paused else "暂停 [空格]"
	pause_button.disabled = not state.started or state.eventOpen or not state.outcome.is_empty()
	speed_button.text = "%d×" % state.speed
	var selected = game.region_by_id(state.selected)
	var count = state.area[state.selected].count
	region_info.text = "%s · %s\n入职：%d / %d（%d%%）\n招聘网络：%d / 12 地区\n%s" % [selected.name, selected.trait, count, selected.pop, count/selected.pop*100, game.covered(), "升级传播能力，让网络抵达这里。" if count == 0 else "待遇与合规影响留存和世界反制。"]
	for region in game.content.regions:
		var button = region_buttons[region.id]
		var area = state.area[region.id]
		button.text = "%s\n%s" % [region.name, "%d%%" % (area.count/region.pop*100) if area.count > 0 else "等待简历"]
		button.add_theme_stylebox_override("normal", box("ffd66b" if state.selected == region.id else ("bde5ce" if area.count > 0 else "fff9e9")))
	bubble_button.visible = not state.bubble.is_empty() and state.outcome.is_empty()
	if bubble_button.visible:
		bubble_button.position = map_point(game.region_by_id(state.bubble)) + Vector2(-25, -65)
	news.text = state.log
	for node in upgrade_list.get_children():
		upgrade_list.remove_child(node)
		node.queue_free()
	for card in game.content.cards:
		if card.tab != active_tab:
			continue
		var button = Button.new()
		var locked = card.has("req") and not game.owned(card.req)
		button.text = "%s  ·  %s" % [card.name, "已启用" if game.owned(card.id) else "%d 点" % card.cost]
		button.tooltip_text = card.desc + ("\n前置：%s" % card.req if locked else "")
		button.disabled = not state.started or game.owned(card.id) or locked or state.points < card.cost or not state.outcome.is_empty()
		button.pressed.connect(buy.bind(card.id))
		button.custom_minimum_size.y = 43
		upgrade_list.add_child(button)
	refresh_dialog()
	queue_redraw()

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
		dialog_label("当前进度会被新局覆盖。", 18)
		dialog_button("重新开局", restart)
		dialog_button("继续当前局", func(): modal = ""; refresh())
	elif not state.started:
		modal = "start"
		dialog_label("把地球变成一家公司的通讯录。", 25)
		dialog_label("选择起点 → 收简历、买升级 → 应对事件\n反制到 100% 就失败；全球全员入职即胜利。\n本版验证招聘玩法，经营与方针尚未接入。", 16)
		for id in ["eastAsia", "westEU", "westNA"]:
			dialog_button("从%s开始" % game.region_by_id(id).name, begin.bind(id))
	elif not state.outcome.is_empty():
		modal = "result"
		dialog_label("全球人人入职！" if state.outcome.win else "工牌计划中止", 28)
		dialog_label("第 %d 天 · 入职 %d / %d\n%s" % [state.day, game.headcount(), game.total_population, state.outcome.body], 18)
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
