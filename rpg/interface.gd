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
var dodge: Label
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
		"exp_loadout":
			popup("09，选择检修武器", "心泵外围  /  首组远征", "三段遭遇后取得心核。先用一件熟悉的工具出发。")
			button("1  短弧 · 扇形电刃", Rect2(252, 433, 360, 60), game.choose_expedition.bind("arc"), true).grab_focus()
			button("2  探针 · 窄线贯穿", Rect2(632, 433, 360, 60), game.choose_expedition.bind("probe"))
		"shop":
			shop_panel()
		"exp_complete":
			popup("首组整备闭环完成", "下一站  /  肺叶", "心核已接入。新构筑通过入口遭遇。\n本版已开放首组四关、中心与肺叶入口。\n其余六组与古神终战仍在施工。")
			button("回到标题", Rect2(252, 453, 270, 56), game.go_title, true).grab_focus()
			button("重新远征", Rect2(541, 453, 270, 56), game.begin_expedition)
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
			popup("09 已倒下", "任务中断  /  01",
				"耐久耗尽。红框锁定后再离开，恢复窗口中反击。\n重试远征将清空本次工料、装备和接驳进度。" if game.campaign else "你在落点里耗尽了耐久。\n红框锁定后先离开，等青色护板抬起再出手。")
			button("重试本轮", Rect2(252, 453, 270, 56), game.retry, true).grab_focus()
			button("回到标题", Rect2(541, 453, 210, 56), game.go_title)
		"complete":
			popup("B-17 已开门", "调查记录  /  02",
				"供给记录签收了「%s」。登记时间：进厂前。\n门内传来同一段求救。" % game.module_name(game.retained_build))
			button("重新调查", Rect2(252, 453, 270, 56), game.new_run, true).grab_focus()
			button("回到标题", Rect2(541, 453, 210, 56), game.go_title)
			button("进入整备中枢", Rect2(770, 453, 258, 56), game.continue_expedition)
		"paused":
			popup("调查暂停", "检修终端  /  设置", "WASD 移动   E 交互   J / 左键 攻击   空格 闪避")
			button("继续调查", Rect2(252, 348, 228, 54), game.resume, true).grab_focus()
			button("文字  %d%%" % roundi(game.text_scale * 100), Rect2(496, 348, 228, 54), game.cycle_text)
			button("低动效  %s" % ("开" if game.reduced_motion else "关"), Rect2(740, 348, 288, 54), game.toggle_motion)
			button("回到标题", Rect2(252, 421, 228, 54), game.go_title)
			if game.campaign:
				button("重新远征", Rect2(496, 421, 228, 54), game.begin_expedition)
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
	words("厂区检修记录  /  09", Rect2(60, 143, 470, 36), 18, CYAN)
	words("夜班回路", Rect2(56, 184, 475, 106), 64)
	words("开发代号  /  正式名称待定", Rect2(60, 286, 470, 58), 24, AMBER)
	words("停机后的第一通求救，来自厂里。", Rect2(60, 354, 470, 77), 20)
	var started: bool = game.saved_stage > 0
	button("继续调查" if started else "开始调查", Rect2(60, 463, 282, 60), game.start, true).grab_focus()
	if started:
		button("重开序章", Rect2(360, 463, 150, 60), game.ask_new)
	button("继续首组远征" if not game.saved_run.is_empty() else "开始首组远征", Rect2(60, 541, 350, 58), game.continue_expedition)
	words("生体工厂试玩  /  0.2", Rect2(60, 640, 470, 40), 16, MIST)

func hud() -> void:
	plate(Rect2(22, 20, 550, 85))
	words(("09   /   首组远征 · 接入 %d / 7" % int(game.integrated)) if game.campaign else "09   /   %s" % ("迭代 02" if game.cycle > 1 else "迭代 01"),
		Rect2(37, 26, 510, 33), 16, CYAN)
	objective = words("", Rect2(37, 56, 515, 46), 20)
	plate(Rect2(22, 644, 426, 56))
	status = words("", Rect2(37, 656, 393, 42), 18)
	dodge = words("", Rect2(466, 656, 450, 42), 17, CYAN)
	dodge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate(Rect2(939, 644, 319, 56))
	words("WASD  移动   /   ESC  暂停", Rect2(951, 656, 295, 42), 16, MIST)
	if game.campaign and game.room == "hub":
		words("武器铺", Rect2(285, 407, 130, 32), 18, CYAN)
		words("脏器接驳", Rect2(588, 365, 160, 32), 18, CYAN)
		words("出发口", Rect2(900, 407, 130, 32), 18, AMBER)
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
	if game.screen == "dying":
		objective.text = "耐久耗尽"
	status.text = "耐久 %d / %d   %s" % [game.hp, game.max_hp() if game.campaign else 5, game.module_name(game.build_id)]
	dodge.text = "空格  闪避就绪"
	if game.screen in ["dying", "failed"]:
		dodge.text = "生命信号中断"
	elif game.dash_left > 0:
		dodge.text = "闪避中"
	elif game.dash_cooldown > 0:
		dodge.text = "闪避恢复  %.1f 秒" % game.dash_cooldown
	context.text = game.context_text() if game.screen == "play" else ""
	notice.text = game.message
	plate_node.visible = game.message != "" and game.screen == "play"
	notice.visible = plate_node.visible
	boss.text = game.boss_text() if game.screen == "play" else ""

func shop_panel() -> void:
	plate(Rect2(0, 0, 1280, 720), Color(INK, 0.78), Color.TRANSPARENT)
	plate(Rect2(154, 142, 972, 447), INK, STEEL)
	words("武器铺   /   工料 %d" % game.cash, Rect2(180, 159, 900, 43), 28, CYAN)
	words("当前：%s  ·  强化等级换装保留" % game.module_name(game.build_id), Rect2(180, 209, 900, 40), 18, MIST)
	if game.stock.is_empty():
		words("首组通关后补货。基础武器已备好。", Rect2(180, 290, 850, 80), 23)
	else:
		for i in game.stock.size():
			var x: int = 180 + int(i) * 310
			var id: String = game.stock[i]
			plate(Rect2(x, 259, 287, 206), NIGHT)
			words(game.item_name(id), Rect2(x + 14, 270, 259, 35), 22)
			var icon := TextureRect.new()
			icon.texture = load("res://art/expedition/%s-%s.png" % ["weapon" if id in game.WEAPONS else "gear", id])
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			place(icon, Rect2(x + 17, 305, 128, 64))
			words(game.item_detail(id), Rect2(x + 14, 375, 259, 72), 17, MIST)
			var equipped: bool = id == game.build_id or id == game.gear
			var buy_button := button("已售出" if i in game.sold else "当前装备" if equipped else "替换装备 · 12 工料", Rect2(x, 472, 287, 48), game.buy.bind(i))
			buy_button.disabled = i in game.sold or game.cash < 12 or equipped
	var improve := button("已强化 +1" if game.tier >= 1 else "当前武器强化 · 10", Rect2(180, 533, 287, 43), game.improve)
	improve.disabled = game.tier >= 1 or game.cash < 10
	var refresh_button := button("本批已刷新" if game.refreshed else "刷新本批 · 6", Rect2(490, 533, 287, 43), game.refresh_stock)
	refresh_button.disabled = game.refreshed or game.cash < 6 or game.stock.is_empty()
	button("返回中心 [ Esc ]", Rect2(800, 533, 287, 43), game.resume, true).grab_focus()
