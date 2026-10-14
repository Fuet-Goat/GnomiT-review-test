extends SceneTree

const Art = preload("res://scripts/story_art.gd")
const Levels = preload("res://scripts/levels.gd")
var app
var checks := 0
var failures: Array[String] = []
var observations: Array = []
var save_path: String

class TouchTrace extends Node:
	func _input(event: InputEvent) -> void:
		if event is InputEventScreenTouch or event is InputEventMouseButton:
			print("CANCEL_EVENT ",event," device ",event.device," canceled ",event.canceled)

func _initialize() -> void:
	create_timer(90).timeout.connect(func() -> void:print("WORLD_MAP TIMEOUT");quit(99))
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		print("FAIL: " + message)

func settle() -> void:
	await process_frame
	await process_frame

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

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
	await settle()
	mouse(MOUSE_BUTTON_LEFT, position, false)
	await settle()

func drag(position: Vector2, delta: Vector2, touch: bool = false, hold_before_release: float = 0.0) -> void:
	if touch:
		var down := InputEventScreenTouch.new()
		down.index = 0
		down.pressed = true
		down.position = root.get_final_transform() * position
		Input.parse_input_event(down)
	else:
		mouse(MOUSE_BUTTON_LEFT, position, true)
	await settle()
	for step in range(1,9):
		if touch:
			var event := InputEventScreenDrag.new()
			event.index = 0
			event.position = root.get_final_transform() * (position + delta * float(step) / 8.0)
			event.relative = root.get_final_transform().basis_xform(delta / 8.0)
			Input.parse_input_event(event)
		else:
			var event := InputEventMouseMotion.new()
			event.position = root.get_final_transform() * (position + delta * float(step) / 8.0)
			event.global_position = event.position
			event.relative = root.get_final_transform().basis_xform(delta / 8.0)
			event.button_mask = MOUSE_BUTTON_MASK_LEFT
			Input.parse_input_event(event)
		await wait(0.015)
	if hold_before_release > 0.0:
		await wait(hold_before_release)
	if touch:
		var up := InputEventScreenTouch.new()
		up.index = 0
		up.pressed = false
		up.position = root.get_final_transform() * (position + delta)
		Input.parse_input_event(up)
	else:
		mouse(MOUSE_BUTTON_LEFT, position + delta, false)
	await settle()

func offset() -> Vector2:
	return app.map_view.current_offset()

func canceled_touch(position: Vector2, delta: Vector2 = Vector2.ZERO) -> void:
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.pressed = true
	down.position = root.get_final_transform() * position
	Input.parse_input_event(down)
	await settle()
	if not delta.is_zero_approx():
		var motion := InputEventScreenDrag.new()
		motion.index = 0
		motion.position = root.get_final_transform() * (position + delta)
		motion.relative = root.get_final_transform().basis_xform(delta)
		Input.parse_input_event(motion)
		await settle()
	var canceled := InputEventScreenTouch.new()
	canceled.index = 0
	canceled.position = root.get_final_transform() * (position + delta)
	canceled.pressed = false
	canceled.canceled = true
	Input.parse_input_event(canceled)
	await settle()

func maximum() -> Vector2:
	return (app.map_view.canvas.size - app.map_view.scroll.size).max(Vector2.ZERO)

func center_node(id: String) -> void:
	var world_point: Vector2 = app.map_view.points[id]
	app.map_view.restore_offset(world_point - app.map_view.scroll.size * Vector2(0.5,0.53))
	await settle()

func close_modal() -> void:
	app._close_modal()
	await settle()

func start_coast() -> void:
	app.map_view.reduced_motion = false
	app.map_view.restore_offset(maximum() * 0.35)
	await settle()
	await drag(app.map_view.scroll.get_global_rect().get_center(), Vector2(-100,-170))

func run() -> void:
	save_path = ProjectSettings.globalize_path("res://../verification/world_map_test_save.json")
	DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
	for suffix in ["", ".tmp"]:DirAccess.remove_absolute(save_path + suffix)
	root.size = Vector2i(432,960)
	app = load("res://scripts/main.gd").new()
	app.save_path_override = save_path
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await wait(0.4)
	app.progress.set_option("sound", false)
	app.progress.set_option("reduced_motion", true)
	app.map_view.reduced_motion = true
	for viewport in [Vector2i(432,960), Vector2i(720,1600), Vector2i(1280,720)]:
		root.size = viewport
		await settle()
		app._resize_stage()
		await settle()
		var view = app.map_view
		var visible: Rect2 = root.get_visible_rect()
		check(view.get_global_rect().is_equal_approx(visible), "map itself fills the logical viewport " + str(viewport))
		check(view.scroll.get_global_rect().is_equal_approx(visible), "world interaction area reaches all screen edges " + str(viewport))
		var artwork_ratio: float = float(Art.MAP.get_width()) / float(Art.MAP.get_height())
		check(absf(view.canvas.size.x / view.canvas.size.y - artwork_ratio) < 0.0001, "world artwork preserves its original aspect ratio " + str(viewport))
		check(view.canvas.size.x >= visible.size.x * 1.64, "world extends horizontally beyond the viewport " + str(viewport))
		check(view.canvas.size.y >= visible.size.y, "world covers the viewport vertically " + str(viewport))
		var physical_area := Rect2(Vector2.ZERO, Vector2(viewport))
		var physical_world_rect: Rect2 = root.get_final_transform() * view.get_global_rect()
		check(physical_world_rect.is_equal_approx(physical_area), "world fills the actual physical window without letterboxing " + str(viewport))
		for control in [view.menu_button,view.current_button]:
			var rect: Rect2 = root.get_final_transform() * control.get_global_rect()
			check(physical_area.grow(1).encloses(rect), "overlay control remains on screen " + control.text + " " + str(viewport))
			check(rect.size.y >= 44, "overlay control keeps a usable physical touch height " + control.text + " " + str(viewport))
		check(view.current_button.size.y < visible.size.y * 0.15, "Current Level is a compact overlay without a giant footer " + str(viewport))
		view.restore_offset(Vector2(-999,-999))
		await settle()
		check(offset().is_equal_approx(Vector2.ZERO), "both world axes clamp at the surface edge " + str(viewport))
		check(view.canvas.get_global_rect().grow(1).encloses(visible), "surface clamp exposes no empty margins " + str(viewport))
		view.restore_offset(Vector2(99999,99999))
		await settle()
		check(offset().is_equal_approx(maximum().floor()), "both world axes clamp at the far integer pixel edge " + str(viewport))
		check(view.canvas.get_global_rect().grow(1).encloses(visible), "deep clamp exposes no empty margins " + str(viewport))
		observations.append({"window":str(viewport),"logical_view":str(visible),"world":str(view.canvas.size),"maximum_offset":str(maximum()),"physical_map":str(root.get_final_transform()*view.get_global_rect())})
	root.size = Vector2i(432,960)
	await settle()
	app._resize_stage()
	await settle()
	app.map_view.restore_offset(maximum() * 0.4)
	await settle()
	var before: Vector2 = offset()
	await drag(app.map_view.scroll.get_global_rect().get_center(), Vector2(-80,-115))
	check(offset().x > before.x and offset().y > before.y, "native mouse drag pans both world axes")
	check(not is_instance_valid(app.modal) and app.seed_counter == 0, "free world drag opens no preview or gameplay")
	var after_release: Vector2 = offset()
	await wait(0.15)
	check(offset().is_equal_approx(after_release), "Reduced Motion stops immediately at drag release")
	await center_node("entry")
	var guide: Vector2 = app.map_view.gnome.position
	var touch_before: Vector2 = offset()
	await drag(app.map_view.buttons.entry.get_global_rect().get_center(), Vector2(-55,-100), true)
	check(offset().x > touch_before.x and offset().y > touch_before.y, "native touch drag beginning on a node pans both axes")
	check(not is_instance_valid(app.modal) and app.seed_counter == 0 and app.map_view.gnome.position.is_equal_approx(guide), "touch pan release neither selects the node nor moves the passage guide")
	await center_node("entry")
	var trace := TouchTrace.new()
	root.add_child(trace)
	await canceled_touch(app.map_view.buttons.entry.get_global_rect().get_center())
	print("CANCEL_STATE ",{"modal":is_instance_valid(app.modal),"seed":app.seed_counter,"guide":app.map_view.gnome.position,"expected":guide,"pointer":app.map_view._pointer_active,"touch":app.map_view._touch_index,"velocity":app.map_view._inertia_velocity})
	check(not is_instance_valid(app.modal) and app.seed_counter == 0 and app.map_view.gnome.position.is_equal_approx(guide) and not app.map_view._pointer_active and app.map_view._inertia_velocity.is_zero_approx(), "native canceled touch on a level clears the gesture without preview, gameplay, guide movement or coast")
	app.map_view.reduced_motion = false
	await center_node("entry")
	await canceled_touch(app.map_view.buttons.entry.get_global_rect().get_center(),Vector2(-30,-65))
	var canceled_drag_offset: Vector2 = offset()
	await wait(0.12)
	check(not is_instance_valid(app.modal) and app.seed_counter == 0 and app.map_view.gnome.position.is_equal_approx(guide) and not app.map_view._pointer_active and app.map_view._inertia_velocity.is_zero_approx() and offset().is_equal_approx(canceled_drag_offset), "native canceled drag stops immediately and cannot select a node or begin release inertia")
	trace.queue_free()
	await start_coast()
	var release_offset: Vector2 = offset()
	await wait(0.12)
	check(offset().distance_to(release_offset) > 1, "normal motion continues gently after native drag release")
	check(offset().x >= 0 and offset().y >= 0 and offset().x <= maximum().x and offset().y <= maximum().y, "release inertia remains inside both world bounds")
	app.map_view.restore_offset(maximum() * 0.35)
	await settle()
	await drag(app.map_view.scroll.get_global_rect().get_center(),Vector2(-90,-135),false,0.25)
	var held_release: Vector2 = offset()
	await wait(0.15)
	check(offset().is_equal_approx(held_release), "holding the pointer still after dragging does not fling the world on release")
	await start_coast()
	app.show_level_preview("entry")
	await settle()
	var modal_offset: Vector2 = offset()
	await wait(0.12)
	check(offset().is_equal_approx(modal_offset), "opening a preview stops inertia behind the modal")
	await close_modal()
	await start_coast()
	await tap(app.map_view.menu_button.get_global_rect().get_center())
	check(is_instance_valid(app.modal) and not is_instance_valid(app.pre_level_view), "native overlay Menu click reaches Settings instead of starting a world pan")
	var settings_offset: Vector2 = offset()
	await wait(0.12)
	check(offset().is_equal_approx(settings_offset), "Settings stops world inertia")
	await close_modal()
	await start_coast()
	await tap(app.map_view.current_button.get_global_rect().get_center())
	var current_offset: Vector2 = offset()
	await wait(0.12)
	check(not is_instance_valid(app.modal) and offset().is_equal_approx(current_offset), "native Current Level overlay centers the passage and stops inertia without opening a preview")
	check(app.map_view.scroll.get_global_rect().has_point(app.map_view.buttons.entry.get_global_rect().get_center()), "Current Level makes the actual current node visible")
	await start_coast()
	app.map_view.notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	var focus_offset: Vector2 = offset()
	await wait(0.12)
	check(offset().is_equal_approx(focus_offset), "losing window focus stops release inertia")
	await start_coast()
	app.map_view.reduced_motion = true
	var reduced_offset: Vector2 = offset()
	await wait(0.12)
	check(offset().is_equal_approx(reduced_offset), "enabling Reduced Motion stops an existing coast")
	app.progress.set_option("reduced_motion", true)
	app.map_view.restore_offset(maximum() * Vector2(0.3,0.55))
	await settle()
	var parked: Vector2 = offset()
	var anchored_guide: Vector2 = app.map_view.gnome.position
	for level in Levels.all():
		app.show_level_preview(level.id)
		await settle()
		check(app.current_screen == "map" and app.map_view.gnome.position.is_equal_approx(anchored_guide) and app.seed_counter == 0, level.id + " preview leaves the current world guide and gameplay untouched")
		await close_modal()
		check(offset().is_equal_approx(parked), level.id + " preview close restores both world offsets")
	app.show_level_preview("entry")
	await settle()
	await tap(app.pre_level_view.play_button.get_global_rect().get_center())
	check(app.current_screen == "play" and app.current_level.id == "entry" and app.seed_counter == 1, "native explicit Play enters the actual selected level exactly once")
	app._exit_level()
	await settle()
	check(offset().is_equal_approx(parked), "gameplay exit restores the freely browsed X and Y world offsets")
	for id in Levels.ordinary():app.progress.record_win(id,1)
	app.show_map()
	await settle()
	check(app.map_view.focus_id == "boss", "completed ordinary path leaves guide at the Boss passage")
	var boss_guide: Vector2 = app.map_view.gnome.position
	await center_node("entry")
	await tap(app.map_view.buttons.entry.get_global_rect().get_center())
	check(is_instance_valid(app.pre_level_view) and app.map_view.gnome.position.is_equal_approx(boss_guide) and app.current_screen == "map", "selecting an earlier level does not pull the guide away from the Boss passage")
	await close_modal()
	await center_node("boss")
	await tap(app.map_view.buttons.boss.get_global_rect().get_center())
	check(app.current_screen == "chamber" and app.progress.best_stars("guardian") == 0, "native unlocked Boss entry opens the separate preparations hall")
	app.queue_free()
	await settle()
	for suffix in ["", ".tmp"]:DirAccess.remove_absolute(save_path + suffix)
	var result: Dictionary = {"checks":checks,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL","observations":observations,"input":"NATIVE_MOUSE_AND_TOUCH_EVENTS","physical_android_test":false,"human_usability_test":false}
	var file = FileAccess.open(ProjectSettings.globalize_path("res://../verification/world_map_checks.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"  "))
	file.close()
	print("WORLD_MAP " + JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
