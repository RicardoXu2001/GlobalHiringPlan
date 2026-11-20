extends "res://tests/visual_motion.gd"

func aim_at(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = game.presentation.position + (point + game.world.position * 0.5) * (game.presentation.size.x / 640.0)
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)

func nearest_target() -> Vector2:
	var point: Vector2 = game.player + game.facing * 50
	var distance := INF
	for enemy in game.enemies:
		if enemy.hp > 0 and game.player.distance_to(enemy.p) < distance:
			point = enemy.p
			distance = game.player.distance_to(enemy.p)
	return point

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	root.grab_focus()
	await create_timer(0.3).timeout
	# Normal stage-two enemy/HP rules, positioned for a compact visual review.
	game.begin_expedition()
	game.choose_expedition("arc")
	game.stage = 1
	game.load_stage()
	game.player = Vector2(225, 260)
	for i in 54:
		if not root.has_focus(): root.grab_focus()
		match i:
			1: await aim_at(Vector2(181, 244))
			6: key(KEY_W, true)
			13: key(KEY_W, false)
			14, 19, 24, 35, 40, 45: await aim_at(nearest_target())
			28: key(KEY_D, true)
			31: key(KEY_SPACE, true)
			32: key(KEY_SPACE, false)
			34: key(KEY_D, false)
		await create_timer(1.0 / 12).timeout
		await RenderingServer.frame_post_draw
		var frame := root.get_texture().get_image()
		var name := "frame-%03d.png" % i
		assert(frame.save_png(output.path_join(name)) == OK)
		samples.append({"file": name, "time_ms": Time.get_ticks_msec(), "hp": game.hp,
			"combo": game.combo_step, "particles": game.world.feedback.particles.size(),
			"marks": game.world.feedback.marks.size(), "enemies_alive": game.enemies.filter(func(e): return e.hp > 0).size()})
		if i == 19: frame.save_png(output.path_join("scene.png"))
	for code in [KEY_D, KEY_W, KEY_SPACE]: key(code, false)
	var report := FileAccess.open(output.path_join("frames.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify(samples, "\t"))
	report.close()
	print("Captured 54 native combat/environment frames with original timestamps.")
	quit(0)
