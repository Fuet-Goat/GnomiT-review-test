extends SceneTree
var app
var notes: Array=[]
func _initialize() -> void:call_deferred("run")
func snap(name: String, fixture: bool=false) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("../verification/runtime_storybook_final_v2/"+name+".png")
	notes.append({"image":name,"fixture":fixture,"screen":app.current_screen,"progress":app.progress.data.duplicate(true)})
func wait(seconds: float) -> void:await create_timer(seconds).timeout
func prepare(id: String) -> void:
	app.start_level(id);await wait(0.5);app.core.setup(app.current_level,42);app.board.setup(app.core);app._update_hud();await wait(0.2)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("../verification/runtime_storybook_final_v2"))
	app=load("res://scripts/main.gd").new();app.save_path_override="user://storybook_final_capture.json"
	root.add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);await wait(0.5)
	app.progress.reset();app.progress.set_option("sound",true);app.show_map();await wait(1.2);await snap("MAP_SURFACE")
	await prepare("entry");await snap("FIRST_CRYSTALS_START");await wait(0.5)
	app.board._press(app.board._center(10));app.board._release(app.board._center(10));await wait(0.35);await snap("FIRST_CRYSTALS_SELECTED")
	var invalid: Array=[]
	for a in range(app.core.grid.size()):
		for b in [a+1,a+app.core.cols]:
			if not app.core._can_swap(a,b):continue
			var copy=load("res://scripts/match_core.gd").new();copy.setup(app.current_level,42)
			if not copy.try_swap(a,b).valid:invalid=[a,b];break
		if not invalid.is_empty():break
	app.board._last_swap=invalid.duplicate();await app._on_swap(invalid[0],invalid[1]);await wait(0.25)
	for pair in [[10,11],[29,36],[39,40]]:
		app.board._press(app.board._center(pair[0]));app.board._release(app.board._center(pair[0]));await wait(0.15)
		await app._on_swap(pair[0],pair[1]);await wait(0.4)
	await wait(0.6);await snap("FIRST_CRYSTALS_VICTORY");await wait(1.0)
	app._continue_after_win();await wait(0.4);await snap("MAP_DESCENT");await wait(0.8);await snap("MAP_NEXT_LEVEL");await wait(0.5)
	await prepare("hollow");await snap("ROOT_HOLLOW_START");await app._on_swap(27,34);await wait(0.5);await snap("ROOT_HOLLOW_EXCAVATED")
	app.show_map();await wait(0.3)
	# The following visual coverage uses explicit progress fixtures, labelled in receipts.
	for id in load("res://scripts/levels.gd").ordinary():app.progress.record_win(id,2)
	for id in ["seam","pearl","goldore","terraces","bridge"]:
		await prepare(id);await snap(id.to_upper()+"_START_FIXTURE",true)
	app.show_map();await wait(0.8);await snap("MAP_BOSS_DOOR_FIXTURE",true)
	app.show_chamber();await wait(0.8);await snap("BOSS_00_LOCKED_FIXTURE",true)
	await prepare("rune");await snap("RUNE_START_FIXTURE",true)
	app.progress.record_win("rune",2);app.show_chamber();await wait(0.7);await snap("BOSS_01_RUNE_COMPLETE_FIXTURE",true)
	await prepare("lantern");await snap("LANTERN_START_FIXTURE",true)
	app.progress.record_win("lantern",2);app.show_chamber();await wait(0.8);await snap("BOSS_02_READY_FIXTURE",true)
	await prepare("guardian");await snap("GUARDIAN_START_FIXTURE",true)
	var paths: Array=JSON.parse_string(FileAccess.get_file_as_string("res://tests/storybook_paths_v1.json"))
	for data in paths:
		if data.level=="guardian":
			for pair in data.path:await app._on_swap(pair[0],pair[1])
	await wait(0.6);await snap("GUARDIAN_REAL_WIN_FROM_FIXTURE",true);await wait(0.7)
	app._continue_after_win();await wait(0.8);await snap("BOSS_03_VICTORY_FIXTURE",true)
	var receipt={"images":notes,"engine":"native Godot desktop GPU","input":"scripted selection and valid swaps","human_test":false,"android_test":false,"screen_index":DisplayServer.window_get_current_screen(),"guardian_won":app.core.won,"fixture_note":"Boss and later-level unlocks are configured fixtures; their boards use real core and Guardian final is actually played."}
	var f=FileAccess.open("../verification/runtime_storybook_final_v2/capture_receipt.json",FileAccess.WRITE);f.store_string(JSON.stringify(receipt,"  "));f.close()
	print("STORYBOOK_CAPTURE "+JSON.stringify({"images":notes.size(),"guardian_won":app.core.won,"screen":DisplayServer.window_get_current_screen()}))
	app.audio.stop();app.audio.stream=null;app.queue_free();await process_frame;await process_frame;quit()
