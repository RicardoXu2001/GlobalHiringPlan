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
	await click_at(Vector2(110, 283))
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
	await walk(game.SHOP + Vector2(0, 6))
	await tap(KEY_E)
	if not expect(game.screen == "shop", "World shop interaction opens equipment stock"): return
	await capture("expedition-shop.png")
	await click_at(Vector2(160, 247))
	if not expect(game.build_id == "nailer" and game.cash == 18, "Purchase equips pressure nailer and spends 12"): return
	await click_at(Vector2(160, 278))
	if not expect(game.tier == 1 and game.cash == 8, "Weapon slot upgrade spends 10"): return
	await click_at(Vector2(310, 278))
	if not expect(game.refreshed and game.cash == 2, "One paid refresh spends 6"): return
	var inventory: Array = game.stock.duplicate()
	await click_at(Vector2(310, 278))
	await click_at(Vector2(160, 247))
	if not expect(game.cash == 2 and game.stock == inventory, "Disabled refresh and unaffordable purchase preserve funds"): return
	facts.coreLoop = "PASS"
	record("grafted-and-rearmed")
	game.queue_free()
	await process_frame
	game = SCENE.instantiate()
	root.add_child(game)
	await create_timer(0.25).timeout
	await click_at(Vector2(110, 283))
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
	await click_at(Vector2(340, 240))
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
	end(0)

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
			if enemy.hp > 0 and enemy.phase in ["warn", "strike"] and enemy.zone.grow(10).has_point(game.player):
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
