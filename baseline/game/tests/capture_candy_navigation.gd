extends SceneTree

var app
var base: String
var started_msec: int
var observations: Array = []

func _initialize() -> void:
	create_timer(90).timeout.connect(func() -> void:
		print("NAVIGATION_RUNTIME_CAPTURE TIMEOUT")
		quit(99)
	)
	call_deferred("run")

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func settle() -> void:
	await process_frame
	await process_frame

func snapshot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = base + "/" + name + ".png"
	image.save_png(path)
	observations.append({"name":name,"path":path,"elapsed_ms":Time.get_ticks_msec()-started_msec,"screen":app.current_screen,"preview":app.pre_level_view.get_summary() if is_instance_valid(app.pre_level_view) else {},"seed_counter":app.seed_counter,"scroll":app.map_view.current_scroll() if is_instance_valid(app.map_view) else -1,"moves":app.core.moves_left if app.core != null else -1,"stars":app.progress.total_stars(),"light":app.progress.data.light})

func mouse(button: MouseButton, position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.position = root.get_final_transform() * position
	event.global_position = event.position
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if button == MOUSE_BUTTON_LEFT and pressed else 0
	Input.parse_input_event(event)

func tap(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = root.get_final_transform() * position
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	await settle()
	mouse(MOUSE_BUTTON_LEFT, position, true)
	await wait(0.10)
	mouse(MOUSE_BUTTON_LEFT, position, false)
	await wait(0.45)

func drag(position: Vector2, delta: Vector2) -> void:
	mouse(MOUSE_BUTTON_LEFT, position, true)
	await wait(0.12)
	for step in range(1,13):
		var event := InputEventMouseMotion.new()
		event.position = root.get_final_transform() * (position + delta * float(step) / 12.0)
		event.global_position = event.position
		event.relative = root.get_final_transform().basis_xform(delta / 12.0)
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(event)
		await wait(0.025)
	mouse(MOUSE_BUTTON_LEFT, position + delta, false)
	await wait(0.35)

func point(id: String) -> Vector2:
	return app.map_view.buttons[id].get_global_rect().get_center()

func run() -> void:
	base = ProjectSettings.globalize_path("res://../verification/navigation_runtime")
	DirAccess.make_dir_recursive_absolute(base)
	for suffix in ["", ".tmp"]:
		DirAccess.remove_absolute(base + "/capture_save.json" + suffix)
	root.size = Vector2i(432,960)
	app = load("res://scripts/main.gd").new()
	app.save_path_override = base + "/capture_save.json"
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	started_msec = Time.get_ticks_msec()
	await wait(1.2)
	await snapshot("01_MAP_SURFACE")
	await drag(point("entry"), Vector2(0,-250))
	await snapshot("02_MAP_FREE_PAN")
	var hollow: Vector2 = app.map_view.points.hollow
	app.map_view.restore_scroll(int(maxf(0,hollow.y-app.map_view.scroll.size.y*0.45)))
	await wait(0.45)
	await tap(point("hollow"))
	await wait(1.3)
	await snapshot("03_LOCKED_LEVEL_PREVIEW")
	await tap(app.pre_level_view.close_button.get_global_rect().get_center())
	await snapshot("04_PREVIEW_CLOSE_SAME_POSITION")
	app.map_view.focus_current()
	await wait(0.7)
	await tap(point("entry"))
	await wait(1.0)
	await snapshot("05_FIRST_CRYSTALS_PREVIEW")
	await tap(app.pre_level_view.play_button.get_global_rect().get_center())
	await wait(0.5)
	app.core.setup(app.current_level,42)
	app.board.setup(app.core)
	app._update_hud()
	await wait(1.0)
	await snapshot("06_ACTUAL_BOARD_AFTER_PLAY")
	for pair in [[10,11],[29,36],[39,40]]:
		var a: int = pair[0]
		var b: int = pair[1]
		app.board._last_swap = [a,b]
		await app._on_swap(a,b)
		await wait(0.5)
	await wait(1.0)
	await snapshot("07_REAL_VICTORY")
	if not app.core.won:
		print("CAPTURE FAILED: deterministic entry path did not win")
		quit(1)
		return
	app._continue_after_win()
	await wait(1.3)
	await snapshot("08_NEXT_LEVEL_UNLOCKED")
	await tap(point("hollow"))
	await wait(1.0)
	await snapshot("09_ROOT_PASSAGE_PREVIEW")
	var report: Dictionary = {"version":ProjectSettings.get_setting("application/config/version"),"runtime":"REAL_GODOT_OPENGL_WINDOW","input":"SCRIPTED_NATIVE_MOUSE_EVENTS_ON_MAP_AND_PREVIEW; REAL_DETERMINISTIC_GAMEPLAY_SWAPS","not_a_human_test":true,"physical_pixel_8a_test":false,"generated_video":false,"ordinary_level_count":7,"boss_encounter_count":3,"observations":observations,"entry_won":app.core.won,"progress_stars":app.progress.best_stars("entry"),"light":app.progress.data.light,"final_preview_level":app.pre_level_view.get_summary().id}
	var file = FileAccess.open(base + "/NAVIGATION_RUNTIME_CAPTURE.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("NAVIGATION_RUNTIME_CAPTURE " + JSON.stringify(report))
	await wait(1.0)
	quit(0)
