extends SceneTree

const SCENE = preload("res://main.tscn")
var game
var output: String
var facts := {"launch": "NOT_RUN", "render": "NOT_RUN", "input": "NOT_RUN",
	"coreLoop": "NOT_RUN", "outcome": "NOT_RUN", "restart": "NOT_RUN"}
var checkpoints: Array[Dictionary] = []
var frames: Array[String] = []
var first_image: Image
var finished := false
var observed_hit_pause := false

func _initialize() -> void:
	output = OS.get_environment("BOSS_QA_OUTPUT")
	physics_frame.connect(observe_hit_pause)
	call_deferred("run")

func observe_hit_pause() -> void:
	if is_instance_valid(game) and game.impact_pause > 0 and game.boss_hurt_age >= 0:
		observed_hit_pause = true

func run() -> void:
	game = SCENE.instantiate()
	root.add_child(game)
	root.grab_focus()
	await create_timer(0.4).timeout
	if not expect(game.screen == "title" and game.saved_stage == 0, "Clean title"):
		return
	facts.launch = "PASS"
	first_image = await capture("title.png")
	if not expect(first_image != null and first_image.get_pixel(25, 25) != first_image.get_pixel(640, 320), "Nonempty rendered title"):
		return
	await tap(KEY_ENTER)
	if not expect(game.screen == "play", "Enter starts the game"):
		return
	await walk(Vector2(171, 153))
	await tap(KEY_E)
	if not expect(game.room == "intake" and game.message.contains("缺少"), "Bypass locked without evidence"):
		return
	facts.input = "PASS"
	record("first-visit-bypass-denied")
	var exploration: Image = await capture("exploration.png")
	if not expect(exploration != null and exploration.get_data() != first_image.get_data(), "Gameplay frame differs from title"):
		return
	facts.render = "PASS"
	await walk(Vector2(320, 176))
	await tap(KEY_E)
	if not expect(game.screen == "choose", "Module selection opens"):
		return
	await capture("weapons.png")
	await tap(KEY_2)
	if not expect(game.build_id == "probe", "Probe equipped"):
		return
	await walk(Vector2(463, 151))
	await tap(KEY_E)
	if not expect(game.room == "press", "Pressure gate opens after equipping"):
		return
	await walk(Vector2(320, 249))
	await click_at(game.player + Vector2(85, 0))
	if not await until(func(): return game.attack_result == "miss" and game.attack_age >= 0, 0.3):
		fail("Off-target probe did not show a miss")
		return
	if not expect(game.boss_hp == 24, "Miss does not damage the machine"):
		return
	record("probe-missed")
	for wave in 4:
		if not await until(func(): return game.boss_phase == "warn", 3):
			fail("Pressure machine failed to warn")
			return
		if wave == 0:
			await capture("combat.png")
			await click_at(game.CORE)
			if not await until(func(): return game.attack_result == "guard" and game.attack_age >= 0, 0.3):
				fail("Closed pressure plate did not show the block effect")
				return
			if not expect(game.boss_hp == 24 and game.boss_hurt_age < 0, "Blocked probe does not damage or stagger the machine"):
				return
			record("probe-blocked")
			await capture("combat-block.png")
		var key: Key = KEY_D if game.player.x < 330 else KEY_A
		send_key(key, true)
		await tap(KEY_SPACE)
		send_key(key, false)
		if not await until(func(): return game.boss_phase == "open", 2):
			fail("Pressure machine failed to expose core")
			return
		for shot in 3:
			if wave == 0 and shot == 0: observed_hit_pause = false
			await click_at(game.CORE)
			await until(func(): return game.attack_windup <= 0, 0.3)
			if wave == 0 and shot == 0:
				if not expect(game.attack_result == "hit" and game.boss_hp == 20 and game.message != game.GUARD_NOTICE,
						"Open core shows probe impact and clears the old block notice"):
					return
				if not expect(observed_hit_pause or (game.boss_hurt_age >= 0 and game.impact_pause > 0), "Probe hit triggers boss reaction and hit pause"):
					return
				await capture("combat-probe.png")
			if game.boss_hp == 0:
				break
			await create_timer(0.43).timeout
		if game.boss_hp == 0:
			break
	if not expect(game.boss_hp == 0 and game.hp == 5, "Avoided hazards and stopped pressure machine"):
		return
	record("press-stopped")
	await walk(Vector2(399, 182))
	await tap(KEY_E)
	if not expect(game.screen == "log" and game.log_read and game.saved_stage == 0, "Evidence before committing rewind"):
		return
	await tap(KEY_ENTER)
	if not expect(game.screen == "rewind", "Rewind requires explicit confirmation"):
		return
	await tap(KEY_ESCAPE)
	if not expect(game.screen == "play" and game.cycle == 1 and game.saved_stage == 0, "Cancellation preserves current round"):
		return
	await tap(KEY_E)
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	if not await until(func(): return game.screen == "play" and game.cycle == 2, 2):
		fail("Confirmed rewind did not return to intake")
		return
	if not expect(game.room == "intake" and game.build_id == "" and game.saved_stage == 2 and game.retained_build == "probe", "Rewind resets loadout and retains evidence"):
		return
	record("rewind-committed")
	game.free()
	game = SCENE.instantiate()
	root.add_child(game)
	await process_frame
	if not expect(game.saved_stage == 2, "New scene loads saved checkpoint from disk"):
		return
	await tap(KEY_ENTER)
	await walk(Vector2(171, 150))
	await tap(KEY_E)
	if not expect(game.room == "bypass", "B-17 opens with retained evidence"):
		return
	await walk(Vector2(320, 188))
	await tap(KEY_E)
	if not expect(game.screen == "complete" and game.saved_stage == 3, "Supply record reached and persisted"):
		return
	facts.coreLoop = "PASS"
	facts.outcome = "PASS"
	record("b17-record-reached")
	await capture("outcome.png")
	await tap(KEY_ENTER)
	if not expect(game.screen == "play" and game.cycle == 1 and game.hp == 5 and game.saved_stage == 0, "Restart resets campaign"):
		return
	record("new-run")
	await walk(Vector2(320, 176))
	await tap(KEY_E)
	await tap(KEY_1)
	await walk(Vector2(463, 151))
	await tap(KEY_E)
	if not await until(func(): return game.boss_phase == "warn" and game.boss_time <= 0.055, 3):
		fail("Could not reach the last moment of the pressure warning")
		return
	send_key(KEY_S, true)
	await tap(KEY_SPACE)
	send_key(KEY_S, false)
	var remaining: float = game.dash_cooldown
	await tap(KEY_SPACE)
	# Two rendered frames can share a physics tick; cooldown must not increase.
	if not expect(game.dash_cooldown <= remaining, "Repeated dodge input respects cooldown"):
		return
	if not await until(func(): return game.boss_phase == "strike" and game.boss_fx_age >= 0.033, 1):
		fail("Pressure strike did not begin")
		return
	if not expect(game.hp == 5 and game.evade_flash > 0 and game.strike_hit and game.hurt_age < 0,
			"Last moment dodge absorbs the strike while still inside its area"):
		return
	record("last-moment-dodge")
	await capture("boss-slam-dodge.png")
	await create_timer(0.23).timeout
	if not expect(game.hp == 5 and game.dash_left == 0 and game.hazard.has_point(game.player),
			"One avoided strike cannot damage the player after dodge protection ends"):
		return
	await tap(KEY_ESCAPE)
	await tap(KEY_TAB)
	await tap(KEY_TAB)
	await tap(KEY_ENTER)
	if not expect(game.reduced_motion, "Reduced effects can be enabled before a live strike"):
		return
	await tap(KEY_ESCAPE)
	if not await until(func(): return game.boss_phase == "warn", 3):
		fail("Could not reach the early-dodge case")
		return
	send_key(KEY_S, true)
	await tap(KEY_SPACE)
	send_key(KEY_S, false)
	if not await until(func(): return game.hp == 3, 2):
		fail("Dodging too early while remaining in the strike area should take damage")
		return
	record("early-dodge-takes-damage")
	await capture("boss-low-motion.png")
	await tap(KEY_ESCAPE)
	await tap(KEY_TAB)
	await tap(KEY_TAB)
	await tap(KEY_ENTER)
	await tap(KEY_ESCAPE)
	if not await until(func(): return game.hp == 1, 4):
		fail("Could not reach a nonfatal full-effects hit")
		return
	if not expect(game.hurt_age >= 0 and game.evade_flash == 0 and game.attack_windup == 0, "Hurt cancels windup and is distinct from evade"):
		return
	record("player-hurt")
	await capture("player-hurt.png")
	if not await until(func(): return game.screen == "dying", 4):
		fail("Fatal strike did not begin knockdown")
		return
	var dead_position: Vector2 = game.player
	var frozen_boss_time: float = game.boss_time
	send_key(KEY_W, true)
	await tap(KEY_SPACE)
	await tap(KEY_J)
	await tap(KEY_E)
	send_key(KEY_W, false)
	if not expect(game.hp == 0 and game.player == dead_position and game.dash_left == 0 and game.attack_windup == 0,
			"Knocked down player cannot move, dodge, attack, or interact"):
		return
	await until(func(): return game.death_age >= 0.16, 0.5)
	await capture("player-knockdown.png")
	record("player-knocked-down")
	await until(func(): return game.death_age >= 0.65, 0.7)
	if not expect(game.screen == "dying" and game.boss_time == frozen_boss_time and game.saved_stage == 0,
			"Death animation freezes combat without advancing the iteration"):
		return
	await capture("player-dead.png")
	if not await until(func(): return game.screen == "failed", 2):
		fail("Standing in three marked strikes should fail")
		return
	if not expect(game.cycle == 1 and game.saved_stage == 0, "Failure does not advance iteration"):
		return
	record("failed-by-standing-still")
	await tap(KEY_ENTER)
	if not expect(game.screen == "play" and game.room == "intake" and game.hp == 5 and game.build_id == ""
			and game.hurt_age < 0 and game.boss_hurt_age < 0 and game.death_age == 0 and game.impact_pause == 0,
			"Retry restores first round and clears hurt/death state"):
		return
	facts.restart = "PASS"
	record("retry-first-round")
	if not expect(not game.reduced_motion, "Full effects can be restored after retry"):
		return
	await walk(Vector2(320, 176))
	await tap(KEY_E)
	await tap(KEY_1)
	await walk(Vector2(463, 151))
	await tap(KEY_E)
	await walk(Vector2(320, 191))
	if not await until(func(): return game.boss_phase == "warn", 3):
		fail("Close range pressure machine failed to warn")
		return
	if not expect(game.hazard.size.x > 100, "Pressure machine uses sweep at close range"):
		return
	await walk(Vector2(320, 218))
	if not await until(func(): return game.boss_phase == "strike" and game.boss_fx_age >= 0.033, 2):
		fail("Could not capture the pressure sweep")
		return
	await capture("boss-sweep.png")
	if not await until(func(): return game.boss_phase == "open", 2):
		fail("Sweep did not expose the core")
		return
	for shot in 3:
		if not await until(func(): return game.attack_cooldown <= 0 and game.impact_pause <= 0, 0.6):
			fail("Short arc did not recover")
			return
		await click_at(game.CORE)
		await until(func(): return game.attack_windup <= 0, 0.3)
		if shot == 0:
			if not expect(game.attack_result == "hit" and game.boss_hp == 16, "Short arc impact removes eight structure"):
				return
			await capture("combat-arc.png")
	if not expect(game.boss_hp == 0 and game.hp == 5, "Short arc stops machine from outside the sweep"):
		return
	record("arc-stopped-machine")
	await tap(KEY_ESCAPE)
	await tap(KEY_TAB)
	await tap(KEY_TAB)
	await tap(KEY_ENTER)
	if not expect(game.screen == "paused" and game.reduced_motion, "Reduced effects can be enabled from pause"):
		return
	await tap(KEY_ESCAPE)
	if not await until(func(): return game.attack_cooldown <= 0 and game.attack_age < 0, 0.6):
		fail("Attack did not recover after resuming")
		return
	await click_at(game.player + Vector2(70, 0))
	if not await until(func(): return game.attack_age >= 0 and game.attack_result == "miss", 0.6):
		fail("Reduced effects interrupted the attack input")
		return
	record("reduced-motion-attack")
	end(0)

func record(id: String) -> void:
	checkpoints.append({"id": id, "room": game.room, "cycle": game.cycle, "stage": game.saved_stage,
		"hp": game.hp, "boss_hp": game.boss_hp, "screen": game.screen, "module": game.build_id})
	checkpoints[-1]["evade"] = game.evade_flash > 0
	checkpoints[-1]["dash_left"] = game.dash_left
	checkpoints[-1]["boss_phase"] = game.boss_phase
	checkpoints[-1]["hurt_age"] = game.hurt_age
	checkpoints[-1]["death_age"] = game.death_age

func capture(name: String) -> Image:
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	if frame != null and frame.save_png(output.path_join(name)) == OK:
		frames.append(name)
		return frame
	return null

func until(predicate: Callable, timeout: float) -> bool:
	var stop := Time.get_ticks_msec() + roundi(timeout * 1000)
	while not predicate.call() and not finished and Time.get_ticks_msec() < stop:
		if not root.has_focus(): root.grab_focus()
		await process_frame
	return predicate.call() and not finished

func walk(target: Vector2) -> void:
	for axis in 2:
		var difference: float = target[axis] - game.player[axis]
		if absf(difference) <= 5:
			continue
		var key: Key = (KEY_D if difference > 0 else KEY_A) if axis == 0 else (KEY_S if difference > 0 else KEY_W)
		send_key(key, true)
		var arrived := await until(func(): return absf(target[axis] - game.player[axis]) < 6, 3)
		send_key(key, false)
		if not arrived:
			fail("Movement did not reach %s from %s (focus=%s)" % [target, game.player, root.has_focus()])
			return

func send_key(key: Key, down: bool) -> void:
	if down and not root.has_focus(): root.grab_focus()
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = down
	Input.parse_input_event(event)

func tap(key: Key) -> void:
	send_key(key, true)
	await process_frame
	send_key(key, false)
	await process_frame

func click_at(world_position: Vector2) -> void:
	if not root.has_focus(): root.grab_focus()
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = game.presentation.position + world_position * (game.presentation.size.x / 640.0)
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func expect(condition: bool, label: String) -> bool:
	if not condition:
		fail(label)
	return condition

func fail(reason: String) -> void:
	if finished:
		return
	printerr(reason)
	record("failure: " + reason)
	end(1)

func end(code: int) -> void:
	finished = true
	var evidence := FileAccess.open(output.path_join("trace.json"), FileAccess.WRITE)
	if evidence != null:
		evidence.store_string(JSON.stringify({"checks": facts, "checkpoints": checkpoints,
			"frames": frames, "engine": Engine.get_version_info().string,
			"renderer": RenderingServer.get_video_adapter_name(), "viewport": root.size}, "\t"))
		evidence.close()
	game.queue_free()
	await process_frame
	await process_frame
	quit(code)
