extends Control
signal pause_requested
signal hint_requested
signal exit_requested
const Board=preload("res://scripts/board_view.gd")
const Trails=preload("res://scripts/goal_trails.gd")
const Art=preload("res://scripts/story_art.gd")
const BACKGROUND=preload("res://assets/first_crystals/cave_background_v1.png")
const ATLAS=Art.TREASURES
var board
var moves_label: Label
var goal_label: Label
var secondary_goal_label: Label
var status_label: Label
var lantern_bar: ProgressBar
var pause_button: Button
var hint_button: Button
var exit_button: Button
var title: Label
var move_caption: Label
var goal_caption: Label
var goal_icon: TextureRect
var gnome: TextureRect
var helper: Label
var guardian: TextureRect
var trails
var target:=12
var shown_collected:=0
var shown_runes:=0
var reduced_motion:=false
var hud_rects: Dictionary={}
var _pulse: Tween
var _core
var _level: Dictionary={}
var _goal_type: String="collect"
var _bold_font: FontVariation
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(layout)
	_bold_font=Art.font()
	title=label("FIRST CRYSTALS",32)
	move_caption=label("MOVES",20)
	moves_label=label("26",48)
	goal_caption=label("COLLECT",20)
	goal_label=label("0 / 12",42)
	secondary_goal_label=label("",24);secondary_goal_label.hide()
	status_label=label("Match 3 treasures to dig!",24)
	status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	goal_icon=texture(Art.treasure(3))
	lantern_bar=ProgressBar.new();add_child(lantern_bar);lantern_bar.show_percentage=false
	lantern_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	lantern_bar.add_theme_stylebox_override("background",style(Color("152e3b"),Color("6d897b"),8,1))
	lantern_bar.add_theme_stylebox_override("fill",style(Color("61d9ee"),Color("e3f5b1"),8,1))
	board=Board.new();board.polished_art=true;add_child(board)
	board.goal_piece_cleared.connect(on_goal_piece)
	board.terrain_target_cleared.connect(on_soil)
	board.rune_freed.connect(on_rune)
	exit_button=button("‹",func() -> void:exit_requested.emit())
	pause_button=button("Ⅱ",func() -> void:pause_requested.emit())
	hint_button=button("✦  Hint",func() -> void:hint_requested.emit())
	exit_button.tooltip_text="Back to the map";pause_button.tooltip_text="Pause"
	gnome=texture(Art.gnome())
	guardian=texture(Art.material(3));guardian.hide()
	helper=label("Light the way!",24)
	trails=Trails.new();add_child(trails);trails.z_index=20;trails.arrived.connect(on_arrived)
	layout()
func texture(image: Texture2D) -> TextureRect:
	var t=TextureRect.new();t.texture=image;t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;t.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(t);return t
func configure(level: Dictionary, core) -> void:
	_level=level;_core=core;_goal_type=String(level.goal)
	title.text=String(level.name).to_upper()
	status_label.text=level.description
	goal_caption.text="CLEAR SOIL" if _goal_type=="floor" else ("FREE RUNES" if _goal_type=="rune" else "COLLECT")
	goal_icon.texture=Art.SOIL if _goal_type=="floor" else (Art.material(5) if _goal_type=="rune" else Art.treasure(core.collect_kind))
	trails.token_texture=goal_icon.texture
	trails.tint=Color("ffe09c") if _goal_type in ["floor","rune"] else Board.GEM_COLORS[core.collect_kind%6]
	secondary_goal_label.visible=_goal_type=="boss";guardian.visible=_goal_type=="boss"
	helper.text="Light the Guardian!" if _goal_type=="boss" else "Light the way!"
	sync_from_core();layout()
func remaining(values: Array) -> int:
	var result:=0
	for value in values:
		if int(value)>0:result+=1
	return result
func objective_done() -> int:
	if _core==null:return shown_collected
	if _goal_type=="floor":return _level.target_cells.size()-remaining(_core.floor)
	if _goal_type=="rune":return _level.rune_cells.size()-remaining(_core.runes)
	return mini(_core.collected,target)
func sync_from_core() -> void:
	if _core==null:return
	var total: int=_level.target_cells.size() if _goal_type=="floor" else (_level.rune_cells.size() if _goal_type=="rune" else _core.collect_goal)
	update_stats(_core.moves_left,objective_done(),total)
	if _goal_type=="boss":
		shown_runes=_level.rune_cells.size()-remaining(_core.runes)
		secondary_goal_label.text="FREE RUNES   %d / %d"%[shown_runes,_level.rune_cells.size()]
		guardian.modulate=Color.WHITE.lerp(Color("c5f6dd"),float(shown_collected)/maxi(1,target))
func label(text: String, font_size: int) -> Label:
	var l=Label.new();l.text=text;l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode=TextServer.AUTOWRAP_OFF;l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font",_bold_font);l.add_theme_font_size_override("font_size",font_size);l.add_theme_color_override("font_color",Color("fff8e2"));l.add_theme_color_override("font_outline_color",Color("352a20"));l.add_theme_constant_override("outline_size",2)
	add_child(l);return l
func style(fill: Color, edge: Color, radius: int=20, border: int=2) -> StyleBoxFlat:
	var s=StyleBoxFlat.new();s.bg_color=fill;s.border_color=edge;s.set_border_width_all(border);s.set_corner_radius_all(radius);return s
func button(text: String, action: Callable) -> Button:
	var b=Button.new();b.add_theme_font_override("font",_bold_font);b.text=text;b.pressed.connect(action);b.add_theme_font_size_override("font_size",30)
	b.add_theme_color_override("font_color",Color("fff3ca"))
	for state in ["normal","hover","pressed","disabled"]:
		b.add_theme_stylebox_override(state,Art.round_button() if text.length()<3 else Art.panel(Color("bfdba5") if state=="normal" else (Color.WHITE if state=="hover" else Color("9faaa5"))))
	add_child(b);return b
func layout() -> void:
	if board==null:return
	var w: float=size.x
	var unit: float=minf(1.0,w/720.0)
	var edge: float=24*unit
	var title_y: float=30*unit
	title.position=Vector2(edge+76*unit,title_y);title.size=Vector2(w-2*edge-152*unit,76*unit)
	title.add_theme_font_size_override("font_size",int((25 if _goal_type=="boss" else 30)*unit))
	exit_button.position=Vector2(edge,title_y+4*unit);exit_button.size=Vector2.ONE*68*unit
	pause_button.position=Vector2(w-edge-68*unit,title_y+4*unit);pause_button.size=Vector2.ONE*68*unit
	var hud_y: float=134*unit
	hud_rects.moves=Rect2(edge,hud_y,184*unit,102*unit)
	hud_rects.goal=Rect2(edge+198*unit,hud_y,w-2*edge-198*unit,102*unit)
	move_caption.position=hud_rects.moves.position+Vector2(6,6)*unit;move_caption.size=Vector2(hud_rects.moves.size.x-12*unit,26*unit)
	moves_label.position=hud_rects.moves.position+Vector2(6,30)*unit;moves_label.size=Vector2(hud_rects.moves.size.x-12*unit,66*unit)
	goal_icon.position=hud_rects.goal.position+Vector2(8,10)*unit;goal_icon.size=Vector2.ONE*82*unit
	goal_caption.position=hud_rects.goal.position+Vector2(92,7)*unit;goal_caption.size=Vector2(hud_rects.goal.size.x-100*unit,25*unit)
	goal_label.position=hud_rects.goal.position+Vector2(92,28)*unit;goal_label.size=Vector2(hud_rects.goal.size.x-100*unit,66*unit)
	lantern_bar.position=Vector2(edge+7*unit,hud_y+115*unit);lantern_bar.size=Vector2(w-2*edge-14*unit,11*unit)
	var boss_extra: float=65*unit if _goal_type=="boss" else 0.0
	secondary_goal_label.position=Vector2(edge+75*unit,hud_y+139*unit);secondary_goal_label.size=Vector2(w-2*edge-80*unit,43*unit)
	guardian.position=Vector2(edge,hud_y+133*unit);guardian.size=Vector2(64,64)*unit
	var board_top: float=hud_y+148*unit+boss_extra
	var footer_height: float=220*unit
	board.position=Vector2(edge-8*unit,board_top);board.size=Vector2(w-2*edge+16*unit,maxf(360*unit,size.y-board_top-footer_height))
	var lower: float=size.y-footer_height
	gnome.position=Vector2(edge-10*unit,lower-2*unit);gnome.size=Vector2(152,174)*unit
	helper.position=Vector2(edge+140*unit,lower+12*unit);helper.size=Vector2(w-2*edge-140*unit,36*unit)
	status_label.position=Vector2(edge+142*unit,lower+52*unit);status_label.size=Vector2(w-2*edge-142*unit,86*unit)
	hud_rects.helper=Rect2(Vector2(edge+136*unit,lower+9*unit),Vector2(w-2*edge-136*unit,138*unit))
	hint_button.position=Vector2(w*0.5-156*unit,size.y-75*unit);hint_button.size=Vector2(312,62)*unit
	move_caption.add_theme_font_size_override("font_size",int(20*unit));goal_caption.add_theme_font_size_override("font_size",int(20*unit));secondary_goal_label.add_theme_font_size_override("font_size",int(25*unit))
	moves_label.add_theme_font_size_override("font_size",int(48*unit));goal_label.add_theme_font_size_override("font_size",int(42*unit));status_label.add_theme_font_size_override("font_size",int(23*unit));helper.add_theme_font_size_override("font_size",int(24*unit));hint_button.add_theme_font_size_override("font_size",int(26*unit))
	queue_redraw()
func update_stats(moves: int, collected: int, goal: int) -> void:
	target=goal;shown_collected=mini(collected,goal);moves_label.text=str(moves);goal_label.text="%d / %d"%[shown_collected,target];lantern_bar.max_value=maxi(1,goal);lantern_bar.value=shown_collected
func fly(global_center: Vector2) -> void:
	trails.reduced_motion=reduced_motion
	trails.launch(global_center,goal_icon.global_position+goal_icon.size*0.5,1)
func on_goal_piece(global_center: Vector2) -> void:
	if _goal_type in ["collect","lantern","boss"]:fly(global_center)
func on_soil(global_center: Vector2) -> void:
	if _goal_type=="floor":fly(global_center)
func on_rune(global_center: Vector2) -> void:
	if _goal_type=="rune":fly(global_center)
	elif _goal_type=="boss":
		shown_runes=mini(_level.rune_cells.size()-remaining(_core.runes),shown_runes+1)
		secondary_goal_label.text="FREE RUNES   %d / %d"%[shown_runes,_level.rune_cells.size()]
func on_arrived(amount: int) -> void:
	# The core owns counts. Late flights may never inflate the displayed objective.
	shown_collected=mini(objective_done(),shown_collected+amount)
	goal_label.text="%d / %d"%[shown_collected,target];lantern_bar.value=shown_collected
	if reduced_motion:return
	if _pulse!=null and _pulse.is_valid():_pulse.kill()
	goal_icon.pivot_offset=goal_icon.size*0.5
	_pulse=create_tween();_pulse.tween_property(goal_icon,"scale",Vector2.ONE*1.13,0.07);_pulse.tween_property(goal_icon,"scale",Vector2.ONE,0.12)
func celebrate() -> void:
	gnome.texture=Art.gnome(true)
	helper.text="Passage open!"
	if reduced_motion:return
	gnome.pivot_offset=gnome.size*Vector2(0.5,1.0)
	var tw=create_tween();tw.tween_property(gnome,"scale",Vector2.ONE*1.06,0.16).set_trans(Tween.TRANS_SINE);tw.tween_property(gnome,"scale",Vector2.ONE,0.16)
func _draw() -> void:
	if size.x<=0:return
	draw_texture_rect(BACKGROUND,Rect2(Vector2.ZERO,size),false)
	if not hud_rects.has("moves"):return
	Art.panel().draw(get_canvas_item(),hud_rects.moves)
	Art.panel().draw(get_canvas_item(),hud_rects.goal)
	Art.panel(Color(0.65,0.77,0.72,0.9)).draw(get_canvas_item(),hud_rects.helper)
