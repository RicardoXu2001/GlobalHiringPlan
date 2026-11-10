extends Node2D

const INK = Color("#07141f")
const NIGHT = Color("#102738")
const STEEL = Color("#244454")
const SLATE = Color("#49616b")
const MIST = Color("#829499")
const BONE = Color("#dfe8d5")
const TEAL = Color("#237c83")
const CYAN = Color("#57e4ce")
const AMBER = Color("#ffc46b")
const RED = Color("#ff526d")
const VIOLET = Color("#a58adc")
const INTAKE = preload("res://art/intake.png")
const RETURN = preload("res://art/intake-return.png")
const HALL = preload("res://art/press-hall.png")
const BYPASS = preload("res://art/bypass.png")
const WORKER = preload("res://art/worker.png")
const PRESS = preload("res://art/press.png")
const CUTTER = preload("res://art/combat/cutter.png")
const RANGEFINDER = preload("res://art/combat/rangefinder.png")
const COMBAT_FX: SpriteFrames = preload("res://art/combat/effects.tres")

var game
var light: GradientTexture2D

func _ready() -> void:
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	light = GradientTexture2D.new()
	light.gradient = ramp
	light.width = 64
	light.height = 64
	light.fill = GradientTexture2D.FILL_RADIAL
	light.fill_from = Vector2(0.5, 0.5)
	light.fill_to = Vector2(1, 0.5)

func block(x: float, y: float, w: float, h: float, color: Color, solid := true) -> void:
	draw_rect(Rect2(x, y, w, h), color, solid)

func halo(p: Vector2, radius: int, color: Color) -> void:
	if not game.reduced_motion:
		draw_texture_rect(light, Rect2(p - Vector2.ONE * radius, Vector2.ONE * radius * 2),
			false, Color(color, 0.18))

func floor_light(p: Vector2, spread: int, color: Color) -> void:
	for i in range(3):
		var w := spread - i * 6
		var y := 10 - i * 3
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(-w + 7, -y), p + Vector2(w - 7, -y),
			p + Vector2(w, y), p + Vector2(-w, y)
		]), Color(color, 0.035))

func gate(x: int, opened: bool) -> void:
	block(x - 24, 96, 49, 43, INK)
	if not opened:
		for row in range(5):
			block(x - 23, 98 + row * 7, 47, 6, STEEL)
			block(x - 19, 98 + row * 7, 39, 1, SLATE)
		block(x - 5, 112, 11, 8, NIGHT)
		block(x - 2, 114, 5, 4, MIST)
	else:
		block(x - 20, 134, 41, 4, SLATE)
		for side in [-1, 1]:
			var p := Vector2(x + side * 32, 118)
			halo(p, 6, AMBER)
			block(p.x - 1, p.y - 5, 3, 10, AMBER)
		floor_light(Vector2(x, 146), 39, AMBER)

func terminal(p: Vector2, active: bool, color: Color) -> void:
	block(p.x - 13, p.y - 3, 27, 7, INK)
	block(p.x - 10, p.y - 23, 21, 22, NIGHT)
	block(p.x - 8, p.y - 20, 17, 16, STEEL)
	block(p.x - 7, p.y - 19, 15, 9, INK)
	block(p.x - 6, p.y - 18, 13, 6, TEAL if active else SLATE)
	if active:
		floor_light(p + Vector2(0, 7), 32, color)
		halo(p + Vector2(0, -16), 6, color)
		block(p.x - 4, p.y - 17, 8, 2, color)
	block(p.x - 6, p.y - 7, 8, 2, MIST)
	block(p.x + 5, p.y - 7, 2, 2, color if active else MIST)

func bracket(p: Vector2, color: Color) -> void:
	for side in [-1, 1]:
		var corner := p + Vector2(side * 14, -26)
		draw_polyline(PackedVector2Array([corner + Vector2(-side * 5, 0), corner,
			corner + Vector2(0, 16), corner + Vector2(-side * 5, 16)]), color, 1)

func _draw() -> void:
	if game == null:
		return
	var room: String = game.room
	var title: bool = game.screen == "title"
	if title:
		room = "bypass"
	match room:
		"intake":
			draw_texture(RETURN if game.cycle > 1 else INTAKE, Vector2.ZERO)
			gate(171, game.cycle > 1)
			gate(463, game.build_id != "")
			var route: Array[Vector2] = [Vector2(320, 228), Vector2(320, 202), Vector2(320, 174)]
			if game.cycle > 1:
				route = [Vector2(276, 230), Vector2(245, 207), Vector2(211, 181), Vector2(175, 157)]
			elif game.build_id != "":
				route = [Vector2(351, 207), Vector2(393, 189), Vector2(432, 167), Vector2(463, 150)]
			for p in route:
				halo(p, 6, AMBER)
				block(p.x - 7, p.y, 4, 2, AMBER)
				block(p.x + 4, p.y, 4, 2, AMBER)
			terminal(game.TERMINAL, game.cycle == 1, CYAN)
		"press":
			draw_texture(HALL, Vector2.ZERO)
			if game.boss_phase in ["warn", "strike"]:
				var opacity := 0.34 if game.boss_phase == "strike" else 0.13
				draw_rect(game.hazard, Color(RED, opacity))
			press()
			if game.boss_hp == 0:
				terminal(game.LOG_POINT, not game.log_read, CYAN)
		"bypass":
			draw_texture(BYPASS, Vector2.ZERO)
			terminal(Vector2(320, 173), true, CYAN)
			for x in [268, 300, 340, 372]:
				halo(Vector2(x, 97), 6, VIOLET)
	if title:
		draw_texture(PRESS, Vector2(347, 98))
		draw_worker(Vector2(412, 256), 0, 0, false)
		return
	if game.hint_pos != Vector2.ZERO:
		bracket(game.hint_pos, CYAN)
	if game.attack_age >= 0:
		attack()
	if room == "press" and game.boss_phase in ["warn", "strike"]:
		hazard()
	if game.dash_left > 0 and not game.reduced_motion:
		block(game.player.x - game.dash_dir.x * 13 - 7, game.player.y - 8, 14, 2, TEAL)
	var pose: int = int(game.walk_clock * 10.0) % 6 if game.moving else 0
	var p: Vector2 = game.player.round()
	var dir: Vector2 = game.facing
	var acting: bool = game.attack_windup > 0 or (game.attack_age >= 0 and game.attack_age < 0.16)
	var body_offset := Vector2.ZERO
	if acting and not game.reduced_motion:
		dir = game.attack_direction
		var kick := -2.0 if game.build_id == "probe" else 3.0
		body_offset = dir * (-2.0 if game.attack_windup > 0 else kick * (1.0 - maxf(0, game.attack_age - 0.05) / 0.16))
		pose = 0
	if dir.y < -0.7:
		draw_weapon(p + body_offset, dir, acting)
	draw_worker((p + body_offset).round(), game.face_index, pose, game.hurt_flash > 0, p)
	if dir.y >= -0.7:
		draw_weapon(p + body_offset, dir, acting)

func draw_worker(p: Vector2, direction: int, pose: int, hit: bool, feet := Vector2.INF) -> void:
	var anchor := p if feet == Vector2.INF else feet
	block(anchor.x - 12, anchor.y - 2, 24, 5, INK)
	halo(p + Vector2(-4, -22), 6, CYAN)
	draw_texture_rect_region(WORKER, Rect2(p - Vector2(16, 44), Vector2(32, 48)),
		Rect2(pose * 32, direction * 48, 32, 48))
	if hit:
		draw_rect(Rect2(p.x - 13, p.y - 36, 26, 38), RED, false, 1)

func draw_weapon(p: Vector2, dir: Vector2, acting: bool) -> void:
	if game.build_id == "":
		return
	var arc: bool = game.build_id == "arc"
	var angle := dir.angle()
	if not game.reduced_motion and acting and arc:
		if game.attack_windup > 0:
			angle -= 1.05
		elif game.attack_age < 0.16:
			angle += lerpf(-0.45, 0.96, minf(1, game.attack_age / 0.07))
	var grip := (p + Vector2(0, -14) + dir * 12).round()
	draw_set_transform(grip, angle)
	draw_texture(CUTTER if arc else RANGEFINDER, Vector2(-7, -12))
	draw_set_transform(Vector2.ZERO)

func press() -> void:
	var p: Vector2 = game.CORE
	var lift := 0
	if game.boss_phase == "open":
		lift = 5
	elif game.boss_phase == "strike":
		lift = -4
	block(p.x - 40, p.y - 2, 80, 8, INK)
	var recoil := Vector2.ZERO
	if not game.reduced_motion and game.attack_result == "hit" and game.attack_age >= 0 and game.attack_age < 0.12:
		recoil = (game.attack_direction * 3.0 * (1.0 - game.attack_age / 0.12)).round()
	draw_texture(PRESS, p - Vector2(48, 84 + lift) + recoil,
		Color(0.66, 0.68, 0.72) if game.boss_hp == 0 else Color.WHITE)
	if game.boss_hp == 0:
		return
	var lamp := RED if game.boss_phase in ["warn", "strike"] else (CYAN if lift == 5 else TEAL)
	var eye := p - Vector2(0, 22 + lift)
	halo(eye, 9, lamp)
	block(eye.x - 11, eye.y - 2, 22, 4, lamp)
	if lift == 5:
		block(p.x - 9, p.y - 10, 18, 5, CYAN)
		block(p.x - 3, p.y - 9, 6, 2, BONE)

func hazard() -> void:
	var r: Rect2 = game.hazard
	draw_rect(r.grow(1), INK, false, 3)
	draw_rect(r, RED, false, 2)
	for i in range(int(r.position.x + 7), int(r.end.x - 8), 11):
		var a := Vector2(i, r.end.y - 3)
		draw_line(a, a + Vector2(6, -6), RED, 1)
	var center := r.get_center().round()
	draw_polyline(PackedVector2Array([center + Vector2(-5, 4), center + Vector2(0, -5),
		center + Vector2(5, 4), center + Vector2(-5, 4)]), RED, 1)

func attack() -> void:
	var p: Vector2 = game.attack_origin
	var dir: Vector2 = game.attack_direction
	var probe: bool = game.build_id == "probe"
	var age: float = game.attack_age
	var impact: Vector2 = game.CORE - Vector2(0, 10)
	if game.reduced_motion:
		if age < 0.11:
			if probe:
				draw_line(p, (p + dir * game.attack_distance).round(), TEAL, 2)
			else:
				var blade := PackedVector2Array()
				for a in [-0.95, -0.48, 0.0, 0.48, 0.95]:
					blade.append((p + dir.rotated(a) * 50).round())
				draw_polyline(blade, MIST, 2)
		if game.attack_result != "miss" and age < 0.17:
			draw_rect(Rect2(impact - Vector2(5, 4), Vector2(10, 8)),
				BONE if game.attack_result == "hit" else SLATE, false, 2)
		return
	if probe:
		draw_effect(&"pulse", age, p, dir.angle(), Vector2(12, 12),
			Vector2(game.attack_distance / 108.0, 1.0))
	else:
		draw_effect(&"sweep", age, p, dir.angle(), Vector2(64, 64))
	if game.attack_result == "guard":
		draw_effect(&"guard", age, impact, dir.angle(), Vector2(32, 32))
	elif game.attack_result == "hit":
		draw_effect(&"probe_hit" if probe else &"arc_hit", age, impact, dir.angle(), Vector2(32, 32))

func draw_effect(id: StringName, age: float, p: Vector2, angle: float, pivot: Vector2,
		stretch := Vector2.ONE) -> void:
	var frame := floori(age * COMBAT_FX.get_animation_speed(id))
	if frame >= COMBAT_FX.get_frame_count(id):
		return
	var forward := Vector2.from_angle(angle)
	var sideways := Vector2(-forward.y, forward.x)
	draw_set_transform_matrix(Transform2D(forward * stretch.x, sideways * stretch.y, p.round()))
	draw_texture(COMBAT_FX.get_frame_texture(id, frame), -pivot)
	draw_set_transform(Vector2.ZERO)
