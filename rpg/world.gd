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
const SOOT = Color("#493b37")
const BRASS = Color("#897451")
const FLESH = Color("#492c42")
const ROSE = Color("#9c626c")
const THREAT := Color("#f59479")
const RAKE := Color("#ee819d")
const COMBAT_FX: SpriteFrames = preload("res://art/combat/effects.tres")
const EXP_FX: SpriteFrames = preload("res://art/expedition/effects.tres")
const ImpactField = preload("res://impact_field.gd")
const HERO_FRAMES: SpriteFrames = preload("res://art/modular/09.tres")
const ENEMY_FRAMES = {"husk": preload("res://art/modular/husk.tres"), "worker": preload("res://art/modular/worker.tres"), "sentinel": preload("res://art/modular/sentinel.tres")}
const MODULES = {
	"floor": preload("res://art/modular/floor.tres"), "hatch": preload("res://art/modular/hatch.tres"),
	"wall-open": preload("res://art/modular/wall-open.tres"), "wall-vent": preload("res://art/modular/wall-vent.tres"),
	"column": preload("res://art/modular/column.tres"), "conduit": preload("res://art/modular/conduit.tres"),
	"elbow": preload("res://art/modular/elbow.tres"), "rail": preload("res://art/modular/rail.tres"),
	"armor": preload("res://art/modular/armor.tres"), "piston": preload("res://art/modular/piston.tres"),
	"heart-cage": preload("res://art/modular/heart-cage.tres"), "lamp": preload("res://art/modular/lamp.tres")}
const WEAPONS = {"arc": preload("res://art/painted/arc.tres"), "probe": preload("res://art/painted/probe.tres"), "nailer": preload("res://art/painted/nailer.tres")}
const FLOOR_BOUNDS := Rect2(112, 135, 416, 159)
const FOOT_RADIUS := 5.0

var game
var clock := 0.0
var shade := Color.WHITE
var doors: Dictionary = {}
var light: GradientTexture2D
# Each module owns a location, a draw recipe and a depth; no room-sized bitmap.
var wall_modules: Array[Dictionary] = []
var hero_metadata: Dictionary
var enemy_metadata: Dictionary
var feedback := ImpactField.new()
var fixtures: Array[Dictionary] = []
var fixture_contact := Vector2.ZERO

func _ready() -> void:
	hero_metadata = JSON.parse_string(FileAccess.get_file_as_string("res://art/modular/09.json"))
	enemy_metadata = JSON.parse_string(FileAccess.get_file_as_string("res://art/modular/creatures.json"))
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	light = GradientTexture2D.new()
	light.gradient = ramp
	light.width = 32
	light.height = 32
	light.fill = GradientTexture2D.FILL_RADIAL
	light.fill_from = Vector2(0.5, 0.5)
	light.fill_to = Vector2(1, 0.5)
	for x in range(104, 537, 48):
		wall_modules.append({"kind": "wall", "p": Vector2(x, 72), "size": Vector2(46, 60)})
	for x in [84, 540]:
		wall_modules.append({"kind": "column", "p": Vector2(x, 106), "size": Vector2(18, 194)})

func _physics_process(dt: float) -> void:
	if game == null: return
	update_feedback_settings()
	position = feedback.camera_offset(dt, game.screen in ["play", "dying"]) * 2
	if game.screen in ["play", "dying"]: feedback.step(dt)
	if game.screen in ["play", "title"]:
		clock += dt
		for fixture in fixtures:
			if fixture.hp > 0 and fixture.fuse >= 0:
				fixture.fuse -= dt
				if fixture.fuse <= 0: break_fixture(fixture)
		for key in doors:
			doors[key].amount = move_toward(float(doors[key].amount), float(doors[key].target), dt * 5)

func reset_feedback(room: String) -> void:
	feedback.reset()
	position = Vector2.ZERO
	fixtures.clear()
	doors.clear()
	if room in ["field", "press"]:
		for p in [Vector2(144, 244), Vector2(181, 244)]:
			fixtures.append({"p": p, "hp": 1, "fuse": -1.0})

func room_props() -> Array[Dictionary]:
	match game.room:
		"hub":
			return [{"kind": "shop", "p": game.SHOP}, {"kind": "graft", "p": game.GRAFT, "filled": game.integrated},
				{"kind": "gate", "p": game.DEPART, "opened": game.stage != 4 or game.integrated}]
		"intake":
			return [{"kind": "terminal", "p": game.TERMINAL, "active": game.cycle == 1},
				{"kind": "gate", "p": game.BYPASS_GATE, "opened": game.cycle > 1},
				{"kind": "gate", "p": game.PRESS_GATE, "opened": game.build_id != ""}]
		"field":
			return [{"kind": "gate", "p": Vector2(game.EXIT.x, 139), "opened": game.cleared}]
		"press":
			var props: Array[Dictionary] = [{"kind": "boss", "p": game.CORE}]
			if game.boss_hp == 0:
				if game.campaign: props.append({"kind": "gate", "p": Vector2(game.EXIT.x, 139), "opened": true})
				else: props.append({"kind": "terminal", "p": game.LOG_POINT, "active": not game.log_read})
			return props
		"bypass":
			return [{"kind": "terminal", "p": game.SUPPLY, "active": true}]
	return []

func floor_blockers() -> Array[Rect2]:
	var boxes: Array[Rect2] = []
	for prop in room_props():
		var p: Vector2 = prop.p
		match prop.kind:
			"gate":
				var slide := door_slide(p, prop.opened)
				for side in [-1, 1]:
					boxes.append(Rect2(p + Vector2(side * 10 + side * slide - 10, -7), Vector2(20 - slide * 0.55, 8)))
					boxes.append(Rect2(p + Vector2(side * 25 - 4, -9), Vector2(8, 12)))
			"shop": boxes.append(Rect2(p + Vector2(-25, -11), Vector2(50, 11)))
			"terminal": boxes.append(Rect2(p + Vector2(-8, -12), Vector2(16, 12)))
			"graft": boxes.append(Rect2(p + Vector2(-51, -18), Vector2(102, 18)))
			"boss": boxes.append(Rect2(p + Vector2(-46, -52), Vector2(92, 56)))
	for fixture in fixtures:
		if fixture.hp > 0: boxes.append(Rect2(fixture.p - Vector2(6, 9), Vector2(12, 9)))
	return boxes

func slide_on_floor(from: Vector2, delta: Vector2, radius := FOOT_RADIUS) -> Vector2:
	if delta == Vector2.ZERO: return from
	var boxes := floor_blockers()
	var position_on_floor := from
	for axis in 2:
		if delta[axis] == 0.0: continue
		var side := 1 - axis
		var start := position_on_floor[axis]
		var stop := clampf(start + delta[axis], FLOOR_BOUNDS.position[axis], FLOOR_BOUNDS.end[axis])
		for box in boxes:
			var expanded := box.grow(radius)
			if position_on_floor[side] <= expanded.position[side] or position_on_floor[side] >= expanded.end[side]:
				continue
			if stop > start and start <= expanded.position[axis]: stop = minf(stop, expanded.position[axis])
			elif stop < start and start >= expanded.end[axis]: stop = maxf(stop, expanded.end[axis])
		position_on_floor[axis] = stop
	return position_on_floor

func update_feedback_settings() -> void:
	feedback.reduced = game.reduced_motion
	feedback.shake_strength = game.shake_strength
	feedback.reduce_flash = game.reduce_flash

func impact(point: Vector2, direction: Vector2, material: String, tier := "hit") -> void:
	update_feedback_settings()
	feedback.burst(point, direction, material, tier)

func break_fixture(fixture: Dictionary) -> void:
	if fixture.hp <= 0: return
	fixture.hp = 0
	fixture.fuse = -1.0
	impact(fixture.p - Vector2(0, 13), Vector2.UP, "coolant", "coolant")
	game.play_sound("break")
	for other in fixtures:
		if other.hp > 0 and other.fuse < 0 and fixture.p.distance_to(other.p) <= 44: other.fuse = 0.12

func strike_fixtures(origin: Vector2, direction: Vector2, reach: float, weapon: String) -> bool:
	var hit := false
	var ordered := fixtures.duplicate()
	ordered.sort_custom(func(a, b): return origin.distance_squared_to(a.p) < origin.distance_squared_to(b.p))
	for fixture in ordered:
		if fixture.hp <= 0: continue
		var to: Vector2 = fixture.p - origin
		if to.length() <= reach and to.normalized().dot(direction) >= (0.5 if weapon == "arc" else 0.94):
			fixture_contact = fixture.p - Vector2(0, 13)
			break_fixture(fixture)
			hit = true
			if weapon == "nailer": break
	return hit

func wall_distance(origin: Vector2, direction: Vector2, reach: float) -> float:
	var result := reach
	for axis in 2:
		if absf(direction[axis]) < 0.001: continue
		var edge: float = (106 if direction.x < 0 else 536) if axis == 0 else (132 if direction.y < 0 else 298)
		var travel: float = (edge - origin[axis]) / direction[axis]
		if travel <= 0 and (origin[axis] - edge) * direction[axis] >= 0: return 0.0
		if travel > 0: result = minf(result, travel)
	return result

func fixture_hint() -> String:
	for fixture in fixtures:
		if fixture.hp > 0 and game.player.distance_to(fixture.p) < 30: return "冷却罐 · 攻击可击碎"
	return ""

func coolant_can(fixture: Dictionary) -> void:
	var p: Vector2 = fixture.p
	if fixture.hp <= 0:
		panel(Rect2(p + Vector2(-6, -3), Vector2(12, 3)), NIGHT)
		stroke([p + Vector2(-4, -4), p + Vector2(-2, -7), p + Vector2(2, -3)], SLATE)
		return
	shadow(p, 8)
	panel(Rect2(p + Vector2(-6, -24), Vector2(12, 23)), SLATE)
	rect(Rect2(p + Vector2(-3, -20), Vector2(6, 13)), NIGHT)
	for y in range(-18, -7, 3): rect(Rect2(p + Vector2(-2, y), Vector2(4, 1)), CYAN)
	panel(Rect2(p + Vector2(-3, -28), Vector2(6, 4)), BRASS)
	stroke([p + Vector2(-5, -3), p + Vector2(5, -3)], MIST)

func rect(box: Rect2, color: Color) -> void:
	draw_rect(Rect2(box.position.snapped(Vector2(0.5, 0.5)), box.size), color * shade)

func block(x: float, y: float, w: float, h: float, color: Color, solid := true) -> void:
	draw_rect(Rect2(x, y, w, h), color * shade, solid)

func stroke(points: Array, color: Color, width := 1.0) -> void:
	var path := PackedVector2Array()
	for p in points: path.append(Vector2(p).snapped(Vector2(0.5, 0.5)))
	draw_polyline(path, color * shade, width, false)

func shape(points: Array, color: Color, outline := false) -> void:
	var path := PackedVector2Array()
	for p in points: path.append(Vector2(p).snapped(Vector2(0.5, 0.5)))
	draw_colored_polygon(path, color * shade)
	if outline:
		path.append(path[0])
		draw_polyline(path, INK * shade, 1, false)

func panel(box: Rect2, color := STEEL) -> void:
	var p := box.position
	var s := box.size
	if s.x < 9 or s.y < 9:
		rect(box, color)
		stroke([p + Vector2(0, s.y), p, p + Vector2(s.x, 0)], MIST, 0.5)
		stroke([p + Vector2(s.x, 1), p + s, p + Vector2(1, s.y)], NIGHT, 0.5)
		return
	rect(box, INK)
	shape([p + Vector2(0, 4), p + Vector2(4, 0), p + Vector2(s.x - 3, 0),
		p + Vector2(s.x, 3), p + s, p + Vector2(0, s.y)], color)
	stroke([p + Vector2(2, 5), p + Vector2(5, 2), p + Vector2(s.x - 4, 2)], MIST, 0.5)
	stroke([p + Vector2(s.x - 2, 5), p + s - Vector2(2, 2), p + Vector2(3, s.y - 2)], NIGHT, 2)
	for b in [p + Vector2(5, 6), p + s - Vector2(6, 6)]:
		rect(Rect2(b - Vector2.ONE, Vector2(3, 3)), INK)
		rect(Rect2(b, Vector2.ONE), MIST)

func tube(points: Array, organic := false, width := 5.0) -> void:
	stroke(points, INK, width + 3)
	stroke(points, FLESH if organic else STEEL, width)
	var highlight: Array = []
	for p in points: highlight.append(Vector2(p) - Vector2(0.5, 1))
	stroke(highlight, ROSE if organic else MIST, 1)
	for i in range(1, points.size()):
		var a := Vector2(points[i - 1])
		var b := Vector2(points[i])
		var tangent := (b - a).normalized()
		var normal := tangent.orthogonal() * width * 0.5
		for step in range(6, int(a.distance_to(b)), 13):
			var at := a + tangent * step
			stroke([at - normal, at + normal], FLESH if organic else NIGHT, 1)

func halo(p: Vector2, radius: int, color: Color) -> void:
	if not game.reduced_motion:
		draw_texture_rect(light, Rect2(p - Vector2.ONE * radius, Vector2.ONE * radius * 2), false, Color(color, 0.12))

func floor_light(p: Vector2, spread: int, color: Color) -> void:
	for i in 3:
		var w := spread - i * 6
		if w > 0:
			shape([p + Vector2(-w, -2), p + Vector2(w, -2), p + Vector2(w + 7, 5), p + Vector2(-w - 7, 5)], Color(color, 0.025))

func bracket(p: Vector2, color: Color) -> void:
	for side in [-1, 1]:
		var corner := p + Vector2(side * 14, -26)
		stroke([corner + Vector2(-side * 5, 0), corner, corner + Vector2(0, 16), corner + Vector2(-side * 5, 16)], color)

func part(id: String, box: Rect2) -> void:
	draw_texture_rect(MODULES[id], box, false, shade * feedback.tint(box.get_center()))

func floor_tile(p: Vector2, alternate: bool) -> void:
	part("hatch" if alternate else "floor", Rect2(p, Vector2(62, 42)))

func draw_room(variant: int) -> void:
	rect(Rect2(0, 0, 640, 360), INK)
	shape([Vector2(77, 103), Vector2(104, 68), Vector2(536, 68), Vector2(563, 103), Vector2(563, 299), Vector2(537, 321), Vector2(102, 321), Vector2(77, 298)], NIGHT)
	for row in 4:
		for column in 7:
			floor_tile(Vector2(104 + column * 62, 136 + row * 42), column in [0, 6] and row == 1)
	for module in wall_modules:
		var p: Vector2 = module.p
		var s: Vector2 = module.size
		panel(Rect2(p, s))
		if module.kind == "wall":
			part("wall-open" if int(p.x) % 96 == 8 else "wall-vent", Rect2(p, s))
		else:
			part("column", Rect2(p, s))
			for y in range(12, 171, 16):
				rect(Rect2(p + Vector2(5, y), Vector2(8, 9)), NIGHT)
			for y in [26, 94, 166]:
				rect(Rect2(p + Vector2(6, y), Vector2(6, 11)), INK)
				rect(Rect2(p + Vector2(8, y + 2), Vector2(2, 6)), AMBER)
				part("lamp", Rect2(p + Vector2(5, y - 1), Vector2(8, 14)))
				floor_light(p + Vector2(9, y + 13), 12, AMBER)
	tube([Vector2(91, 116), Vector2(91, 69), Vector2(111, 49), Vector2(527, 49), Vector2(550, 72), Vector2(550, 116)], false, 9)
	tube([Vector2(111, 123), Vector2(111, 69), Vector2(126, 57), Vector2(514, 57), Vector2(534, 75), Vector2(534, 123)], variant > 1, 4)
	for x in range(124, 508, 64): part("conduit", Rect2(x, 43, 64, 11))
	part("elbow", Rect2(105, 48, 21, 21))
	for x in range(125, 528, 42): panel(Rect2(x, 42, 10, 15), SLATE)
	stroke([Vector2(106, 137), Vector2(535, 137)], MIST, 0.5)
	for x in range(112, 531, 16): stroke([Vector2(x, 306), Vector2(x + 6, 302)], BRASS, 2)
	if variant >= 2:
		for x in [164, 476]:
			panel(Rect2(x - 23, 64, 46, 63))
			tube([Vector2(x, 48), Vector2(x, 79), Vector2(x + 13, 91), Vector2(x + 13, 122)], true, 7)
			if variant == 4:
				lung(Vector2(x, 103))
			else:
				heart(Vector2(x, 100), 0.65, clock + x, false)
	elif variant == 1:
		for x in [159, 474]:
			panel(Rect2(x - 22, 91, 44, 36))
			for y in range(99, 123, 4): stroke([Vector2(x - 15, y), Vector2(x + 15, y)], NIGHT)
	for x in [116, 524]:
		panel(Rect2(x - 6, 129, 12, 6), NIGHT)
		rect(Rect2(x - 3, 130, 6, 1.5), AMBER)

func foreground() -> void:
	var fade := 0.38 if game.player.y > 280 and game.screen != "title" else 1.0
	shade = Color(1, 1, 1, fade)
	panel(Rect2(91, 315, 458, 14), NIGHT)
	for x in range(96, 540, 64): part("rail", Rect2(x, 305, 64, 28))
	stroke([Vector2(97, 315), Vector2(544, 315)], SLATE, 2)
	shade = Color.WHITE

func door_slide(p: Vector2, opened: bool) -> float:
	var key := "%s/%s" % [game.room, p.x]
	if not doors.has(key): doors[key] = {"amount": 1.0 if opened else 0.0, "target": 1.0 if opened else 0.0}
	doors[key].target = 1.0 if opened else 0.0
	return float(doors[key].amount) * 17

func gate(p: Vector2, opened: bool) -> void:
	var slide := door_slide(p, opened)
	part("wall-open", Rect2(p + Vector2(-29, -64), Vector2(58, 64)))
	rect(Rect2(p + Vector2(-21, -54), Vector2(42, 54)), INK)
	for side in [-1, 1]:
		var x: float = p.x + side * (10 + slide)
		panel(Rect2(x - 10, p.y - 51, 20 - slide * 0.55, 49), STEEL)
		for y in range(-44, -5, 7): stroke([Vector2(x - 6, p.y + y), Vector2(x + 6 - slide * 0.55, p.y + y)], NIGHT)
		rect(Rect2(p + Vector2(side * 25 - 1, -43), Vector2(2, 18)), AMBER if opened else TEAL)
	for x in range(-19, 20, 8): stroke([p + Vector2(x, -1), p + Vector2(x + 3, -4)], AMBER if opened else BRASS, 2)
	if opened: floor_light(p + Vector2(0, 2), 22, AMBER)

func terminal(p: Vector2, active: bool) -> void:
	shadow(p, 13)
	panel(Rect2(p + Vector2(-8, -16), Vector2(16, 16)), NIGHT)
	panel(Rect2(p + Vector2(-13, -36), Vector2(26, 21)), SLATE)
	rect(Rect2(p + Vector2(-9, -32), Vector2(17, 10)), INK)
	var color := CYAN if active else TEAL
	stroke([p + Vector2(-7, -27), p + Vector2(-4, -27), p + Vector2(-2, -30), p + Vector2(0, -24), p + Vector2(2, -27), p + Vector2(6, -27)], color, 0.5)
	for x in range(-7, 8, 4): rect(Rect2(p + Vector2(x, -19), Vector2(2, 1)), MIST)
	stroke([p + Vector2(-5, -12), p + Vector2(5, -12)], BRASS)
	if active: halo(p + Vector2(0, -27), 8, CYAN)

func shop_counter(p: Vector2) -> void:
	shadow(p, 26)
	panel(Rect2(p + Vector2(-25, -17), Vector2(50, 17)), STEEL)
	part("hatch", Rect2(p + Vector2(-25, -23), Vector2(50, 13)))
	rect(Rect2(p + Vector2(-22, -5), Vector2(44, 2)), TEAL)
	part("piston", Rect2(p + Vector2(-19, -22), Vector2(15, 5)))
	part("armor", Rect2(p + Vector2(6, -23), Vector2(14, 5)))
	terminal(p - Vector2(0, 19), true)

func heart(p: Vector2, scale_factor: float, time: float, bright: bool) -> void:
	var beat := 0.0 if game.reduced_motion else maxf(0, sin(time * TAU * 1.1)) * 0.8
	var points: Array = []
	for q in [Vector2(-13, -8), Vector2(-10, -17), Vector2(-3, -18), Vector2(1, -12), Vector2(7, -19), Vector2(15, -14), Vector2(17, -4), Vector2(13, 9), Vector2(4, 20), Vector2(-7, 11)]:
		points.append(p + q * (scale_factor + beat * 0.018))
	shape(points, FLESH, true)
	stroke([p + Vector2(-8, -11) * scale_factor, p + Vector2(-4, -14) * scale_factor, p + Vector2(0, -10) * scale_factor, p + Vector2(1, 8) * scale_factor, p + Vector2(4, 16) * scale_factor], ROSE, 2 * scale_factor)
	stroke([p + Vector2(11, -11) * scale_factor, p + Vector2(7, -6) * scale_factor, p + Vector2(7, 6) * scale_factor], Color("#ba7d82"), scale_factor)
	stroke([p + Vector2(-9, -5) * scale_factor, p + Vector2(-2, -2) * scale_factor, p + Vector2(2, 4) * scale_factor], ROSE, scale_factor)
	if bright: halo(p, 9, CYAN)

func lung(p: Vector2) -> void:
	var breath := 0.0 if game.reduced_motion else sin(clock * 2.2) * 0.7
	for side in [-1, 1]:
		var points: Array = []
		for q in [Vector2(3, -20), Vector2(13, -16), Vector2(18, -7), Vector2(18, 14), Vector2(12, 20), Vector2(3, 13)]:
			points.append(p + Vector2(side * (q.x + breath), q.y))
		shape(points, FLESH, true)
		stroke([p + Vector2(side * 7, -13), p + Vector2(side * 13, -4), p + Vector2(side * 12, 12)], ROSE)
	tube([p + Vector2(0, -26), p + Vector2(0, -5), p + Vector2(-10, 3)], false, 3)
	tube([p + Vector2(0, -5), p + Vector2(10, 3)], true, 3)

func machine(p: Vector2, graft: bool, filled: bool) -> void:
	var phase: String = "idle" if graft else game.boss_phase
	var warn := clampf(1.0 - game.boss_time / 0.85, 0, 1) if phase == "warn" and not game.reduced_motion else 0.0
	var slam := 0.0
	if phase == "strike" and game.boss_fx_age >= 0.0:
		slam = 13.0 * (1.0 - clampf(game.boss_fx_age / 0.19, 0, 1))
	var recoil := Vector2.ZERO
	if not graft and game.boss_hurt_age >= 0 and not game.reduced_motion:
		recoil = game.boss_hurt_direction * (5 if game.boss_hp == 0 else 3) * settle(game.boss_hurt_age, 0.22)
	p += recoil.snapped(Vector2(0.5, 0.5))
	if not graft and game.boss_hp == 0: shade = Color(0.5, 0.57, 0.61)
	shadow(p, 53)
	panel(Rect2(p + Vector2(-51, -12), Vector2(102, 12)), NIGHT)
	for side in [-1, 1]:
		part("column", Rect2(p + Vector2(side * 43 - 7, -91), Vector2(14, 83)))
		tube([p + Vector2(side * 29, -102), p + Vector2(side * 29, -80), p + Vector2(side * 12, -67), p + Vector2(side * 12, -44)], true, 5)
		panel(Rect2(p + Vector2(side * 48 - 10, -18), Vector2(20, 15)), SLATE)
		for y in range(-82, -19, 12): rect(Rect2(p + Vector2(side * 43 - 3, y), Vector2(6, 3)), AMBER if phase == "idle" else RED if phase in ["warn", "strike"] else CYAN)
	panel(Rect2(p + Vector2(-48, -105), Vector2(96, 16)), SLATE)
	for x in range(-32, 33, 9): stroke([p + Vector2(x, -93), p + Vector2(x + 4, -100)], BRASS, 2)
	part("heart-cage", Rect2(p + Vector2(-27, -80), Vector2(54, 67)))
	rect(Rect2(p + Vector2(-14, -57), Vector2(28, 39)), NIGHT)
	if filled:
		heart(p + Vector2(0, -38), 0.9, clock, phase == "open")
	else:
		for side in [-1, 1]: tube([p + Vector2(side * 12, -64), p + Vector2(side * 9, -49), p + Vector2(side * 14, -27)], false, 3)
	if not graft:
		var aperture := 16.0 if phase == "open" else 0.0
		for side in [-1, 1]:
			panel(Rect2(p + Vector2(side * (11 + aperture) - 10, -64), Vector2(20, 43)), STEEL)
			stroke([p + Vector2(side * (12 + aperture), -59), p + Vector2(side * (12 + aperture), -26)], CYAN if phase == "open" else SLATE)
			var shoulder := p + Vector2(side * 44, -77)
			var elbow := p + Vector2(side * (57 + warn * 3), -40 - warn * 15)
			var hammer := p + Vector2(side * (55 + warn * 4), -5 - warn * 20 + slam)
			if game.hazard.size.x > 100 and phase == "strike": hammer.x += -side * 18
			tube([shoulder, elbow, hammer], false, 8)
			stroke([elbow + Vector2(2, 0), hammer + Vector2(2, -6)], MIST, 3)
			piston_link(elbow, hammer)
			part("armor", Rect2(hammer + Vector2(-12, -11), Vector2(24, 15)))
			for x in [-7, 0, 7]: stroke([hammer + Vector2(x, -7), hammer + Vector2(x, 1)], NIGHT, 2)
		if game.boss_hp < 17: stroke([p + Vector2(-19, -61), p + Vector2(-14, -52), p + Vector2(-18, -44)], MIST)
		if game.boss_hp < 9: stroke([p + Vector2(19, -58), p + Vector2(12, -49), p + Vector2(17, -36)], MIST)
	else:
		terminal(p + Vector2(50, -2), true)
		var pump := p + Vector2(-52, -29)
		panel(Rect2(pump - Vector2(11, 13), Vector2(22, 26)), SLATE)
		for i in 6:
			var a: float = i * TAU / 6 + (clock * 2 if filled and not game.reduced_motion else 0)
			stroke([pump, pump + Vector2.from_angle(a) * 7], NIGHT, 2)
		stroke([pump - Vector2(4, 7), pump + Vector2(0, -9), pump + Vector2(6, -5)], MIST)
	shade = Color.WHITE

func piston_link(a: Vector2, b: Vector2) -> void:
	var texture: Texture2D = MODULES["piston"]
	var size := texture.get_size()
	var distance := a.distance_to(b)
	draw_set_transform(a, (b - a).angle())
	# The cylinder keeps its length; only the exposed rod follows the moving hammer.
	draw_texture_rect_region(texture, Rect2(0, -5, 17, 10), Rect2(0, 0, size.x * 0.56, size.y), shade)
	draw_line(Vector2(15, 0), Vector2(distance - 3, 0), MIST * shade, 3)
	draw_line(Vector2(15, -1), Vector2(distance - 3, -1), BONE * shade, 0.5)
	draw_texture_rect_region(texture, Rect2(distance - 6, -4, 7, 8), Rect2(size.x * 0.85, 0, size.x * 0.15, size.y), shade)
	draw_set_transform(Vector2.ZERO)

func shadow(p: Vector2, width: float) -> void:
	shape([p + Vector2(-width, -1), p + Vector2(-width + 5, -4), p + Vector2(width - 4, -3), p + Vector2(width + 6, 3), p + Vector2(-width + 7, 4)], Color(INK, 0.6))

func equipped(grip: Vector2, direction: Vector2, tint: Color, yaw := 0.0) -> void:
	if game.build_id not in WEAPONS: return
	var texture: Texture2D = WEAPONS[game.build_id]
	var bounds := Vector2(48, 12) if game.build_id == "probe" else Vector2(31, 16)
	var size := texture.get_size() * minf(bounds.x / texture.get_width(), bounds.y / texture.get_height())
	var side := -1.0 if direction.x < -0.1 else 1.0
	draw_set_transform(grip.snapped(Vector2(0.5, 0.5)), direction.angle() + yaw * side, Vector2(1, side))
	draw_texture_rect(texture, Rect2(Vector2(-size.x * 0.14, -size.y * 0.55), size), false, tint)
	draw_set_transform(Vector2.ZERO)

func hero(p: Vector2, tint := Color.WHITE, preview := false) -> void:
	if not preview:
		tint *= feedback.tint(p - Vector2(0, 24))
		if game.attack_age >= 0 and game.attack_age < 0.16 and not game.reduced_motion:
			p += game.attack_direction * (4 if game.combo_step == 2 else 2) * settle(game.attack_age, 0.16)
	var motion = game.hero_motion
	var clip: String = "walk-front" if preview else motion.clip
	var frame: int = 0 if preview else motion.frame
	var direction: Vector2 = Vector2.RIGHT if preview else motion.direction
	var side := -1.0 if direction.x < -0.1 else 1.0
	var fallen: bool = not preview and game.screen in ["dying", "failed"]
	if fallen:
		side = -game.death_side
		tint *= Color.WHITE.lerp(Color(0.48, 0.53, 0.58), clampf(game.death_age / 0.75, 0, 1))
	var data: Dictionary = hero_metadata[clip][frame]
	var texture := HERO_FRAMES.get_frame_texture(clip, frame)
	var pixel_scale: float = data.scale
	var origin := Vector2(data.origin[0], data.origin[1]) * pixel_scale
	var grip_offset := (Vector2(data.grip[0], data.grip[1]) - Vector2(data.origin[0], data.origin[1])) * pixel_scale
	var compression := 0.0
	if not preview and not game.reduced_motion:
		if fallen: compression = settle(game.death_age, 0.12) * 0.04
		elif clip == "death": compression = settle(game.hurt_age, 0.16) * 0.05
	var pose_scale := Vector2(side * (1.0 + compression), 1.0 - compression)
	var grip := p + grip_offset * pose_scale
	var weapon_yaw: float = 0.0 if preview or game.reduced_motion else motion.yaw
	if not preview and not game.reduced_motion:
		grip += direction * motion.recoil
		if game.combo_step == 1 and motion.state in [&"arc_draw", &"arc_cut"]: weapon_yaw *= -1.0
	if tint.a > 0.5: shadow(p, 11)
	if not preview and game.hurt_age >= 0 and not (game.reduced_motion or game.reduce_flash):
		tint *= Color.WHITE.lerp(Color(1.24, 0.71, 0.73), settle(game.hurt_age, 0.15))
	var show_weapon: bool = not fallen and not preview and game.build_id != ""
	if show_weapon and direction.y < -0.7: equipped(grip, direction, tint, weapon_yaw)
	draw_set_transform(p.snapped(Vector2(0.5, 0.5)), 0, pose_scale)
	draw_texture_rect(texture, Rect2(-origin, texture.get_size() * pixel_scale), false, tint)
	draw_set_transform(Vector2.ZERO)
	if show_weapon and direction.y >= -0.7: equipped(grip, direction, tint, weapon_yaw)
	if fallen and game.death_age >= 0.32:
		equipped(p + Vector2(-game.death_side * 20, 1), Vector2.RIGHT, tint)
		if not game.reduced_motion: draw_effect(&"collapse", game.death_age - 0.32, p + Vector2(game.death_side * 15, 0), 0, Vector2(48, 24))

func settle(age: float, seconds: float) -> float:
	return pow(1.0 - clampf(age / seconds, 0.0, 1.0), 2)

func creature(e: Dictionary) -> void:
	if e.hp <= 0 and e.dead > 0.5: return
	var p: Vector2 = e.p
	var frame := int(clock * 9) % 4
	var tint := Color.WHITE
	if e.hurt > 0 and not (game.reduce_flash or game.reduced_motion):
		tint = tint.lerp(Color(1.20, 0.79, 0.82), settle(0.18 - e.hurt, 0.14))
	tint *= feedback.tint(p - Vector2(0, 24))
	if e.hp <= 0:
		frame = 10 if e.dead < 0.16 else 11
		tint = Color(0.65, 0.68, 0.72, maxf(0, 1 - e.dead / 0.5))
	elif e.phase == "warn": frame = 4 if e.time > 0.35 else 5
	elif e.phase == "strike": frame = 6 if e.time > 0.08 else 7
	elif e.hurt > 0: frame = 8 if e.hurt > 0.09 else 9
	elif e.phase == "recover": frame = 7
	if game.reduced_motion and e.phase == "seek": frame = 0
	var data: Dictionary = enemy_metadata[e.kind][frame]
	var texture: Texture2D = ENEMY_FRAMES[e.kind].get_frame_texture(&"body", frame)
	var origin := Vector2(data.origin[0], data.origin[1]) * float(data.scale)
	var facing := Vector2(-1 if e.dir.x < -0.1 else 1, 1)
	var sprite_box := Rect2(-origin, texture.get_size() * float(data.scale))
	if e.kind == "husk" and e.phase == "strike" and not game.reduced_motion:
		var flight := clampf(e.time / 0.16, 0, 1)
		if flight > 0.35:
			for i in [2, 1]:
				var echo: Vector2 = p.lerp(e.launch, flight * i * 0.28) - Vector2(0, 4 * i)
				draw_set_transform(echo.round(), 0, facing)
				draw_texture_rect(texture, sprite_box, false, Color(RAKE, flight * 0.18 / i))
			draw_set_transform(Vector2.ZERO)
	shadow(p, 20 if e.kind != "worker" else 11)
	var compression := 0.0 if game.reduced_motion else settle(0.18 - e.hurt, 0.15) * 0.05
	draw_set_transform(p.snapped(Vector2(0.5, 0.5)), 0, facing * Vector2(1.0 + compression, 1.0 - compression))
	draw_texture_rect(texture, sprite_box, false, tint)
	draw_set_transform(Vector2.ZERO)
	if e.hp > 0:
		var height := 67 if e.kind == "sentinel" else 48 if e.kind == "worker" else 38
		rect(Rect2(p + Vector2(-12, -height - 4), Vector2(24, 3)), INK)
		rect(Rect2(p + Vector2(-12, -height - 4), Vector2(24 * float(e.hp) / (12 if e.kind == "sentinel" else 8), 2)), RED)
		if e.kind == "sentinel" and e.phase == "recover": rect(Rect2(p + Vector2(-4, -35), Vector2(8, 2)), CYAN)

func _draw() -> void:
	if game == null: return
	shade = Color.WHITE
	var title: bool = game.screen == "title"
	var room: String = "bypass" if title else game.room
	var variant := 1 if room == "bypass" else 2 if room == "press" else 0
	if room == "field": variant = 4 if game.stage == 5 else game.stage
	if room == "intake" and game.cycle > 1: variant = 2
	draw_room(variant)
	feedback.draw_ground(self)
	if not title and game.hp > 0:
		if room == "press" and game.boss_phase in ["warn", "strike"]: boss_telegraph()
		if room == "field":
			for e in game.enemies:
				if e.hp > 0 and e.phase in ["warn", "strike"]: enemy_telegraph(e)
	var entities: Array[Dictionary] = []
	if not title:
		for fixture in fixtures: entities.append({"kind": "fixture", "p": fixture.p, "fixture": fixture})
	if title:
		entities.append({"kind": "graft", "p": Vector2(459, 273), "filled": true})
		entities.append({"kind": "hero-preview", "p": Vector2(357, 276)})
	else:
		entities.append_array(room_props())
		if room == "field":
			for e in game.enemies: entities.append({"kind": "enemy", "p": e.p, "enemy": e})
	if room == "intake":
		var route: Array[Vector2] = [Vector2(320, 228), Vector2(320, 202), Vector2(320, 174)]
		if game.cycle > 1: route = [Vector2(276, 230), Vector2(245, 207), Vector2(211, 181), Vector2(175, 157)]
		elif game.build_id != "": route = [Vector2(351, 207), Vector2(393, 189), Vector2(432, 167), Vector2(463, 150)]
		for p in route:
			block(p.x - 7, p.y, 4, 2, AMBER)
			block(p.x + 4, p.y, 4, 2, AMBER)
	if not title:
		if game.dash_left > 0 and not game.reduced_motion:
			for i in game.dash_trail.size(): hero(game.dash_trail[i], Color(CYAN, 0.04 + i * 0.035))
		entities.append({"kind": "hero", "p": game.player})
	entities.sort_custom(func(a: Dictionary, b: Dictionary): return a.p.y < b.p.y)
	for entity in entities:
		match entity.kind:
			"gate": gate(entity.p, entity.opened)
			"terminal": terminal(entity.p, entity.active)
			"shop": shop_counter(entity.p)
			"graft": machine(entity.p, true, entity.filled)
			"boss": machine(entity.p, false, true)
			"hero": hero(entity.p)
			"hero-preview": hero(entity.p, Color.WHITE, true)
			"enemy": creature(entity.enemy)
			"fixture": coolant_can(entity.fixture)
	foreground()
	if title: return
	feedback.draw_air(self, light)
	if game.screen == "failed": return
	if game.attack_age >= 0: attack()
	if room == "press": boss_attack()
	if game.campaign:
		for fx in game.effects: expedition_effect(fx.id, fx.age, fx.p, fx.get("angle", 0.0))
		if game.graft_age >= 0 and game.graft_age < 1.4: expedition_effect(&"organ_collect", game.graft_age, game.GRAFT)
		if game.room == "field" and game.cleared: bracket(game.EXIT, AMBER)
	draw_contacts()
	if game.screen == "dying": return
	if game.hint_pos != Vector2.ZERO: bracket(game.hint_pos, CYAN)
	if game.dash_age >= 0 and not game.reduced_motion: draw_effect(&"dash", game.dash_age, game.player - Vector2(0, 8), game.dash_dir.angle(), Vector2(60, 24))
	if game.evade_flash > 0:
		if not game.reduced_motion: draw_effect(&"evade", 0.35 - game.evade_flash, game.evade_point, 0, Vector2(32, 24))
		else: draw_rect(Rect2(game.player - Vector2(14, 36), Vector2(28, 37)), CYAN, false, 1)

func boss_attack() -> void:
	if game.boss_fx_age < 0 or game.reduced_motion: return
	var r: Rect2 = game.hazard
	if r.size.x > 100:
		draw_effect(&"boss_sweep", game.boss_fx_age, r.get_center(), 0, Vector2(120, 56))
	else:
		draw_effect(&"boss_slam", game.boss_fx_age, r.get_center(), 0, Vector2(40, 96))
	if game.boss_fx_age < 0.29:
		enemy_recipe(&"shield_slam", game.boss_fx_age, r.get_center(), 0.0, Vector2(144, 164), 0.46, 0.29)

func chevron(tip: Vector2, direction: Vector2, span: float, color: Color) -> void:
	var edge := direction.orthogonal() * span
	var tail := tip - direction * minf(9, span * 0.65)
	stroke([tail + edge, tip, tail - edge], Color(INK, 0.85), 3)
	stroke([tail + edge, tip, tail - edge], color, 1.5)

func warning_tone(progress: float, active: bool, base: Color) -> Color:
	if active: return BONE
	return base.lerp(Color("#ffe0ae"), 0.55 * progress)

func boss_telegraph() -> void:
	var r: Rect2 = game.hazard
	var sweep := r.size.x > 100
	var direction := Vector2.RIGHT if sweep else Vector2.DOWN
	var edge := direction.orthogonal() * (r.size.y if sweep else r.size.x) * 0.5
	var length := r.size.x if sweep else r.size.y
	var start := r.get_center() - direction * length * 0.5
	var active: bool = game.boss_phase == "strike"
	var progress := 0.65 if game.reduced_motion else clampf(1.0 - game.boss_time / 0.85, 0, 1)
	var color := warning_tone(progress, active, THREAT)
	# Repeated treads expose the lane width at several points, including its ends.
	for i in 8:
		var from := start + direction * length * i / 8.0
		var to := from + direction * (length / 8.0 - 2)
		var alpha := 0.14 if active else 0.07 + 0.09 * progress
		if i % 2 == 0: alpha *= 0.6
		shape([from - edge, from + edge, to + edge, to - edge], Color(THREAT, alpha))
		for side in [-1, 1]:
			var rail: Vector2 = from + edge * side
			stroke([rail, rail + direction * (length / 8.0 - 4)], Color(color, 0.72), 1.25)
	for i in 5:
		var distance := length * float(i + 1) / 5
		var lit := active or progress >= float(i) / 5
		chevron(start + direction * distance, direction, edge.length() - 3, Color(color, 0.9 if lit else 0.42))

func enemy_telegraph(e: Dictionary) -> void:
	var active: bool = e.phase == "strike"
	var progress := 0.65 if game.reduced_motion else clampf(1.0 - e.time / game.ENEMY_WINDUP, 0, 1)
	var color := warning_tone(progress, active, RAKE if e.kind == "husk" else THREAT)
	var points: PackedVector2Array = e.zone
	draw_colored_polygon(points, Color(color, 0.14 if active else 0.06 + progress * 0.1))
	match e.kind:
		"husk":
			for i in range(0, points.size(), 2):
				stroke([points[i], points[i + 1]], color, 1.5)
			var path: Vector2 = e.aim - e.launch
			if path.length() > 15:
				for j in 3:
					var step := float(j + 1) * 0.21
					chevron(e.launch + path * step, path.normalized(), 4, Color(color, 0.9 if progress >= step else 0.45))
			chevron(e.aim + e.dir * 5, e.dir, 7, color)
		"worker":
			stroke([points[0], points[1]], Color(color, 0.75), 1)
			stroke([points[3], points[2]], Color(color, 0.75), 1)
			for i in 4:
				var fraction := (i + 1) / 4.0
				chevron(e.launch.lerp(e.aim, fraction), e.dir, 10, Color(color, 0.9 if progress >= fraction - 0.25 else 0.45))
		_:
			stroke(Array(points), Color(color, 0.78), 1.5)
			stroke([points[-1], points[0]], Color(color, 0.55))
			for i in [-1, 0, 1]:
				var direction: Vector2 = e.dir.rotated(i * 0.44)
				chevron(e.launch + direction * 45, direction, 8, color)

func attack() -> void:
	var p: Vector2 = game.attack_origin
	var dir: Vector2 = game.attack_direction
	var probe: bool = game.build_id != "arc"
	var age: float = game.attack_age
	if game.reduced_motion:
		if age < 0.11:
			if probe:
				draw_line(p, (p + dir * game.attack_distance).round(), TEAL, 2)
			else:
				var blade := PackedVector2Array()
				for a in [-0.95, -0.48, 0.0, 0.48, 0.95]:
					blade.append((p + dir.rotated(a) * 50).round())
				draw_polyline(blade, MIST, 2)
		return
	if probe:
		if game.build_id == "nailer":
			if age < 0.07:
				draw_line(p, p + dir * game.attack_distance, Color(AMBER, 1 - age / 0.07), 0.75)
				draw_line(p, p + dir * 6, AMBER if game.reduce_flash else BONE, 2)
		else:
			draw_effect(&"pulse", age, p, dir.angle(), Vector2(12, 12), Vector2(game.attack_distance / 108.0, 1.0))
	else:
		var tilt := -0.18 if game.combo_step == 1 else 0.12 if game.combo_step == 2 else 0.0
		draw_effect(&"sweep", age, p, dir.angle() + tilt, Vector2(64, 64), Vector2(1, -1 if game.combo_step == 1 else 1))

func draw_contacts() -> void:
	for contact in feedback.contacts:
		if contact.material == "coolant": continue
		var point: Vector2 = contact.p.round()
		var dir: Vector2 = contact.dir
		var age: float = contact.age
		var size: float = 4.0 + contact.power * 3.0
		if game.reduced_motion or game.reduce_flash:
			if age >= 0.15: continue
			var tangent := Vector2(-dir.y, dir.x)
			var color := MIST if contact.tier == "guard" else Color(contact.color).lerp(MIST, 0.4)
			draw_polyline(PackedVector2Array([point - dir * size - tangent * 4, point, point - dir * size + tangent * 4]), color, 1)
		elif contact.tier == "guard":
			enemy_recipe(&"shield_contact", age, point, dir.angle(), Vector2(100, 66), 0.47, 0.22)
		elif contact.tier == "finish" or (contact.tier == "heavy" and contact.material == "metal"):
			enemy_recipe(&"heavy_contact", age, point, dir.angle(), Vector2(84, 80), 0.47 if contact.tier == "finish" else 0.37, 0.40)
		else:
			var id := &"metal_hit" if contact.material == "metal" else &"tissue_hit"
			enemy_recipe(id, age, point, dir.angle(), Vector2(44, 44), size / 16.0, 0.24)

func draw_effect(id: StringName, age: float, p: Vector2, angle: float, pivot: Vector2,
		stretch := Vector2.ONE) -> void:
	var frame := floori(age * COMBAT_FX.get_animation_speed(id))
	if frame >= COMBAT_FX.get_frame_count(id):
		return
	var forward := Vector2.from_angle(angle)
	var sideways := Vector2(-forward.y, forward.x)
	draw_set_transform_matrix(Transform2D(forward * stretch.x, sideways * stretch.y, p.round()))
	draw_texture(COMBAT_FX.get_frame_texture(id, frame), -pivot, Color(0.78, 0.81, 0.82, 0.78) if game.reduce_flash else Color.WHITE)
	draw_set_transform(Vector2.ZERO)

func expedition_effect(id: StringName, age: float, p: Vector2, angle := 0.0) -> void:
	match id:
		&"pounce_rake":
			enemy_recipe(id, age, p, angle, Vector2(73, 67), 0.8, 0.26)
			return
		&"wrench_arc":
			enemy_recipe(id, age, p, angle, Vector2(81, 60), 0.84, 0.27)
			return
		&"shield_slam":
			enemy_recipe(id, age, p, 0.0, Vector2(144, 164), 0.38, 0.30)
			return
	if game.reduced_motion:
		if age < 0.16: draw_rect(Rect2(p - Vector2(8, 15), Vector2(16, 12)), CYAN if id == &"organ_collect" else BONE, false, 1)
		return
	var frame := floori(age * EXP_FX.get_animation_speed(id))
	if frame >= EXP_FX.get_frame_count(id): return
	draw_set_transform(p.round(), 0, Vector2(0.5, 0.5))
	draw_texture(EXP_FX.get_frame_texture(id, frame), -Vector2(56, 94), Color(0.78, 0.81, 0.82, 0.78) if game.reduce_flash else Color.WHITE)
	draw_set_transform(Vector2.ZERO)

func enemy_recipe(id: StringName, age: float, p: Vector2, angle: float, pivot: Vector2, zoom: float, duration: float) -> void:
	if game.reduced_motion or age >= duration: return
	var count := EXP_FX.get_frame_count(id)
	var frame := mini(count - 1, floori(age / duration * count))
	var fade := 1.0 - smoothstep(duration * 0.58, duration, age)
	draw_set_transform(p.round(), angle, Vector2.ONE * zoom)
	draw_texture(EXP_FX.get_frame_texture(id, frame), -pivot, Color(0.78, 0.81, 0.82, fade * 0.78) if game.reduce_flash else Color(1, 1, 1, fade))
	draw_set_transform(Vector2.ZERO)
