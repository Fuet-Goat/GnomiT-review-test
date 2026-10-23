extends Control
## Native R3 geometry, route travel and arrival adapter for the existing game.
signal level_selected(id: String)
signal settings_requested
const Route = preload("res://scripts/r3/island_route.gd")
const SIZE := Vector2(432, 960)
const SPEED := 1.8
const DRAG_THRESHOLD := 12.0
var progress
var session_state: Dictionary = {}
var alive_enabled := true
var slice_enabled := true
var alive_hero
var alive_ambient
var gnome: TextureRect
var canvas: Control
var continue_button: Control
var buttons: Dictionary = {}
var native_viewport: SubViewport
var native_scene: Node3D
var model: Node3D
var camera: Camera3D
var guide: Node3D
var route = Route.new()
var avatar_s := 0.4
var target_s := 0.4
var selected_level := ""
var destination := ""
var walking := false
var interaction_enabled := true
var reduced_motion := false:
	set(value):
		reduced_motion = value
		if is_instance_valid(guide): guide.set_motion(not value and interaction_enabled and has_focus_window)
var has_focus_window := true
var pointer_active := false
var pointer_index := -1
var pointer_start := Vector2.ZERO
var pointer_distance := 0.0
var camera_scroll := 0.0
var camera_goal := 0.0
var camera_base: Transform3D
var follow := true
var overlay: Control
var status: Label
var stats: Label
var follow_button: Button
var lantern: OmniLight3D
var lantern_base_energy := 1.7
var lighting_profile_id := ""
var lighting_settings: Dictionary = {}
var age := 0.0
var lock_bar: MeshInstance3D
var ready_for_play := false
var last_tap_result := ""

func configure(value, reduced: bool) -> void:
	progress = value
	reduced_motion = reduced

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	canvas = self
	continue_button = self
	native_viewport = SubViewport.new()
	native_viewport.size = Vector2i(432, 960)
	native_viewport.own_world_3d = true
	native_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	native_viewport.msaa_3d = Viewport.MSAA_4X
	native_viewport.use_taa = true
	add_child(native_viewport)
	native_scene = Node3D.new()
	native_viewport.add_child(native_scene)
	var island_path := OS.get_environment("GROK_ISLAND_GLB")
	if island_path.is_empty(): island_path = "res://assets/r3/airy_island.glb"
	model = (load(island_path) as PackedScene).instantiate()
	native_scene.add_child(model)
	_apply_reference_grass_material()
	_apply_tree_vertex_colours()
	camera = model.find_child("Portrait_Camera", true, false) as Camera3D
	if camera == null or not route.configure(model):
		push_error("R3 import is missing the authored route/camera; navigation disabled.")
		return
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.make_current()
	camera_base = camera.global_transform
	_build_lighting()
	guide = load("res://scripts/r3/r3_guide.gd").new()
	native_scene.add_child(guide)
	guide.set_motion(not reduced_motion)
	avatar_s = clampf(float(session_state.get("avatar_s", 0.4)), 0, reachable_s())
	target_s = avatar_s
	camera_scroll = clampf(float(session_state.get("camera_scroll", 0.0)), -2.4, 2.8)
	camera_goal = camera_scroll
	guide.position = route.point(avatar_s)
	guide.set_walk(0.0, false, 0.0)
	var image := TextureRect.new()
	image.texture = native_viewport.get_texture()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image)
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_build_lock()
	layout()
	ready_for_play = true
	_update_camera(1.0)
	_update_markers()
	print("R3_JOURNEY_READY " + JSON.stringify({"route_samples": route.points.size(), "length_m": route.end_s(), "dock_1": route.dock_s("entry"), "dock_2": route.dock_s("hollow"), "user_dir": OS.get_user_data_dir(), "viewport": [432,960]}))

func _apply_reference_grass_material() -> void:
	var grass_material := ShaderMaterial.new()
	grass_material.shader = preload("res://shaders/reference_grass.gdshader")
	for grass in model.find_children("Reference_Grass_*", "MeshInstance3D", true, false):
		grass.material_override = grass_material

func _apply_tree_vertex_colours() -> void:
	for tree_mesh in model.find_children("*", "MeshInstance3D", true, false):
		var tree_name: String = tree_mesh.name
		if not (tree_name.ends_with("_Crown_Sculpt") or "_Sculpted_Trunk" in tree_name or "_Root_" in tree_name or "_Branch_" in tree_name):
			continue
		for surface in range(tree_mesh.mesh.get_surface_count()):
			var imported := tree_mesh.get_active_material(surface) as StandardMaterial3D
			if imported == null: continue
			var coloured := imported.duplicate() as StandardMaterial3D
			coloured.vertex_color_use_as_albedo = true
			tree_mesh.set_surface_override_material(surface, coloured)

func _light_color(values: Dictionary) -> Color:
	if values.has("rgb"):
		var rgb: Array = values["rgb"]
		return Color(float(rgb[0]),float(rgb[1]),float(rgb[2]))
	return Color(values["color"])

func _build_lighting() -> void:
	var recipe: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/r3/lighting_v012.json"))
	var requested := OS.get_environment("GNOMIT_LIGHTING_PROFILE")
	lighting_profile_id = requested if not requested.is_empty() else String(recipe["selected"])
	assert(recipe["profiles"].has(lighting_profile_id), "Unknown lighting profile")
	lighting_settings = recipe["profiles"][lighting_profile_id]
	var cfg := lighting_settings
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(cfg["background"])
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(cfg["ambient_color"])
	environment.ambient_light_energy = float(cfg["ambient_energy"])
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = float(cfg["exposure"])
	environment.ssao_enabled = true
	environment.ssao_radius = float(cfg["ao_radius"])
	environment.ssao_intensity = float(cfg["ao_intensity"])
	environment.ssao_light_affect = float(cfg["ao_light_affect"])
	var world := WorldEnvironment.new()
	world.name = "Map_Lighting_Environment"
	world.environment = environment
	native_scene.add_child(world)
	for role in ["key", "fill"]:
		var values: Dictionary = cfg[role]
		var light := DirectionalLight3D.new()
		light.name = "Map_Sun_Key" if role == "key" else "Map_Sky_Fill"
		var angles: Array = values["rotation"]
		light.rotation_degrees = Vector3(float(angles[0]),float(angles[1]),float(angles[2]))
		light.light_color = Color(values["color"])
		light.light_energy = float(values["energy"])
		light.shadow_enabled = role == "key"
		light.light_angular_distance = float(cfg["key"]["angular_distance"])
		light.directional_shadow_max_distance = 65.0
		light.shadow_bias = 0.03
		native_scene.add_child(light)
	var pivot := model.find_child("Lantern_Pivot", true, false) as Node3D
	lantern = OmniLight3D.new()
	lantern.name = "Map_Lantern"
	lantern.light_color = _light_color(cfg["lantern"])
	lantern_base_energy = float(cfg["lantern"]["energy"])
	lantern.light_energy = lantern_base_energy
	lantern.omni_range = float(cfg["lantern"]["range"])
	lantern.shadow_enabled = true
	lantern.light_size = float(cfg["lantern"]["size"])
	native_scene.add_child(lantern)
	lantern.global_position = pivot.global_position if pivot != null else route.point(route.end_s()) + Vector3(-0.6,1.7,-0.2)
	var amber := OmniLight3D.new()
	amber.name = "Map_Interior_Amber"
	amber.light_color = _light_color(cfg["interior"])
	amber.light_energy = float(cfg["interior"]["energy"])
	amber.omni_range = float(cfg["interior"]["range"])
	native_scene.add_child(amber)
	amber.position = route.point(route.end_s()) + Vector3(0.2,1.0,-0.7)

func _panel_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(16)
	style.border_color = Color("e8c978")
	style.set_border_width_all(2)
	return style

func _label(text: String, position: Vector2, extent: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = extent
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color", Color("fff8e4"))
	label.add_theme_color_override("font_outline_color", Color("28483f"))
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_constant_override("shadow_offset_y", 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(label)
	return label

func _button(text: String, position: Vector2, extent: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = extent
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size",15)
	button.add_theme_stylebox_override("normal",_panel_style(Color("315a4ded")))
	button.add_theme_stylebox_override("hover",_panel_style(Color("4c795bed")))
	button.add_theme_stylebox_override("pressed",_panel_style(Color("254739")))
	button.pressed.connect(callback)
	overlay.add_child(button)
	return button

func _build_ui() -> void:
	overlay = Control.new()
	var map_theme := Theme.new()
	map_theme.default_font = load("res://assets/font.ttf")
	map_theme.default_font_size = 16
	map_theme.set_constant("shadow_offset_y", "Label", 0)
	overlay.theme = map_theme
	overlay.size = SIZE
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	_label("GnomiT", Vector2(18,14), Vector2(230,48), 34)
	_label("R3 · THE SURFACE", Vector2(20,60), Vector2(270,28), 13)
	stats = _label("",Vector2(20,89),Vector2(260,26),13)
	_button("Settings",Vector2(322,22),Vector2(94,42),func(): settings_requested.emit())
	for id in ["entry", "hollow"]:
		var button := _button("1" if id == "entry" else "2",Vector2.ZERO,Vector2(52,52),func(): pass)
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_theme_font_size_override("font_size",26)
		buttons[id] = button
	var footer := Panel.new()
	footer.position = Vector2(12,852)
	footer.size = Vector2(408,94)
	footer.add_theme_stylebox_override("panel",_panel_style(Color("244a42ed")))
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(footer)
	status = _label("Tap the wooden path to walk.\nDrag up or down to explore.",Vector2(25,863),Vector2(285,68),15)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	follow_button = _button("Find\ngnome",Vector2(321,872),Vector2(86,58),func(): follow = true; guide.greet())

func _build_lock() -> void:
	lock_bar = MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(1.16,0.08,0.10)
	lock_bar.mesh = bar
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("d99d4a")
	material.roughness = 0.85
	lock_bar.material_override = material
	native_scene.add_child(lock_bar)
	lock_bar.position = route.point(route.dock_s("entry")+0.55)+Vector3(0,0.14,0)
	var tangent := route.point(route.dock_s("entry")+0.6)-route.point(route.dock_s("entry")+0.5)
	lock_bar.rotation.y = atan2(-tangent.x,-tangent.z)
	lock_bar.visible = not progress.is_unlocked("hollow")

func reachable_s() -> float:
	return route.end_s() if progress.is_unlocked("hollow") else route.dock_s("entry")

func walk_to(s: float, id: String = "") -> bool:
	if not ready_for_play or not interaction_enabled: return false
	if s > reachable_s()+0.015 or (not id.is_empty() and not progress.is_unlocked(id)):
		last_tap_result = "locked"
		status.text = "Win Level 1 to open the path\nto the mine entrance."
		return false
	target_s = clampf(s,0.0,reachable_s())
	destination = id
	selected_level = ""
	follow = true
	walking = absf(target_s-avatar_s)>0.005
	last_tap_result = "walk"
	status.text = "On our way..." if walking else "Ready. Tap a level to enter."
	if not walking: _arrive()
	return true

func _arrive() -> void:
	walking = false
	guide.set_walk(0.0,false,guide.rotation.y)
	if destination.is_empty():
		status.text = "Tap the path to keep walking.\nTap a level to see its goals."
		return
	var arrived := destination
	destination = ""
	selected_level = arrived
	status.text = "Level " + ("1" if arrived == "entry" else "2") + " · arrived"
	guide.greet()
	# Existing goals/reward panel owns the single Play button.
	level_selected.emit(arrived)

func _update_markers() -> void:
	for id in buttons:
		var button: Button = buttons[id]
		var foot := camera.unproject_position(route.point(route.dock_s(id)))
		# Offset the badge to the side, preserving the road and avatar silhouette.
		var offset := Vector2(43,-19) if id == "entry" else Vector2(40,-10)
		button.position = foot + offset - button.size*0.5
		button.visible = button.position.y > 122 and button.position.y < 790
		var unlocked: bool = progress.is_unlocked(id)
		button.text = ("1" if id == "entry" else "2") + ("" if unlocked else "×")
		button.add_theme_stylebox_override("normal",_panel_style(Color("5b9139") if unlocked else Color("667777")))
	stats.text = "%d stars · %d Light" % [progress.total_stars(),progress.data.light]

func _marker_at(p: Vector2) -> String:
	for id in buttons:
		var button: Button = buttons[id]
		if button.visible and button.get_rect().has_point(p): return id
	return ""

func tap(p: Vector2) -> void:
	var id := _marker_at(p)
	if not id.is_empty():
		walk_to(route.dock_s(id),id)
		return
	var nearest: Dictionary = route.screen_closest(p,camera)
	if nearest.distance <= nearest.tolerance:
		walk_to(nearest.s)
	else:
		last_tap_result = "off_path"
		status.text = "Follow the wooden path."

func _gui_input(event: InputEvent) -> void:
	if not interaction_enabled or not ready_for_play: return
	var ratio := SIZE/size
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: _begin_pointer(event.position*ratio,-1)
		elif pointer_index == -1: _end_pointer(event.position*ratio)
	elif event is InputEventMouseMotion and pointer_active and pointer_index == -1:
		_move_pointer(event.position*ratio,event.relative*ratio)
	elif event is InputEventScreenTouch:
		if event.pressed and not pointer_active: _begin_pointer(event.position*ratio,event.index)
		elif not event.pressed and event.index == pointer_index: _end_pointer(event.position*ratio)
	elif event is InputEventScreenDrag and pointer_active and event.index == pointer_index:
		_move_pointer(event.position*ratio,event.relative*ratio)
	accept_event()

func _begin_pointer(p: Vector2, index: int) -> void:
	if p.y < 122 or p.y > 845: return
	pointer_active = true
	pointer_index = index
	pointer_start = p
	pointer_distance = 0.0

func _move_pointer(p: Vector2, relative: Vector2) -> void:
	pointer_distance = maxf(pointer_distance,p.distance_to(pointer_start))
	if pointer_distance < DRAG_THRESHOLD: return
	stop_walking()
	follow = false
	camera_goal = clampf(camera_goal+relative.y*camera.size/SIZE.y,-2.4,2.8)
	status.text = "Exploring · tap the path to walk."

func _end_pointer(p: Vector2) -> void:
	if not pointer_active: return
	pointer_distance = maxf(pointer_distance,p.distance_to(pointer_start))
	pointer_active = false
	pointer_index = -1
	if pointer_distance < DRAG_THRESHOLD: tap(p)

func stop_walking() -> void:
	walking = false
	target_s = avatar_s
	destination = ""
	if is_instance_valid(guide): guide.set_walk(0.0,false,guide.rotation.y)

func cancel_transition() -> void:
	pointer_active = false
	pointer_index = -1
	stop_walking()

func set_interaction_enabled(enabled: bool) -> void:
	interaction_enabled = enabled
	if not enabled: cancel_transition()
	if is_instance_valid(guide): guide.set_motion(enabled and not reduced_motion and has_focus_window)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		has_focus_window = false
		cancel_transition()
		if is_instance_valid(guide): guide.set_motion(false)
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		has_focus_window = true
		if is_instance_valid(guide): guide.set_motion(interaction_enabled and not reduced_motion)

func _update_camera(delta: float) -> void:
	if follow and not pointer_active:
		var foot_y := camera.unproject_position(guide.position).y
		if walking and foot_y < 270: camera_goal += (270-foot_y)*camera.size/SIZE.y
		elif walking and foot_y > 750: camera_goal -= (foot_y-750)*camera.size/SIZE.y
		camera_goal = clampf(camera_goal,-2.4,2.8)
	camera_scroll = lerpf(camera_scroll,camera_goal,1.0-exp(-delta*5.0))
	camera.global_transform = camera_base
	camera.global_position += camera_base.basis.y*camera_scroll

func _process(delta: float) -> void:
	if not ready_for_play: return
	if walking and interaction_enabled and has_focus_window:
		var previous := avatar_s
		avatar_s = move_toward(avatar_s,target_s,SPEED*delta)
		var movement := route.point(avatar_s)-route.point(previous)
		guide.position = route.point(avatar_s)
		if movement.length_squared()>0.000001:
			guide.set_walk(absf(avatar_s-previous),true,atan2(movement.x,movement.z))
		if absf(avatar_s-target_s)<0.001: _arrive()
	_update_camera(delta)
	_update_markers()
	if interaction_enabled and has_focus_window and not reduced_motion:
		age += delta
		lantern.light_energy = lantern_base_energy*(1.0+0.045*sin(age*2.1)+0.02*sin(age*4.7))

func layout() -> void:
	if overlay != null: overlay.scale = size/SIZE
func get_session_state() -> Dictionary:
	return {"avatar_s":avatar_s,"camera_scroll":camera_scroll}
func current_scroll() -> float: return camera_scroll
func current_offset() -> Vector2: return Vector2(0,camera_scroll)
func marker_center(id: String) -> Vector2:
	var button: Button = buttons[id]
	return get_global_transform()*((button.position+button.size*0.5)*size/SIZE)
func entry_context() -> Dictionary: return {}
