extends Control

const INK = Color("#07141f")
const NIGHT = Color("#102738")
const STEEL = Color("#244454")
const MIST = Color("#829499")
const BONE = Color("#dfe8d5")
const CYAN = Color("#57e4ce")
const AMBER = Color("#ffc46b")
const RED = Color("#ff526d")

var game
var objective: Label
var status: Label
var context: Label
var notice: Label
var boss: Label
var plate_node: Panel
var theme_font: SystemFont

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme_font = SystemFont.new()
	theme_font.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "SimHei"])
	theme = Theme.new()
	theme.default_font = theme_font

func surface(color: Color, stroke: Color, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = stroke
	style.set_border_width_all(border_width)
	style.content_margin_left = 16
	style.content_margin_right = 16
	return style

func place(c: Control, rect: Rect2) -> void:
	add_child(c)
	c.position = rect.position
	c.size = rect.size

func plate(rect: Rect2, bg: Color = INK, stroke: Color = STEEL) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", surface(bg, stroke))
	place(panel, rect)
	return panel

func words(copy: String, rect: Rect2, px: int, color: Color = BONE) -> Label:
	var line := Label.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_color_override("font_color", color)
	line.add_theme_font_size_override("font_size", roundi(px * game.text_scale))
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.text = copy
	place(line, rect)
	return line

func button(copy: String, rect: Rect2, action: Callable, primary := false) -> Button:
	var b := Button.new()
	b.text = copy
	b.add_theme_font_size_override("font_size", roundi(20 * game.text_scale))
	b.add_theme_color_override("font_color", CYAN if primary else BONE)
	b.add_theme_color_override("font_hover_color", BONE)
	b.add_theme_stylebox_override("normal", surface(NIGHT, CYAN if primary else STEEL))
	b.add_theme_stylebox_override("hover", surface(STEEL, CYAN))
	b.add_theme_stylebox_override("pressed", surface(INK, BONE))
	b.add_theme_stylebox_override("focus", surface(Color(0, 0, 0, 0), BONE, 2))
	b.pressed.connect(action)
	place(b, rect)
	return b

func refresh() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if game.screen == "title":
		title()
		return
	hud()
	match game.screen:
		"choose":
			popup("接入模块", "系统  /  01", "压力门已接入。选一件工具，带进去。")
			plate(Rect2(252, 314, 372, 102), NIGHT)
			plate(Rect2(656, 314, 372, 102), NIGHT)
			weapon_card(preload("res://art/combat/cutter.png"), "棘齿切割器", "近身宽斩 · 8 伤害", 252)
			weapon_card(preload("res://art/combat/rangefinder.png"), "脉冲测距枪", "远距窄束 · 4 伤害", 656)
			button("1   装配短弧", Rect2(252, 431, 372, 56), game.equip.bind("arc"), true).grab_focus()
			button("2   装配探针", Rect2(656, 431, 372, 56), game.equip.bind("probe"))
		"log":
			popup("停机日志", "证据  /  01",
				"02:14  求救信号由 B-17 转入。\n压力机已经停下。接收灯还在闪。\n系统：回到接收厅。原件由我保留。")
			button("查看回溯", Rect2(252, 453, 260, 56), game.open_rewind, true).grab_focus()
			button("返回车间", Rect2(530, 453, 210, 56), game.resume)
		"rewind":
			popup("确认回溯", "系统  /  02",
				"回到进厂时刻，携带 B-17 原件。\n本轮模块与战斗状态将重置。")
			button("确认回溯", Rect2(252, 453, 260, 56), game.rewind, true).grab_focus()
			button("取消", Rect2(530, 453, 180, 56), game.resume)
		"transition":
			popup("回到接收厅", "迭代  /  02", "B-17 原件已封存。")
		"failed":
			popup("压力机未停机", "任务中断  /  01",
				"你在落点里耗尽了耐久。\n红框锁定后先离开，等青色护板抬起再出手。")
			button("重试本轮", Rect2(252, 453, 270, 56), game.retry, true).grab_focus()
			button("回到标题", Rect2(541, 453, 210, 56), game.go_title)
		"complete":
			popup("B-17 已开门", "调查记录  /  02",
				"供给记录签收了「%s」。登记时间：进厂前。\n门内传来同一段求救。" % game.module_name(game.retained_build))
			button("重新调查", Rect2(252, 453, 270, 56), game.new_run, true).grab_focus()
			button("回到标题", Rect2(541, 453, 210, 56), game.go_title)
		"paused":
			popup("调查暂停", "检修终端  /  设置", "WASD 移动   E 交互   J / 左键 攻击   空格 闪避")
			button("继续调查", Rect2(252, 348, 228, 54), game.resume, true).grab_focus()
			button("文字  %d%%" % roundi(game.text_scale * 100), Rect2(496, 348, 228, 54), game.cycle_text)
			button("低动效  %s" % ("开" if game.reduced_motion else "关"), Rect2(740, 348, 288, 54), game.toggle_motion)
			button("回到标题", Rect2(252, 421, 228, 54), game.go_title)
		"confirm_new":
			popup("重新调查", "检修终端  /  档案", "重新调查会覆盖已保存的 B-17 原件。")
			button("清除检查点", Rect2(252, 453, 270, 56), game.new_run, true).grab_focus()
			button("取消", Rect2(541, 453, 210, 56), game.go_title)
	update_hud()

func weapon_card(texture: Texture2D, name_text: String, details: String, x: int) -> void:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(icon, Rect2(x + 12, 330, 72, 72))
	words(name_text, Rect2(x + 94, 324, 260, 44), 21)
	words(details, Rect2(x + 94, 369, 260, 41), 17, MIST)

func title() -> void:
	plate(Rect2(0, 0, 550, 720))
	plate(Rect2(59, 118, 49, 4), CYAN, CYAN)
	words("厂区检修记录  /  01", Rect2(60, 143, 470, 36), 18, CYAN)
	words("牛马公司", Rect2(56, 184, 475, 106), 64)
	words("夜班回路", Rect2(60, 286, 470, 58), 32, AMBER)
	words("停机后的第一通求救，来自厂里。", Rect2(60, 354, 470, 77), 20)
	var started: bool = game.saved_stage > 0
	button("继续调查" if started else "开始调查", Rect2(60, 463, 282, 60), game.start, true).grab_focus()
	if started:
		button("重新调查", Rect2(60, 541, 282, 58), game.ask_new)
	words("RPG 重构试玩  /  0.1", Rect2(60, 640, 470, 40), 16, MIST)

func hud() -> void:
	plate(Rect2(22, 20, 550, 85))
	words("夜班回路   /   %s" % ("迭代 02" if game.cycle > 1 else "迭代 01"),
		Rect2(37, 26, 510, 33), 16, CYAN)
	objective = words("", Rect2(37, 56, 515, 46), 20)
	plate(Rect2(22, 644, 426, 56))
	status = words("", Rect2(37, 656, 393, 42), 18)
	plate(Rect2(939, 644, 319, 56))
	words("WASD  移动   /   ESC  暂停", Rect2(951, 656, 295, 42), 16, MIST)
	context = words("", Rect2(332, 578, 616, 46), 18, CYAN)
	context.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	context.add_theme_color_override("font_shadow_color", INK)
	context.add_theme_constant_override("shadow_offset_x", 2)
	context.add_theme_constant_override("shadow_offset_y", 2)
	plate_node = plate(Rect2(707, 20, 551, 83))
	notice = words("", Rect2(723, 32, 519, 65), 17, BONE)
	boss = words("", Rect2(430, 116, 420, 64), 18, BONE)
	boss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss.add_theme_color_override("font_shadow_color", INK)
	boss.add_theme_constant_override("shadow_offset_y", 2)

func popup(title_text: String, kicker: String, body: String) -> void:
	plate(Rect2(0, 0, 1280, 720), Color(INK, 0.62), Color.TRANSPARENT)
	plate(Rect2(220, 159, 840, 382), INK, STEEL)
	plate(Rect2(220, 159, 840, 3), CYAN, CYAN)
	words(kicker, Rect2(252, 180, 776, 35), 16, CYAN)
	words(title_text, Rect2(252, 217, 776, 67), 34)
	words(body, Rect2(252, 279, 776, 161), 19)

func update_hud() -> void:
	if game.screen == "title" or not is_instance_valid(objective):
		return
	objective.text = game.objective_text()
	status.text = "耐久  %d / 5    %s" % [game.hp, game.module_name(game.build_id)]
	context.text = game.context_text() if game.screen == "play" else ""
	notice.text = game.message
	plate_node.visible = game.message != "" and game.screen == "play"
	notice.visible = plate_node.visible
	boss.text = game.boss_text() if game.screen == "play" else ""
