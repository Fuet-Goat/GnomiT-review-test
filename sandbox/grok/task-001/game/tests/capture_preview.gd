extends SceneTree
var app
func _initialize() -> void:
	call_deferred("run")
func snap(name: String) -> void:
	await process_frame
	await create_timer(0.32).timeout
	var image: Image = root.get_texture().get_image()
	var output: String = ProjectSettings.globalize_path("res://verification/screenshots/" + name + ".png")
	var result: Error = image.save_png(output)
	print("CAPTURE ",name," ",image.get_width(),"x",image.get_height()," result=",result)
func run() -> void:
	DisplayServer.window_set_size(Vector2i(648,990))
	print("USERDIR ",OS.get_user_data_dir()," GLOBAL ",ProjectSettings.globalize_path("user://"))
	for setting in ProjectSettings.get_property_list():
		if "shader" in setting.name and "cache" in setting.name:
			print("CACHE_SETTING ",setting.name,"=",ProjectSettings.get_setting(setting.name))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://verification/screenshots"))
	var packed: PackedScene = load("res://main.tscn")
	app = packed.instantiate()
	app.save_path_override = "user://gnomit_capture_progress_v1.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(app.save_path_override))
	root.add_child(app)
	await snap("01_map")
	app.start_level("entry")
	await snap("02_entry")
	var pair: Array = app.core.hint_move()
	app._on_swap(pair[0],pair[1])
	await create_timer(0.15).timeout
	await snap("03_swap")
	await create_timer(1.5).timeout
	app.progress.record_win("entry",1)
	app.progress.record_win("hollow",2)
	app.progress.record_win("seam",2)
	app.show_chamber()
	await snap("04_boss_locked")
	app.progress.record_win("rune",2)
	app.show_chamber()
	await snap("05_rune_complete")
	app.progress.record_win("lantern",1)
	app.show_chamber()
	await snap("06_boss_ready")
	app.start_level("guardian")
	await snap("07_guardian")
	app._show_result(true,2,{"reward":10,"saved":true})
	await snap("08_two_star_result_fixture")
	app._close_modal()
	app.show_options()
	await snap("09_options")
	app.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://gnomit_capture_progress_v1.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://gnomit_capture_progress_v1.json.tmp"))
	quit()
