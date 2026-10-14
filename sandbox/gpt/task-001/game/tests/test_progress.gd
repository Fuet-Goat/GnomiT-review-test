extends SceneTree
var checks: int = 0
var failures: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: " + message)
func _initialize() -> void:
	var catalog_path: String = "res://scripts/levels.gd"
	var progress_path: String = "res://scripts/progress.gd"
	check(FileAccess.file_exists(catalog_path), "ten-level catalog exists")
	check(FileAccess.file_exists(progress_path), "persistent progression exists")
	if failures > 0:
		print("PROGRESS TESTS: ", checks, " checks, ", failures, " failures")
		quit(1)
		return
	var catalog: Script = load(catalog_path)
	var progress_script: Script = load(progress_path)
	var levels: Array = catalog.all()
	check(levels.size() == 10, "exactly ten gameplay levels")
	for level in levels:
		check(level.mask.size() == level.rows, "rows match mask")
		for row in level.mask:
			check(row.length() == level.cols, "columns match mask")
	var store = progress_script.new()
	var scratch: String = "user://gnomit_test_progress_v1.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	store.load_progress(scratch)
	check(store.is_unlocked("entry"), "first level open")
	check(not store.is_unlocked("hollow"), "second level locked")
	check(not store.record_win("guardian", 3).accepted, "cannot win locked boss")
	var first: Dictionary = store.record_win("entry", 2)
	check(first.accepted and first.first_win, "first win accepted")
	check(store.data.light == 10, "first reward once")
	store.record_win("entry", 1)
	check(store.best_stars("entry") == 2, "best stars never decrease")
	check(store.data.light == 10, "replay no duplicate reward")
	check(store.is_unlocked("hollow"), "next ordinary unlocked")
	store.record_win("hollow", 1)
	store.record_win("seam", 1)
	for id in ["pearl","goldore","terraces","bridge"]:store.record_win(id,1)
	check(store.is_unlocked("rune") and store.is_unlocked("lantern"), "both preparations available freely")
	store.record_win("lantern", 1)
	check(not store.is_unlocked("guardian"), "one preparation insufficient")
	var reloaded = progress_script.new()
	reloaded.load_progress(scratch)
	check(reloaded.best_stars("lantern") == 1, "separate preparation saved")
	check(not reloaded.is_unlocked("guardian"), "reload keeps boss locked")
	reloaded.record_win("rune", 3)
	check(reloaded.is_unlocked("guardian"), "both preparations unlock final")
	reloaded.record_win("guardian", 2)
	check(reloaded.best_stars("guardian") == 2, "actual two stars saved")
	check(reloaded.total_stars() == 14, "highest stars summed")
	check(reloaded.data.light == 100, "ten first rewards")
	reloaded.record_win("guardian", 3)
	check(reloaded.data.light == 100, "boss replay reward once")
	check(reloaded.best_stars("guardian") == 3, "replay improves stars")
	reloaded.set_option("reduced_motion", true)
	var third = progress_script.new()
	third.load_progress(scratch)
	check(third.option("reduced_motion"), "option saved")
	var f: FileAccess = FileAccess.open(scratch, FileAccess.WRITE)
	f.store_string("{broken save")
	f.close()
	var recovered = progress_script.new()
	recovered.load_progress(scratch)
	check(recovered.is_unlocked("entry"), "corrupt save recoverable")
	check(not recovered.is_unlocked("guardian"), "corrupt save does not unlock everything")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch + ".tmp"))
	print("PROGRESS TESTS: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
