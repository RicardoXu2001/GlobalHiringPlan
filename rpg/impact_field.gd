extends RefCounted

const MAX_PARTICLES := 240
const MAX_MARKS := 96
const FLOOR := Rect2(106, 138, 430, 160)
const SHAKE_DECAY := 4.2
const PROFILES := {
	"chip": {"count": 3, "trauma": 0.12, "power": 0.45, "light": 0.0},
	"guard": {"count": 4, "trauma": 0.15, "power": 0.55, "light": 0.05},
	"light": {"count": 6, "trauma": 0.24, "power": 0.7, "light": 0.08},
	"hit": {"count": 10, "trauma": 0.42, "power": 1.0, "light": 0.14},
	"heavy": {"count": 19, "trauma": 0.67, "power": 1.18, "light": 0.20},
	"finish": {"count": 26, "trauma": 0.88, "power": 1.30, "light": 0.23},
	"coolant": {"count": 30, "trauma": 0.62, "power": 1.30, "light": 0.18},
}
var particles: Array[Dictionary] = []
var marks: Array[Dictionary] = []
var contacts: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var reduced := false
var reduce_flash := false
var shake_strength := 1.0
var trauma := 0.0
var shake_clock := 0.0
var landed_count := 0

func reset() -> void:
	particles.clear()
	marks.clear()
	contacts.clear()
	trauma = 0.0
	shake_clock = 0.0
	landed_count = 0
	rng.seed = 9014

func kick(amount: float) -> void:
	if reduced or shake_strength <= 0: return
	if trauma <= 0: shake_clock = 0.0
	trauma = minf(1.0, trauma + amount)

func camera_offset(dt: float, active: bool) -> Vector2:
	if reduced or shake_strength <= 0 or not active:
		trauma = 0.0
		return Vector2.ZERO
	var amplitude := trauma * trauma * shake_strength
	trauma = maxf(0.0, trauma - SHAKE_DECAY * dt)
	shake_clock += dt
	var wave := Vector2(sin(shake_clock * 63), cos(shake_clock * 47))
	return (Vector2(3, 2) * wave * amplitude).round()

func burst(point: Vector2, direction: Vector2, material: String, tier: String) -> void:
	var profile: Dictionary = PROFILES[tier]
	var power: float = profile.power
	var base := Vector2(point.x, clampf(point.y + 16, FLOOR.position.y, FLOOR.end.y))
	var color := Color("#57e4ce") if material == "coolant" else Color("#ffbd65") if material == "metal" else Color("#a66677")
	if tier != "chip":
		contacts.append({"p": point, "dir": direction, "material": material, "tier": tier,
			"color": color, "age": 0.0, "power": power, "light": profile.light})
		if contacts.size() > 8: contacts.pop_front()
	var count: int = profile.count
	if reduced: count = maxi(2, count / 4)
	for i in count:
		var velocity := direction.rotated(rng.randf_range(-1.8, 1.8)) * rng.randf_range(18, 90) * power
		particles.append({"p": base, "v": velocity, "z": base.y - point.y,
			"vz": rng.randf_range(25, 95), "age": 0.0, "life": rng.randf_range(0.5, 1.15),
			"material": material, "color": color, "size": rng.randf_range(0.7, 1.6), "bounces": 0})
	if material == "coolant" and not reduced:
		for i in 7:
			particles.append({"p": base, "v": Vector2(rng.randf_range(-8, 8), 0), "z": 14.0,
				"vz": rng.randf_range(12, 23), "age": 0.0, "life": rng.randf_range(0.7, 1.2),
				"material": "vapor", "color": Color("#829499"), "size": rng.randf_range(2, 4), "bounces": 0})
	while particles.size() > MAX_PARTICLES: particles.pop_front()
	kick(profile.trauma)

func step(dt: float) -> void:
	if dt <= 0: return
	if reduced and particles.size() > 60: particles.resize(60)
	for contact in contacts: contact.age += dt
	contacts = contacts.filter(func(contact): return contact.age < 0.4)
	for p in particles:
		p.age += dt
		p.vz += (8 if p.material == "vapor" else -180) * dt
		p.z += p.vz * dt
		p.p += p.v * dt
		if p.p.x < FLOOR.position.x or p.p.x > FLOOR.end.x:
			p.v.x *= -0.4
			p.p.x = clampf(p.p.x, FLOOR.position.x, FLOOR.end.x)
		if p.p.y < FLOOR.position.y or p.p.y > FLOOR.end.y:
			p.v.y *= -0.4
			p.p.y = clampf(p.p.y, FLOOR.position.y, FLOOR.end.y)
		if p.z <= 0:
			p.z = 0.0
			if p.bounces == 0:
				landed_count += 1
				marks.append({"p": p.p, "size": p.size, "material": p.material})
				if marks.size() > MAX_MARKS: marks.pop_front()
			p.bounces += 1
			if p.material == "metal" and p.bounces < 3:
				p.vz = absf(p.vz) * 0.35
				p.v *= 0.5
			else: p.age = p.life
	particles = particles.filter(func(p): return p.age < p.life)

func tint(point: Vector2) -> Color:
	var result := Color.WHITE
	if reduced or reduce_flash: return result
	for contact in contacts:
		var amount: float = maxf(0, 1 - point.distance_to(contact.p) / 42) * (1 - smoothstep(0.0, 0.13, contact.age)) * contact.light
		result = result.lerp(Color.WHITE.lerp(contact.color, 0.45) * 1.22, amount)
	return result

func draw_ground(canvas: Node2D) -> void:
	for mark in marks:
		var color := Color("#174a52") if mark.material == "coolant" else Color("#45494d") if mark.material == "metal" else Color("#472737")
		var size := Vector2(mark.size * 3, mark.size)
		canvas.draw_rect(Rect2(mark.p.round() - size * 0.5, size), color)
		if mark.material == "coolant": canvas.draw_line(mark.p, mark.p + Vector2(2, 0), Color("#287c80"), 0.5)

func draw_air(canvas: Node2D, glow: Texture2D) -> void:
	if not reduced and not reduce_flash:
		for contact in contacts:
			if contact.age >= 0.13: continue
			var radius: float = 12 + 10 * contact.power
			var opacity: float = (1 - smoothstep(0.0, 0.13, contact.age)) * contact.light
			canvas.draw_texture_rect(glow, Rect2(contact.p - Vector2.ONE * radius, Vector2.ONE * radius * 2),
				false, Color(contact.color, opacity))
	for p in particles:
		var pos: Vector2 = (p.p - Vector2(0, p.z)).snapped(Vector2(0.5, 0.5))
		var alpha: float = clampf((p.life - p.age) * 5, 0, 1)
		var color: Color = p.color
		if p.material == "metal" and p.age < 0.06 and not (reduced or reduce_flash): color = Color("#dfe8d5")
		if p.material == "vapor":
			canvas.draw_rect(Rect2(pos, Vector2(p.size, p.size)), Color(color, alpha * 0.2))
		elif p.material == "metal" and not reduced:
			canvas.draw_line(pos - p.v.normalized() * 3, pos, Color(color, alpha), 0.75)
		else: canvas.draw_rect(Rect2(pos, Vector2(p.size, p.size)), Color(color, alpha))
