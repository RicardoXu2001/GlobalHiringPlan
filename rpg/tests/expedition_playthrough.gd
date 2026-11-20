extends "res://tests/playthrough.gd"

func capture(name: String) -> Image:
	await process_frame
	await process_frame
	return await super.capture(name)

func record(id: String) -> void:
	super.record(id)
	checkpoints[-1]["expedition_stage"] = game.stage
	checkpoints[-1]["cash"] = game.cash
	checkpoints[-1]["tier"] = game.tier
	checkpoints[-1]["integrated"] = game.integrated
	checkpoints[-1]["stock"] = game.stock.duplicate()
	checkpoints[-1]["refreshed"] = game.refreshed
	checkpoints[-1]["continuable"] = not game.saved_run.is_empty()

func run() -> void:
	game = SCENE.instantiate()
	root.add_child(game)
	root.grab_focus()
	await create_timer(0.4).timeout
	if not expect(game.screen == "title" and game.saved_run.is_empty(), "Clean expedition title"): return
	facts.launch = "PASS"
	first_image = await capture("expedition-title.png")
	await click_action("expedition")
	if not expect(game.screen == "exp_loadout", "Title button opens real expedition entry"): return
	await tap(KEY_2)
	if not expect(game.campaign and game.room == "hub" and game.build_id == "probe", "Choose probe through keyboard"): return
	await capture("expedition-hub.png")
	facts.render = "PASS"
	await walk(game.DEPART + Vector2(0, 5))
	await tap(KEY_E)
	if not expect(game.stage == 0 and game.enemies.size() == 1, "Depart enters first populated room"): return
	facts.input = "PASS"
	for level in 3:
		await process_frame
		await capture("expedition-room%d.png" % (level + 1))
		if not await fight_field(): return
		if not expect(game.cash == (level + 1) * 6, "Room reward is granted once"): return
		record("room-%d-cleared" % (level + 1))
		await walk(game.EXIT + Vector2(0, 6))
		await tap(KEY_E)
	if not expect(game.stage == 3 and game.boss_hp == 32, "Fourth room is the guardian"): return
	if not await fight_guardian(): return
	await capture("expedition-guardian.png")
	await walk(game.EXIT + Vector2(0, 6))
	await tap(KEY_E)
	if not expect(game.room == "hub" and game.cash == 30 and game.organ and game.hp == 5, "Guardian returns one organ and restores endurance"): return
	await walk(game.GRAFT + Vector2(0, 8))
	await tap(KEY_E)
	if not expect(game.integrated and not game.organ, "Graft integrates the collected heart"): return
	await capture("expedition-graft.png")
	await tap(KEY_E)
	if not expect(game.integrated and game.cash == 30, "Repeated graft cannot duplicate reward"): return
	await walk(game.SHOP + Vector2(0, 12))
	await tap(KEY_E)
	if not expect(game.screen == "shop", "World shop interaction opens equipment stock"): return
	await capture("expedition-shop.png")
	await click_action("buy_0")
	if not expect(game.build_id == "nailer" and game.cash == 18, "Purchase equips pressure nailer and spends 12"): return
	await click_action("improve")
	if not expect(game.tier == 1 and game.cash == 8, "Weapon slot upgrade spends 10"): return
	await click_action("refresh_stock")
	if not expect(game.refreshed and game.cash == 2, "One paid refresh spends 6"): return
	var inventory: Array = game.stock.duplicate()
	await click_action("refresh_stock")
	await click_action("buy_0")
	if not expect(game.cash == 2 and game.stock == inventory, "Disabled refresh and unaffordable purchase preserve funds"): return
	facts.coreLoop = "PASS"
	record("grafted-and-rearmed")
	game.queue_free()
	await process_frame
	game = SCENE.instantiate()
	root.add_child(game)
	await create_timer(0.25).timeout
	await click_action("expedition")
	if not expect(game.room == "hub" and game.integrated and game.cash == 2 and game.tier == 1 and game.stock == inventory and game.build_id == "nailer", "Disk reload retains graft, equipment, funds and stock"): return
	await walk(game.DEPART + Vector2(0, 5))
	await tap(KEY_E)
	if not expect(game.stage == 5 and game.enemies.size() == 2, "Depart again carries upgraded weapon into real encounter"): return
	await capture("expedition-rearmed.png")
	if not await fight_field(): return
	await walk(game.EXIT + Vector2(0, 6))
	await tap(KEY_E)
	if not expect(game.screen == "exp_complete", "Preview encounter reaches a defined end"): return
	facts.outcome = "PASS"
	record("rearmed-encounter-completed")
	await capture("expedition-outcome.png")
	await click_action("restart")
	if not expect(game.screen == "exp_loadout" and game.cash == 0 and game.tier == 0 and not game.integrated, "Restart resets the expedition"): return
	facts.restart = "PASS"
	record("fresh-expedition")
	await tap(KEY_1)
	await walk(game.DEPART + Vector2(0, 5))
	await tap(KEY_E)
	if not await fight_field(): return
	if not expect(game.build_id == "arc" and game.cash == 6, "New arc sweeps the first encounter with normal reward"): return
	await capture("expedition-arc.png")
	await walk(game.EXIT + Vector2(0, 6))
	await tap(KEY_E)
	if not await until(func(): return game.screen == "failed", 12):
		fail("Standing in enemy attacks did not produce a defeat")
		return
	if not expect(game.saved_run.is_empty(), "Defeat invalidates the old room checkpoint"): return
	record("expedition-defeated")
	game.queue_free()
	await process_frame
	game = SCENE.instantiate()
	root.add_child(game)
	await create_timer(0.2).timeout
	if not expect(game.saved_run.is_empty(), "Defeated expedition cannot be revived by disk reload"): return
	if not await hub_restart_regression(): return
	if not await feedback_regression(): return
	end(0)

func hub_restart_regression() -> bool:
	game.begin_expedition()
	await tap(KEY_2)
	game.stage = 1
	game.load_stage()
	game.player = game.SPAWN
	game.enemies.clear()
	game.spawn_enemy("worker", game.SPAWN - Vector2(72, 36))
	if not await until(func(): return game.enemies[0].phase == "warn", 1.4):
		fail("Enemy did not lock onto the player before restart")
		return false
	await tap(KEY_ESCAPE)
	if not expect(game.screen == "paused", "Pause during enemy windup"): return false
	await click_action("restart")
	if not expect(game.screen == "exp_loadout", "Restart from pause opens expedition loadout"): return false
	await tap(KEY_2)
	await create_timer(1.25).timeout
	if not expect(game.screen == "play" and game.room == "hub" and game.hp == game.max_hp(),
			"Enemy attack from the old room must not deduct endurance in the hub"): return false
	if not expect(game.enemies.is_empty() and game.effects.is_empty(),
			"Restart removes the previous room's enemies and effects"): return false
	record("hub-safe-after-restarting-during-windup")
	return true

# Isolated feedback fixtures follow the complete, unmodified expedition/save path above.
func feedback_regression() -> bool:
	game.begin_expedition()
	await tap(KEY_1)
	game.stage = 0
	game.load_stage()
	game.enemies.clear()
	game.set_facing(Vector2.RIGHT)
	await tap(KEY_J)
	if not await until(func(): return game.attack_cooldown > 0 and game.attack_cooldown < 0.09, 0.6):
		fail("Could not reach the attack buffer window")
		return false
	await tap(KEY_J)
	if not await until(func(): return game.combo_step == 1, 0.3):
		fail("Late attack input was dropped instead of buffered")
		return false
	if not expect(game.attack_cooldown > 0.2, "Buffered input starts one complete next swing"): return false
	await tap(KEY_J)
	await create_timer(0.48).timeout
	if not expect(game.combo_step == 1, "An early press cannot queue an indefinite extra attack"): return false
	await tap(KEY_J)
	if not await until(func(): return game.attack_cooldown > 0 and game.attack_cooldown < 0.09, 0.6): return false
	await tap(KEY_J)
	var combo: int = game.combo_step
	await tap(KEY_SPACE)
	if not expect(game.attack_buffer == 0 and game.attack_windup == 0 and game.dash_cooldown > 0, "Dodge cancels windup and queued attack"): return false
	await create_timer(0.24).timeout
	if not expect(game.combo_step == combo and game.attack_age < 0, "Dodge does not release a phantom queued swing"): return false
	record("buffered-attack-and-dodge-cancel")
	game.build_id = "nailer"
	game.player = Vector2(230, 244)
	game.set_facing(Vector2.LEFT)
	var cash: int = game.cash
	var hp: int = game.hp
	await click_at(Vector2(181, 244))
	if not await until(func(): return game.world.fixtures.filter(func(f): return f.hp <= 0).size() == 1, 0.2):
		fail("A nailer shot did not break one coolant fixture")
		return false
	if not await until(func(): return game.world.fixtures.all(func(f): return f.hp <= 0), 0.5):
		fail("Nearby coolant fixture did not react after its fuse")
		return false
	if not expect(game.hp == hp and game.cash == cash, "Decorative coolant reaction cannot damage the player or award resources"): return false
	if not expect(game.attack_distance < 100, "Nailer tracer stops at its contacted fixture"): return false
	await capture("feedback-coolant-burst.png")
	if not await until(func(): return game.world.feedback.landed_count > 0, 1.4):
		fail("Ballistic debris never reached the ground")
		return false
	if not expect(not game.world.feedback.marks.is_empty(), "Landed droplets leave persistent surface marks"): return false
	await capture("feedback-surface-marks.png")
	game.player = Vector2(320, 135)
	await click_at(Vector2(320, 80))
	if not await until(func(): return game.attack_age >= 0 and game.attack_distance <= 1, 0.3):
		fail("Outward shots at the back wall escaped the room")
		return false
	for i in 30: game.world.impact(Vector2(230, 220), Vector2.RIGHT, "metal", "heavy")
	if not expect(game.world.feedback.particles.size() <= 240 and game.world.feedback.marks.size() <= 96
		and game.world.feedback.contacts.size() <= 8, "Overlapping impacts remain within particle, surface and contact budgets"): return false
	game.cycle_shake()
	game.cycle_shake()
	game.toggle_flash()
	game.world.impact(Vector2(230, 220), Vector2.RIGHT, "metal", "heavy")
	await physics_frame
	await process_frame
	if not expect(game.world.position == Vector2.ZERO and game.world.feedback.tint(Vector2(230, 220)) == Color.WHITE
		and not game.reduced_motion, "Independent shake and flash options preserve full motion"): return false
	game.cycle_shake()
	game.toggle_flash()
	game.toggle_motion()
	game.world.feedback.reset()
	game.world.impact(Vector2(230, 220), Vector2.RIGHT, "metal")
	await physics_frame
	await process_frame
	if not expect(game.world.position == Vector2.ZERO and game.world.feedback.particles.size() <= 10, "Reduced effects disable shake and reduce particle count"): return false
	record("environment-feedback-and-reduced-effects")
	game.begin_expedition()
	if not expect(game.world.feedback.particles.is_empty() and game.world.feedback.marks.is_empty() and game.attack_buffer == 0, "New expedition clears visual residue and buffered input"): return false
	return true

func click_action(id: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var button := game.ui.find_child("Action_" + id, true, false) as Button
	if not is_instance_valid(button):
		fail("Missing UI action " + id)
		return
	var at := button.get_global_transform_with_canvas() * (button.size * 0.5)
	await click_at((at - game.presentation.position) * (640.0 / game.presentation.size.x) - game.world.position * 0.5)

func fight_field() -> bool:
	var limit := Time.get_ticks_msec() + 18000
	while not game.cleared and not finished and Time.get_ticks_msec() < limit:
		if game.screen != "play":
			fail("Field combat ended before clear")
			return false
		var target: Dictionary = {}
		for enemy in game.enemies:
			if enemy.hp > 0 and (target.is_empty() or game.player.distance_to(enemy.p) < game.player.distance_to(target.p)):
				target = enemy
		if target.is_empty(): break
		var movement := Vector2.ZERO
		for enemy in game.enemies:
			if enemy.hp > 0 and enemy.phase in ["warn", "strike"] and game.enemy_attack_contains(enemy, game.player):
				movement = Vector2.RIGHT if game.player.x < 385 else Vector2.LEFT
		var stand_off: float = float(game.WEAPONS[game.build_id].reach) - 12
		if movement == Vector2.ZERO and game.player.distance_to(target.p) > stand_off:
			movement = (target.p - game.player).normalized()
		for pair in [[KEY_A, movement.x < -0.2], [KEY_D, movement.x > 0.2], [KEY_W, movement.y < -0.2], [KEY_S, movement.y > 0.2]]:
			send_key(pair[0], pair[1])
		if game.attack_cooldown <= 0:
			await click_at(target.p)
		await process_frame
	for key in [KEY_A, KEY_D, KEY_W, KEY_S]: send_key(key, false)
	if not expect(game.cleared and game.hp > 0, "Field encounter cleared with normal damage rules"): return false
	return true

func fight_guardian() -> bool:
	for wave in 7:
		if not await until(func(): return game.boss_phase == "warn", 3):
			fail("Guardian did not telegraph")
			return false
		if wave == 0: await capture("expedition-guardian-warn.png")
		var key: Key = KEY_D if game.player.x < 340 else KEY_A
		send_key(key, true)
		await tap(KEY_SPACE)
		if not await until(func(): return not game.hazard.grow(12).has_point(game.player), 0.6):
			send_key(key, false)
			fail("Dodge and movement did not leave the locked column")
			return false
		send_key(key, false)
		if not await until(func(): return game.boss_phase == "open", 2):
			fail("Guardian did not open")
			return false
		for shot in 3:
			await click_at(game.CORE)
			await create_timer(0.45).timeout
			if game.boss_hp == 0: return true
	fail("Guardian did not go down")
	return false
