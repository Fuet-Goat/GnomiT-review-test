extends Node3D
## Exact v004 volumetric guide, with original finite greeting and calm idle.
## Walking is a distance-driven procedural prototype, not an authored clip.
## The caller moves this Node3D along its route; this script never changes position.

@export var model_path := "res://assets/r3/gnome_guide.glb"
@export_range(0.1, 2.0) var character_scale := 0.85
@export var stride_cycle_metres := 0.42

var model: Node3D
var guide_root: Node3D
var torso: Node3D
var animation_player: AnimationPlayer
var leg_pivots: Array[Node3D] = []
var _leg_points: Array = []
var _torso_rest := Vector3.ZERO
var _motion := true
var _moving := false
var _greeting := false
var _greeting_time := 0.0
var _phase := 0.0
var _walk_blend := 0.0
const GREETING_SECONDS := 6.0

func _ready() -> void:
	var scene := load(model_path) as PackedScene
	if scene == null:
		push_error("R3 guide missing: " + model_path)
		return
	model = scene.instantiate() as Node3D
	model.name = "OriginalVolumetricGuide"
	add_child(model)
	model.scale *= character_scale
	guide_root = model.find_child("Guide_Root", true, false) as Node3D
	if guide_root == null:
		push_error("R3 guide has no original Guide_Root")
		return
	torso = model.find_child("Guide_BreathingTorso", true, false) as Node3D
	_torso_rest = torso.position
	_build_animation_library()
	_build_procedural_legs()
	_idle()

func _build_animation_library() -> void:
	for candidate in model.find_children("*", "AnimationPlayer", true, false):
		animation_player = candidate as AnimationPlayer
		break
	if animation_player == null:
		push_error("R3 guide original animation player missing")
		return
	var greeting := Animation.new()
	greeting.length = GREETING_SECONDS
	greeting.loop_mode = Animation.LOOP_NONE
	var idle := Animation.new()
	idle.length = GREETING_SECONDS
	idle.loop_mode = Animation.LOOP_LINEAR
	var seen: Dictionary = {}
	for source_name in animation_player.get_animation_list():
		if String(source_name).get_file().to_upper() == "RESET":
			continue
		var source := animation_player.get_animation(source_name)
		for index in range(source.get_track_count()):
			if not source.track_is_enabled(index):
				continue
			var path := String(source.track_get_path(index))
			if not "Guide" in path:
				continue
			var identity := "%s|%s" % [path, source.track_get_type(index)]
			if seen.has(identity):
				continue
			seen[identity] = true
			source.copy_track(index, greeting)
			var track_path := source.track_get_path(index)
			var target_name := String(track_path.get_name(track_path.get_name_count() - 1))
			if "EyeBlink" in target_name or target_name == "Guide_BreathingTorso":
				source.copy_track(index, idle)
	var library := AnimationLibrary.new()
	library.add_animation("greeting", greeting)
	library.add_animation("idle", idle)
	animation_player.add_animation_library("r3", library)
	animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	animation_player.play("r3/greeting")
	animation_player.seek(0.0, true)
	animation_player.advance(0.0)

func _build_procedural_legs() -> void:
	# Boots, their stitches, and trouser cuffs retain their exact native meshes.
	# Each pair receives an independent runtime hip pivot, preserving transforms.
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.name = "R3_LegLeft" if side < 0 else "R3_LegRight"
		guide_root.add_child(pivot)
		pivot.position = Vector3(side * 0.112, 0.245, 0.0)
		var pieces: Array[Node3D] = []
		for child in guide_root.get_children():
			if not child is Node3D or child == pivot:
				continue
			var item := child as Node3D
			var label := String(item.name)
			if not ("boot" in label or "trouser cuff" in label):
				continue
			# Stitch curves have their vertices in root coordinates, origin at zero.
			var centre_x := item.position.x
			if item is MeshInstance3D:
				var mesh_item := item as MeshInstance3D
				centre_x = (item.transform * mesh_item.get_aabb().get_center()).x
			if centre_x * side > 0:
				pieces.append(item)
		for item in pieces:
			item.reparent(pivot, true)
		var points: Array[Vector3] = []
		for item in pieces:
			if not item is MeshInstance3D:
				continue
			var aabb := (item as MeshInstance3D).get_aabb()
			for corner in range(8):
				points.append(item.transform * aabb.get_endpoint(corner))
		leg_pivots.append(pivot)
		_leg_points.append(points)

func set_walk(distance_delta: float, moving: bool, heading: float) -> void:
	rotation.y = heading # Model front is +Z; heading is Godot yaw in radians.
	_moving = moving and _motion
	if _motion and moving:
		_phase = fposmod(_phase + absf(distance_delta) * TAU / maxf(0.05, stride_cycle_metres), TAU)
		if _greeting:
			_idle()

func set_motion(enabled: bool) -> void:
	_motion = enabled
	if not enabled:
		_moving = false
		_greeting = false
		_walk_blend = 0.0
		_phase = 0.0
		if animation_player != null:
			animation_player.play("r3/greeting")
			animation_player.seek(0.0, true)
			animation_player.advance(0.0)
			animation_player.stop(true)
		_apply_gait()
	else:
		_idle()

func greet() -> bool:
	if not _motion or _moving or _greeting or animation_player == null:
		return false
	_greeting = true
	_greeting_time = 0.0
	animation_player.play("r3/greeting")
	animation_player.seek(0.0, true)
	animation_player.advance(0.0)
	return true

func _idle() -> void:
	_greeting = false
	if animation_player != null:
		# Settle every greeting channel before the restricted idle takes over.
		# This also recovers the resting hand if route motion interrupts a wave.
		animation_player.play("r3/greeting")
		animation_player.seek(GREETING_SECONDS, true)
		animation_player.advance(0.0)
		animation_player.play("r3/idle")
		animation_player.advance(0.0)

func _process(delta: float) -> void:
	if guide_root == null:
		return
	if _motion and animation_player != null:
		if _greeting:
			_greeting_time = minf(GREETING_SECONDS, _greeting_time + delta)
			animation_player.seek(_greeting_time, true)
			animation_player.advance(0.0)
			if _greeting_time >= GREETING_SECONDS:
				_idle()
		else:
			animation_player.advance(delta)
	_walk_blend = move_toward(_walk_blend, 1.0 if _moving and _motion else 0.0, delta * 7.0)
	_apply_gait()

func _apply_gait() -> void:
	for index in range(leg_pivots.size()):
		var pivot := leg_pivots[index]
		var cycle := _phase + float(index) * PI
		var swing := sin(cycle)
		pivot.rotation.x = swing * 0.24 * _walk_blend
		pivot.position.y = 0.245
		# Contact correction keeps the full native boot mesh above the ground.
		# One boot lifts while the other maintains its lowest point at ground.
		var minimum := INF
		for point: Vector3 in _leg_points[index]:
			minimum = minf(minimum, (pivot.transform * point).y)
		if not is_inf(minimum):
			pivot.position.y += -minimum + maxf(0.0, swing) * 0.035 * _walk_blend
	if torso != null:
		torso.position = _torso_rest + Vector3(0.0, absf(sin(_phase)) * 0.009 * _walk_blend, 0.0)
