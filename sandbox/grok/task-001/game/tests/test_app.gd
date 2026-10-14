extends SceneTree
var failures: int = 0
var checks: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: " + message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	check(FileAccess.file_exists("res://scripts/main.gd"),"playable app exists")
	if failures > 0:
		print("APP TESTS: ",checks," checks, ",failures," failures")
		quit(1)
		return
	var script: Script = load("res://scripts/main.gd")
	var app = script.new()
	app.save_path_override = "user://gnomit_test_app.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(app.save_path_override))
	root.add_child(app)
	await process_frame
	await process_frame
	check(app.current_screen == "map","starts at descending map")
	check(app.map_buttons.size() == 8,"map seven ordinary plus boss")
	check(app.map_buttons.entry.disabled == false,"entry playable")
	check(app.map_buttons.hollow.disabled,"second locked")
	check(app.map_buttons.boss.disabled,"boss hall initially locked")
	app.progress.record_win("entry",1)
	app.progress.record_win("hollow",1)
	app.progress.record_win("seam",1)
	for id in ["pearl","goldore","terraces","bridge"]:app.progress.record_win(id,1)
	app.show_chamber()
	await process_frame
	check(app.current_screen == "chamber","separate boss chamber")
	check(app.map_buttons.rune.disabled == false and app.map_buttons.lantern.disabled == false,"free preparation choice")
	check(app.map_buttons.guardian.disabled,"final needs both")
	app.progress.record_win("rune",1)
	app.show_chamber()
	await process_frame
	check(app.map_buttons.guardian.disabled,"one preparation not enough")
	app.progress.record_win("lantern",2)
	app.show_chamber()
	await process_frame
	check(not app.map_buttons.guardian.disabled,"both preparations unlock final")
	app.start_level("guardian")
	await process_frame
	check(app.current_screen == "play","boss gameplay entered")
	check(is_instance_valid(app.board),"animated board present")
	check(app.current_level.id == "guardian","correct level configuration")
	check(app.moves_label.text.contains("38"),"moves visible")
	check(app.goal_label.text.contains("18"),"crystal goal visible")
	app.show_map()
	await process_frame
	check(app.progress.best_stars("rune") == 1,"exit keeps preparation")
	check(app.progress.best_stars("lantern") == 2,"exit keeps second preparation")
	app.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://gnomit_test_app.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://gnomit_test_app.json.tmp"))
	print("APP TESTS: ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
