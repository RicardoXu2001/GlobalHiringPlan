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
const EXP_FX: SpriteFrames = preload("res://art/expedition/effects.tres")
const HEART = preload("res://art/expedition/heart.png")
const EXP_ROOMS = [preload("res://art/expedition/field0.png"), preload("res://art/expedition/field1.png"), preload("res://art/expedition/field2.png")]
const HUB = preload("res://art/expedition/hub.png")
const BIO_BOSS = preload("res://art/expedition/boss.png")
const PREVIEW = preload("res://art/expedition/preview.png")
const CREATURES = {"husk": preload("res://art/expedition/husk.png"), "worker": preload("res://art/expedition/worker.png"), "sentinel": preload("res://art/expedition/sentinel.png")}
const WEAPONS = {"arc": preload("res://art/expedition/weapon-arc.png"), "probe": preload("res://art/expedition/weapon-probe.png"), "nailer": preload("res://art/expedition/weapon-nailer.png")}

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
		"hub":
			draw_texture(HUB, Vector2.ZERO)
			terminal(game.SHOP, true, CYAN)
			terminal(game.DEPART, true, AMBER)
			terminal(game.GRAFT, game.organ, CYAN)
			if game.integrated:
				var pulse := 1 if game.heartbeat_left > 0.7 and not game.reduced_motion else 0
				draw_texture_rect(HEART, Rect2(297 - pulse, 60 - pulse, 48 + pulse * 2, 48 + pulse * 2), false)
				halo(Vector2(320, 85), 9, RED)
			if game.graft_age >= 0 and game.graft_age < 1.4:
				expedition_effect(&"organ_collect", game.graft_age, game.GRAFT)
		"field":
			draw_texture(PREVIEW if game.stage == 5 else EXP_ROOMS[game.stage], Vector2.ZERO)
			field_enemies()
			gate(500, game.cleared)
			if game.cleared: bracket(game.EXIT, AMBER)
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
			draw_texture(BIO_BOSS if game.campaign else HALL, Vector2.ZERO)
			if game.hp > 0 and game.boss_phase in ["warn", "strike"]:
				var opacity := 0.34 if game.boss_phase == "strike" else 0.13
				draw_rect(game.hazard, Color(RED, opacity))
			boss_attack()
			press()
			if game.campaign and game.boss_hp == 0:
				gate(500, true)
				bracket(game.EXIT, AMBER)
			elif game.boss_hp == 0:
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
	if game.screen in ["dying", "failed"]:
		draw_downed()
		return
	if game.hint_pos != Vector2.ZERO:
		bracket(game.hint_pos, CYAN)
	if game.attack_age >= 0:
		attack()
	if game.campaign:
		for fx in game.effects:
			expedition_effect(fx.id, fx.age, fx.p)
		# Draw danger boundaries after decorative particles, before the player.
		for e in game.enemies:
			if e.hp > 0 and e.phase in ["warn", "strike"]:
				draw_rect(e.zone.grow(1), INK, false, 3)
				draw_rect(e.zone, RED, false, 2)
				draw_line(e.zone.position + Vector2(4, 4), e.zone.end - Vector2(4, 4), RED, 1)
	if room == "press" and game.boss_phase in ["warn", "strike"]:
		hazard()
	if game.dash_left > 0 and not game.reduced_motion:
		for i in game.dash_trail.size():
			var ghost: Vector2 = game.dash_trail[i]
			draw_texture_rect_region(WORKER, Rect2(ghost - Vector2(16, 42), Vector2(32, 44)),
				Rect2(0, game.face_index * 48, 32, 48), Color(CYAN, 0.05 + i * 0.04))
	if game.dash_age >= 0 and not game.reduced_motion:
		draw_effect(&"dash", game.dash_age, game.player - Vector2(0, 8),
			game.dash_dir.angle(), Vector2(60, 24))
	if game.evade_flash > 0:
		if not game.reduced_motion:
			draw_effect(&"evade", 0.35 - game.evade_flash, game.evade_point, 0, Vector2(32, 24))
		else:
			draw_rect(Rect2(game.player - Vector2(14, 36), Vector2(28, 37)), CYAN, false, 1)
	var pose: int = int(game.walk_clock * 10.0) % 6 if game.moving else 0
	var p: Vector2 = game.player.round()
	var dir: Vector2 = game.facing
	var acting: bool = game.attack_windup > 0 or (game.attack_age >= 0 and game.attack_age < 0.16)
	var body_offset := Vector2.ZERO
	if game.hurt_age >= 0 and not game.reduced_motion:
		pose = 2
		var settle: float = 1.0 - clampf((game.hurt_age - 0.05) / 0.22, 0, 1)
		body_offset = game.hurt_direction * 6.0 * settle + Vector2(0, 2)
	elif game.dash_left > 0 and not game.reduced_motion:
		pose = 2
		body_offset = Vector2(0, 3) + game.dash_dir * 3
	elif acting and not game.reduced_motion:
		dir = game.attack_direction
		var kick := -2.0 if game.build_id == "probe" else 3.0
		body_offset = dir * (-2.0 if game.attack_windup > 0 else kick * (1.0 - maxf(0, game.attack_age - 0.05) / 0.16))
		pose = 0
	if dir.y < -0.7:
		draw_weapon(p + body_offset, dir, acting)
	draw_worker((p + body_offset).round(), game.face_index, pose, game.hurt_flash > 0, p)
	if dir.y >= -0.7:
		draw_weapon(p + body_offset, dir, acting)
	if game.hurt_age >= 0:
		if not game.reduced_motion:
			draw_effect(&"player_hurt", game.hurt_age, p + body_offset - Vector2(0, 22),
				game.hurt_direction.angle(), Vector2(32, 32))

func draw_downed() -> void:
	var age: float = game.death_age
	var p: Vector2 = game.player.round()
	var side: float = game.death_side
	var turn := clampf((age - 0.10) / 0.24, 0, 1)
	turn = turn * turn * (3 - 2 * turn)
	if game.reduced_motion:
		turn = 1.0 if age >= 0.16 else 0.0
	var shade := Color.WHITE.lerp(Color(0.42, 0.48, 0.52), clampf((age - 0.35) / 0.4, 0, 1))
	block(p.x - 12, p.y - 2, 24, 5, INK)
	if turn > 0.5:
		draw_line(p, p + Vector2(side * 38, 0), INK, 9)
	draw_set_transform(p + Vector2(side * turn * 2, 0), side * PI * 0.5 * turn)
	draw_texture_rect_region(WORKER, Rect2(-16, -44, 32, 48),
		Rect2(0, game.face_index * 48, 32, 48), shade)
	draw_set_transform(Vector2.ZERO)
	if age < 0.2 and not game.reduced_motion:
		draw_effect(&"player_hurt", age, p - Vector2(0, 22), 0, Vector2(32, 32))
	if age >= 0.32:
		var landing := p + Vector2(side * 20, 0)
		if not game.reduced_motion:
			draw_effect(&"collapse", age - 0.32, landing, 0, Vector2(48, 24))
		draw_set_transform(p + Vector2(-side * 15, 4), side * 0.35)
		draw_texture(WEAPONS[game.build_id] if game.campaign else (CUTTER if game.build_id == "arc" else RANGEFINDER), Vector2(-12, -12), shade)
		draw_set_transform(Vector2.ZERO)

func boss_attack() -> void:
	if game.hp <= 0:
		return
	var r: Rect2 = game.hazard
	if game.boss_phase == "warn":
		var progress: float = 1.0 - game.boss_time / 0.85
		var inset := 3.0 + 15.0 * (1.0 - progress)
		draw_rect(r.grow(-inset), Color(RED, 0.5), false, 1)
		for side in [-1, 1]:
			var y: float = game.CORE.y - 49 - 6 * progress
			block(game.CORE.x + side * 35 - 2, y, 4, 8, RED)
	if game.boss_fx_age < 0:
		return
	if game.reduced_motion:
		if game.boss_phase == "strike":
			draw_line(r.position + Vector2(4, 4), r.end - Vector2(4, 4), MIST, 2)
		return
	if r.size.x > 100:
		draw_effect(&"boss_sweep", game.boss_fx_age, r.get_center(), 0, Vector2(120, 56))
	else:
		draw_effect(&"boss_slam", game.boss_fx_age, r.get_center(), 0, Vector2(40, 96))

func draw_worker(p: Vector2, direction: int, pose: int, hit: bool, feet := Vector2.INF) -> void:
	var anchor := p if feet == Vector2.INF else feet
	block(anchor.x - 12, anchor.y - 2, 24, 5, INK)
	halo(p + Vector2(-4, -22), 6, CYAN)
	draw_texture_rect_region(WORKER, Rect2(p - Vector2(16, 44), Vector2(32, 48)),
		Rect2(pose * 32, direction * 48, 32, 48),
		Color(1.4, 0.55, 0.6) if hit and not game.reduced_motion else Color.WHITE)
	if hit and game.reduced_motion:
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
	if game.campaign:
		draw_texture(WEAPONS[game.build_id], Vector2(-12, -16))
	else:
		draw_texture(CUTTER if arc else RANGEFINDER, Vector2(-7, -12))
	draw_set_transform(Vector2.ZERO)

func press() -> void:
	var p: Vector2 = game.CORE
	var lift := 0
	if game.boss_phase == "warn" and not game.reduced_motion:
		lift = roundi(3 + 5 * (1.0 - game.boss_time / 0.85))
	elif game.boss_phase == "open":
		lift = 5
	elif game.boss_phase == "strike":
		lift = -4
	block(p.x - 40, p.y - 2, 80, 8, INK)
	var recoil := Vector2.ZERO
	if not game.reduced_motion and game.boss_hurt_age >= 0 and game.boss_hurt_age < 0.20:
		var settle: float = 1.0 - clampf((game.boss_hurt_age - 0.045) / 0.15, 0, 1)
		recoil = (game.boss_hurt_direction * 4.0 * settle).round()
	var tint := Color(0.66, 0.68, 0.72) if game.boss_hp == 0 else Color.WHITE
	if not game.reduced_motion and game.boss_hurt_age >= 0 and game.boss_hurt_age < 0.067:
		tint = Color(1.5, 1.5, 1.4)
	draw_texture(PRESS, p - Vector2(48, 84 + lift) + recoil,
		tint)
	if game.campaign:
		for side in [-1, 1]:
			var elbow := p + Vector2(side * 65, -30 - lift)
			draw_line(p + Vector2(side * 36, -54), elbow, INK, 10)
			draw_line(p + Vector2(side * 36, -54), elbow, SLATE, 6)
			draw_line(elbow, p + Vector2(side * 75, -2), STEEL, 9)
			block(p.x + side * 75 - 12, p.y - 10, 24, 13, SLATE)
		draw_texture_rect(HEART, Rect2(p - Vector2(24, 69 + lift) + recoil, Vector2(48, 48)), false, tint)
	if game.boss_hp <= 16:
		draw_polyline(PackedVector2Array([p + Vector2(-22, -47), p + Vector2(-25, -37),
			p + Vector2(-20, -30), p + Vector2(-23, -19)]), MIST, 1)
	if game.boss_hp <= 8:
		draw_polyline(PackedVector2Array([p + Vector2(22, -40), p + Vector2(17, -31),
			p + Vector2(21, -24), p + Vector2(17, -14)]), MIST, 1)
	if game.boss_hurt_age >= 0:
		if game.reduced_motion:
			draw_rect(Rect2(p - Vector2(14, 32), Vector2(28, 23)), BONE, false, 2)
		else:
			draw_effect(&"boss_hurt", game.boss_hurt_age, p - Vector2(0, 20),
				game.boss_hurt_direction.angle(), Vector2(48, 40))
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
	var probe: bool = game.build_id != "arc"
	var age: float = game.attack_age
	var impact: Vector2 = game.attack_contact
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
		if game.campaign and game.build_id == "nailer" and age < 0.07:
			draw_line(p, p + dir * game.attack_distance, BONE, 1)
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

func field_enemies() -> void:
	for e in game.enemies:
		if e.hp <= 0 and e.dead > 0.5: continue
		var p: Vector2 = e.p.round()
		block(p.x - 15, p.y - 2, 30, 4, INK)
		var frame := 1 if e.phase == "warn" else 2 if e.phase == "strike" else int(game.walk_clock * 7) % 2
		var tint := Color(1.5, 1.0, 1.0) if e.hurt > 0 else Color.WHITE
		if e.hp <= 0: tint = Color(0.45, 0.45, 0.5, 1.0 - float(e.dead) / 0.5)
		draw_set_transform(p, 0, Vector2(-1 if e.dir.x < -0.3 else 1, 1))
		draw_texture_rect_region(CREATURES[e.kind], Rect2(-32, -56, 64, 64), Rect2(frame * 64, 0, 64, 64), tint)
		draw_set_transform(Vector2.ZERO)
		if e.hp > 0:
			if e.kind == "sentinel" and e.phase == "recover":
				block(p.x - 5, p.y - 34, 10, 3, CYAN)
			block(p.x - 12, p.y - 59, 24, 3, INK)
			block(p.x - 12, p.y - 59, 24 * float(e.hp) / (12 if e.kind == "sentinel" else 8), 2, RED)

func expedition_effect(id: StringName, age: float, p: Vector2) -> void:
	if game.reduced_motion:
		if age < 0.16: draw_rect(Rect2(p - Vector2(8, 15), Vector2(16, 12)), CYAN if id == &"organ_collect" else BONE, false, 1)
		return
	var frame := floori(age * EXP_FX.get_animation_speed(id))
	if frame >= EXP_FX.get_frame_count(id): return
	var pivot := Vector2(56, 94) if id == &"organ_collect" else Vector2(44, 64)
	draw_set_transform(p.round(), 0, Vector2(0.5, 0.5))
	draw_texture(EXP_FX.get_frame_texture(id, frame), -pivot)
	draw_set_transform(Vector2.ZERO)
