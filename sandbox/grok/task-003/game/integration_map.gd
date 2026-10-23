extends "res://scripts/r3/island_map.gd"
## Real inherited map, read-only route context: camera drag works, travel disabled.
var old_guide: Node3D
var master: Node3D
var showing_master := true

func _ready() -> void:
	super._ready()
	old_guide=guide
	old_guide.set_motion(false)
	old_guide.set_process(false)
	master=load("res://master_guide.gd").new()
	native_scene.add_child(master)
	master.position=old_guide.position
	master.rotation=old_guide.rotation
	set_master(true)
	status.text="Stationary integration preview.\nDrag to explore; Find gnome to greet."
	for child in overlay.get_children():
		if child is Button and child.text=="Settings":child.hide()
		elif child is Label and child.text=="R3 · THE SURFACE":child.text="MASTER R3 · MAP CONTEXT"

func set_master(enabled: bool) -> void:
	# Selection cancels both greetings, including a hidden or reselected master.
	old_guide.set_motion(false)
	master.set_motion(false)
	showing_master=enabled
	old_guide.visible=not enabled
	master.visible=enabled
	old_guide.set_process(not enabled)
	master.set_process(enabled)
	guide=master if enabled else old_guide
	guide.set_motion(not reduced_motion and has_focus_window)
	if enabled:master.pose(0)
	else:
		old_guide.animation_player.play("r3/greeting")
		old_guide.animation_player.seek(0,true)
		old_guide.animation_player.advance(0)
		old_guide.animation_player.stop(true)
	status.text="Master R3 · original greeting" if enabled else "Old guide · original map reference"

func walk_to(_s: float,_id: String="") -> bool:
	last_tap_result="preview_no_travel"
	status.text="Placement + greeting only.\nNo authored walking clip in this master."
	return false

func tap(_p: Vector2) -> void:
	last_tap_result="preview_no_travel"
	status.text="Drag to explore.\nUse Replay or Find gnome to greet."

func _move_pointer(p: Vector2,relative: Vector2) -> void:
	super._move_pointer(p,relative)
	if pointer_distance>=DRAG_THRESHOLD:status.text="Exploring · stationary context preview."

