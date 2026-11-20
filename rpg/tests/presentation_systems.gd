extends SceneTree

const SCENE := preload("res://main.tscn")
var game
var failed := 0

func _initialize() -> void:
	call_deferred("run")

func verify(ok: bool, detail: String) -> void:
	if ok: return
	failed += 1
	push_error(detail)

func run() -> void:
	game = SCENE.instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.world.set_physics_process(false)
	await process_frame
	verify_motion()
	verify_collision()
	verify_audio()
	await verify_interfaces()
	game.queue_free()
	await process_frame
	await create_timer(0.12).timeout
	print("Presentation systems: %d failures" % failed)
	quit(1 if failed else 0)

func verify_motion() -> void:
	var motion = game.hero_motion
	for id in motion.CLIPS:
		verify(motion.player.has_animation(id), "Missing animation " + id)
		motion.sample(id, 0.00)
		verify(motion.clip == motion.CLIPS[id][0] and motion.frame == motion.CLIPS[id][1][0][1],
			"Animation cannot be entered: " + id)
		motion.sample(id, 1.0)
		verify(motion.frame == motion.CLIPS[id][1].back()[1], "Final pose differs: " + id)
	game.reset_round(1)
	game.build_id = "arc"
	game.request_attack(Vector2.LEFT)
	motion.sync(game)
	verify(motion.state == &"arc_draw" and motion.yaw < 0, "Short arc draws back before contact")
	game.tick_play(0.06)
	motion.sync(game)
	verify(motion.state == &"arc_cut" and motion.frame == 1 and motion.yaw == 0.0, "Contact frame and blade direction agree")
	motion.sample(&"arc_cut", 0.085)
	verify(motion.frame == 2 and motion.yaw > 0.5, "Cut reaches the follow-through between keyed frames")
	game.dash_cooldown = 0.0
	game.request_dash()
	motion.sync(game)
	verify(motion.state == &"dash" and motion.frame == 0, "Dash preempts strike recovery")
	game.build_id = "nailer"
	game.attack_age = 0.0
	game.dash_left = 0.0
	motion.sync(game)
	verify(motion.state == &"fire" and motion.recoil < 0, "Nailer kicks back on fire frame")
	game.build_id = "probe"
	motion.sync(game)
	verify(motion.state == &"thrust" and motion.recoil > 0, "Probe extends on thrust frame")

func verify_collision() -> void:
	game.begin_expedition()
	game.choose_expedition("arc")
	var start := Vector2(225, 272)
	game.player = start
	for i in 60: game.move(Vector2.RIGHT * game.WALK_SPEED / 60.0)
	var walked: float = game.player.x - start.x
	game.player = start
	game.set_facing(Vector2.RIGHT)
	game.dash()
	var frames := 0
	while game.dash_left > 0.0 and frames < 15:
		game.tick_play(1.0 / 60.0)
		frames += 1
	var dashed: float = game.player.x - start.x
	print("Controller: walk %.2f logical px/s, full dash %.2f logical px in %d ticks" % [walked, dashed, frames])
	verify(absf(walked - 116.0) < 0.01 and absf(dashed - 355.0 * 10.0 / 60.0) < 0.01, "Unexpected controller metrics")
	var stop_shop: Vector2 = game.world.slide_on_floor(game.SHOP + Vector2(0, 65), Vector2(0, -90))
	verify(stop_shop.y == game.SHOP.y + game.world.FOOT_RADIUS, "Large dash tunnels through shop counter")
	game.player = stop_shop
	verify(game.nearest_object() == game.SHOP, "Shop cannot be reached at counter collision")
	var flank: Vector2 = game.world.slide_on_floor(stop_shop, Vector2(38, -46))
	verify(flank.x >= game.SHOP.x + 30 and flank.y <= game.SHOP.y - 16, "Shop flank cannot be walked")
	var stop_graft: Vector2 = game.world.slide_on_floor(game.GRAFT + Vector2(0, 65), Vector2(0, -90))
	verify(stop_graft.y == game.GRAFT.y + game.world.FOOT_RADIUS, "Graft collider misses its base")
	game.stage = 4
	game.integrated = false
	var from: Vector2 = game.DEPART + Vector2(0, 45)
	game.world.slide_on_floor(from, Vector2(0, -90))
	for i in 14: game.world._physics_process(1.0 / 60.0)
	var closed: Vector2 = game.world.slide_on_floor(from, Vector2(0, -90))
	verify(closed.y >= game.DEPART.y + 6.0, "Closed gate lets the player cross")
	game.integrated = true
	game.world.slide_on_floor(from, Vector2(0, -90))
	for i in 14: game.world._physics_process(1.0 / 60.0)
	var open: Vector2 = game.world.slide_on_floor(from, Vector2(0, -90))
	verify(open.y < game.DEPART.y - 8.0, "Open gate keeps an invisible leaf")
	var post_x: float = game.DEPART.x + 25.0
	var post: Vector2 = game.world.slide_on_floor(Vector2(post_x, from.y), Vector2(0, -90))
	verify(post.y > game.DEPART.y, "Open gate loses its jamb")
	game.gear = "plating"
	game.hp = 7
	game.stock = ["capacitor", "plating", "arc"]
	game.cash = 30
	game.set_screen("shop")
	game.buy(0)
	verify(game.hp == 5 and game.max_hp() == 5, "Removing plating does not clamp HP")
	game.buy(1)
	verify(game.hp == 5 and game.max_hp() == 7, "Re-equipping plating gives free healing")

func verify_audio() -> void:
	var mix = game.audio_mix
	for name in mix.VOLUMES + [&"MusicDuck"]:
		verify(AudioServer.get_bus_index(name) >= 0, "Missing audio bus " + name)
	for id in mix.voices:
		var voice: AudioStreamPlayer = mix.voices[id]
		verify(voice.bus != &"Master" and voice.stream != null, "Unrouted or missing clip " + id)
	verify(mix.music.bus == &"MusicDuck" and mix.score.stream_count == 2 and mix.music.playing,
		"Synchronized music is missing")
	verify(mix.atmosphere.bus == &"Ambience" and mix.atmosphere.playing, "Ambience is not looping")
	var music_index := AudioServer.get_bus_index(&"Music")
	var sfx_index := AudioServer.get_bus_index(&"SFX")
	mix.set_level(&"SFX", 0.0)
	verify(AudioServer.is_bus_mute(sfx_index) and not AudioServer.is_bus_mute(music_index), "SFX mute leaks into music")
	mix.set_level(&"SFX", 0.5)
	verify(absf(AudioServer.get_bus_volume_linear(sfx_index) - 0.25) < 0.001, "SFX slider must square its gain")
	mix.set_level(&"SFX", 1.0)
	mix.set_level(&"Music", 0.65)
	mix.save_levels()
	var saved := ConfigFile.new()
	verify(saved.load(mix.SETTINGS) == OK and saved.get_value("volume", &"Music") == 0.65,
		"Category gain is not saved")
	mix.set_level(&"Music", 1.0)

func verify_interfaces() -> void:
	var screens := ["title", "choose", "exp_loadout", "paused", "settings", "shop", "log", "rewind", "failed", "complete", "confirm_new", "exp_complete"]
	for dimension in [Vector2i(1280, 720), Vector2i(2560, 1080), Vector2i(1080, 1920)]:
		root.size = dimension
		await process_frame
		game.layout()
		for scale in [1.0, 2.0]:
			game.text_scale = scale
			for screen in screens:
				game.set_screen(screen)
				await process_frame
				await process_frame
				var choice := root.gui_get_focus_owner()
				verify(is_instance_valid(choice) and game.ui.is_ancestor_of(choice), "%s loses focus at %.2f" % [screen, scale])
				var bounds := root.get_visible_rect().grow(1.5)
				for child in game.ui.find_children("*", "Control", true, false):
					if not child.is_visible_in_tree(): continue
					var transform: Transform2D = child.get_global_transform_with_canvas()
					var footprint := Rect2(transform.origin, child.size * transform.get_scale())
					verify(bounds.encloses(footprint), "%s overflows at %s: %s %s" % [screen, root.size, child.name, footprint])
		print("UI focus and viewport bounds checked at %s (100 and 200 percent)" % root.size)
	game.text_scale = 1.0
	game.set_screen("paused")
	game.open_settings()
	game.close_settings()
	verify(game.screen == "paused" and root.gui_get_focus_owner().name == &"Action_settings", "Settings back does not restore focus")
