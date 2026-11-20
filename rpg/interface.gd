extends Control

const INK := Color("#091722")
const NIGHT := Color("#122734")
const STEEL := Color("#3b5664")
const MIST := Color("#a9bdc2")
const BONE := Color("#e4ede6")
const CYAN := Color("#57e4ce")
const AMBER := Color("#ffc46b")
const ROSE := Color("#f68b9b")

var game
var objective: Label
var status: Label
var context: Label
var notice: Label
var boss: Label
var dodge: Label
var division: Label
var integrity: ProgressBar
var dodge_meter: ProgressBar
var boss_meter: ProgressBar
var context_panel: PanelContainer
var notice_panel: PanelContainer
var boss_panel: PanelContainer
var markers: Control
var overlay: Control
var controls: Array[Control]
var first_focus: Control
var last_screen := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "SimHei"])
	theme = Theme.new()
	theme.default_font = font
	theme.set_color("font_color", "Label", BONE)
	theme.set_color("font_color", "Button", BONE)
	theme.set_color("font_hover_color", "Button", BONE)
	theme.set_color("font_disabled_color", "Button", MIST.darkened(0.22))
	theme.set_stylebox("normal", "Button", surface(NIGHT, STEEL, Vector2(14, 8)))
	theme.set_stylebox("hover", "Button", surface(Color("#1a3542"), CYAN, Vector2(14, 8)))
	theme.set_stylebox("pressed", "Button", surface(Color("#26454b"), CYAN, Vector2(14, 8)))
	theme.set_stylebox("disabled", "Button", surface(INK, STEEL.darkened(0.28), Vector2(14, 8)))
	theme.set_stylebox("focus", "Button", surface(Color.TRANSPARENT, BONE, Vector2.ZERO, 2))
	theme.set_type_variation("Primary", "Button")
	theme.set_stylebox("normal", "Primary", surface(Color("#1a3d42"), CYAN, Vector2(14, 8)))
	theme.set_color("font_color", "Primary", BONE)
	theme.set_stylebox("slider", "HSlider", surface(INK, STEEL, Vector2(0, 4)))
	theme.set_stylebox("grabber_area", "HSlider", surface(Color("#30747a"), Color.TRANSPARENT, Vector2(0, 4), 0))
	theme.set_stylebox("grabber_area_highlight", "HSlider", surface(CYAN, Color.TRANSPARENT, Vector2(0, 4), 0))
	theme.set_icon("grabber", "HSlider", slider_thumb(MIST))
	theme.set_icon("grabber_highlight", "HSlider", slider_thumb(BONE))
	game.hud_changed.connect(update_hud)

func slider_thumb(color: Color) -> Texture2D:
	var pixels := Image.create(12, 16, false, Image.FORMAT_RGBA8)
	pixels.fill(color)
	pixels.fill_rect(Rect2i(5, 3, 2, 10), NIGHT)
	return ImageTexture.create_from_image(pixels)

func surface(color: Color, stroke: Color, pad := Vector2(14, 10), border := 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = stroke
	style.set_border_width_all(border)
	style.content_margin_left = pad.x
	style.content_margin_right = pad.x
	style.content_margin_top = pad.y
	style.content_margin_bottom = pad.y
	return style

func add_panel(parent: Control, bg := INK, line := STEEL, pad := Vector2(15, 11)) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", surface(bg, line, pad))
	parent.add_child(panel)
	return panel

func pinned(control: Control, anchor: Vector2, offset: Vector2, minimum := Vector2.ZERO) -> void:
	control.anchor_left = anchor.x
	control.anchor_right = anchor.x
	control.anchor_top = anchor.y
	control.anchor_bottom = anchor.y
	control.grow_horizontal = Control.GROW_DIRECTION_BEGIN if anchor.x == 1.0 else Control.GROW_DIRECTION_END
	control.grow_vertical = Control.GROW_DIRECTION_BEGIN if anchor.y == 1.0 else Control.GROW_DIRECTION_END
	control.custom_minimum_size = minimum
	control.offset_left = offset.x
	control.offset_top = offset.y
	control.offset_right = offset.x
	control.offset_bottom = offset.y

func column(parent: Control, spacing := 10) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", spacing)
	parent.add_child(box)
	return box

func row(parent: Control, spacing := 10) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", spacing)
	parent.add_child(box)
	return box

func text(parent: Control, copy: String, px: int, color := BONE, wrap := true) -> Label:
	var caption := Label.new()
	caption.text = copy
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.add_theme_font_size_override("font_size", roundi(px * game.text_scale))
	caption.add_theme_color_override("font_color", color)
	if wrap: caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(caption)
	return caption

func action(parent: Control, key: String, copy: String, callback: Callable, primary := false, disabled := false) -> Button:
	var control := Button.new()
	control.name = "Action_" + key
	control.text = copy
	control.custom_minimum_size.y = 48
	control.focus_mode = Control.FOCUS_ALL
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.add_theme_font_size_override("font_size", roundi(19 * game.text_scale))
	control.theme_type_variation = &"Primary" if primary else &""
	control.disabled = disabled
	control.pressed.connect(callback)
	parent.add_child(control)
	if not disabled:
		controls.append(control)
		if not is_instance_valid(first_focus): first_focus = control
	return control

func button_row(parent: Control) -> HBoxContainer:
	var box := row(parent, 12)
	box.alignment = BoxContainer.ALIGNMENT_END
	return box

func meter(parent: Control, color: Color, height := 6) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.show_percentage = false
	bar.custom_minimum_size.y = height
	bar.add_theme_stylebox_override("background", surface(NIGHT.lightened(0.08), Color.TRANSPARENT, Vector2.ZERO, 0))
	bar.add_theme_stylebox_override("fill", surface(color, Color.TRANSPARENT, Vector2.ZERO, 0))
	parent.add_child(bar)
	return bar

func layer() -> Control:
	var panel := Control.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return panel

func refresh() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	var keep := focused.name if is_instance_valid(focused) and last_screen == game.screen else &""
	last_screen = game.screen
	for child in get_children():
		remove_child(child)
		child.queue_free()
	controls.clear()
	first_focus = null
	if game.screen not in ["title", "settings"] or (game.screen == "settings" and game.settings_return == "paused"):
		hud()
	overlay = layer()
	match game.screen:
		"title": title()
		"settings": settings()
		"shop": shop()
		"paused": pause_menu()
		"choose", "exp_loadout": loadout()
		"log", "rewind", "transition", "failed", "complete", "confirm_new", "exp_complete": story()
	for i in controls.size():
		controls[i].focus_next = controls[(i + 1) % controls.size()].get_path()
		controls[i].focus_previous = controls[posmod(i - 1, controls.size())].get_path()
		if controls[i].name == keep: first_focus = controls[i]
	if is_instance_valid(first_focus): first_focus.grab_focus()
	update_hud()

func modal(title_copy: String, section: String, width := 880.0) -> VBoxContainer:
	var scrim := ColorRect.new()
	scrim.color = Color("#040c14c7")
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(scrim)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame := add_panel(center, INK, STEEL, Vector2(28, 22))
	frame.custom_minimum_size.x = width
	var content := column(frame, 14)
	var header := column(content, 3)
	if not section.is_empty(): text(header, section, 15, CYAN)
	text(header, title_copy, 32)
	var rule := ColorRect.new()
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.color = STEEL
	rule.custom_minimum_size.y = 1
	content.add_child(rule)
	return content

func title() -> void:
	var frame := add_panel(overlay, INK, STEEL, Vector2(46, 30))
	pinned(frame, Vector2.ZERO, Vector2.ZERO, Vector2(548, 720))
	var content := column(frame, 15)
	var header := column(content, 9)
	header.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var blank := Control.new()
	blank.custom_minimum_size.y = 41 if game.text_scale <= 1.5 else 14
	header.add_child(blank)
	text(header, "09   /   厂区检修记录", 17, CYAN)
	text(header, "夜班回路", mini(58, floori(98.0 / game.text_scale)), BONE, false)
	text(header, "停机后的第一通求救，来自厂里。", 20, MIST)
	var started: bool = game.saved_stage > 0
	var first_row := button_row(content)
	action(first_row, "investigate", "继续调查" if started else "开始调查", game.start, true)
	if started: action(first_row, "new_prologue", "重开序章", game.ask_new)
	action(content, "expedition", "开始首组远征" if game.saved_run.is_empty() else "继续首组远征", game.continue_expedition)
	action(content, "settings", "设置", game.open_settings)
	text(content, "Windows 试玩版   /   " + str(ProjectSettings.get_setting("application/config/version")), 15, MIST)

func hud() -> void:
	var panel := add_panel(self)
	pinned(panel, Vector2.ZERO, Vector2(24, 20), Vector2(508, 0))
	var left := column(panel, 2)
	division = text(left, "", 15, CYAN, false)
	objective = text(left, "", 19)
	var base := add_panel(self)
	pinned(base, Vector2.DOWN, Vector2(24, -20), Vector2(372, 0))
	var base_content := column(base, 5)
	status = text(base_content, "", 18)
	integrity = meter(base_content, CYAN, 5)
	var right := add_panel(self)
	pinned(right, Vector2.ONE, Vector2(-24, -20), Vector2(218, 0))
	var right_content := column(right, 5)
	dodge = text(right_content, "", 18)
	dodge_meter = meter(right_content, CYAN, 5)
	context_panel = add_panel(self, INK, CYAN)
	pinned(context_panel, Vector2(0.5, 1.0), Vector2(-209, -22), Vector2(418, 0))
	context_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	context = text(context_panel, "", 18, CYAN)
	context.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_panel = add_panel(self)
	pinned(notice_panel, Vector2.RIGHT, Vector2(-24, 20), Vector2(456, 0))
	notice = text(notice_panel, "", 18)
	boss_panel = add_panel(self, INK, STEEL, Vector2(13, 7))
	pinned(boss_panel, Vector2(0.5, 0), Vector2(-202, 107 + 68 * (game.text_scale - 1.0)), Vector2(404, 0))
	var boss_content := column(boss_panel, 5)
	boss = text(boss_content, "", 18)
	boss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_meter = meter(boss_content, ROSE, 5)
	markers = layer()
	for spec in [["武器铺", Vector2(340, 424), CYAN], ["脏器接驳", Vector2(640, 376), CYAN], ["出发口", Vector2(950, 424), AMBER]]:
		var sign := add_panel(markers, INK, STEEL, Vector2(10, 3))
		pinned(sign, Vector2.ZERO, spec[1] - Vector2(70, 0), Vector2(140, 0))
		text(sign, spec[0], 17, spec[2]).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func update_hud() -> void:
	if not is_instance_valid(objective): return
	var live: bool = game.screen == "play"
	markers.visible = game.campaign and game.room == "hub" and live
	division.text = "09  /  首组远征 · 接入 %d / 7" % int(game.integrated) if game.campaign else "09  /  调查迭代 %02d" % game.cycle
	objective.text = "耐久耗尽" if game.screen in ["dying", "failed"] else game.objective_text()
	var capacity: int = game.max_hp() if game.campaign else 5
	var combo := "  ·  连击 %d/3" % (game.combo_step + 1) if game.build_id == "arc" and game.combo_window > 0 and live else ""
	status.text = "耐久 %d/%d  ·  %s%s" % [game.hp, capacity, game.module_name(game.build_id), combo]
	integrity.value = 100.0 * game.hp / capacity
	dodge.text = "信号中断" if game.hp <= 0 else "闪避中" if game.dash_left > 0 else "闪避冷却  %.1f s" % (ceilf(game.dash_cooldown * 10.0) / 10.0) if game.dash_cooldown > 0 else "空格  闪避就绪"
	dodge_meter.value = 100.0 * (1.0 - clampf(game.dash_cooldown / game.DASH_COOLDOWN, 0.0, 1.0)) if game.hp > 0 else 0.0
	context.text = game.context_text() if live else ""
	if live and context.text.is_empty(): context.text = game.world.fixture_hint()
	context_panel.visible = not context.text.is_empty()
	notice.text = game.message
	notice_panel.visible = live and not notice.text.is_empty()
	boss.text = game.boss_text() if live else ""
	boss_panel.visible = not boss.text.is_empty()
	boss_meter.value = 100.0 * game.boss_hp / (32 if game.campaign else 24)

func pause_menu() -> void:
	var content := modal("暂停", "检修终端")
	text(content, "WASD 移动    E 交互    J / 左键 攻击    空格 闪避", 18, MIST)
	var quick := button_row(content)
	action(quick, "resume", "继续", game.resume, true)
	action(quick, "text_size", "字号 %d%%" % roundi(game.text_scale * 100), game.cycle_text)
	action(quick, "low_motion", "低动效 %s" % ("开" if game.reduced_motion else "关"), game.toggle_motion)
	var more := button_row(content)
	action(more, "settings", "音量与显示", game.open_settings)
	action(more, "title", "返回标题", game.go_title)
	if game.campaign: action(more, "restart", "重新远征", game.begin_expedition)

func settings() -> void:
	var content := modal("音量与显示", "", 1010)
	var sections := row(content, 16)
	var audio_panel := add_panel(sections, NIGHT)
	audio_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	audio_panel.custom_minimum_size.x = 510
	var audio := column(audio_panel, 5)
	text(audio, "音量", 19, CYAN)
	for entry in [[&"Master", "主音量"], [&"Music", "音乐"], [&"Ambience", "环境"], [&"SFX", "战斗音效"], [&"UI", "界面音效"]]:
		volume_row(audio, entry[0], entry[1])
	var visual_panel := add_panel(sections, NIGHT)
	visual_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var visual := column(visual_panel, 6)
	text(visual, "显示", 19, CYAN)
	action(visual, "shake", "震动 %d%%" % roundi(game.shake_strength * 100), game.cycle_shake)
	action(visual, "flash", "减弱闪光 %s" % ("开" if game.reduce_flash else "关"), game.toggle_flash)
	action(visual, "text_size", "字号 %d%%" % roundi(game.text_scale * 100), game.cycle_text)
	action(visual, "low_motion", "低动效 %s" % ("开" if game.reduced_motion else "关"), game.toggle_motion)
	action(content, "back", "返回  Esc", game.close_settings, true)

func volume_row(parent: Control, bus: StringName, name_copy: String) -> void:
	var line := row(parent, 16)
	var name_label := text(line, name_copy, 17, BONE, false)
	name_label.custom_minimum_size.x = 150 if game.text_scale > 1.7 else 112
	var slider := HSlider.new()
	slider.name = "Volume_" + String(bus)
	slider.max_value = 100
	slider.step = 5
	slider.value = game.audio_mix.volumes[bus] * 100.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.y = 36
	slider.focus_mode = Control.FOCUS_ALL
	line.add_child(slider)
	controls.append(slider)
	if bus == &"Master": first_focus = slider
	slider.focus_entered.connect(func(): name_label.modulate = CYAN)
	slider.focus_exited.connect(func(): name_label.modulate = Color.WHITE)
	var readout := text(line, "%d%%" % roundi(slider.value), 16, MIST, false)
	readout.custom_minimum_size.x = 82
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	slider.value_changed.connect(func(value: float):
		game.audio_mix.set_level(bus, value / 100.0)
		readout.text = "%d%%" % roundi(value)
	)

func weapon_icon(parent: Control, id: String) -> void:
	var icon := TextureRect.new()
	icon.texture = load("res://art/painted/%s.tres" % id)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size.y = 76
	parent.add_child(icon)

func loadout() -> void:
	var expedition: bool = game.screen == "exp_loadout"
	var content := modal("选择检修武器", "整备中枢" if expedition else "压力门终端")
	var grid := row(content, 14)
	var equip: Callable = game.choose_expedition if expedition else game.equip
	for id in ["arc", "probe"]:
		var card := add_panel(grid, NIGHT)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var display := column(card, 8)
		weapon_icon(display, id)
		text(display, "短弧电切刃" if id == "arc" else "探针长枪", 21)
		text(display, "近身扇扫 · 8 伤害" if id == "arc" else "窄线贯穿 · %d 伤害" % (5 if expedition else 4), 17, MIST)
		action(display, id, "1  装配短弧" if id == "arc" else "2  装配探针", equip.bind(id), id == "arc")
	action(content, "back", "返回标题" if expedition else "返回接收厅", game.go_title if expedition else game.resume)

func shop() -> void:
	var content := modal("武器铺  ·  %d 工料" % game.cash, "整备中枢", 1080)
	var gear: String = "空" if game.gear.is_empty() else game.item_name(game.gear)
	text(content, "%s   /   装备 %s" % [game.module_name(game.build_id), gear], 18, MIST)
	if game.stock.is_empty():
		text(content, "击败压维守卫后补货。", 20)
	else:
		var grid := row(content, 12)
		for i in game.stock.size():
			var id: String = game.stock[i]
			var card := add_panel(grid, NIGHT)
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var shelf := column(card, 8)
			text(shelf, game.item_name(id), 21)
			weapon_icon(shelf, id)
			var detail := text(shelf, game.item_detail(id), 17, MIST)
			detail.custom_minimum_size.y = 65
			detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
			var equipped: bool = id == game.build_id or id == game.gear
			var sold: bool = i in game.sold
			var label := "售出" if sold else "正在使用" if equipped else "购买  ·  12"
			action(shelf, "buy_%d" % i, label, game.buy.bind(i), false, sold or equipped or game.cash < 12)
	var footer := button_row(content)
	action(footer, "improve", "已强化 +1" if game.tier >= 1 else "强化  ·  10", game.improve, false, game.tier >= 1 or game.cash < 10)
	action(footer, "refresh_stock", "已刷新" if game.refreshed else "刷新  ·  6", game.refresh_stock, false, game.refreshed or game.cash < 6 or game.stock.is_empty())
	first_focus = action(footer, "shop_back", "返回  Esc", game.resume, true)

func story() -> void:
	var content: VBoxContainer
	var actions: Array
	var details := ""
	match game.screen:
		"log":
			content = modal("停机日志", "B-17  /  02:14")
			details = "求救信号由 B-17 转入。压力机已经停下，接收灯还在闪。\n系统：回到接收厅。原件由我保留。"
			actions = [["rewind", "查看回溯", game.open_rewind], ["back", "返回车间", game.resume]]
		"rewind":
			content = modal("确认回溯", "系统  /  02")
			details = "回到进厂时刻，携带 B-17 原件。本轮模块与战斗状态将重置。"
			actions = [["confirm", "确认回溯", game.rewind], ["cancel", "取消", game.resume]]
		"transition":
			content = modal("回到接收厅", "迭代  /  02")
			details = "B-17 原件已封存。"
		"failed":
			content = modal("09 已倒下", "任务中断")
			details = "留意敌人的攻击轨迹，等它收招再反击。\n重试会清空本轮工料、装备和接驳进度。" if game.campaign else "沿箭纹侧边离开攻击轨道，等青色护板抬起再出手。"
			actions = [["retry", "重试本轮", game.retry], ["title", "返回标题", game.go_title]]
		"complete":
			content = modal("B-17 已开门", "调查记录  /  02")
			details = "供给记录签收了「%s」。登记时间在进厂前。\n门内传来同一段求救。" % game.module_name(game.retained_build)
			actions = [["restart", "重新调查", game.new_run], ["title", "返回标题", game.go_title], ["expedition", "进入整备中枢", game.continue_expedition]]
		"confirm_new":
			content = modal("重新调查", "档案")
			details = "重新调查会覆盖已保存的 B-17 原件。"
			actions = [["confirm", "清除检查点", game.new_run], ["cancel", "取消", game.go_title]]
		"exp_complete":
			content = modal("心核接驳完成", "肺叶入口")
			details = "新构筑通过了肺叶入口遭遇。首组远征试玩到此结束。"
			actions = [["title", "返回标题", game.go_title], ["restart", "重新远征", game.begin_expedition]]
	text(content, details, 19)
	if actions.is_empty(): return
	var buttons := button_row(content)
	for i in actions.size():
		var spec: Array = actions[i]
		action(buttons, spec[0], spec[1], spec[2], i == 0)
