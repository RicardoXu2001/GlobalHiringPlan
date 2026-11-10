extends Node

const World = preload("res://world.gd")
const Interface = preload("res://interface.gd")
const TERMINAL := Vector2(320, 161)
const PRESS_GATE := Vector2(463, 137)
const BYPASS_GATE := Vector2(171, 137)
const CORE := Vector2(320, 169)
const LOG_POINT := Vector2(399, 167)
const SUPPLY := Vector2(320, 173)
const SPAWN := Vector2(320, 272)
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
var attack_cooldown := 0.0
var attack_windup := 0.0
var attack_age := -1.0
var attack_result := ""
var attack_origin := Vector2.ZERO
var attack_direction := Vector2.ZERO
var attack_distance := 108.0
var hurt_flash := 0.0
var boss_hp := 24
var boss_phase := "idle"
var boss_time := 0.0
var hazard := Rect2()
var strike_hit := false
var hint_pos := Vector2.ZERO
var message := ""
var message_time := 0.0
var transition_left := 0.0
var text_scale := 1.0
var reduced_motion := false

var world: Node2D
var presentation: TextureRect
var ui: Control
var audio: AudioStreamPlayer
var tones: Dictionary

func _ready() -> void:
	get_window().min_size = Vector2i(960, 540)
	var pixel_view := SubViewport.new()
	pixel_view.size = Vector2i(640, 360)
	pixel_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	pixel_view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(pixel_view)
	world = World.new()
	world.game = self
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
	audio = AudioStreamPlayer.new()
	audio.volume_db = -12
	add_child(audio)
	tones = {
		"click": tone(540, 210, 0.085), "hit": tone(162, 72, 0.13),
		"warn": tone(330, 440, 0.24), "stop": tone(86, 42, 0.36),
		"return": tone(120, 410, 0.40), "open": tone(220, 410, 0.17),
		"arc_miss": tone(155, 91, 0.13, 0.27), "arc_hit": tone(123, 45, 0.22, 0.43),
		"probe_miss": tone(880, 254, 0.10, 0.08), "probe_hit": tone(760, 153, 0.15, 0.35),
		"guard": tone(1120, 490, 0.115, 0.25), "break": tone(118, 34, 0.35, 0.48)
	}
	get_viewport().size_changed.connect(layout)
	layout()
	load_checkpoint()
	ui.refresh()

func layout() -> void:
	var available := get_viewport().get_visible_rect().size
	var pixel_scale := maxf(1.0, floorf(minf(available.x / 640, available.y / 360)))
	presentation.size = Vector2(640, 360) * pixel_scale
	presentation.position = ((available - presentation.size) / 2).floor()
	var text_zoom := minf(available.x / 1280, available.y / 720)
	ui.size = Vector2(1280, 720)
	ui.scale = Vector2.ONE * text_zoom
	ui.position = ((available - ui.size * text_zoom) / 2).floor()

func tone(start_hz: float, end_hz: float, length: float, grit := 0.0) -> AudioStreamWAV:
	var sound := AudioStreamWAV.new()
	sound.mix_rate = 22050
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	var count := roundi(length * sound.mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 4499
	for i in count:
		var fraction := float(i) / count
		phase += TAU * lerpf(start_hz, end_hz, fraction) / sound.mix_rate
		var envelope := minf(1, i / 100.0) * pow(1 - fraction, 2)
		var sample := (sin(phase) * 0.8 + sin(phase * 2.02) * 0.2) * envelope
		if grit > 0.0:
			sample += rng.randf_range(-grit, grit) * minf(1, i / 25.0) * exp(-fraction * 9.0)
		bytes.encode_s16(i * 2, clampi(roundi(sample * 22000), -32768, 32767))
	sound.data = bytes
	return sound

func play_sound(key: String) -> void:
	audio.stream = tones[key]
	audio.play()

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
	ui.refresh()

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
	dash_left = 0
	dash_cooldown = 0
	hurt_flash = 0
	message = ""
	enter_room("intake")
	set_screen("play")
	notify("B-17 原件在手。西侧旁路可开。" if cycle > 1 else "停机后的第一通求救，来自厂里。", 3.3)

func enter_room(next: String) -> void:
	room = next
	player = SPAWN
	facing = Vector2.UP
	face_index = 0
	hint_pos = Vector2.ZERO
	attack_age = -1.0
	attack_windup = 0
	attack_result = ""
	dash_left = 0
	boss_phase = "idle"
	boss_time = 1.2
	play_sound("open")

func resume() -> void:
	set_screen("play")

func cycle_text() -> void:
	text_scale = 1.0 if text_scale >= 1.5 else text_scale + 0.25
	ui.refresh()

func toggle_motion() -> void:
	reduced_motion = not reduced_motion
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
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE:
				match screen:
					"play": set_screen("paused")
					"paused", "choose", "log", "rewind": resume()
					"confirm_new": go_title()
			KEY_E:
				if screen == "play": interact()
			KEY_1:
				if screen == "choose": equip("arc")
			KEY_2:
				if screen == "choose": equip("probe")
			KEY_J:
				if screen == "play": attack(facing)
			KEY_SPACE:
				if screen == "play": dash()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and screen == "play":
		var at: Vector2 = (event.position - presentation.position) * (640.0 / presentation.size.x)
		if Rect2(Vector2.ZERO, Vector2(640, 360)).has_point(at):
			attack((at - player).normalized())

func _physics_process(dt: float) -> void:
	if screen == "transition":
		transition_left -= dt
		if transition_left <= 0:
			reset_round(2)
	if screen == "play":
		tick_play(dt)
	world.queue_redraw()
	ui.update_hud()

func tick_play(dt: float) -> void:
	attack_cooldown = maxf(0, attack_cooldown - dt)
	dash_cooldown = maxf(0, dash_cooldown - dt)
	hurt_flash = maxf(0, hurt_flash - dt)
	if attack_age >= 0.0:
		attack_age += dt
		if attack_age >= 0.32:
			attack_age = -1.0
	message_time = maxf(0, message_time - dt)
	if message_time <= 0:
		message = ""
	var direction := move_direction()
	moving = direction != Vector2.ZERO or dash_left > 0
	if direction != Vector2.ZERO and dash_left <= 0:
		set_facing(direction)
	if moving:
		walk_clock += dt
	if dash_left > 0:
		move(dash_dir * 355.0 * dt)
		dash_left = maxf(0, dash_left - dt)
	else:
		move(direction * 116.0 * dt)
	if attack_windup > 0.0:
		attack_windup = maxf(0, attack_windup - dt)
		if attack_windup < 0.0001:
			attack_windup = 0.0
			release_attack()
	hint_pos = nearest_object()
	if room == "press" and boss_hp > 0:
		tick_boss(dt)

func move_direction() -> Vector2:
	if not get_window().has_focus():
		return Vector2.ZERO
	return Vector2(
		int(Input.is_physical_key_pressed(KEY_D)) - int(Input.is_physical_key_pressed(KEY_A)),
		int(Input.is_physical_key_pressed(KEY_S)) - int(Input.is_physical_key_pressed(KEY_W))
	).normalized()

func move(delta: Vector2) -> void:
	# Apply axes separately so the pressure frame can be skirted at corners.
	var frame := Rect2(274, 117, 92, 56)
	for component in [Vector2(delta.x, 0), Vector2(0, delta.y)]:
		var next: Vector2 = (player + component).clamp(Vector2(112, 135), Vector2(528, 294))
		if room != "press" or not frame.has_point(next):
			player = next

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
	dash_dir = move_direction()
	if dash_dir == Vector2.ZERO:
		dash_dir = facing
	dash_left = 0.16
	dash_cooldown = 0.7
	set_facing(dash_dir)
	play_sound("click")

func attack(direction: Vector2) -> void:
	if build_id == "" or attack_cooldown > 0 or dash_left > 0 or direction == Vector2.ZERO:
		return
	set_facing(direction)
	attack_cooldown = 0.38 if build_id == "arc" else 0.42
	attack_windup = 0.05 if build_id == "arc" else 0.025
	attack_direction = direction

func release_attack() -> void:
	set_facing(attack_direction)
	attack_age = 0.0
	attack_origin = player.round() - Vector2(0, 10)
	attack_result = "miss"
	var to_core := CORE - player
	var reach := 54.0 if build_id == "arc" else 108.0
	var aim := 0.58 if build_id == "arc" else 0.90
	attack_distance = reach
	if room != "press" or boss_hp == 0 or to_core.length() > reach or attack_direction.dot(to_core.normalized()) < aim:
		play_sound(build_id + "_miss")
		return
	if build_id == "probe":
		var contact := CORE - Vector2(0, 10) - attack_origin
		attack_direction = contact.normalized()
		attack_distance = contact.length()
	if boss_phase != "open":
		attack_result = "guard"
		play_sound("guard")
		notify(GUARD_NOTICE, 1.2)
		return
	attack_result = "hit"
	boss_hp = maxi(0, boss_hp - (8 if build_id == "arc" else 4))
	if boss_hp == 0:
		boss_phase = "offline"
		play_sound("break")
		notify("压力机停下了。检查右侧日志终端。", 3.2)
	else:
		play_sound(build_id + "_hit")

func tick_boss(dt: float) -> void:
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
				play_sound("hit")
			"strike":
				boss_phase = "open"
				boss_time = 1.07
				if message == GUARD_NOTICE:
					message = ""
			"open":
				boss_phase = "idle"
				boss_time = 0.68
	if boss_phase == "strike" and not strike_hit and hazard.has_point(player) and dash_left <= 0:
		strike_hit = true
		hp = maxi(0, hp - 2)
		hurt_flash = 0.16
		play_sound("hit")
		if hp == 0:
			play_sound("stop")
			set_screen("failed")

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
				notify("红框预警。空格闪避，J 或左键出手。", 4)
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
	if room != "press" or boss_hp == 0:
		return ""
	var state := "护板闭合"
	match boss_phase:
		"warn", "strike": state = "▲  落点锁定"
		"open": state = "◇  护板打开"
	return "压力机  %02d / 24   %s" % [boss_hp, state]
