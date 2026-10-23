extends Node3D
## Compatibility wrapper only: original accepted clip, no idle or gait invention.
const SCALE := 0.61279296875
var model: Node3D
var guide_root: Node3D
var animation_player: AnimationPlayer
var clip: StringName
var _motion := true
var _greeting := false
var _greeting_time := 0.0

func _ready() -> void:
	model=load("res://assets/gnome_r3.glb").instantiate() as Node3D
	add_child(model)
	model.scale=Vector3.ONE*SCALE
	guide_root=model.find_child("R2_GnomeRoot",true,false)
	animation_player=model.find_child("AnimationPlayer",true,false)
	assert(guide_root!=null and animation_player!=null)
	for name in animation_player.get_animation_list():
		if name!="RESET":clip=name
	assert(not clip.is_empty())
	assert(is_equal_approx(animation_player.get_animation(clip).length,6.0))
	assert(animation_player.get_animation(clip).loop_mode==Animation.LOOP_NONE)
	animation_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	pose(0)

func pose(seconds: float) -> void:
	animation_player.play(clip)
	animation_player.seek(clampf(seconds,0,6),true)
	animation_player.advance(0)

func set_walk(_distance_delta: float,moving: bool,heading: float) -> void:
	assert(not moving,"Map context probe has no walking clip; travel must stay disabled")
	rotation.y=heading

func set_motion(enabled: bool) -> void:
	_motion=enabled
	if not enabled:
		_greeting=false
		_greeting_time=0
		pose(0)

func greet() -> bool:
	if not _motion or _greeting:return false
	_greeting=true
	_greeting_time=0
	pose(0)
	return true

func _process(delta: float) -> void:
	if not _motion or not _greeting:return
	_greeting_time=minf(6,_greeting_time+delta)
	pose(_greeting_time)
	if _greeting_time>=6:_greeting=false

