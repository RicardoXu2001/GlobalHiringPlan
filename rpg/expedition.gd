extends "res://game.gd"

const RUN_SAVE = "user://expedition.cfg"
const EXIT = Vector2(500, 166)
const GRAFT = Vector2(320, 169)
const SHOP = Vector2(170, 193)
const DEPART = Vector2(475, 193)
const WEAPONS = {
	"arc": {"name": "短弧", "detail": "电弧宽刃 · 近身扇扫", "damage": 8, "reach": 60.0, "aim": 0.50, "cooldown": 0.40, "windup": 0.06},
	"probe": {"name": "探针长枪", "detail": "窄线穿刺 · 可贯穿敌群", "damage": 5, "reach": 122.0, "aim": 0.95, "cooldown": 0.44, "windup": 0.08},
	"nailer": {"name": "压力铆枪", "detail": "远距点射 · 高频单体", "damage": 3, "reach": 184.0, "aim": 0.98, "cooldown": 0.25, "windup": 0.03}
}
const GOODS = ["nailer", "arc", "probe", "plating", "capacitor"]

var stage := -1
var cash := 0
var tier := 0
var gear := ""
var cleared := false
var integrated := false
var organ := false
var refreshed := false
var stock: Array = []
var sold: Array = []
var enemies: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var graft_age := -1.0
var saved_run: Dictionary = {}
var run_seed := 0
var heartbeat_left := 0.0

func _ready() -> void:
	super._ready()
	tones["heartbeat"] = tone(67, 34, 0.20)
	var save := ConfigFile.new()
	if save.load(RUN_SAVE) == OK:
		var data: Variant = save.get_value("expedition", "state", {})
		if data is Dictionary and data.get("weapon", "") in WEAPONS and int(data.get("stage", -2)) in range(-1, 6):
			var required := ["cash", "tier", "gear", "hp", "integrated", "organ", "cleared", "refreshed", "stock", "sold", "seed"]
			if required.all(func(key): return data.has(key)) and data.stock is Array and data.sold is Array and data.stock.all(func(id): return id in GOODS):
				saved_run = data
	ui.refresh()

func start() -> void:
	campaign = false
	super.start()

func new_run() -> void:
	campaign = false
	super.new_run()

func begin_expedition() -> void:
	campaign = true
	cycle = 1
	stage = -1
	cash = 0
	tier = 0
	gear = ""
	integrated = false
	organ = false
	refreshed = false
	cleared = false
	stock.clear()
	sold.clear()
	effects.clear()
	build_id = "arc"
	run_seed = randi_range(1, 1000000)
	hp = 5
	enter_room("hub")
	set_screen("exp_loadout")
	save_expedition()

func continue_expedition() -> void:
	if saved_run.is_empty():
		begin_expedition()
		return
	campaign = true
	stage = int(saved_run.stage)
	cash = int(saved_run.cash)
	tier = int(saved_run.tier)
	gear = String(saved_run.gear)
	build_id = String(saved_run.weapon)
	hp = int(saved_run.hp)
	integrated = bool(saved_run.integrated)
	organ = bool(saved_run.organ)
	cleared = bool(saved_run.cleared)
	refreshed = bool(saved_run.refreshed)
	stock = saved_run.stock.duplicate()
	sold = saved_run.sold.duplicate()
	run_seed = int(saved_run.seed)
	load_stage()
	notify("远征记录已恢复。当前关从入场状态继续。", 3)

func save_expedition() -> bool:
	var data := {"stage": stage, "cash": cash, "tier": tier, "gear": gear,
		"weapon": build_id, "hp": hp, "integrated": integrated, "organ": organ,
		"cleared": cleared, "refreshed": refreshed, "stock": stock.duplicate(),
		"sold": sold.duplicate(), "seed": run_seed}
	var save := ConfigFile.new()
	save.set_value("expedition", "state", data)
	if save.save(RUN_SAVE + ".tmp") != OK or DirAccess.rename_absolute(RUN_SAVE + ".tmp", RUN_SAVE) != OK:
		notify("远征记录写入失败。请检查可写空间。", 4)
		return false
	saved_run = data
	return true

func choose_expedition(id: String) -> void:
	if screen != "exp_loadout" or id not in WEAPONS:
		return
	build_id = id
	resume()
	save_expedition()
	notify("09，前往右侧出发口。首次任务：取回心核。", 4)

func max_hp() -> int:
	return 7 if gear == "plating" else 5

func module_name(id: String) -> String:
	if campaign and id in WEAPONS:
		return String(WEAPONS[id].name) + (" +%d" % tier if tier > 0 else "")
	return super.module_name(id)

func retry() -> void:
	if not campaign:
		super.retry()
		return
	begin_expedition()

func load_stage() -> void:
	enemies.clear()
	effects.clear()
	attack_cooldown = 0
	dash_cooldown = 0
	if stage in [-1, 4]:
		enter_room("hub")
	elif stage == 3:
		boss_hp = 32 if not cleared else 0
		enter_room("press")
	else:
		enter_room("field")
		if not cleared:
			match stage:
				0: spawn_enemy("husk", Vector2(342, 182))
				1:
					spawn_enemy("worker", Vector2(250, 174))
					spawn_enemy("husk", Vector2(412, 198))
				2:
					spawn_enemy("sentinel", Vector2(310, 175))
					spawn_enemy("worker", Vector2(438, 185))
				5:
					spawn_enemy("husk", Vector2(257, 178))
					spawn_enemy("worker", Vector2(425, 185))
	resume()

func spawn_enemy(kind: String, p: Vector2) -> void:
	enemies.append({"kind": kind, "p": p, "hp": 12 if kind == "sentinel" else 8,
		"phase": "seek", "time": 0.7, "zone": Rect2(), "hit": false,
		"dir": Vector2.DOWN, "hurt": 0.0, "dead": -1.0})

func depart() -> void:
	if room != "hub" or screen != "play":
		return
	if stage == 4 and not integrated:
		notify("先在中央接驳台接入心核。")
		return
	stage = 5 if stage == 4 else 0
	cleared = false
	load_stage()
	save_expedition()
	notify("肺叶入口：验证新构筑。本版后续区域仍在施工。" if stage == 5 else "第一组 · 01 / 04。扑击锁定后再闪开。", 4)

func advance() -> void:
	if not cleared:
		return
	if stage == 5:
		set_screen("exp_complete")
		return
	if stage == 3:
		stage = 4
		organ = true
		hp = max_hp()
		var rng := RandomNumberGenerator.new()
		rng.seed = run_seed
		stock = ["nailer", "plating", "capacitor"]
		# Keep the first new weapon readable; the other offers are sampled without duplicates.
		stock[1] = ["arc", "probe", "plating"][rng.randi_range(0, 2)]
		stock[2] = "capacitor" if stock[1] != "capacitor" else "plating"
		load_stage()
		notify("已回中心。心核待接入，武器铺已补货。", 4)
	else:
		stage += 1
		cleared = false
		load_stage()
		notify("心泵守卫：等核心护板打开。" if stage == 3 else "下一关：观察敌人的前摇与恢复。", 3)
	save_expedition()

func graft() -> void:
	if stage != 4 or not organ or integrated:
		notify("系统：接驳台等待新的功能脏器。")
		return
	integrated = true
	organ = false
	graft_age = 0.0
	play_sound("return")
	save_expedition()
	ui.refresh()
	notify("接入 1 / 7 · 心核。脉冲共鸣：强化攻击 +1。墙后响起心跳。", 5)

func buy(index: int) -> void:
	if screen != "shop" or index < 0 or index >= stock.size() or index in sold:
		return
	if cash < 12:
		notify("工料不足：需要 12。")
		return
	var id: String = stock[index]
	if id == build_id or id == gear:
		return
	if id in WEAPONS:
		build_id = id
	else:
		gear = id
		hp = mini(hp + (2 if id == "plating" else 0), max_hp())
	cash -= 12
	sold.append(index)
	play_sound("open")
	save_expedition()
	ui.refresh()

func improve() -> void:
	if screen != "shop" or tier >= 1 or cash < 10:
		return
	cash -= 10
	tier += 1
	play_sound("open")
	save_expedition()
	ui.refresh()

func refresh_stock() -> void:
	if screen != "shop" or refreshed or cash < 6:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed + 19
	var pool: Array = GOODS.duplicate()
	stock.clear()
	for i in 3:
		var pick := rng.randi_range(0, pool.size() - 1)
		stock.append(pool.pop_at(pick))
	refreshed = true
	sold.clear()
	cash -= 6
	play_sound("click")
	save_expedition()
	ui.refresh()

func item_name(id: String) -> String:
	if id in WEAPONS: return WEAPONS[id].name
	return "加固护具" if id == "plating" else "回路电容"

func item_detail(id: String) -> String:
	if id in WEAPONS: return WEAPONS[id].detail
	return "耐久上限 +2 · 替换当前装备" if id == "plating" else "攻击恢复加快 15% · 替换当前装备"

func attack(direction: Vector2) -> void:
	if not campaign:
		super.attack(direction)
		return
	if room == "hub" or attack_cooldown > 0 or dash_left > 0 or direction == Vector2.ZERO:
		return
	set_facing(direction)
	attack_cooldown = float(WEAPONS[build_id].cooldown) * (0.85 if gear == "capacitor" else 1.0)
	attack_windup = float(WEAPONS[build_id].windup)
	attack_direction = direction

func release_attack() -> void:
	if not campaign:
		super.release_attack()
		return
	attack_age = 0.0
	attack_origin = player.round() - Vector2(0, 10)
	attack_contact = attack_origin + attack_direction * float(WEAPONS[build_id].reach)
	attack_distance = float(WEAPONS[build_id].reach)
	attack_result = "miss"
	var damage: int = int(WEAPONS[build_id].damage) + tier * 2 + (1 if integrated else 0)
	if room == "press" and boss_hp > 0 and can_hit(CORE):
		attack_contact = CORE - Vector2(0, 10)
		if boss_phase != "open":
			attack_result = "guard"
			play_sound("guard")
			notify("护板闭合。等核心青灯亮起。", 1.4)
			return
		boss_hp = maxi(0, boss_hp - damage)
		boss_hurt_age = 0.0
		boss_hurt_direction = attack_direction
		attack_result = "hit"
		if boss_hp == 0:
			boss_phase = "offline"
			clear_stage()
	else:
		enemies.sort_custom(func(a, b): return player.distance_squared_to(a.p) < player.distance_squared_to(b.p))
		for e in enemies:
			if e.hp <= 0 or not can_hit(e.p): continue
			attack_contact = e.p - Vector2(0, 16)
			if e.kind == "sentinel" and e.phase != "recover" and attack_direction.dot(e.dir) < -0.4:
				if attack_result != "hit": attack_result = "guard"
				notify("免疫守卫正面格挡。绕后或等它收招。", 1.5)
				if build_id == "nailer": break
				continue
			e.hp = maxi(0, int(e.hp) - damage)
			e.hurt = 0.18
			attack_result = "hit"
			effects.append({"id": &"tissue_hit", "age": 0.0, "p": attack_contact})
			if e.hp == 0:
				e.dead = 0.0
				e.phase = "dead"
			elif e.kind != "sentinel":
				e.phase = "recover"
				e.time = 0.5
			if build_id == "nailer": break
		if not enemies.is_empty() and enemies.all(func(e): return e.hp <= 0):
			clear_stage()
	if attack_result == "hit":
		impact_pause = 0.05 if build_id == "arc" else 0.025
		play_sound("arc_hit" if build_id == "arc" else "probe_hit")
	else:
		play_sound("guard" if attack_result == "guard" else ("arc_miss" if build_id == "arc" else "probe_miss"))

func can_hit(p: Vector2) -> bool:
	var to := p - player
	return to.length() <= float(WEAPONS[build_id].reach) and attack_direction.dot(to.normalized()) >= float(WEAPONS[build_id].aim)

func clear_stage() -> void:
	if cleared: return
	cleared = true
	cash += 12 if stage == 3 else 6
	play_sound("break")
	effects.append({"id": &"organ_collect", "age": 0.0, "p": EXIT})
	save_expedition()
	notify("心核已释放。沿琥珀灯到出口，返回中心。" if stage == 3 else "通路已清理 · 工料 +6。前往右上出口。", 4)

func take_hit() -> void:
	super.take_hit()
	if campaign and hp == 0:
		# A dead expedition cannot be continued through its old room checkpoint.
		saved_run.clear()
		var save := ConfigFile.new()
		save.set_value("expedition", "state", {})
		if save.save(RUN_SAVE + ".tmp") != OK or DirAccess.rename_absolute(RUN_SAVE + ".tmp", RUN_SAVE) != OK:
			push_error("Could not invalidate the defeated expedition checkpoint.")

func tick_play(dt: float) -> void:
	var paused_hit := impact_pause > 0
	var before := player
	var evading := dash_left > 0
	super.tick_play(dt)
	if not campaign or paused_hit: return
	if room == "hub" and integrated:
		heartbeat_left -= dt
		if heartbeat_left <= 0:
			heartbeat_left = 0.9
			if not audio.playing: play_sound("heartbeat")
	if graft_age >= 0: graft_age += dt
	for fx in effects: fx.age += dt
	effects = effects.filter(func(fx): return fx.age < 1.4)
	for e in enemies:
		if e.hp <= 0:
			e.dead += dt
			continue
		e.hurt = maxf(0, float(e.hurt) - dt)
		e.time -= dt
		var to: Vector2 = player - e.p
		var reach := 106.0 if e.kind == "worker" else 58.0
		match e.phase:
			"seek":
				e.dir = to.normalized()
				if to.length() > reach:
					var speed := 34.0 if e.kind == "sentinel" else 53.0
					e.p = (e.p + e.dir * speed * dt).clamp(Vector2(126, 150), Vector2(514, 280))
				elif e.time <= 0:
					e.phase = "warn"
					e.time = 0.75
					e.hit = false
					var center: Vector2 = player if e.kind == "husk" else e.p + e.dir * 34
					e.zone = Rect2(center - Vector2(27, 24), Vector2(54, 48))
					if e.kind == "worker":
						e.zone = Rect2(Vector2(minf(e.p.x, player.x), minf(e.p.y, player.y)) - Vector2(10, 10), to.abs() + Vector2(20, 20))
			"warn":
				if e.time <= 0:
					e.phase = "strike"
					e.time = 0.16
					if e.kind == "husk": e.p = e.zone.get_center()
					effects.append({"id": &"tissue_hit", "age": 0.0, "p": e.zone.get_center()})
			"strike":
				if not e.hit and (e.zone.has_point(player) or (evading and e.zone.has_point(before))):
					e.hit = true
					if evading:
						evade_flash = 0.35
						evade_point = player
						play_sound("evade")
					elif hurt_flash <= 0:
						take_hit()
						if screen == "dying": return
				if e.time <= 0:
					e.phase = "recover"
					e.time = 0.95
			"recover":
				if e.time <= 0:
					e.phase = "seek"
					e.time = 0.3

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if screen == "exp_loadout":
			if event.physical_keycode == KEY_1: choose_expedition("arc")
			if event.physical_keycode == KEY_2: choose_expedition("probe")
			return
		if screen == "shop" and event.physical_keycode == KEY_ESCAPE:
			resume()
			return
	super._unhandled_input(event)

func nearest_object() -> Vector2:
	if not campaign: return super.nearest_object()
	var options: Array = [GRAFT, SHOP, DEPART] if room == "hub" else ([EXIT] if cleared else [])
	for target in options:
		if player.distance_to(target) <= 28: return target
	return Vector2.ZERO

func interact() -> void:
	if not campaign:
		super.interact()
		return
	var target := nearest_object()
	if target == Vector2.ZERO: return
	if room == "hub":
		if target == GRAFT: graft()
		elif target == SHOP: set_screen("shop")
		else: depart()
	else: advance()

func objective_text() -> String:
	if not campaign: return super.objective_text()
	if room == "hub": return "接入心核 · 查看武器铺" if organ else "前往右侧出发口"
	if cleared: return "沿琥珀灯到出口 [E]"
	if stage == 3: return "04 / 04  压维守卫 · 取得心核"
	if stage == 5: return "肺叶入口 · 检验新构筑"
	return "%02d / 04  %s" % [stage + 1, ["供给前廊 · 失败孵化体", "转运通道 · 感染夜班工", "拘束侧室 · 免疫守卫体"][stage]]

func context_text() -> String:
	if not campaign: return super.context_text()
	if hint_pos == Vector2.ZERO: return ""
	if room != "hub": return "[ E ] 返回中心" if stage == 3 else "[ E ] 前往下一关"
	if hint_pos == GRAFT: return "[ E ] 合并心核" if organ else "接驳台 · %d / 7" % int(integrated)
	if hint_pos == SHOP: return "[ E ] 武器铺 · 工料 %d" % cash
	return "[ E ] 出发探索"

func boss_text() -> String:
	if not campaign: return super.boss_text()
	if stage == 3 and boss_hp > 0 and hp > 0:
		return "压维守卫  %02d / 32   %s" % [boss_hp, "◇ 核心开放" if boss_phase == "open" else "▲ 注意落点" if boss_phase in ["warn", "strike"] else "护板闭合"]
	return ""
