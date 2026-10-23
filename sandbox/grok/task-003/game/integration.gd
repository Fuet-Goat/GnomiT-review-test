extends Control
class PreviewProgress extends RefCounted:
	var data: Dictionary={"light":0}
	func total_stars() -> int:return 0
	func is_unlocked(id: String) -> bool:return id=="entry"

var map
var capture_mode := false
var mode_label: Label

func _ready() -> void:
	map=load("res://integration_map.gd").new()
	map.configure(PreviewProgress.new(),false)
	add_child(map)
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map.layout()
	var panel:=PanelContainer.new()
	panel.position=Vector2(12,852)
	panel.size=Vector2(408,94)
	panel.add_theme_stylebox_override("panel",map._panel_style(Color("244a42ed")))
	map.status.hide()
	map.follow_button.hide()
	add_child(panel)
	var rows:=VBoxContainer.new()
	panel.add_child(rows)
	mode_label=Label.new()
	mode_label.text="MASTER R3 · ORIGINAL MAP LIGHTING"
	mode_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(mode_label)
	var controls:=HBoxContainer.new()
	controls.alignment=BoxContainer.ALIGNMENT_CENTER
	rows.add_child(controls)
	for pair in [["Old guide",false],["Master R3",true]]:
		var button:=Button.new()
		button.text=pair[0]
		button.pressed.connect(choose_master.bind(bool(pair[1])))
		controls.add_child(button)
	var replay:=Button.new()
	replay.text="Find / Replay"
	replay.pressed.connect(func():map.follow=true;map.guide.greet())
	controls.add_child(replay)
	var motion:=CheckButton.new()
	motion.text="Reduced"
	motion.toggled.connect(func(enabled):map.reduced_motion=enabled)
	controls.add_child(motion)
	var note:=Label.new()
	note.text="Stationary preview · drag to inspect · no travel"
	note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size",13)
	rows.add_child(note)
	if DisplayServer.get_screen_count()>1:
		DisplayServer.window_set_current_screen(1)
		DisplayServer.window_set_position(DisplayServer.screen_get_position(1)+Vector2i(70,40))
	if not capture_mode:map.master.greet()

func choose_master(enabled: bool) -> void:
	map.set_master(enabled)
	mode_label.text=("MASTER R3" if enabled else "OLD GUIDE")+" · ORIGINAL MAP LIGHTING"

