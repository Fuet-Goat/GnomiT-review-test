extends SceneTree

# Native-event regressions for ownership, physical thresholds, and walk interruption.
# Keep fixture progress and settings outside the player's user save directory.
var app
var checks: Array = []
var failures: Array[String] = []
var observations: Array = []
var save_path: String

func _initialize() -> void:
	create_timer(75).timeout.connect(func() -> void: print("JOURNEY_EDGES TIMEOUT"); quit(99))
	call_deferred("run")

func check(ok: bool, name: String, observed: Dictionary = {}) -> void:
	checks.append({"name":name, "pass":ok, "observed":observed})
	if not ok:
		failures.append(name)
		print("FAIL: " + name + " " + JSON.stringify(observed))

func settle() -> void:
	await process_frame
	await process_frame

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func touch(position: Vector2, pressed: bool, canceled: bool = false) -> void:
	var event = InputEventScreenTouch.new()
	event.position = root.get_final_transform() * position
	event.index = 0
	event.pressed = pressed
	event.canceled = canceled
	Input.parse_input_event(event)

func drag(position: Vector2) -> void:
	var event = InputEventScreenDrag.new()
	event.position = root.get_final_transform() * position
	event.index = 0
	Input.parse_input_event(event)

func mouse(position: Vector2, pressed: bool) -> void:
	var event = InputEventMouseButton.new()
	event.position = root.get_final_transform() * position
	event.global_position = event.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(event)

func mouse_move(position: Vector2, relative: Vector2) -> void:
	var event = InputEventMouseMotion.new()
	event.position = root.get_final_transform() * position
	event.global_position = event.position
	event.relative = root.get_final_transform().basis_xform(relative)
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(event)

func tap(position: Vector2) -> void:
	touch(position, true)
	await settle()
	touch(position, false)
	await settle()

func resize_window(window: Vector2i) -> void:
	root.size = window
	await settle()
	app._resize_stage()
	await settle()

func reset_map(reduced: bool = true, completed: int = 0, previous: String = "") -> void:
	app.progress.reset()
	app.progress.set_option("sound", false)
	app.progress.set_option("reduced_motion", reduced)
	var ordinary: Array = ["entry", "hollow", "seam", "pearl", "goldore", "terraces", "bridge"]
	for i in range(completed):
		app.progress.record_win(ordinary[i], 1)
	app._saved_map_scroll = -1
	app._saved_map_offset = Vector2(-1, -1)
	app._return_from_id = previous
	app.show_map()
	await settle()

func center(id: String) -> Vector2:
	app.map_view.restore_scroll(app.map_view.points[id].y - app.map_view.size.y * 0.52)
	await settle()
	return app.map_view.buttons[id].get_global_rect().get_center()

func rect_text(rect: Rect2) -> Dictionary:
	return {"position":str(rect.position), "size":str(rect.size)}

func test_overlay_release() -> void:
	# Losing an emulated release after a press began on the HUD leaves GUI state stale.
	for name in ["menu", "current"]:
		for kind in ["outside", "canceled_inside", "canceled_outside"]:
			await reset_map()
			var view = app.map_view
			view.restore_scroll(900)
			await settle()
			var button: Button = view.menu_button if name == "menu" else view.current_button
			var p: Vector2 = button.get_global_rect().get_center()
			var end: Vector2 = p if kind == "canceled_inside" else p + Vector2(-190, 110 if name == "menu" else -110)
			var before: Vector2 = view.current_offset()
			var seed: int = app.seed_counter
			touch(p, true)
			await settle()
			if kind != "canceled_inside":
				drag(end)
				await settle()
			touch(end, false, kind != "outside")
			await settle()
			var state = {"pressed":button.is_pressed(), "screen":app.current_screen, "modal":is_instance_valid(app.modal), "before_offset":str(before), "after_offset":str(view.current_offset())}
			check(not button.is_pressed(), name + " HUD " + kind + " releases GUI button", state)
			check(app.current_screen == "map" and app.seed_counter == seed and not is_instance_valid(app.modal), name + " HUD " + kind + " cannot activate or start a board", state)
			check(view.current_offset().distance_to(before) < 2, name + " HUD " + kind + " cannot pan the map", state)
			# A valid subsequent tap must still work after cancellation/outside release.
			await tap(button.get_global_rect().get_center())
			if name == "menu":
				check(is_instance_valid(app.modal), name + " HUD recovers after " + kind)
				app._close_modal()
				await settle()
			else:
				check(app.current_screen == "map" and view.current_scroll() < before.y - 100 and view.scroll.get_global_rect().encloses(view.buttons.entry.get_global_rect()) and app.seed_counter == seed, name + " HUD recovers after " + kind, {"scroll":view.current_scroll(), "current_badge":rect_text(view.buttons.entry.get_global_rect())})

func test_mouse_thresholds() -> void:
	# At 12 physical pixels a mouse gesture is a drag even if its release is on the badge.
	for window in [Vector2i(432, 960), Vector2i(720, 1600)]:
		await resize_window(window)
		for physical in [11.9, 12.0, 12.1]:
			await reset_map()
			var p: Vector2 = await center("entry")
			var delta: Vector2 = root.get_final_transform().affine_inverse().basis_xform(Vector2(physical, 0))
			var seed: int = app.seed_counter
			mouse(p, true)
			await settle()
			mouse_move(p + delta, delta)
			await settle()
			mouse(p + delta, false)
			await settle()
			var should_play: bool = physical < 12.0
			check((app.current_screen == "play") == should_play and app.seed_counter == seed + (1 if should_play else 0), "mouse physical boundary " + str(physical) + " at " + str(window), {"screen":app.current_screen, "seed_delta":app.seed_counter-seed, "transform":str(root.get_final_transform())})
			check(not is_instance_valid(app.pre_level_view), "mouse boundary never opens preparation " + str(physical) + " at " + str(window))
		await reset_map()
		var p: Vector2 = await center("entry")
		var delta: Vector2 = root.get_final_transform().affine_inverse().basis_xform(Vector2(12.1, 0))
		var seed: int = app.seed_counter
		mouse(p, true)
		await settle()
		mouse_move(p + delta, delta)
		await settle()
		mouse_move(p, -delta)
		await settle()
		mouse(p, false)
		await settle()
		check(app.current_screen == "map" and app.seed_counter == seed, "mouse excursion remains a drag after returning at " + str(window))
		mouse(p, true)
		await settle()
		mouse(p + delta, false)
		await settle()
		check(app.current_screen == "map" and app.seed_counter == seed, "mouse release alone measures physical displacement at " + str(window))

func test_chamber_navigation() -> void:
	await resize_window(Vector2i(432, 960))
	await reset_map()
	var p: Vector2 = await center("boss")
	var seed: int = app.seed_counter
	await tap(p)
	check(app.current_screen == "map" and app.seed_counter == seed and not is_instance_valid(app.modal), "locked map boss is a complete no-op")
	await reset_map(true, 7)
	p = await center("boss")
	seed = app.seed_counter
	await tap(p)
	check(app.current_screen == "chamber" and is_instance_valid(app.chamber_view) and app.seed_counter == seed and not is_instance_valid(app.modal), "unlocked map boss opens existing chamber without a board")
	if app.current_screen != "chamber":
		app.show_chamber()
		await settle()
	for id in ["rune", "lantern"]:
		app.show_chamber()
		await settle()
		seed = app.seed_counter
		await tap(app.chamber_view.buttons[id].get_global_rect().get_center())
		check(app.current_screen == "play" and app.current_level.id == id and app.seed_counter == seed + 1 and not is_instance_valid(app.pre_level_view) and not is_instance_valid(app.modal), "chamber preparation " + id + " starts directly on one native tap")
	app.show_chamber()
	await settle()
	seed = app.seed_counter
	await tap(app.chamber_view.buttons.guardian.get_global_rect().get_center())
	check(app.current_screen == "chamber" and app.seed_counter == seed and not is_instance_valid(app.modal), "guardian stays locked before both preparations")
	app.progress.record_win("rune", 1)
	app.progress.record_win("lantern", 1)
	app.show_chamber()
	await settle()
	seed = app.seed_counter
	await tap(app.chamber_view.buttons.guardian.get_global_rect().get_center())
	check(app.current_screen == "play" and app.current_level.id == "guardian" and app.seed_counter == seed + 1 and not is_instance_valid(app.pre_level_view), "ready guardian starts directly through existing chamber")

func test_horizontal_wheel() -> void:
	# ScrollContainer must not receive wheel events that bypass the depth-only camera.
	await resize_window(Vector2i(432, 960))
	await reset_map()
	var view = app.map_view
	view.restore_scroll(900)
	await settle()
	var point: Vector2 = Vector2(60, view.size.y * 0.5)
	check(view._node_at(point).is_empty() and not view._overlaid_control_at(point), "horizontal wheel fixture uses blank map space", {"point":str(point)})
	var start: Vector2 = view.current_offset()
	for button in [MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]:
		var motion = InputEventMouseMotion.new()
		motion.position = root.get_final_transform() * point
		motion.global_position = motion.position
		Input.parse_input_event(motion)
		await settle()
		for i in range(5):
			for pressed in [true, false]:
				var event = InputEventMouseButton.new()
				event.position = root.get_final_transform() * point
				event.global_position = event.position
				event.button_index = button
				event.pressed = pressed
				event.factor = 1.0
				Input.parse_input_event(event)
				await settle()
		check(view.current_offset() == start, "horizontal wheel " + ("left" if button == MOUSE_BUTTON_WHEEL_LEFT else "right") + " cannot freely pan either camera axis", {"start":str(start), "after":str(view.current_offset()), "button":button})

func test_walk_interruptions() -> void:
	await resize_window(Vector2i(432, 960))
	await reset_map(false, 1, "entry")
	var view = app.map_view
	check(view.skip_button.visible, "tap-during-walk fixture is actually walking")
	var p: Vector2 = view.buttons.entry.get_global_rect().get_center()
	check(view.scroll.get_global_rect().has_point(p), "old unlocked badge is visibly tappable during walk", {"badge":rect_text(view.buttons.entry.get_global_rect()), "viewport":rect_text(view.scroll.get_global_rect())})
	var seed: int = app.seed_counter
	var before_offset: Vector2 = view.current_offset()
	await tap(p)
	check(app.current_screen == "play" and app.current_level.id == "entry" and app.seed_counter == seed + 1, "native tap selects visibly pressed unlocked badge during walk", {"screen":app.current_screen, "seed_delta":app.seed_counter-seed, "pressed_at":str(p), "offset_before":str(before_offset), "offset_after":str(view.current_offset()) if is_instance_valid(view) else "view freed"})
	for window in [Vector2i(720, 1600), Vector2i(960, 432)]:
		await resize_window(Vector2i(432, 960))
		await reset_map(false, 1, "entry")
		view = app.map_view
		await wait(0.12)
		check(view.skip_button.visible, "resize fixture is still walking before " + str(window))
		await resize_window(window)
		var hero: Rect2 = view.gnome.get_global_rect()
		var viewport: Rect2 = view.scroll.get_global_rect()
		check(viewport.grow(1).encloses(hero), "resize during walk keeps hero fully visible at " + str(window), {"hero":rect_text(hero), "viewport":rect_text(viewport), "offset":str(view.current_offset()), "walking":view.skip_button.visible})
		check(not view.gnome.get_rect().intersects(view.buttons.hollow.get_rect()), "resize interruption keeps guide outside current badge at " + str(window))
		await wait(0.95)
		check(view.scroll.get_global_rect().grow(1).encloses(view.gnome.get_global_rect()) and not view.skip_button.visible, "resize walk settles visibly at current node at " + str(window), {"hero":rect_text(view.gnome.get_global_rect()), "viewport":rect_text(view.scroll.get_global_rect()), "offset":str(view.current_offset())})

func find_button(node: Node, text: String) -> BaseButton:
	if node is BaseButton and node.text == text:
		return node
	for child in node.get_children():
		var found: BaseButton = find_button(child, text)
		if found != null:
			return found
	return null

func test_skip_and_reduced() -> void:
	await resize_window(Vector2i(432, 960))
	await reset_map(false, 1, "entry")
	var view = app.map_view
	await wait(0.92)
	var endpoint: Vector2 = view.gnome.position
	var endpoint_offset: Vector2 = view.current_offset()
	check(not view.skip_button.visible and view.scroll.get_global_rect().encloses(view.gnome.get_global_rect()), "normal walk completes visibly near 0.8 seconds")
	await reset_map(false, 1, "entry")
	view = app.map_view
	var seed: int = app.seed_counter
	await tap(view.skip_button.get_global_rect().get_center())
	check(not view.skip_button.visible and view.gnome.position.distance_to(endpoint) < 1 and view.current_offset().distance_to(endpoint_offset) < 2 and app.seed_counter == seed, "native Skip reaches same endpoint and camera as completed walk", {"normal_hero":str(endpoint), "skip_hero":str(view.gnome.position), "normal_offset":str(endpoint_offset), "skip_offset":str(view.current_offset())})
	await reset_map(false, 1, "entry")
	view = app.map_view
	await wait(0.12)
	check(view.skip_button.visible, "reduced-motion fixture is actually walking")
	# Opening this existing overlay directly keeps the walk in flight until its option changes.
	app.show_options()
	await settle()
	var reduced: BaseButton = find_button(app.modal, "Reduced Motion")
	check(reduced != null, "existing settings overlay exposes Reduced Motion")
	if reduced != null:
		await tap(reduced.get_global_rect().get_center())
		check(app.progress.option("reduced_motion") and view.reduced_motion and not view.skip_button.visible and view.gnome.position.distance_to(endpoint) < 1 and view.current_offset().distance_to(endpoint_offset) < 2, "native Reduced Motion toggle during walk immediately reaches same endpoint", {"hero":str(view.gnome.position), "offset":str(view.current_offset()), "option":app.progress.option("reduced_motion")})
		var positions: Array = []
		for npc in view.side_gnomes:
			positions.append(npc.position)
		await wait(0.1)
		for i in range(view.side_gnomes.size()):
			var npc: TextureRect = view.side_gnomes[i]
			check(npc.position == positions[i] and is_zero_approx(npc.rotation), "mid-walk Reduced Motion keeps NPC " + str(i) + " still")
	app._close_modal()
	await settle()
	await reset_map(false, 1, "hollow")
	view = app.map_view
	var same_endpoint: Vector2 = view.gnome.position
	await wait(0.15)
	check(not view.skip_button.visible and view.gnome.position == same_endpoint and not view.gnome.get_rect().intersects(view.buttons.hollow.get_rect()), "same-node return never starts a redundant walk")

func run() -> void:
	save_path = ProjectSettings.globalize_path("res://../verification/journey_edges_save.json")
	DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
	for suffix in ["", ".tmp"]:
		DirAccess.remove_absolute(save_path + suffix)
	root.size = Vector2i(432, 960)
	app = load("res://scripts/main.gd").new()
	app.save_path_override = save_path
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await wait(0.15)
	await test_overlay_release()
	await test_mouse_thresholds()
	await test_chamber_navigation()
	await test_horizontal_wheel()
	await test_walk_interruptions()
	await test_skip_and_reduced()
	app.queue_free()
	await settle()
	var result = {"status":"PASS" if failures.is_empty() else "FAIL", "checks":checks.size(), "failures":failures, "results":checks, "scope":"PC headless Godot native events; no physical Android or visual smoke claim", "save_path":save_path}
	var file = FileAccess.open(ProjectSettings.globalize_path("res://../verification/JOURNEY_EDGES_TEST.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("JOURNEY_EDGES " + JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
