extends SceneTree

class BoardFixture:
	extends RefCounted
	var cols := 7
	var rows := 8
	var grid: Array = []
	var floor: Array = []
	var runes: Array = []
	func _init() -> void:
		for i in range(56):
			grid.append(i % 6)
			floor.append(0)
			runes.append(0)
		grid[2] = -2

var failures := 0
var checks := 0
var observed: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL: " + label)

func _click(view: Control, point: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = point
	view._gui_input(down)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = point
	view._gui_input(up)

func _touch_click(view: Control, point: Vector2) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = point
	touch.pressed = true
	view._gui_input(touch)
	var mouse := InputEventMouseButton.new()
	mouse.device = InputEvent.DEVICE_ID_EMULATION
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = point
	mouse.pressed = true
	view._gui_input(mouse)
	touch.pressed = false
	view._gui_input(touch)
	mouse.pressed = false
	view._gui_input(mouse)

func _run() -> void:
	if not ResourceLoader.exists("res://scripts/board_view.gd"):
		_expect(false, "BoardView implementation is missing")
		quit(1)
		return
	var script = load("res://scripts/board_view.gd")
	if script == null or not script.can_instantiate():
		_expect(false, "BoardView loads")
		quit(1)
		return
	var preview := "--board-preview" in OS.get_cmdline_user_args()
	if preview:
		root.content_scale_size = Vector2i.ZERO
		root.size = Vector2i(480, 520)
		var backdrop := ColorRect.new()
		backdrop.size = Vector2(480, 520)
		backdrop.color = Color("091d2a")
		root.add_child(backdrop)
	var view = script.new()
	root.add_child(view)
	view.size = Vector2(480, 520)
	var core := BoardFixture.new()
	view.setup(core, false)
	view.swap_requested.connect(func(a: int, b: int) -> void: observed.append([a, b]))
	await process_frame
	# The 7x8 board fits inside 14-pixel margins with 61.5-pixel cells.
	_click(view, Vector2(55.5, 44.75))
	_click(view, Vector2(117, 44.75))
	_expect(observed == [[0, 1]], "neighbor clicks request the expected swap")
	observed.clear()
	_click(view, Vector2(55.5, 44.75))
	_click(view, Vector2(178.5, 44.75))
	_click(view, Vector2(117, 44.75))
	_expect(observed.is_empty(), "clicking a hole clears selection")
	_click(view, Vector2(424.5, 44.75))
	_click(view, Vector2(55.5, 106.25))
	_expect(observed.is_empty(), "adjacency never wraps across rows")
	view.setup(core, false)
	observed.clear()
	_touch_click(view, Vector2(55.5, 44.75))
	_touch_click(view, Vector2(117, 44.75))
	_expect(observed == [[0, 1]], "native touch with emulated mouse requests exactly one swap")
	var original: Array = core.grid.duplicate()
	var after: Array = original.duplicate()
	after[0] = original[1]
	after[1] = original[0]
	core.grid = after.duplicate()
	view.animate_result({"valid": true, "events": [{"type": "swap", "a": 0, "b": 1, "before": original, "after": after, "floor": core.floor, "runes": core.runes}]})
	_expect(view.busy, "animation locks input immediately")
	_expect(view.get("_display_grid") == original, "animation keeps the pre-swap snapshot while core is final")
	observed.clear()
	_click(view, Vector2(55.5, 44.75))
	_click(view, Vector2(117, 44.75))
	_expect(observed.is_empty(), "busy animation blocks input")
	await create_timer(0.7).timeout
	_expect(not view.busy, "animation unlocks after playback")
	_expect(view.get("_display_grid") == after, "animation finishes on the final snapshot")
	view.setup(core, true)
	await view.animate_result({"valid": false, "events": []})
	_expect(not view.busy, "empty invalid results complete in reduced motion")
	_expect(view.get("_display_grid") == core.grid, "invalid result restores the authoritative board")
	# Reusing the control during a swap must cancel the old visual stream.
	view.setup(core, false)
	view.animate_result({"valid": true, "events": [{"type": "swap", "a": 0, "b": 1, "before": original, "after": after, "floor": core.floor, "runes": core.runes}]})
	var replacement := BoardFixture.new()
	replacement.grid[0] = 5
	view.setup(replacement, true)
	await create_timer(0.35).timeout
	_expect(not view.busy and view.get("_display_grid") == replacement.grid, "setup cancels a prior stream without corrupting the next board")
	# Real seeded core events must end on each level’s authoritative snapshot.
	var core_script = load("res://scripts/match_core.gd")
	var catalog = load("res://scripts/levels.gd")
	for level in catalog.all():
		var real_core = core_script.new()
		real_core.setup(level, 101)
		view.setup(real_core, String(level.id) != "guardian")
		var pair: Array = real_core.hint_move()
		_expect(pair.size() == 2, "seeded level provides a legal hint: " + String(level.id))
		if pair.size() == 2:
			var result: Dictionary = real_core.try_swap(int(pair[0]), int(pair[1]))
			await view.animate_result(result)
			_expect(not view.busy and view.get("_display_grid") == real_core.grid, "real cascade ends on core grid: " + String(level.id))
			_expect(view.get("_display_floor") == real_core.floor and view.get("_display_runes") == real_core.runes, "real cascade ends on goal snapshots: " + String(level.id))
	if preview:
		core.floor[14] = 1
		core.floor[15] = 1
		core.floor[16] = 1
		core.grid[23] = -3
		core.runes[23] = 2
		core.grid[24] = -2
		core.grid[25] = -2
		view.setup(core, false)
		view.show_hint([7, 8])
		await process_frame
		await RenderingServer.frame_post_draw
		var output := OS.get_environment("TEMP").path_join("gnomit-board-preview.png")
		var image := root.get_texture().get_image()
		_expect(image.save_png(output) == OK, "board screenshot saves")
		print("BOARD_PREVIEW: " + output)
	if "--world-preview" in OS.get_cmdline_user_args():
		view.hide()
		root.content_scale_size = Vector2i.ZERO
		root.size = Vector2i(720, 1100)
		var world_script = load("res://scripts/world_view.gd")
		var world = world_script.new()
		root.add_child(world)
		world.size = Vector2(720, 1100)
		world.route_points = [Vector2(0.4, 0.22), Vector2(0.6, 0.35), Vector2(0.4, 0.49), Vector2(0.6, 0.63), Vector2(0.4, 0.78)]
		world.route_open = [true, true, true, false, false]
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var output := OS.get_environment("TEMP").path_join("gnomit-world-map-preview.png")
		_expect(image.save_png(output) == OK, "world map screenshot saves")
		world.scene_mode = "chamber"
		world.guardian_light = 0.8
		await process_frame
		await RenderingServer.frame_post_draw
		image = root.get_texture().get_image()
		output = OS.get_environment("TEMP").path_join("gnomit-world-chamber-preview.png")
		_expect(image.save_png(output) == OK, "world chamber screenshot saves")
		world.queue_free()
	view.queue_free()
	await process_frame
	print("BOARD_TESTS: " + ("PASS" if failures == 0 else "FAIL") + " (" + str(checks) + " checks, " + str(failures) + " failures)")
	quit(0 if failures == 0 else 1)
