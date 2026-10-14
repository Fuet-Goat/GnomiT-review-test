extends Control
const Levels = preload("res://scripts/levels.gd")
const Progress = preload("res://scripts/progress.gd")
const Core = preload("res://scripts/match_core.gd")
const RockAudio=preload("res://scripts/rock_audio.gd")
var rock_audio
const Board = preload("res://scripts/board_view.gd")
const World = preload("res://scripts/world_view.gd")
const Art=preload("res://scripts/story_art.gd")
const StoryChamber=preload("res://scripts/story_chamber_view.gd")
var chamber_view
const StoryMap=preload("res://scripts/slice_map_view.gd")
var map_view
const PreLevel=preload("res://scripts/pre_level_view.gd")
var pre_level_view
var _slice_session: Dictionary={}
var _saved_map_scroll: float=-1.0
var _saved_map_offset:=Vector2(-1,-1)
var _modal_return_focus: Control
var _return_from_id: String=""
var _map_focus_before_play: String=""
const FirstCrystals=preload("res://scripts/first_crystals_view.gd")
var first_scene
var save_path_override: String = "user://gnomit_vertical_slice1_progress_v2.json"
var progress
var core
var board
var current_level: Dictionary = {}
var current_screen: String = ""
var map_buttons: Dictionary = {}
var moves_label: Label
var goal_label: Label
var status_label: Label
var lantern_bar: ProgressBar
var stage: Control
var box: VBoxContainer
var world
var map_area: Control
var scene_world
var companion: TextureRect
var modal: Control
var audio: AudioStreamPlayer
var play_generation: int = 0
var seed_counter: int = 0
var pending_receipt: Dictionary = {}
var action_buttons: Array = []
var ui_theme: Theme
var _map_mode: String = "map"
var _paused: bool = false

func _ready() -> void:
	get_tree().auto_accept_quit = false
	DisplayServer.window_set_title("GnomiT — First Bend Preview")
	if DisplayServer.get_name()!="headless" and DisplayServer.get_screen_count()>1:
		DisplayServer.window_set_current_screen(0)
	ui_theme = _make_theme()
	theme = ui_theme
	progress = Progress.new()
	progress.load_progress(save_path_override if not save_path_override.is_empty() else "user://gnomit_storybook_progress_v2.json")
	world = World.new()
	world.scene_mode = "play"
	world.reduced_motion = progress.option("reduced_motion")
	world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(world)
	audio = AudioStreamPlayer.new()
	audio.volume_db = -12.0
	add_child(audio)
	rock_audio=RockAudio.new();add_child(rock_audio);rock_audio.set_enabled(progress.option("sound"))
	resized.connect(_resize_stage)
	if progress.option("fullscreen") and save_path_override.is_empty():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	show_map()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and progress != null:
		progress.persist()
		get_tree().quit()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if current_screen == "play" and core != null and (core.won or core.lost):
				get_viewport().set_input_as_handled()
				return
			if is_instance_valid(modal):
				_close_modal()
			elif current_screen == "play":
				show_pause()
			else:
				show_options()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F11:
			_set_fullscreen(DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN)
			get_viewport().set_input_as_handled()

func _make_theme() -> Theme:
	var t: Theme = Theme.new()
	var font: FontVariation = FontVariation.new()
	font.base_font = load("res://assets/font.ttf")
	font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700.0}
	t.default_font = font
	t.default_font_size = 21
	t.set_color("font_color","Label",Color("fff1c7"))
	t.set_color("font_shadow_color","Label",Color(0.02,0.03,0.06,0.8))
	t.set_constant("shadow_offset_y","Label",2)
	t.set_color("font_color","Button",Color("fff2cf"))
	t.set_color("font_disabled_color","Button",Color("9b9a9a"))
	for state in ["normal","hover","pressed","disabled"]:
		var fill: Color = Color("60331e")
		if state == "hover": fill = Color("865329")
		if state == "pressed": fill = Color("3b702e")
		if state == "disabled": fill = Color("323943")
		t.set_stylebox(state,"Button",Art.panel(Color("a9b7ab") if state=="disabled" else (Color.WHITE if state=="hover" else Color("ded0b7"))))
	t.set_stylebox("focus","Button",_style(Color(0,0,0,0),Color("96f3e8"),18,3))
	t.set_stylebox("panel","PanelContainer",Art.panel())
	t.set_constant("separation","VBoxContainer",12)
	t.set_constant("separation","HBoxContainer",12)
	return t

func _style(fill: Color, edge: Color, radius: int, border: int) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = edge
	s.set_border_width_all(border)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	s.shadow_color = Color(0,0,0,0.35)
	s.shadow_size = 5
	s.shadow_offset = Vector2(0,4)
	return s

func _label(text: String, font_size: int = 22, color: Color = Color("fff1c7"), centered: bool = false) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if centered: l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _button(text: String, action: Callable, kind: String = "wood") -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0,58)
	b.add_theme_font_size_override("font_size",22)
	b.pressed.connect(action)
	if kind == "green":
		b.add_theme_stylebox_override("normal",Art.panel(Color("bfdba5")))
		b.add_theme_stylebox_override("hover",Art.panel(Color("dcffc4")))
	elif kind == "gold":
		b.add_theme_stylebox_override("normal",Art.panel(Color("ffe6ab")))
	return b

func _new_screen(name: String) -> void:
	if is_instance_valid(map_view):
		_slice_session=map_view.get_session_state()
		_saved_map_scroll=map_view.current_scroll();_saved_map_offset=map_view.current_offset()
	if is_instance_valid(rock_audio):rock_audio.stop_all()
	play_generation += 1
	_close_modal()
	_paused = false
	if is_instance_valid(stage):
		stage.queue_free()
	current_screen = name
	map_buttons = {}
	action_buttons.clear()
	board = null
	first_scene = null
	map_view = null
	chamber_view=null
	world.show()
	map_area = null
	scene_world = null
	companion = null
	stage = Control.new()
	add_child(stage)
	_resize_stage()
	box = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(box)
	if not progress.option("reduced_motion"):
		stage.modulate.a = 0.0
		create_tween().tween_property(stage,"modulate:a",1.0,0.25)

func _resize_stage() -> void:
	if not is_instance_valid(stage): return
	if current_screen=="map":
		stage.position=Vector2.ZERO;stage.size=size;_layout_nodes();return
	var width: float = maxf(320.0,minf(size.x - 32.0,740.0))
	stage.position = Vector2((size.x-width)*0.5,0 if is_instance_valid(first_scene) or is_instance_valid(map_view) or is_instance_valid(chamber_view) else 16)
	stage.size = Vector2(width,maxf(550.0,size.y-(0.0 if is_instance_valid(first_scene) or is_instance_valid(map_view) else 32.0)))
	_layout_nodes()

func _header(title: String, subtitle: String, back: bool = false) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	box.add_child(row)
	var title_box: VBoxContainer = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_box)
	title_box.add_child(_label(title,38,Color("ffe09b")))
	title_box.add_child(_label(subtitle,18,Color("b7e9dd")))
	var menu: Button = _button("Back" if back else "☰",show_map if back else show_options)
	menu.custom_minimum_size.x = 82
	row.add_child(menu)

func show_map() -> void:
	_new_screen("map")
	box.hide();world.hide()
	map_view=StoryMap.new()
	map_view.session_state=_slice_session.duplicate(true)
	map_view.configure(progress,Levels.ordinary(),_next_level(),progress.option("reduced_motion"),_return_from_id,_saved_map_scroll,_saved_map_offset)
	_return_from_id=""
	stage.add_child(map_view)
	map_view.level_chosen.connect(start_level);map_view.boss_requested.connect(show_chamber);map_view.settings_requested.connect(show_options)
	map_view.arrived_at_level.connect(show_level_preview)
	map_buttons=map_view.buttons;map_area=map_view.canvas;companion=map_view.gnome
	_resize_stage();map_view.layout()
func _next_level() -> String:
	for id in Levels.ordinary():
		if progress.best_stars(id) == 0:
			return id
	return "boss"

func _gnome(extent: Vector2) -> TextureRect:
	var g: TextureRect = TextureRect.new()
	g.texture = Art.gnome()
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	g.size = extent
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return g

func _layout_nodes() -> void:
	if is_instance_valid(map_view):map_view.layout();return
	if is_instance_valid(chamber_view):chamber_view.layout();return
	if not is_instance_valid(map_area) or not is_instance_valid(scene_world): return
	if _map_mode == "map":
		var points: Array = [Vector2(0.34,0.13),Vector2(0.68,0.36),Vector2(0.31,0.59),Vector2(0.59,0.83)]
		var ids: Array = ["entry","hollow","seam","boss"]
		var open: Array = []
		for i in range(ids.size()):
			var b: Button = map_buttons.get(ids[i])
			if not is_instance_valid(b): continue
			b.size = Vector2(138,98)
			b.position = points[i] * map_area.size - b.size*0.5
			open.append(not b.disabled)
		scene_world.route_points = points
		scene_world.route_open = open
		var current_index: int = ids.find(_next_level())
		if current_index < 0: current_index = 3
		if is_instance_valid(companion):
			companion.position = points[current_index] * map_area.size + Vector2(-165,-80)
			companion.position.x = maxf(2.0,companion.position.x)
	else:
		var positions: Dictionary = {"rune":Vector2(0.25,0.28),"lantern":Vector2(0.75,0.28),"guardian":Vector2(0.5,0.77)}
		for id in positions:
			var b: Button = map_buttons.get(id)
			if not is_instance_valid(b): continue
			b.size = Vector2(minf(220.0,map_area.size.x*0.43),120 if id != "guardian" else 145)
			b.position = positions[id] * map_area.size - b.size * 0.5
		if is_instance_valid(companion):
			companion.position = Vector2(8,map_area.size.y*0.53)
	scene_world.queue_redraw()

func show_chamber() -> void:
	if progress.best_stars(Levels.ordinary().back())==0:show_map();return
	_new_screen("chamber");box.hide();world.hide()
	chamber_view=StoryChamber.new();chamber_view.configure(progress);stage.add_child(chamber_view)
	chamber_view.level_chosen.connect(start_level);chamber_view.back_requested.connect(show_map)
	map_buttons=chamber_view.buttons;companion=chamber_view.gnome
	_resize_stage();chamber_view.layout()

func show_level_preview(id: String) -> void:
	if current_screen not in ["map","chamber"]:return
	var data: Dictionary=Levels.get_level(id)
	if data.is_empty():return
	_close_modal()
	_modal_return_focus=get_viewport().gui_get_focus_owner()
	_set_navigation_interaction(false)
	pre_level_view=PreLevel.new()
	pre_level_view.configure(data,progress.best_stars(id),progress.is_unlocked(id),_unlock_reason(id),progress.option("reduced_motion"))
	pre_level_view.reward_available=id not in progress.data.claimed
	modal=pre_level_view;add_child(modal)
	pre_level_view.closed.connect(_close_modal)
	pre_level_view.play_requested.connect(func(chosen: String) -> void:
		if not is_instance_valid(pre_level_view) or chosen!=pre_level_view.level_id or not progress.is_unlocked(chosen):return
		if is_instance_valid(map_view) and map_view.slice_enabled:
			if map_view.selected_level!=chosen or absf(map_view.avatar_s-map_view.route.dock_s(chosen))>0.01:return
		_close_modal();start_level(chosen)
	)

func _unlock_reason(id: String) -> String:
	if progress.is_unlocked(id):return ""
	var ordinary: Array=Levels.ordinary()
	var index: int=ordinary.find(id)
	if index>0:return "Finish Level %d · %s to open this passage."%[index,Levels.get_level(ordinary[index-1]).name]
	if id in ["rune","lantern"] or progress.best_stars(ordinary.back())==0:return "Finish Level 7 · Crystal Bridge to enter the Guardian's chamber."
	if id=="guardian":return "Complete both preparations: Free the Runes and Charge the Lantern. Any order."
	return "Follow the lantern to the next open passage."

func _set_navigation_interaction(enabled: bool) -> void:
	if is_instance_valid(map_view):map_view.cancel_transition();map_view.set_interaction_enabled(enabled)
	if is_instance_valid(chamber_view):
		for control in chamber_view.buttons.values():control.focus_mode=Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
		chamber_view.back.disabled=not enabled

func start_level(id: String) -> void:
	if not progress.is_unlocked(id): return
	_map_focus_before_play=_next_level()
	_new_screen("play")
	current_level = Levels.get_level(id)
	if current_level.is_empty(): show_map(); return
	seed_counter += 1
	core = Core.new()
	core.setup(current_level,int(Time.get_ticks_msec()) + seed_counter*7919)
	world.guardian_light = 0.0
	if not current_level.is_empty():
		box.hide();world.hide()
		first_scene=FirstCrystals.new();stage.add_child(first_scene)
		first_scene.reduced_motion=progress.option("reduced_motion")
		board=first_scene.board;moves_label=first_scene.moves_label;goal_label=first_scene.goal_label;status_label=first_scene.status_label;lantern_bar=first_scene.lantern_bar
		board.setup(core,progress.option("reduced_motion"));first_scene.configure(current_level,core);board.swap_requested.connect(_on_swap);board.foley_requested.connect(_play_foley)
		first_scene.pause_requested.connect(show_pause);first_scene.hint_requested.connect(_hint);first_scene.exit_requested.connect(_exit_level)
		action_buttons.assign([first_scene.pause_button,first_scene.hint_button,first_scene.exit_button])
		_resize_stage();first_scene.layout();_update_hud();return
func _remaining(values: Array) -> int:
	var remaining: int = 0
	for value in values:
		if int(value) > 0: remaining += 1
	return remaining

func _update_hud() -> void:
	if current_screen != "play" or core == null: return
	if is_instance_valid(first_scene):
		first_scene.sync_from_core();return
	moves_label.text = "MOVES\n%d" % core.moves_left
	var total_runes: int = current_level.rune_cells.size()
	var total_floor: int = current_level.target_cells.size()
	match current_level.goal:
		"floor": goal_label.text = "▧  Golden Tiles\n%d / %d" % [total_floor-_remaining(core.floor),total_floor]
		"rune": goal_label.text = "◇  Runes\n%d / %d" % [total_runes-_remaining(core.runes),total_runes]
		"boss": goal_label.text = "◇ Runes %d/%d   ✦ Blue %d/%d" % [total_runes-_remaining(core.runes),total_runes,mini(core.collected,core.collect_goal),core.collect_goal]
		_: goal_label.text = "✦  Blue Gems\n%d / %d" % [mini(core.collected,core.collect_goal),core.collect_goal]
	lantern_bar.value = core.collected
	world.guardian_light = clampf(float(core.collected)/maxf(1,float(core.collect_goal)),0.0,1.0)

func _on_swap(a: int, b: int) -> void:
	if current_screen != "play" or _paused or board == null or board.busy: return
	if core.won or core.lost:return
	var generation: int = play_generation
	var active_board = board
	var result: Dictionary = core.try_swap(a,b)
	if result.valid:
		if is_instance_valid(first_scene):first_scene.moves_label.text=str(core.moves_left)
		status_label.text = "Gathering light…"
		if core.won:
			var earned: int = Levels.stars_for(core.moves_left,core.initial_moves)
			pending_receipt = progress.record_win(current_level.id,earned)
		for control in action_buttons: control.disabled = true
	else:
		status_label.text = "Try another swap. Match three or more."
	await active_board.animate_result(result)
	if generation != play_generation or current_screen != "play" or not is_instance_valid(active_board): return
	_update_hud()
	for control in action_buttons: control.disabled = false
	if core.won:
		_show_result(true,Levels.stars_for(core.moves_left,core.initial_moves),pending_receipt)
	elif core.lost:
		_show_result(false,0,{})
	elif result.valid:
		status_label.text = "A little closer!"

func _hint() -> void:
	if board == null or board.busy: return
	var pair: Array = core.hint_move()
	board.show_hint(pair)
	status_label.text = "Swap the glowing gems."
	_sound("select")

func _exit_level() -> void:
	if board != null and board.busy: return
	if current_level.id in ["rune","lantern","guardian"]: show_chamber()
	else: show_map()

func _modal_box() -> VBoxContainer:
	_close_modal()
	_modal_return_focus=get_viewport().gui_get_focus_owner()
	_set_navigation_interaction(false)
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.015,0.02,0.05,0.8)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size.x = minf(580.0,size.x-48.0)
	panel.add_theme_stylebox_override("panel",Art.panel())
	center.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation",18)
	panel.add_child(column)
	return column

func _close_modal() -> void:
	var was_open: bool=is_instance_valid(modal)
	if is_instance_valid(modal): modal.queue_free()
	modal = null
	pre_level_view=null
	_set_navigation_interaction(true)
	if was_open:
		if is_instance_valid(_modal_return_focus) and not _modal_return_focus.is_queued_for_deletion():_modal_return_focus.grab_focus()
		elif is_instance_valid(map_view):map_view.continue_button.grab_focus()
	_modal_return_focus=null
	_paused = false
	if is_instance_valid(board):
		board.mouse_filter = Control.MOUSE_FILTER_STOP

func _show_result(victory: bool, stars: int, receipt: Dictionary) -> void:
	var column: VBoxContainer = _modal_box()
	_paused = true
	column.add_child(_label("Passage Open!" if victory else "Try Again",35,Color("ffe09c"),true))
	column.add_child(_label(current_level.name,22,Color("a2ebdf"),true))
	if victory:
		if is_instance_valid(first_scene):first_scene.celebrate()
		var celebrating: TextureRect=_gnome(Vector2(135,175));celebrating.texture=Art.gnome(true);celebrating.custom_minimum_size=celebrating.size;column.add_child(celebrating)
		_sound("victory")
		var star_row: HBoxContainer = HBoxContainer.new()
		star_row.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_child(star_row)
		for i in range(3):
			var star: Label = _label("★",65,Color("ffd168") if i < stars else Color("40556b"),true)
			star.custom_minimum_size.x = 85
			star_row.add_child(star)
			if i < stars and not progress.option("reduced_motion"):
				star.modulate.a = 0.0
				var tw: Tween = create_tween()
				tw.tween_interval(0.12+float(i)*0.18)
				tw.tween_property(star,"modulate:a",1.0,0.22)
				if is_instance_valid(first_scene):
					star.pivot_offset=Vector2(42.5,35);star.scale=Vector2.ONE*0.55
					tw.parallel().tween_property(star,"scale",Vector2.ONE*1.15,0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					tw.tween_property(star,"scale",Vector2.ONE,0.12)
		column.add_child(_label("%d stars · %d moves left" % [stars,core.moves_left],22,Color("ffecc1"),true))
		if receipt.get("reward",0) > 0:
			column.add_child(_label("+10 Light for this new passage",21,Color("8ef1e8"),true))
		if not receipt.get("saved",true):
			column.add_child(_label("Progress is in memory. Saving failed.",18,Color("ffbe94"),true))
		column.add_child(_button("Continue Down  ↓",_continue_after_win,"green"))
	else:
		column.add_child(_label("No moves left. Your completed preparations and stars are safe.",21,Color("e4d7cc"),true))
		column.add_child(_button("Try Again",func() -> void: start_level(current_level.id),"green"))
	column.add_child(_button("Replay Level" if victory else "Back to Map",func() -> void:
		if victory: start_level(current_level.id)
		else: _exit_from_modal()
	))

func _exit_from_modal() -> void:
	_close_modal()
	if current_level.id in ["rune","lantern","guardian"]: show_chamber()
	else: show_map()

func _continue_after_win() -> void:
	var id: String=current_level.id
	_close_modal()
	if id in ["rune","lantern","guardian"]:show_chamber()
	else:
		_return_from_id=id if id==_map_focus_before_play and _next_level()!=id else ""
		show_map()

func show_pause() -> void:
	if is_instance_valid(board) and board.busy:return
	var column: VBoxContainer = _modal_box()
	_paused = true
	if is_instance_valid(board): board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_label("Paused",34,Color("ffe19e"),true))
	column.add_child(_button("Resume",_close_modal,"green"))
	column.add_child(_button("Settings",show_options))
	column.add_child(_button("Try Again",func() -> void: start_level(current_level.id)))
	column.add_child(_button("Back to Map",_exit_from_modal))

func show_options() -> void:
	if is_instance_valid(board) and board.busy:return
	var column: VBoxContainer = _modal_box()
	_paused = current_screen == "play"
	if is_instance_valid(board): board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_label("Settings",35,Color("ffe09c"),true))
	var sound: CheckButton = CheckButton.new()
	sound.text = "Sound Effects"
	sound.button_pressed = progress.option("sound")
	sound.custom_minimum_size.y = 52
	sound.toggled.connect(func(value: bool) -> void:
		progress.set_option("sound",value);rock_audio.set_enabled(value)
		if not value:audio.stop()
	)
	column.add_child(sound)
	var reduced: CheckButton = CheckButton.new()
	reduced.text = "Reduced Motion"
	reduced.button_pressed = progress.option("reduced_motion")
	reduced.custom_minimum_size.y = 52
	reduced.toggled.connect(func(value: bool) -> void:
		progress.set_option("reduced_motion",value)
		world.reduced_motion = value
		if is_instance_valid(scene_world): scene_world.reduced_motion = value
		if is_instance_valid(board): board.reduced_motion = value
		if is_instance_valid(first_scene):first_scene.reduced_motion=value
		if is_instance_valid(map_view):map_view.reduced_motion=value;map_view.cancel_transition()
	)
	column.add_child(reduced)
	var full: CheckButton = CheckButton.new()
	full.text = "Fullscreen (F11)"
	full.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	full.custom_minimum_size.y = 52
	full.toggled.connect(_set_fullscreen)
	column.add_child(full)
	column.add_child(_button("Done",_close_modal,"green"))
	column.add_child(_button("New Expedition",_confirm_reset))
	column.add_child(_button("Quit",func() -> void: progress.persist(); get_tree().quit()))

func _confirm_reset() -> void:
	var column: VBoxContainer = _modal_box()
	column.add_child(_label("New Expedition?",33,Color("ffe09c"),true))
	column.add_child(_label("This resets your GnomiT stars and Light.",22,Color("e7c8bb"),true))
	column.add_child(_button("Cancel",show_options,"green"))
	column.add_child(_button("Start Over",func() -> void: progress.reset(); _slice_session={}; _saved_map_scroll=-1.0; _saved_map_offset=Vector2(-1,-1); _return_from_id=""; map_view=null; show_map()))

func _set_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)
	progress.set_option("fullscreen",enabled)

func _play_foley(kind: String, strength: float) -> void:
	rock_audio.set_enabled(progress.option("sound"))
	rock_audio.play_cue(kind,strength)

func _sound(name: String) -> void:
	if not progress.option("sound"): return
	var stream: AudioStream = load("res://assets/" + name + ".wav")
	if stream != null:
		audio.stream = stream
		audio.play()
