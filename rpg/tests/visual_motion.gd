extends SceneTree

var game
var output: String
var samples: Array[Dictionary] = []

func _initialize() -> void:
	output = OS.get_environment("BOSS_QA_OUTPUT")
	call_deferred("run")

func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	root.grab_focus()
	await create_timer(0.3).timeout
	game.reset_round(1)
	game.build_id = "arc"
	game.enter_room("press")
	game.player = Vector2(250, 238)
	game.set_screen("play")
	for i in 36:
		if not root.has_focus(): root.grab_focus()
		match i:
			0: key(KEY_D, true)
			8:
				key(KEY_D, false)
				key(KEY_J, true)
			9: key(KEY_J, false)
			14: key(KEY_W, true)
			17: key(KEY_SPACE, true)
			18: key(KEY_SPACE, false)
			22: key(KEY_W, false)
			24: key(KEY_J, true)
			25: key(KEY_J, false)
		await create_timer(1.0 / 12).timeout
		await RenderingServer.frame_post_draw
		var frame := root.get_texture().get_image()
		var name := "frame-%03d.png" % i
		assert(frame.save_png(output.path_join(name)) == OK)
		samples.append({"file": name, "time_ms": Time.get_ticks_msec(), "action_age": game.attack_age,
			"dash_left": game.dash_left, "boss_phase": game.boss_phase, "player": [game.player.x, game.player.y]})
		if i == 5: frame.save_png(output.path_join("scene.png"))
	for code in [KEY_D, KEY_W, KEY_J, KEY_SPACE]: key(code, false)
	var report := FileAccess.open(output.path_join("frames.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify(samples, "\t"))
	report.close()
	print("Captured 36 native animation frames with original timestamps.")
	quit(0)
