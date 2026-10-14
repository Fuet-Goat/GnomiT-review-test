extends SceneTree
var checks:=0
var failures: Array[String]=[]
var encounters: Array=[]
func _initialize() -> void:call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures.append(message);print("FAIL: "+message)
func settle() -> void:await process_frame;await process_frame
func run() -> void:
	var app=load("res://scripts/main.gd").new();app.save_path_override="user://storybook_runtime.json"
	root.add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);await settle()
	app.progress.reset();app.progress.set_option("sound",false)
	var paths: Array=JSON.parse_string(FileAccess.get_file_as_string("res://tests/storybook_paths_v1.json"))
	for run_data in paths:
		var id: String=run_data.level
		check(app.progress.is_unlocked(id),id+" reached through real previous wins")
		app.start_level(id);await settle()
		app.core.setup(app.current_level,42);app.board.setup(app.core,id!="entry");app.first_scene.reduced_motion=id!="entry";app._update_hud()
		check(not app.board._excavated.size(),id+" starts fresh")
		check(not app.board.get_rect().intersects(app.first_scene.hud_rects.moves),id+" HUD outside board")
		for pair in run_data.path:await app._on_swap(pair[0],pair[1])
		check(app.core.won and is_instance_valid(app.modal),id+" actual swaps reach victory")
		check(app.progress.best_stars(id)==run_data.stars,id+" saves earned stars")
		check(app.goal_label.text=="%d / %d"%[app.first_scene.target,app.first_scene.target],id+" actual objective reached")
		var moves: int=app.core.moves_left
		var light: int=app.progress.data.light
		var before: Array=app.core.grid.duplicate()
		await app._on_swap(run_data.path[0][0],run_data.path[0][1])
		check(app.core.moves_left==moves and app.core.grid==before and app.progress.data.light==light,id+" terminal input cannot change result or reward")
		encounters.append({"id":id,"won":app.core.won,"stars":app.progress.best_stars(id),"moves_left":moves})
		app._continue_after_win();await settle()
		if id=="entry":
			check(app.map_view.focus_id=="hollow", "real continuation chooses next level")
			check(app.map_view.skip_button.visible,"ordinary victory starts skippable map descent")
			app.map_view.finish_transition();check(not app.map_view.skip_button.visible,"skip finishes same target")
		if id=="rune":check(app.progress.best_stars("rune")>0 and not app.progress.is_unlocked("guardian"),"first preparation persists while final stays locked")
		if id=="lantern":check(app.progress.is_unlocked("guardian"),"second real preparation opens final")
	check(app.progress.data.light==100,"all ten actual wins credit exactly ten rewards")
	var store=load("res://scripts/progress.gd").new();store.load_progress(app.save_path_override)
	check(store.best_stars("guardian")>0 and store.data.light==100,"restart reloads complete actual campaign")
	app.queue_free();await settle()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://storybook_runtime.json"))
	var result={"checks":checks,"failures":failures,"encounters":encounters,"status":"PASS" if failures.is_empty() else "FAIL","input":"scripted valid swaps through live app; not a human or Android test"}
	print("STORYBOOK_RUNTIME "+JSON.stringify(result));quit(0 if failures.is_empty() else 1)
