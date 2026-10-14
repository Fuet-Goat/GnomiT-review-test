extends SceneTree

const Levels = preload("res://scripts/levels.gd")
const Art = preload("res://scripts/story_art.gd")
var checks := 0
var failures: Array[String] = []
var observations: Array = []
var app
var save_path: String

func _initialize() -> void:
	create_timer(90).timeout.connect(func() -> void:
		print("CANDY_NAVIGATION TIMEOUT: test did not complete")
		quit(99)
	)
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

func emit_mouse(button: MouseButton, position: Vector2, pressed: bool) -> void:
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
	emit_mouse(MOUSE_BUTTON_LEFT, position, true)
	await settle()
	emit_mouse(MOUSE_BUTTON_LEFT, position, false)
	await settle()

func mouse_drag(position: Vector2, delta: Vector2) -> void:
	emit_mouse(MOUSE_BUTTON_LEFT, position, true)
	await settle()
	for fraction in [0.25, 0.5, 0.75, 1.0]:
		var event := InputEventMouseMotion.new()
		event.position = root.get_final_transform() * (position + delta * fraction)
		event.global_position = event.position
		event.relative = root.get_final_transform().basis_xform(delta * 0.25)
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(event)
		await settle()
	emit_mouse(MOUSE_BUTTON_LEFT, position + delta, false)
	await settle()

func touch_drag(position: Vector2, delta: Vector2) -> void:
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = root.get_final_transform() * position
	down.pressed = true
	Input.parse_input_event(down)
	await settle()
	for fraction in [0.25, 0.5, 0.75, 1.0]:
		var motion := InputEventScreenDrag.new()
		motion.index = 0
		motion.position = root.get_final_transform() * (position + delta * fraction)
		motion.relative = root.get_final_transform().basis_xform(delta * 0.25)
		Input.parse_input_event(motion)
		await settle()
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = root.get_final_transform() * (position + delta)
	up.pressed = false
	Input.parse_input_event(up)
	await settle()

func node_center(id: String) -> Vector2:
	return app.map_view.buttons[id].get_global_rect().get_center()

func key_press(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await settle()

func texture_signature(texture: Texture2D) -> String:
	if texture is AtlasTexture:
		return texture.atlas.resource_path + ":" + str(texture.region)
	return texture.resource_path

func play_fingerprint() -> String:
	var core_state: Variant = null
	if app.core != null:
		core_state = {"grid":app.core.grid,"moves":app.core.moves_left,"collected":app.core.collected,"rng":app.core._rng.state}
	return JSON.stringify({"screen":app.current_screen,"seed":app.seed_counter,"generation":app.play_generation,"core":core_state,"level":app.current_level,"progress":app.progress.data})

func close_preview() -> void:
	app._close_modal()
	await settle()

func assert_preview(id: String, expected_goals: Array) -> void:
	var before: String = play_fingerprint()
	var before_scroll: int = app.map_view.current_scroll() if is_instance_valid(app.map_view) else -1
	app.show_level_preview(id)
	await settle()
	var preview = app.pre_level_view
	check(is_instance_valid(preview), id + " has a native pre-level view")
	if not is_instance_valid(preview):
		return
	var summary: Dictionary = preview.get_summary()
	var level: Dictionary = Levels.get_level(id)
	check(summary.get("id") == id and summary.get("name") == level.name, id + " preview identifies the real level")
	check(summary.get("moves") == level.moves, id + " preview displays the real move budget")
	check(summary.get("goals") == expected_goals, id + " preview contains the real goal kinds and counts")
	check(preview.goal_icons.size() == expected_goals.size(), id + " renders one actual icon per objective")
	for index in range(preview.goal_icons.size()):
		var icon = preview.goal_icons[index]
		check(icon.texture != null, id + " objective icon is a texture resource")
		var data: Dictionary = expected_goals[index]
		var expected_texture: Texture2D = Art.SOIL if data.type == "floor" else (Art.material(5) if data.type == "rune" else Art.treasure(data.kind))
		check(texture_signature(icon.texture) == texture_signature(expected_texture), id + " rendered objective uses the corresponding actual sprite")
	check(summary.get("stars") == app.progress.best_stars(id), id + " preview displays actual best stars")
	check(summary.get("unlocked") == app.progress.is_unlocked(id), id + " preview uses actual prerequisites")
	check(preview.play_button.disabled == not app.progress.is_unlocked(id), id + " Play respects actual prerequisites")
	check(play_fingerprint() == before, id + " opening preview changes no gameplay or persistent progress")
	if not app.progress.is_unlocked(id):
		preview.request_play()
		check(play_fingerprint() == before, id + " locked Play cannot start or mutate gameplay")
		check(not str(summary.get("lock_reason", "")).is_empty(), id + " locked preview explains the prerequisite")
	await close_preview()
	if before_scroll >= 0:
		check(app.map_view.current_scroll() == before_scroll, id + " closing preview keeps map position")

func run() -> void:
	root.size = Vector2i(432, 960)
	save_path = ProjectSettings.globalize_path("res://../verification/navigation_test_save.json")
	DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
	for suffix in ["", ".tmp"]:
		DirAccess.remove_absolute(save_path + suffix)
	app = load("res://scripts/main.gd").new()
	app.save_path_override = save_path
	root.add_child(app)
	app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await wait(0.35)
	app.progress.set_option("sound", false)
	app.progress.set_option("reduced_motion", true)
	app.map_view.reduced_motion = true
	check(app.current_screen == "map" and app.seed_counter == 0 and app.core == null, "fresh start stays on map without creating a level")
	check(app.map_buttons.size() == 8, "map has seven actual levels and one Boss entry")
	check(not app.map_view.scroll.follow_focus, "focus does not move a freely browsed map")
	var initial: int = app.map_view.current_scroll()
	var area: Vector2 = app.map_view.scroll.get_global_rect().get_center()
	emit_mouse(MOUSE_BUTTON_WHEEL_DOWN, area, true)
	await settle()
	emit_mouse(MOUSE_BUTTON_WHEEL_DOWN, area, false)
	await settle()
	check(app.map_view.current_scroll() > initial, "native mouse wheel moves downward through the map")
	check(not is_instance_valid(app.modal) and app.seed_counter == 0, "wheel browsing starts no level")
	app.map_view.focus_current()
	await settle()
	var mouse_start: int = app.map_view.current_scroll()
	await mouse_drag(node_center("entry"), Vector2(0, -95))
	check(app.map_view.current_scroll() > mouse_start, "mouse drag beginning on a node pans the map")
	check(not is_instance_valid(app.modal) and app.seed_counter == 0, "mouse pan release does not select its starting node")
	app.map_view.focus_current()
	await settle()
	var touch_start: int = app.map_view.current_scroll()
	await touch_drag(node_center("entry"), Vector2(0, -100))
	check(app.map_view.current_scroll() > touch_start, "native screen drag beginning on a node pans the map")
	check(not is_instance_valid(app.modal) and app.seed_counter == 0, "touch pan release does not select its starting node")
	app.map_view.focus_current()
	await settle()
	var fingerprint: String = play_fingerprint()
	await tap(node_center("entry"))
	check(is_instance_valid(app.pre_level_view) and app.current_screen == "map", "clicking current node opens preview before gameplay")
	check(play_fingerprint() == fingerprint, "a real node click leaves seed, moves, level and save untouched")
	var preview_scroll: int = app.map_view.current_scroll()
	emit_mouse(MOUSE_BUTTON_WHEEL_DOWN, area, true)
	await settle()
	emit_mouse(MOUSE_BUTTON_WHEEL_DOWN, area, false)
	await settle()
	check(app.map_view.current_scroll() == preview_scroll, "preview blocks map scrolling behind its panel")
	await tap(app.pre_level_view.close_button.get_global_rect().get_center())
	check(not is_instance_valid(app.modal), "native close button dismisses the preview")
	check(app.map_view.current_scroll() == preview_scroll, "native close button keeps the same map position")
	app.show_level_preview("entry")
	await settle()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await settle()
	check(not is_instance_valid(app.modal) and app.map_view.current_scroll() == preview_scroll, "Escape closes preview without moving the map")
	var hollow: Vector2 = app.map_view.points.hollow
	app.map_view.restore_scroll(int(maxf(0, hollow.y - app.map_view.scroll.size.y * 0.5)))
	await settle()
	await tap(node_center("hollow"))
	check(is_instance_valid(app.pre_level_view) and app.pre_level_view.play_button.disabled, "native pointer can inspect a locked node without Play")
	check(app.current_screen == "map" and app.seed_counter == 0, "locked node browsing cannot enter gameplay")
	var locked_scroll: int = app.map_view.current_scroll()
	for iteration in range(4):
		await key_press(KEY_TAB)
		check(root.gui_get_focus_owner() == app.pre_level_view.close_button, "locked preview keyboard focus stays on Close " + str(iteration))
	await key_press(KEY_ENTER)
	check(not is_instance_valid(app.modal) and app.current_screen == "map" and app.seed_counter == 0 and app.map_view.current_scroll() == locked_scroll, "Enter closes a locked preview without reaching map controls or gameplay")
	var boss_point: Vector2 = app.map_view.points.boss
	app.map_view.restore_scroll(boss_point.y - app.map_view.scroll.size.y * 0.55)
	await settle()
	await tap(node_center("boss"))
	check(is_instance_valid(app.pre_level_view) and app.pre_level_view.get_summary().id == "guardian" and app.pre_level_view.play_button.disabled, "native locked Boss entry opens an informative final preview")
	check(app.current_screen == "map" and app.seed_counter == 0, "locked Boss entry cannot bypass the ordinary path")
	await close_preview()
	var expected: Dictionary = {
		"entry":[{"type":"collect","kind":3,"count":12}],
		"hollow":[{"type":"floor","kind":-1,"count":12}],
		"seam":[{"type":"floor","kind":-1,"count":18}],
		"pearl":[{"type":"collect","kind":5,"count":16}],
		"goldore":[{"type":"collect","kind":2,"count":20}],
		"terraces":[{"type":"floor","kind":-1,"count":16}],
		"bridge":[{"type":"floor","kind":-1,"count":18}],
		"rune":[{"type":"rune","kind":-1,"count":3}],
		"lantern":[{"type":"lantern","kind":3,"count":16}],
		"guardian":[{"type":"rune","kind":-1,"count":3},{"type":"lantern","kind":3,"count":18}]
	}
	for id in expected:
		await assert_preview(id, expected[id])
	app.map_view.restore_scroll(230)
	await settle()
	var keyboard_parked: int = app.map_view.current_scroll()
	app.show_level_preview("entry")
	await settle()
	for iteration in range(8):
		await key_press(KEY_TAB)
		var focused: Control = root.gui_get_focus_owner()
		check(focused == app.pre_level_view.close_button or focused == app.pre_level_view.play_button, "unlocked preview Tab stays within the popup " + str(iteration))
		check(app.map_view.current_scroll() == keyboard_parked and app.current_screen == "map", "keyboard traversal cannot recenter or leave the map " + str(iteration))
	await key_press(KEY_TAB)
	check(root.gui_get_focus_owner() == app.pre_level_view.close_button, "Tab can select popup Close")
	await key_press(KEY_ENTER)
	check(not is_instance_valid(app.modal) and app.map_view.current_scroll() == keyboard_parked and app.seed_counter == 0, "native Enter on Close cannot invoke a background map action")
	app.show_level_preview("entry")
	await settle()
	var keyboard_seed: int = app.seed_counter
	await key_press(KEY_ENTER)
	check(app.current_screen == "play" and app.current_level.id == "entry" and app.seed_counter == keyboard_seed + 1, "native Enter on focused Play starts exactly the selected level")
	app._exit_level()
	await settle()
	app.show_level_preview("entry")
	await settle()
	var native_play_seed: int = app.seed_counter
	await tap(app.pre_level_view.play_button.get_global_rect().get_center())
	check(app.current_screen == "play" and app.current_level.id == "entry" and app.seed_counter == native_play_seed + 1, "native mouse Play starts exactly the selected level")
	app._exit_level()
	await settle()
	app.map_view.focus_current()
	await settle()
	app.show_level_preview("entry")
	await settle()
	var active_preview = app.pre_level_view
	var seed_before: int = app.seed_counter
	active_preview.request_play()
	active_preview.request_play()
	await settle()
	check(app.current_screen == "play" and app.current_level.id == "entry", "explicit Play enters the selected real board")
	check(app.seed_counter == seed_before + 1 and app.core.moves_left == 26, "repeated Play requests start exactly one fresh run")
	check(not is_instance_valid(app.modal), "pre-level panel is removed once gameplay begins")
	app._exit_level()
	await settle()
	check(app.current_screen == "map", "exiting level returns to map")
	app.map_view.restore_scroll(240)
	await settle()
	var parked: int = app.map_view.current_scroll()
	app.show_level_preview("entry")
	await settle()
	app.pre_level_view.request_play()
	await settle()
	app._exit_level()
	await wait(0.2)
	check(app.map_view.current_scroll() == parked, "gameplay exit restores the previously browsed map position")
	app.show_options()
	await settle()
	await close_preview()
	check(app.map_view.current_scroll() == parked, "settings close keeps freely browsed map position")
	await tap(app.map_view.current_button.get_global_rect().get_center())
	check(app.map_view.current_scroll() < parked, "native Current Level action returns to the active node")
	for viewport in [Vector2i(432,960), Vector2i(720,1600)]:
		root.size = viewport
		await settle()
		app._resize_stage()
		var current_rect: Rect2 = root.get_final_transform() * app.map_view.current_button.get_global_rect()
		check(current_rect.size.y >= 44, "Current Level keeps a usable physical touch-height target " + str(viewport))
		check(app.map_view.buttons.entry.tooltip_text.is_empty(), "level tooltips cannot float across the pre-level panel " + str(viewport))
		for id in expected:
			app.show_level_preview(id)
			await settle()
			var view = app.pre_level_view
			var viewport_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(viewport))
			var play_rect: Rect2 = root.get_final_transform() * view.play_button.get_global_rect()
			var close_rect: Rect2 = root.get_final_transform() * view.close_button.get_global_rect()
			check(viewport_rect.grow(1).encloses(play_rect), id + " Play fits the native viewport " + str(viewport))
			check(viewport_rect.grow(1).encloses(close_rect), id + " Close fits the native viewport " + str(viewport))
			check(play_rect.size.y >= 44 and close_rect.size.y >= 44, id + " Play and Close keep usable physical touch targets " + str(viewport))
			var panel_bounds := Rect2(Vector2.ZERO, view.panel.size)
			check(panel_bounds.grow(1).encloses(view.description_label.get_rect()), id + " description is contained in the popup " + str(viewport))
			check(view.description_label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, id + " description wraps by words " + str(viewport))
			check(view.description_label.get_content_height() <= view.description_label.size.y + 1, id + " rendered description fits its actual allotted height " + str(viewport))
			var next_content_y: float = view.lock_label.position.y if view.lock_label.visible else view.play_button.position.y
			check(view.description_label.get_rect().end.y < next_content_y, id + " description stays clear of the lock explanation or Play " + str(viewport))
			if view.lock_label.visible:
				check(panel_bounds.grow(1).encloses(view.lock_label.get_rect()) and view.lock_label.get_content_height() <= view.lock_label.size.y + 1, id + " full lock explanation fits the popup " + str(viewport))
				check(view.lock_label.get_rect().end.y < view.play_button.position.y, id + " lock explanation stays clear of Play " + str(viewport))
			observations.append({"viewport":str(viewport),"id":id,"play_physical":str(play_rect),"close_physical":str(close_rect),"description_height":view.description_label.size.y,"description_content_height":view.description_label.get_content_height(),"scroll":app.map_view.current_scroll()})
			await close_preview()
	root.size = Vector2i(432,960)
	await settle()
	for id in Levels.ordinary():
		app.progress.record_win(id, 1)
	app.show_chamber()
	await settle()
	check(app.current_screen == "chamber", "seven completed ordinary levels open the separate Boss hall")
	app.show_level_preview("guardian")
	await settle()
	check(app.pre_level_view.play_button.disabled, "Boss final preview stays locked until both preparations")
	await close_preview()
	app.progress.record_win("rune", 1)
	app.show_level_preview("guardian")
	await settle()
	check(app.pre_level_view.play_button.disabled, "one preparation alone keeps the final preview locked")
	await close_preview()
	app.progress.record_win("lantern", 2)
	app.show_level_preview("guardian")
	await settle()
	check(not app.pre_level_view.play_button.disabled, "both independently saved preparations enable Boss Play")
	await close_preview()
	var reloaded = load("res://scripts/progress.gd").new()
	reloaded.load_progress(save_path)
	check(reloaded.best_stars("rune") == 1 and reloaded.best_stars("lantern") == 2 and reloaded.is_unlocked("guardian"), "existing local save schema retains preparation stars and unlocks")
	app.progress.reset()
	app.progress.set_option("sound", false)
	app.progress.set_option("reduced_motion", true)
	app.show_map()
	await settle()
	app.show_level_preview("entry")
	await settle()
	app.pre_level_view.request_play()
	await settle()
	app.core.setup(app.current_level, 42)
	app.board.setup(app.core, true)
	app.first_scene.reduced_motion = true
	app._update_hud()
	for pair in [[10,11],[29,36],[39,40]]:
		await app._on_swap(pair[0],pair[1])
	check(app.core.won and app.progress.best_stars("entry") > 0, "selected real entry swaps earn actual victory")
	app._continue_after_win()
	await settle()
	check(app.current_screen == "map" and app.map_view.focus_id == "hollow", "real victory continues downward to the next actual level")
	check(not app.map_view.skip_button.visible, "reduced motion finishes descent without a camera flight")
	var saved_light: int = app.progress.data.light
	check(saved_light == 10, "actual victory rewards Light exactly once")
	var passage_guide_position: Vector2 = app.map_view.gnome.position
	app.progress.set_option("reduced_motion", false)
	app._return_from_id = "entry"
	app.show_map()
	await settle()
	check(app.map_view.skip_button.visible, "normal-motion victory descent can be skipped")
	check(app.map_view.gnome.position.is_equal_approx(passage_guide_position), "victory camera starts with guide anchored at the current unlocked passage")
	await wait(0.15)
	check(app.map_view.skip_button.visible and app.map_view.gnome.position.is_equal_approx(passage_guide_position), "guide remains stationary while the victory camera moves")
	app.map_view.finish_transition()
	check(not app.map_view.skip_button.visible and app.map_view.focus_id == "hollow" and app.progress.data.light == saved_light, "Skip preserves the same unlocked target and reward")
	await settle()
	var browse_seed: int = app.seed_counter
	await tap(node_center("entry"))
	check(is_instance_valid(app.pre_level_view) and app.pre_level_view.get_summary().id == "entry" and app.map_view.gnome.position.is_equal_approx(passage_guide_position) and app.current_screen == "map" and app.seed_counter == browse_seed, "clicking a completed level opens its preview without moving the passage guide or starting gameplay")
	await close_preview()
	app.map_view.restore_scroll(app.map_view.points.seam.y - app.map_view.scroll.size.y * 0.5)
	await settle()
	await tap(node_center("seam"))
	check(is_instance_valid(app.pre_level_view) and app.pre_level_view.get_summary().id == "seam" and app.pre_level_view.play_button.disabled and app.map_view.gnome.position.is_equal_approx(passage_guide_position) and app.current_screen == "map" and app.seed_counter == browse_seed, "clicking a locked level keeps the guide at the current passage and cannot start gameplay")
	await close_preview()
	app.queue_free()
	await settle()
	for suffix in ["", ".tmp"]:
		DirAccess.remove_absolute(save_path + suffix)
	var result: Dictionary = {"checks":checks,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL","observations":observations,"input":"NATIVE_INPUT_EVENTS_AND_REAL_GAMEPLAY_SWAPS","physical_android_test":false,"human_usability_test":false}
	var report = FileAccess.open(ProjectSettings.globalize_path("res://../verification/navigation_checks.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify(result, "  "))
	report.close()
	print("CANDY_NAVIGATION " + JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
