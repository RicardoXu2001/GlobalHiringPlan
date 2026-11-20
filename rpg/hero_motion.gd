extends Node

# Body poses use the authored atlas. These clips key the hand pose and weapon on
# the same clock, which the game can hold at contact without stopping combat.
const CLIPS := {
	"idle_front": ["walk-front", [[0.0, 0, 0.19, 0.0]]],
	"idle_back": ["walk-back", [[0.0, 0, -0.14, 0.0]]],
	"walk_front": ["walk-front", [[0.0, 0, 0.15, 0.0], [0.08, 1, 0.04, 0.0], [0.16, 2, -0.06, 0.0], [0.25, 3, 0.08, 0.0], [0.33, 4, 0.17, 0.0], [0.41, 5, 0.22, 0.0], [0.50, 5, 0.15, 0.0]]],
	"walk_back": ["walk-back", [[0.0, 0, -0.1, 0.0], [0.08, 1, -0.18, 0.0], [0.16, 2, -0.08, 0.0], [0.25, 3, 0.04, 0.0], [0.33, 4, -0.06, 0.0], [0.41, 5, -0.14, 0.0], [0.50, 5, -0.1, 0.0]]],
	"arc_draw": ["arc", [[0.0, 0, -0.88, 0.0], [0.08, 0, -0.45, 0.0]]],
	"arc_cut": ["arc", [[0.0, 1, 0.0, 0.0], [0.07, 2, 0.88, 0.0], [0.14, 3, 0.52, 0.0], [0.27, 3, 0.19, 0.0]]],
	"aim": ["ranged", [[0.0, 1, 0.15, 0.0], [0.08, 1, 0.0, 0.0]]],
	"thrust": ["ranged", [[0.0, 2, 0.0, 1.25], [0.06, 2, 0.0, 0.0], [0.10, 3, 0.05, 0.0], [0.24, 3, 0.19, 0.0]]],
	"fire": ["ranged", [[0.0, 2, 0.0, -1.50], [0.045, 2, -0.16, -0.70], [0.09, 3, 0.02, 0.0], [0.17, 3, 0.19, 0.0]]],
	"dash": ["dash", [[0.0, 0, 0.48, 0.0], [0.04, 1, 0.58, 0.0], [0.08, 2, 0.62, 0.0], [0.12, 3, 0.36, 0.0], [0.16, 3, 0.19, 0.0]]],
	"hurt": ["death", [[0.0, 0, -0.34, 0.0], [0.18, 0, 0.19, 0.0]]],
	"fall": ["death", [[0.0, 0, -0.34, 0.0], [0.12, 1, -0.62, 0.0], [0.28, 2, -0.22, 0.0], [0.48, 3, 0.0, 0.0]]],
}

var player: AnimationPlayer
var state := &""
var clip := "walk-front"
var frame := 0
var yaw := 0.0
var recoil := 0.0
var direction := Vector2.RIGHT

func _ready() -> void:
	player = AnimationPlayer.new()
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	add_child(player)
	var library := AnimationLibrary.new()
	for id in CLIPS:
		var animation := Animation.new()
		var keys: Array = CLIPS[id][1]
		animation.length = maxf(0.001, keys.back()[0])
		for property in ["frame", "yaw", "recoil"]:
			var track := animation.add_track(Animation.TYPE_VALUE)
			animation.track_set_path(track, NodePath(".:" + property))
			if property == "frame": animation.value_track_set_update_mode(track, Animation.UPDATE_DISCRETE)
			for key in keys: animation.track_insert_key(track, key[0], key[track + 1])
		library.add_animation(id, animation)
	player.add_animation_library(&"", library)
	sample(&"idle_front", 0.0)

func sample(next: StringName, time: float) -> void:
	if next != state:
		state = next
		clip = CLIPS[next][0]
		player.play(next)
	player.seek(clampf(time, 0.0, player.current_animation_length), true)

func sync(game) -> void:
	direction = game.facing
	if game.screen in ["dying", "failed"]:
		sample(&"fall", (0.48 if game.death_age >= 0.16 else 0.0) if game.reduced_motion else game.death_age)
	elif game.dash_left > 0:
		direction = game.dash_dir
		sample(&"dash", game.DASH_DURATION - game.dash_left)
	elif game.attack_windup > 0.0:
		direction = game.attack_direction
		sample(&"arc_draw" if game.build_id == "arc" else &"aim", game.attack_windup_total - game.attack_windup)
	elif game.attack_age >= 0 and game.attack_age < (0.17 if game.build_id == "nailer" else 0.25):
		direction = game.attack_direction
		sample(&"arc_cut" if game.build_id == "arc" else &"fire" if game.build_id == "nailer" else &"thrust", game.attack_age)
	elif game.hurt_age >= 0.0 and game.hurt_age < 0.18:
		sample(&"hurt", game.hurt_age)
	elif game.moving and not game.reduced_motion:
		sample(&"walk_back" if game.face_index == 0 else &"walk_front", fposmod(game.walk_clock, 0.50))
	else:
		sample(&"idle_back" if game.face_index == 0 else &"idle_front", 0.0)
