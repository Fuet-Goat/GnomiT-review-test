extends SceneTree

var app
var base: String
var started_msec: int
var observations: Array = []

func _initialize() -> void:
	create_timer(90).timeout.connect(func() -> void:print("WORLD_CAPTURE TIMEOUT");quit(99))
	call_deferred("run")

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func settle() -> void:
	await process_frame
	await process_frame

func snapshot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var path: String = base + "/" + name + ".png"
	root.get_texture().get_image().save_png(path)
	observations.append({"name":name,"path":path,"elapsed_ms":Time.get_ticks_msec()-started_msec,"screen":app.current_screen,"preview":app.pre_level_view.get_summary() if is_instance_valid(app.pre_level_view) else {},"offset":str(app.map_view.current_offset()) if is_instance_valid(app.map_view) else "none","seed_counter":app.seed_counter,"moves":app.core.moves_left if app.core != null else -1,"light":app.progress.data.light})

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
	mouse(MOUSE_BUTTON_LEFT,position,true)
	await wait(0.10)
	mouse(MOUSE_BUTTON_LEFT,position,false)
	await wait(0.45)

func drag(position: Vector2, delta: Vector2) -> void:
	mouse(MOUSE_BUTTON_LEFT,position,true)
	await wait(0.12)
	for step in range(1,13):
		var event := InputEventMouseMotion.new()
		event.position = root.get_final_transform() * (position + delta * float(step) / 12.0)
		event.global_position = event.position
		event.relative = root.get_final_transform().basis_xform(delta / 12.0)
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(event)
		await wait(0.025)
	mouse(MOUSE_BUTTON_LEFT,position + delta,false)
	await wait(0.45)

func point(id: String) -> Vector2:
	return app.map_view.buttons[id].get_global_rect().get_center()

func run() -> void:
	base = ProjectSettings.globalize_path("res://../verification/world_map_runtime")
	DirAccess.make_dir_recursive_absolute(base)
	for suffix in ["", ".tmp"]:DirAccess.remove_absolute(base + "/capture_save.json" + suffix)
	root.size = Vector2i(432,960)
	app = load("res://scripts/main.gd").new()
	app.save_path_override = base + "/capture_save.json"
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	started_msec = Time.get_ticks_msec()
	await wait(1.2)
	await snapshot("01_SURFACE_VILLAGE")
	await drag(app.map_view.scroll.get_global_rect().get_center(),Vector2(-80,-420))
	await wait(0.35)
	await snapshot("02_ROOTS_FREE_PAN")
	for step in range(3):
		await drag(app.map_view.scroll.get_global_rect().get_center(),Vector2(40 if step%2==0 else -40,-500))
	await snapshot("03_CRYSTAL_DEPTHS")
	await tap(app.map_view.current_button.get_global_rect().get_center())
	await wait(0.6)
	await snapshot("04_RETURN_CURRENT_PASSAGE")
	await tap(point("entry"))
	await wait(0.9)
	await snapshot("05_FIRST_CRYSTALS_PREVIEW")
	await tap(app.pre_level_view.play_button.get_global_rect().get_center())
	await wait(0.45)
	app.core.setup(app.current_level,42)
	app.board.setup(app.core)
	app._update_hud()
	await wait(0.8)
	await snapshot("06_ACTUAL_BOARD_AFTER_PLAY")
	for pair in [[10,11],[29,36],[39,40]]:
		app.board._last_swap = [pair[0],pair[1]]
		await app._on_swap(pair[0],pair[1])
		await wait(0.4)
	await wait(0.9)
	await snapshot("07_REAL_ENTRY_VICTORY")
	if not app.core.won:
		print("WORLD_CAPTURE FAILED: entry path did not win")
		quit(1)
		return
	app._continue_after_win()
	await wait(1.2)
	await snapshot("08_NEXT_PASSAGE_UNLOCKED")
	await tap(point("hollow"))
	await wait(0.8)
	await snapshot("09_ROOT_PASSAGE_PREVIEW")
	var report: Dictionary = {"version":ProjectSettings.get_setting("application/config/version"),"runtime":"REAL_GODOT_OPENGL_WINDOW","input":"SCRIPTED_NATIVE_MOUSE_WORLD_PANS_AND_PREVIEW_BUTTONS; REAL_DETERMINISTIC_GAMEPLAY_SWAPS","not_a_human_test":true,"physical_pixel_8a_test":false,"generated_video":false,"observations":observations,"entry_won":app.core.won,"entry_stars":app.progress.best_stars("entry"),"light":app.progress.data.light,"final_preview":app.pre_level_view.get_summary().id}
	var file = FileAccess.open(base + "/WORLD_MAP_RUNTIME_CAPTURE.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("WORLD_MAP_RUNTIME_CAPTURE " + JSON.stringify(report))
	await wait(0.8)
	quit(0)
