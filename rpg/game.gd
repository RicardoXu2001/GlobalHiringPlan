extends Node

signal hud_changed

const World = preload("res://world.gd")
const Interface = preload("res://interface.gd")
const HeroMotion = preload("res://hero_motion.gd")
const ShiftAudio = preload("res://shift_audio.gd")
const TERMINAL := Vector2(320, 161)
const PRESS_GATE := Vector2(463, 137)
const BYPASS_GATE := Vector2(171, 137)
const CORE := Vector2(320, 169)
const LOG_POINT := Vector2(399, 167)
const SUPPLY := Vector2(320, 173)
const SPAWN := Vector2(320, 272)
const WALK_SPEED := 116.0
const DASH_SPEED := 355.0
const DASH_DURATION := 0.16
const DASH_COOLDOWN := 0.7
const SAVE := "user://night-shift.cfg"
const GUARD_NOTICE := "护板格挡。等青灯亮。"

var screen := "title"
var room := "intake"
var cycle := 1
var saved_stage := 0
var retained_build := ""
var build_id := ""
var log_read := false
var hp := 5
var player := SPAWN
var facing := Vector2.UP
var face_index := 0
var moving := false
var walk_clock := 0.0
var dash_dir := Vector2.ZERO
var dash_left := 0.0
var dash_cooldown := 0.0
var dash_age := -1.0
var dash_trail: Array[Vector2] = []
var evade_flash := 0.0
var evade_point := Vector2.ZERO
var attack_cooldown := 0.0
var attack_windup := 0.0
var attack_windup_total := 0.0
var attack_age := -1.0
var attack_result := ""
var attack_origin := Vector2.ZERO
var attack_direction := Vector2.ZERO
var attack_distance := 108.0
var hurt_flash := 0.0
var hurt_age := -1.0
var hurt_direction := Vector2.DOWN
var death_age := 0.0
var death_side := 1.0
var impact_pause := 0.0
var boss_hp := 24
var boss_hurt_age := -1.0
var boss_hurt_direction := Vector2.ZERO
var boss_phase := "idle"
var boss_time := 0.0
var boss_fx_age := -1.0
var hazard := Rect2()
var strike_hit := false
var hint_pos := Vector2.ZERO
var message := ""
var message_time := 0.0
var transition_left := 0.0
var text_scale := 1.0
var reduced_motion := false
var shake_strength := 1.0
var reduce_flash := false
var settings_return := "title"
var hud_state: Array = []
var campaign := false
var attack_contact := CORE - Vector2(0, 10)
var queued_attack := Vector2.ZERO
var attack_buffer := 0.0
var dash_buffer := 0.0
var combo_step := -1
var combo_window := 0.0
var hurt_recoil := Vector2.ZERO

var world: Node2D
var presentation: TextureRect
var ui: Control
var hero_motion: Node
var audio_mix: Node

func _ready() -> void:
	get_window().min_size = Vector2i(960, 540)
	hero_motion = HeroMotion.new()
	add_child(hero_motion)
	var pixel_view := SubViewport.new()
	pixel_view.size = Vector2i(1280, 720)
	pixel_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	pixel_view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(pixel_view)
	world = World.new()
	world.game = self
	world.scale = Vector2(2, 2)
	pixel_view.add_child(world)
	presentation = TextureRect.new()
	presentation.texture = pixel_view.get_texture()
	presentation.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	presentation.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	presentation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(presentation)
	ui = Interface.new()
	ui.game = self
	add_child(ui)
	audio_mix = ShiftAudio.new()
	add_child(audio_mix)
	get_viewport().size_changed.connect(layout)
	layout()
	load_checkpoint()
	ui.refresh()

func layout() -> void:
	var available := get_viewport().get_visible_rect().size
	var fit := minf(available.x / 1280, available.y / 720)
	var pixel_scale := floorf(fit) if fit >= 1.0 else fit
	presentation.size = Vector2(1280, 720) * pixel_scale
	presentation.position = ((available - presentation.size) / 2).floor()
	ui.size = Vector2(1280, 720)
	ui.scale = Vector2.ONE * pixel_scale
	ui.position = presentation.position

func play_sound(key: String, heavy := false) -> void:
	audio_mix.trigger(key, heavy, build_id, combo_step)

func sound_scene() -> String:
	if screen != "play": return "menu"
	return "boss" if room == "press" and boss_hp > 0 else "quiet"

func load_checkpoint() -> void:
	var save := ConfigFile.new()
	if save.load(SAVE) != OK:
		return
	var stage: Variant = save.get_value("run", "stage", 0)
	var module: Variant = save.get_value("run", "module", "")
	if stage in [2, 3] and module in ["arc", "probe"]:
		saved_stage = int(stage)
		retained_build = String(module)

func save_checkpoint(stage: int, module: String) -> bool:
	var save := ConfigFile.new()
	save.set_value("run", "stage", stage)
	save.set_value("run", "module", module)
	if save.save(SAVE + ".tmp") != OK or DirAccess.rename_absolute(SAVE + ".tmp", SAVE) != OK:
		resume()
		notify("写入检查点失败。请重试。")
		return false
	saved_stage = stage
	retained_build = module
	return true

func set_screen(next: String) -> void:
	screen = next
	if next != "play": clear_input_buffer()
	ui.refresh()

func open_settings() -> void:
	settings_return = screen
	set_screen("settings")

func close_settings() -> void:
	audio_mix.save_levels()
	set_screen(settings_return)
	var settings_button := ui.find_child("Action_settings", true, false) as Button
	if settings_button: settings_button.grab_focus()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and screen == "settings" and is_instance_valid(audio_mix):
		audio_mix.save_levels()

func go_title() -> void:
	set_screen("title")

func start() -> void:
	reset_round(2 if saved_stage >= 2 else 1)
	if saved_stage == 3:
		enter_room("bypass")
		set_screen("complete")

func ask_new() -> void:
	set_screen("confirm_new")

func new_run() -> void:
	if saved_stage == 0 or save_checkpoint(0, ""):
		reset_round(1)

func retry() -> void:
	reset_round(cycle)

func reset_round(next_cycle: int) -> void:
	cycle = next_cycle
	build_id = ""
	log_read = false
	hp = 5
	boss_hp = 24
	attack_cooldown = 0
	dash_cooldown = 0
	hurt_flash = 0
	message = ""
	enter_room("intake")
	set_screen("play")
	notify("B-17 原件在手。西侧旁路可开。" if cycle > 1 else "停机后的第一通求救，来自厂里。", 3.3)

func enter_room(next: String) -> void:
	room = next
	clear_input_buffer()
	combo_step = -1
	combo_window = 0
	hurt_recoil = Vector2.ZERO
	world.reset_feedback(next)
	player = SPAWN
	facing = Vector2.UP
	face_index = 0
	walk_clock = 0.0
	moving = false
	hint_pos = Vector2.ZERO
	attack_age = -1.0
	attack_windup = 0
	attack_result = ""
	dash_left = 0
	dash_age = -1.0
	dash_trail.clear()
	evade_flash = 0.0
	boss_fx_age = -1.0
	hurt_flash = 0.0
	hurt_age = -1.0
	boss_hurt_age = -1.0
	impact_pause = 0.0
	death_age = 0.0
	boss_phase = "idle"
	boss_time = 1.2
	play_sound("open")

func resume() -> void:
	set_screen("play")

func cycle_text() -> void:
	text_scale = 1.0 if text_scale >= 2.0 else text_scale + 0.25
	ui.refresh()

func toggle_motion() -> void:
	reduced_motion = not reduced_motion
	ui.refresh()

func cycle_shake() -> void:
	shake_strength = 1.0 if shake_strength <= 0.0 else shake_strength - 0.5
	ui.refresh()

func toggle_flash() -> void:
	reduce_flash = not reduce_flash
	ui.refresh()

func equip(id: String) -> void:
	if screen != "choose" or cycle != 1 or build_id != "":
		return
	build_id = id
	play_sound("open")
	resume()
	notify("模块已接入。东侧压力门开启。")

func open_rewind() -> void:
	if log_read and cycle == 1:
		set_screen("rewind")

func rewind() -> void:
	if screen != "rewind" or not log_read or not save_checkpoint(2, build_id):
		return
	play_sound("return")
	transition_left = 0.75 if not reduced_motion else 0.12
	set_screen("transition")

func notify(copy: String, length := 2.35) -> void:
	message = copy
	message_time = length

func module_name(id: String) -> String:
	match id:
		"arc": return "短弧"
		"probe": return "探针"
	return "无模块"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		match screen:
			"play": set_screen("paused")
			"paused", "choose", "log", "rewind", "shop": resume()
			"confirm_new", "exp_loadout": go_title()
			"settings": close_settings()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_E:
				if screen == "play": interact()
			KEY_1:
				if screen == "choose": equip("arc")
			KEY_2:
				if screen == "choose": equip("probe")
			KEY_J:
				if screen == "play": request_attack(facing)
			KEY_SPACE:
				if screen == "play": request_dash()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and screen == "play":
		var at: Vector2 = (event.position - presentation.position) * (640.0 / presentation.size.x) - world.position * 0.5
		if Rect2(Vector2.ZERO, Vector2(640, 360)).has_point(at):
			request_attack((at - player).normalized())

func _physics_process(dt: float) -> void:
	if screen in ["play", "dying"]:
		impact_pause = maxf(0.0, impact_pause - dt)
		boss_fx_age = advance_pose(boss_fx_age, dt, 0.45)
	if screen == "transition":
		transition_left -= dt
		if transition_left <= 0:
			reset_round(2)
	if screen == "play":
		tick_play(dt)
	elif screen == "dying":
		var before := death_age
		if impact_pause <= 0.0: death_age += dt
		hurt_flash = maxf(0, hurt_flash - dt)
		if before < 0.32 and death_age >= 0.32:
			play_sound("fall")
		if death_age >= 1.1:
			set_screen("failed")
	hero_motion.sync(self)
	audio_mix.set_context(sound_scene())
	world.queue_redraw()
	publish_hud()

func publish_hud() -> void:
	if screen != "play": return
	# The UI receives changes to displayed values. Cooldown updates are quantized
	# to the precision of the meter and never cause layout on unrelated ticks.
	var next := [room, cycle, hp, build_id, combo_step, combo_window > 0, dash_left > 0,
		ceili(dash_cooldown * 20.0), hint_pos, message, boss_hp, boss_phase, hazard.size.x > 100,
		world.fixture_hint()]
	if next != hud_state:
		hud_state = next
		hud_changed.emit()

func tick_play(dt: float) -> void:
	if impact_pause <= 0.0:
		hurt_age = advance_pose(hurt_age, dt, 0.36)
		boss_hurt_age = advance_pose(boss_hurt_age, dt, 0.36)
		attack_age = advance_pose(attack_age, dt, 0.32)
	attack_cooldown = maxf(0, attack_cooldown - dt)
	dash_cooldown = maxf(0, dash_cooldown - dt)
	hurt_flash = maxf(0, hurt_flash - dt)
	combo_window = maxf(0, combo_window - dt)
	consume_input_buffer(dt)
	evade_flash = maxf(0, evade_flash - dt)
	if dash_age >= 0:
		dash_age += dt
		if dash_age >= 0.26:
			dash_age = -1.0
	message_time = maxf(0, message_time - dt)
	if message_time <= 0:
		message = ""
	var direction := move_direction()
	if direction != Vector2.ZERO and dash_left <= 0: set_facing(direction)
	var before_move := player
	var evading := dash_left > 0
	if hurt_recoil != Vector2.ZERO:
		move(hurt_recoil * dt)
		hurt_recoil = hurt_recoil.move_toward(Vector2.ZERO, 460 * dt)
	if dash_left > 0:
		dash_trail.append(player.round())
		if dash_trail.size() > 4:
			dash_trail.pop_front()
		move(dash_dir * DASH_SPEED * dt)
		dash_left = maxf(0, dash_left - dt)
	else:
		move(direction * WALK_SPEED * dt)
	moving = player != before_move and (direction != Vector2.ZERO or evading)
	if moving and not evading:
		var previous_step := int(walk_clock * 12)
		walk_clock += dt
		var next_step := int(walk_clock * 12)
		if next_step != previous_step and next_step % 6 in [1, 4]: play_sound("step")
	if attack_windup > 0.0:
		attack_windup = maxf(0, attack_windup - dt)
		if attack_windup < 0.0001:
			attack_windup = 0.0
			release_attack()
	hint_pos = nearest_object()
	if room == "press" and boss_hp > 0:
		tick_boss(dt, evading, before_move)

func advance_pose(age: float, dt: float, duration: float) -> float:
	return age + dt if age >= 0.0 and age + dt < duration else -1.0

func hold_impact(seconds: float) -> void:
	impact_pause = maxf(impact_pause, seconds)

func move_direction() -> Vector2:
	if not get_window().has_focus():
		return Vector2.ZERO
	return Vector2(
		int(Input.is_physical_key_pressed(KEY_D)) - int(Input.is_physical_key_pressed(KEY_A)),
		int(Input.is_physical_key_pressed(KEY_S)) - int(Input.is_physical_key_pressed(KEY_W))
	).normalized()

func move(delta: Vector2) -> void:
	player = world.slide_on_floor(player, delta)

func set_facing(direction: Vector2) -> void:
	facing = direction
	if absf(direction.x) > absf(direction.y):
		face_index = 2 if direction.x < 0 else 3
	else:
		face_index = 0 if direction.y < 0 else 1

func dash() -> void:
	if dash_cooldown > 0:
		return
	attack_windup = 0.0
	clear_input_buffer()
	dash_dir = move_direction()
	if dash_dir == Vector2.ZERO:
		dash_dir = facing
	dash_left = DASH_DURATION
	dash_cooldown = DASH_COOLDOWN
	dash_age = 0.0
	dash_trail.clear()
	set_facing(dash_dir)
	play_sound("dash")

func clear_input_buffer() -> void:
	attack_buffer = 0
	dash_buffer = 0
	queued_attack = Vector2.ZERO

func request_attack(direction: Vector2) -> void:
	if build_id == "" or direction == Vector2.ZERO or hp <= 0: return
	if attack_cooldown <= 0 and dash_left <= 0:
		attack(direction)
	elif attack_cooldown <= 0.12 or dash_left > 0:
		queued_attack = direction
		attack_buffer = 0.12

func request_dash() -> void:
	if hp <= 0: return
	if dash_cooldown <= 0: dash()
	elif dash_cooldown <= 0.12: dash_buffer = 0.12

func consume_input_buffer(dt: float) -> void:
	if dash_buffer > 0 and dash_cooldown <= 0:
		dash()
	elif attack_buffer > 0 and attack_cooldown <= 0 and dash_left <= 0:
		var direction := queued_attack
		attack_buffer = 0
		attack(direction)
	attack_buffer = maxf(0, attack_buffer - dt)
	dash_buffer = maxf(0, dash_buffer - dt)

func begin_attack(direction: Vector2) -> void:
	set_facing(direction)
	combo_step = (combo_step + 1) % 3 if build_id == "arc" and combo_window > 0 else 0
	combo_window = 0.68 if build_id == "arc" else 0.0
	attack_buffer = 0

func aim_tracer_at_contact() -> void:
	var offset := attack_contact - attack_origin
	attack_direction = offset.normalized()
	attack_distance = offset.length()

func finish_attack(finisher := false) -> void:
	var had_body_hit := attack_result == "hit"
	if attack_result == "miss" or (had_body_hit and build_id in ["arc", "probe"]):
		var reach := attack_distance
		if world.strike_fixtures(player, attack_direction, reach, build_id):
			if attack_result == "miss":
				attack_result = "hit"
				attack_contact = world.fixture_contact
				if build_id != "arc": aim_tracer_at_contact()
	if attack_result == "hit":
		var hold := (0.075 if combo_step == 2 else 0.055) if build_id == "arc" else 0.018 if build_id == "nailer" else 0.03
		var boss_contact := room == "press" and had_body_hit
		hold_impact(0.10 if finisher else maxf(0.065, hold) if boss_contact else hold)
		if boss_contact:
			world.impact(attack_contact, attack_direction, "metal", "finish" if finisher else "heavy")
		play_sound(build_id + "_hit", boss_contact or combo_step == 2 or finisher)
	elif attack_result == "guard":
		if room == "press": world.impact(attack_contact, -attack_direction, "metal", "guard")
		play_sound("guard")
	else:
		if build_id != "arc":
			var clipped: float = world.wall_distance(attack_origin, attack_direction, attack_distance)
			if clipped < attack_distance:
				attack_distance = maxf(0.5, clipped)
				world.impact(attack_origin + attack_direction * clipped, -attack_direction, "metal", "chip")
		play_sound(build_id + "_miss")

func attack(direction: Vector2) -> void:
	if build_id == "" or attack_cooldown > 0 or dash_left > 0 or direction == Vector2.ZERO:
		return
	begin_attack(direction)
	attack_cooldown = 0.38 if build_id == "arc" else 0.42
	attack_windup = 0.05 if build_id == "arc" else 0.025
	attack_windup_total = attack_windup
	attack_direction = direction

func release_attack() -> void:
	attack_contact = CORE - Vector2(0, 14 if build_id == "arc" else 38)
	set_facing(attack_direction)
	attack_age = 0.0
	attack_origin = player.round() - Vector2(0, 10)
	attack_result = "miss"
	var to_core := CORE - player
	var reach := 54.0 if build_id == "arc" else 108.0
	var aim := 0.58 if build_id == "arc" else 0.90
	attack_distance = reach
	if room != "press" or boss_hp == 0 or to_core.length() > reach or attack_direction.dot(to_core.normalized()) < aim:
		finish_attack()
		return
	if build_id != "arc": aim_tracer_at_contact()
	if boss_phase != "open":
		attack_result = "guard"
		finish_attack()
		notify(GUARD_NOTICE, 1.2)
		return
	attack_result = "hit"
	boss_hurt_age = 0.0
	boss_hurt_direction = attack_direction
	boss_hp = maxi(0, boss_hp - (8 if build_id == "arc" else 4))
	if boss_hp == 0:
		boss_phase = "offline"
		play_sound("break")
		notify("压力机停下了。检查右侧日志终端。", 3.2)
	finish_attack(boss_hp == 0)

func tick_boss(dt: float, evading: bool, before_move: Vector2) -> void:
	boss_time -= dt
	if boss_time <= 0:
		match boss_phase:
			"idle":
				if player.distance_to(CORE) < 75:
					hazard = Rect2(213, 132, 214, 75)
				else:
					hazard = Rect2(clampf(roundf(player.x) - 24, 103, 490), 132, 48, 166)
				boss_phase = "warn"
				boss_time = 0.85
				strike_hit = false
				play_sound("warn")
			"warn":
				boss_phase = "strike"
				boss_time = 0.19
				boss_fx_age = 0.0
				world.feedback.kick(0.38 if hazard.size.x > 100 else 0.54)
				play_sound("sweep" if hazard.size.x > 100 else "slam")
			"strike":
				boss_phase = "open"
				boss_time = 1.07
				if message == GUARD_NOTICE:
					message = ""
			"open":
				boss_phase = "idle"
				boss_time = 0.68
	var in_strike := hazard.has_point(player) or (evading and hazard.has_point(before_move))
	if boss_phase == "strike" and not strike_hit and in_strike:
		strike_hit = true
		if evading:
			evade_flash = 0.35
			evade_point = player.round()
			play_sound("evade")
			notify("擦身闪避", 0.65)
			return
		take_hit()

func take_hit(source: Vector2 = CORE) -> void:
	hp = maxi(0, hp - 2)
	hurt_flash = 0.20
	hurt_age = 0.0
	hurt_direction = (player - source).normalized()
	if hurt_direction == Vector2.ZERO:
		hurt_direction = Vector2.DOWN
	attack_windup = 0.0
	attack_age = -1.0
	clear_input_buffer()
	combo_window = 0
	hurt_recoil = hurt_direction * 70
	world.impact(player - Vector2(0, 24), hurt_direction, "tissue", "heavy" if hp == 0 else "hit")
	hold_impact(0.09 if hp == 0 else 0.04)
	play_sound("hurt", hp == 0)
	notify("受击  −2 耐久", 0.85)
	if hp == 0:
		moving = false
		dash_left = 0
		dash_age = -1.0
		death_side = -1.0 if player.x > 490 or (player.x >= 150 and player.x < CORE.x) else 1.0
		death_age = 0.0
		message = ""
		set_screen("dying")

func nearest_object() -> Vector2:
	var options: Array[Vector2] = []
	match room:
		"intake": options = [TERMINAL, PRESS_GATE, BYPASS_GATE]
		"press":
			if boss_hp == 0: options = [LOG_POINT]
		"bypass": options = [SUPPLY]
	for target in options:
		if target.distance_to(player) <= 27:
			return target
	return Vector2.ZERO

func interact() -> void:
	var target := nearest_object()
	if target == Vector2.ZERO:
		return
	play_sound("click")
	match room:
		"intake":
			if target == TERMINAL:
				if cycle == 1 and build_id == "": set_screen("choose")
				elif cycle > 1: notify("系统：原件有效。请走西侧旁路。")
				else: notify("压力门已开放。")
			elif target == PRESS_GATE and build_id != "":
				enter_room("press")
				notify("箭纹亮起后离开攻击轨道。空格闪避。", 4)
			elif target == BYPASS_GATE and cycle > 1:
				enter_room("bypass")
				notify("B-17 原件通过。供给记录可查。")
			else:
				notify("压力门需要检修模块。" if target == PRESS_GATE else "B-17：缺少转接原件。")
		"press":
			log_read = true
			set_screen("log")
		"bypass":
			if save_checkpoint(3, retained_build):
				set_screen("complete")

func objective_text() -> String:
	match room:
		"intake":
			if cycle > 1: return "带原件进 B-17 旁路"
			return "接入检修终端" if build_id == "" else "穿过东侧压力门"
		"press":
			if boss_hp > 0: return "避开落点，让压力机停机"
			return "导出停机日志"
		"bypass": return "读取供给记录"
	return ""

func context_text() -> String:
	if hint_pos == Vector2.ZERO:
		return ""
	if room == "press":
		return "[ E ]  查看停机日志"
	if room == "bypass":
		return "[ E ]  读取供给记录"
	if hint_pos == TERMINAL: return "[ E ]  接入检修终端"
	if hint_pos == BYPASS_GATE: return "[ E ]  B-17 旁路" if cycle > 1 else "[ E ]  B-17  /  缺少原件"
	return "[ E ]  进入压力车间" if build_id != "" else "[ E ]  压力门  /  等待接入"

func boss_text() -> String:
	if room != "press" or boss_hp == 0 or hp == 0:
		return ""
	var state := "护板闭合"
	match boss_phase:
		"warn": state = "▲  横扫蓄力" if hazard.size.x > 100 else "▲  压降蓄力"
		"strike": state = "▲  横扫释放" if hazard.size.x > 100 else "▲  压降落击"
		"open": state = "◇  护板打开"
	return "压力机  %02d / 24   %s" % [boss_hp, state]
