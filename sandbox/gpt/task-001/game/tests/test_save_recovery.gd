extends SceneTree
var failures: Array[String]=[]
var checks:=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures.append(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var path: String="user://storybook_save_recovery.json"
	var f=FileAccess.open(path,FileAccess.WRITE);f.store_string("{damaged original bytes");f.close()
	var app=load("res://scripts/main.gd").new();app.save_path_override=path;root.add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame;await process_frame
	var warning=app.map_view.get("warning_label")
	check(is_instance_valid(warning) and warning.visible and not warning.text.is_empty(),"map visibly reports unreadable progress")
	check(not app.progress.persist(),"normal close must not replace an unreadable save")
	check(FileAccess.get_file_as_string(path)=="{damaged original bytes","original save bytes remain intact")
	check(app.progress.reset(),"explicit new expedition may reset damaged progress")
	app.show_map();await process_frame
	warning=app.map_view.get("warning_label")
	check(is_instance_valid(warning) and not warning.visible,"successful explicit reset resolves warning")
	app.queue_free();await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("SAVE_RECOVERY "+JSON.stringify({"checks":checks,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL"}));quit(0 if failures.is_empty() else 1)
