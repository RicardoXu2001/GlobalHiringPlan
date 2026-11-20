extends "res://tests/visual_motion.gd"

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	for kind in ["husk", "worker", "sentinel", "press_drop", "press_sweep"]:
		if not await capture_attack(kind):
			push_error("Enemy telegraph review failed: " + kind)
			quit(1)
			return
	var report := FileAccess.open(output.path_join("frames.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify(samples))
	report.close()
	print("Five locked telegraphs reached their native strike phase and dealt exactly one hit each.")
	quit(0)

func capture_attack(kind: String) -> bool:
	var boss := kind.begins_with("press_")
	game.begin_expedition()
	game.choose_expedition("arc")
	game.stage = 3 if boss else ["husk", "worker", "sentinel"].find(kind)
	game.load_stage()
	game.player = Vector2(350, 250)
	var enemy: Dictionary
	if boss:
		game.player = Vector2(325, 191) if kind == "press_sweep" else Vector2(320, 248)
	else:
		game.enemies.clear()
		var start := Vector2(278, 197) if kind == "worker" else Vector2(312, 216)
		game.spawn_enemy(kind, start)
		enemy = game.enemies[0]
	var deadline := Time.get_ticks_msec() + 3000
	while (game.boss_phase if boss else enemy.phase) != "warn":
		if Time.get_ticks_msec() >= deadline: return false
		await physics_frame
	var locked: Variant = game.hazard if boss else enemy.zone.duplicate()
	if boss:
		if (game.hazard.size.x > 100) != (kind == "press_sweep"): return false
	else:
		if not game.enemy_attack_contains(enemy, game.player): return false
		# An old AABB diagonal corner must be safe for the new circular or directional footprints.
		var corner: Vector2 = enemy.aim + Vector2(25, 22) if kind == "husk" else Vector2(340, 205) if kind == "worker" else enemy.launch + Vector2(-1, 26)
		if game.enemy_attack_contains(enemy, corner): return false
		# Simulate a reposition during windup and check the locked footprint stays put.
		var position_before: Vector2 = game.player
		game.player = corner
		await physics_frame
		await physics_frame
		if locked != enemy.zone: return false
		game.player = position_before
	for i in 14:
		await RenderingServer.frame_post_draw
		var frame := root.get_texture().get_image()
		var phase: String = game.boss_phase if boss else enemy.phase
		if phase in ["warn", "strike"] and locked != (game.hazard if boss else enemy.zone): return false
		var name := "%s-%02d.png" % [kind, i]
		if frame.save_png(output.path_join(name)) != OK: return false
		samples.append({"file": name, "t": Time.get_ticks_msec(), "kind": kind, "phase": phase, "hp": game.hp})
		await create_timer(0.083).timeout
	return game.hp == 3
