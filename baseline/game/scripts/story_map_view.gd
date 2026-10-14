extends Control
signal level_chosen(id: String)
signal boss_requested
signal settings_requested
const Art=preload("res://scripts/story_art.gd")
const Levels=preload("res://scripts/levels.gd")
const WORLD_ZOOM:=1.65
var buttons: Dictionary={}
var points: Dictionary={}
var model
var ordinary_ids: Array=[]
var focus_id: String="entry"
var from_id: String=""
var reduced_motion:=false
var interaction_enabled:=true
var restored_scroll: float=-1.0
var restored_offset:=Vector2(-1,-1)
var scroll: ScrollContainer
var canvas: Control
var hud: Control
var gnome: TextureRect
var side_gnomes: Array[TextureRect]=[]
var title: RichTextLabel
var stats: Label
var warning_label: Label
var depth_label: Label
var exploration_hint: Label
var menu_button: Button
var continue_button: Button
var current_button: Button
var skip_button: Button
var _transition: Tween
var _walking:=false
var _walk_elapsed:=0.0
var _walk_curve: Curve2D
var _last_walk_frame: int=-1
var _sway_clock:=0.0
var _resize_focus_pending:=false
var _unit:=1.0
var _target_gnome:=Vector2.ZERO
var _pointer_active:=false
var _touch_index: int=-1
var _press_position:=Vector2.ZERO
var _press_offset:=Vector2.ZERO
var _last_pointer_position:=Vector2.ZERO
var _last_pointer_time: int=0
var _last_movement_time: int=0
var _drag_velocity:=Vector2.ZERO
var _inertia_velocity:=Vector2.ZERO
var _pressed_node: String=""
var _panning:=false
var _maximum_displacement_px:=0.0

class Landscape extends Control:
	var art: Texture2D
	func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		if art!=null:draw_texture_rect(art,Rect2(Vector2.ZERO,size),false)

class HUDSurface extends Control:
	var chip_rects: Array=[]
	var warning_rect:=Rect2()
	func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var skin=StyleBoxFlat.new();skin.bg_color=Color(0.08,0.16,0.18,0.8);skin.border_color=Color(0.92,0.73,0.36,0.6);skin.set_border_width_all(2);skin.set_corner_radius_all(18)
		for rect in chip_rects:skin.draw(get_canvas_item(),rect)
		if warning_rect.size.x>0:skin.bg_color=Color(0.25,0.12,0.08,0.93);skin.draw(get_canvas_item(),warning_rect)

class LockMark extends Control:
	func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var center=size*0.5
		draw_arc(center+Vector2(0,-6),11,PI,TAU,16,Color("4e3019"),8,true)
		draw_arc(center+Vector2(0,-6),11,PI,TAU,16,Color("ffda6a"),4,true)
		var skin=StyleBoxFlat.new();skin.bg_color=Color("efbd4b");skin.border_color=Color("68401f");skin.set_border_width_all(2);skin.set_corner_radius_all(6)
		skin.draw(get_canvas_item(),Rect2(center+Vector2(-16,-5),Vector2(32,27)))
		draw_circle(center+Vector2(0,5),3.5,Color("56391f"),true,-1,true)
		draw_line(center+Vector2(0,6),center+Vector2(0,12),Color("56391f"),3,true)

func configure(progress, path: Array, current: String, reduced: bool, previous: String="", saved_scroll: float=-1.0, saved_offset: Vector2=Vector2(-1,-1)) -> void:
	model=progress;ordinary_ids=path.duplicate();focus_id=current;reduced_motion=reduced;from_id=previous;restored_scroll=saved_scroll;restored_offset=saved_offset
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(layout)
	scroll=ScrollContainer.new();add_child(scroll)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.follow_focus=false
	canvas=Landscape.new();canvas.art=Art.MAP;scroll.add_child(canvas)
	hud=HUDSurface.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(hud)
	title=RichTextLabel.new();title.bbcode_enabled=true;title.scroll_active=false;title.mouse_filter=Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_override("normal_font",Art.font());title.add_theme_color_override("font_outline_color",Color("4a281a"));title.add_theme_constant_override("outline_size",4)
	title.text="[center][color=#ff8099]G[/color][color=#ffbc62]n[/color][color=#ffe978]o[/color][color=#a8ef8a]m[/color][color=#77dcff]i[/color][color=#d3a7ff]T[/color][/center]";add_child(title)
	stats=label("★  %d / 30     ✦  %d Light"%[model.total_stars(),model.data.light],25)
	depth_label=label("The Surface",21)
	exploration_hint=label("Drag to explore · Tap a level",20)
	warning_label=label(model.last_error,24);warning_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;warning_label.visible=not model.last_error.is_empty();warning_label.add_theme_color_override("font_color",Color("ffe7b3"))
	menu_button=action("☰",func() -> void:if interaction_enabled:cancel_transition();settings_requested.emit())
	current_button=action("Current Level",focus_current)
	# Kept as an API alias; the View Level footer is removed.
	continue_button=current_button
	skip_button=action("Skip",finish_transition);skip_button.hide()
	var ids: Array=ordinary_ids.duplicate();ids.append("boss")
	for i in range(ids.size()):
		var id: String=ids[i]
		var real_id: String="guardian" if id=="boss" else id
		var stars: int=model.best_stars(real_id)
		var unlocked: bool=model.is_unlocked(id) if id!="boss" else model.best_stars(ordinary_ids.back())>0
		var b=TextureButton.new();b.ignore_texture_size=true;b.stretch_mode=TextureButton.STRETCH_KEEP_ASPECT_CENTERED;b.focus_mode=Control.FOCUS_ALL
		var material: int=0 if stars>0 else (1 if unlocked and id==focus_id else 2)
		b.texture_normal=Art.material(3 if id=="boss" else material)
		b.texture_hover=b.texture_normal;b.texture_pressed=b.texture_normal;b.texture_disabled=Art.material(3 if id=="boss" else 2)
		# Pointer gestures are captured by the map before GUI buttons receive them.
		b.disabled=not unlocked
		b.pressed.connect(func() -> void:_choose_node(id))
		b.mouse_entered.connect(func() -> void:if not b.disabled:b.self_modulate=Color(1.08,1.08,1.03))
		b.mouse_exited.connect(func() -> void:b.self_modulate=Color.WHITE)
		canvas.add_child(b);buttons[id]=b
		var number=label("BOSS" if id=="boss" else str(i+1),25 if id=="boss" else 49);number.name="LiveNumber";remove_child(number);b.add_child(number)
		if id=="boss":number.add_theme_color_override("font_color",Color("ffe2a6"))
		if stars>0:
			var earned=label("★".repeat(stars),32);earned.name="EarnedStars";remove_child(earned);b.add_child(earned)
		if not unlocked:
			var lock=LockMark.new();lock.name="Lock";b.add_child(lock)
		if id=="boss" and stars==0:
			var slots=label("%s  %s  %s"%["◆" if model.best_stars("rune")>0 else "◇","◆" if model.best_stars("lantern")>0 else "◇","◆" if model.best_stars("guardian")>0 else "◇"],29)
			slots.name="Preparations";remove_child(slots);b.add_child(slots)
	gnome=TextureRect.new();gnome.texture=Art.gnome();gnome.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;gnome.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;gnome.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(gnome)
	for i in range(2):
		var npc=TextureRect.new();npc.texture=Art.side_gnome(i);npc.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;npc.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;npc.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(npc);side_gnomes.append(npc)
	layout();call_deferred("_initial_position")

func label(text: String, font_size: int) -> Label:
	var node=Label.new();node.text=text;node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;node.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	node.add_theme_font_override("font",Art.font());node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",Color("fff5d8"));node.add_theme_color_override("font_outline_color",Color("392513"));node.add_theme_constant_override("outline_size",3)
	node.autowrap_mode=TextServer.AUTOWRAP_OFF;node.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(node);return node
func action(text: String, callable: Callable) -> Button:
	var b=Button.new();b.text=text;b.pressed.connect(callable);b.add_theme_font_override("font",Art.font())
	for state in ["normal","hover","pressed","disabled"]:
		var skin=StyleBoxFlat.new();skin.bg_color=Color("273e3b") if state=="normal" else (Color("3b5b48") if state=="hover" else (Color("20312b") if state=="pressed" else Color("38413e")))
		skin.border_color=Color("ecc66a");skin.set_border_width_all(2);skin.set_corner_radius_all(30);skin.content_margin_left=12;skin.content_margin_right=12;skin.content_margin_top=8;skin.content_margin_bottom=8;skin.shadow_color=Color(0,0,0,0.35);skin.shadow_size=3
		b.add_theme_stylebox_override(state,skin)
	b.add_theme_font_size_override("font_size",24);add_child(b);return b
func layout() -> void:
	if canvas==null:return
	_unit=clampf(minf(size.x/720.0,size.y/1600.0),0.75,1.2)
	var previous_offset: Vector2=current_offset()
	scroll.position=Vector2.ZERO;scroll.size=size
	var map_ratio: float=float(Art.MAP.get_height())/maxf(1.0,float(Art.MAP.get_width()))
	var world_width: float=maxf(size.x*WORLD_ZOOM,size.y/map_ratio)
	canvas.custom_minimum_size=Vector2(world_width,world_width*map_ratio);canvas.size=canvas.custom_minimum_size
	var physical_scale: float=maxf(0.01,get_viewport().get_final_transform().get_scale().y)
	var touch_extent: float=maxf(80.0*_unit,44.0/physical_scale)
	title.position=Vector2(18,12)*_unit;title.size=Vector2(294,72)*_unit;title.add_theme_font_size_override("normal_font_size",int(44*_unit))
	stats.position=Vector2(20,84)*_unit;stats.size=Vector2(314,48)*_unit;stats.add_theme_font_size_override("font_size",int(24*_unit))
	depth_label.position=Vector2(22,140)*_unit;depth_label.size=Vector2(308,35)*_unit;depth_label.add_theme_font_size_override("font_size",int(21*_unit))
	warning_label.position=Vector2(22,188)*_unit;warning_label.size=Vector2(minf(size.x-44*_unit,550*_unit),112*_unit);warning_label.add_theme_font_size_override("font_size",int(24*_unit))
	menu_button.position=Vector2(size.x-touch_extent-20*_unit,16*_unit);menu_button.size=Vector2.ONE*touch_extent;menu_button.add_theme_font_size_override("font_size",int(31*_unit))
	current_button.position=Vector2(size.x-248*_unit,size.y-touch_extent-20*_unit);current_button.size=Vector2(228*_unit,touch_extent);current_button.add_theme_font_size_override("font_size",int(24*_unit))
	skip_button.position=Vector2(size.x-148*_unit,menu_button.position.y+touch_extent+15*_unit);skip_button.size=Vector2(128*_unit,touch_extent);skip_button.add_theme_font_size_override("font_size",int(24*_unit))
	exploration_hint.position=Vector2(20*_unit,size.y-56*_unit);exploration_hint.size=Vector2(410,36)*_unit;exploration_hint.add_theme_font_size_override("font_size",int(20*_unit))
	hud.chip_rects=[Rect2(stats.position-Vector2(4,1)*_unit,stats.size+Vector2(8,2)*_unit),Rect2(depth_label.position-Vector2(4,1)*_unit,depth_label.size+Vector2(8,2)*_unit)]
	hud.warning_rect=Rect2(warning_label.position,warning_label.size) if warning_label.visible else Rect2();hud.queue_redraw()
	var ids: Array=ordinary_ids.duplicate();ids.append("boss")
	for i in range(ids.size()):
		var id: String=ids[i];var b: TextureButton=buttons[id]
		var point: Vector2=Art.MAP_POINTS[id]*canvas.size
		var extent: float=(160 if id=="boss" else (145 if id==focus_id else 125))*_unit
		points[id]=point;b.size=Vector2.ONE*extent;b.position=point-b.size*0.5
		var number: Label=b.get_node("LiveNumber");number.position=Vector2(0,extent*0.49 if id=="boss" else extent*0.21);number.size=Vector2(extent,extent*0.46);number.add_theme_font_size_override("font_size",int((26 if id=="boss" else 45)*_unit))
		if b.has_node("EarnedStars"):
			var stars: Label=b.get_node("EarnedStars");stars.position=Vector2(-10*_unit,extent*0.76);stars.size=Vector2(extent+20*_unit,40*_unit);stars.add_theme_font_size_override("font_size",int(31*_unit))
		if b.has_node("Lock"):
			var lock: Control=b.get_node("Lock");lock.size=Vector2(38,46);lock.scale=Vector2.ONE*_unit;lock.position=Vector2(extent*0.72,extent*0.65)
		if b.has_node("Preparations"):
			var slots: Label=b.get_node("Preparations");slots.position=Vector2(-20*_unit,extent*0.91);slots.size=Vector2(extent+40*_unit,40*_unit)
	gnome.size=Vector2(125,125)*_unit
	_target_gnome=_hero_position(focus_id)
	gnome.position=_target_gnome
	for i in range(side_gnomes.size()):
		var npc: TextureRect=side_gnomes[i];npc.size=Vector2(102,112)*_unit;npc.pivot_offset=Vector2(npc.size.x*0.5,npc.size.y*0.95)
		var anchor: Vector2=Vector2(0.29,0.345) if i==0 else Vector2(0.76,0.69)
		npc.position=anchor*canvas.size-Vector2(npc.size.x*0.5,npc.size.y)
	if _walking or _resize_focus_pending:
		finish_transition()
		if not _resize_focus_pending:
			_resize_focus_pending=true;call_deferred("_settle_resize_focus")
	else:_apply_offset(previous_offset)
	update_depth();canvas.queue_redraw()

func _settle_resize_focus() -> void:
	# ScrollContainer re-sorts its child after layout. Until then its bars still
	# clamp against the old canvas dimensions, so reapply the destination afterward.
	await get_tree().process_frame
	if not is_instance_valid(canvas):return
	_apply_offset(_focus_offset(focus_id));_resize_focus_pending=false;update_depth()

func _initial_position() -> void:
	await get_tree().process_frame
	if not is_instance_valid(canvas):return
	if restored_offset.x>=0.0 and from_id.is_empty():restore_offset(restored_offset)
	elif restored_scroll>=0.0 and from_id.is_empty():restore_offset(Vector2(_balanced_x(),restored_scroll))
	elif from_id.is_empty() and focus_id=="entry" and points.entry.y<size.y-140*_unit:restore_offset(Vector2(_balanced_x(),0))
	else:focus_current()
func _balanced_x() -> float:return maxf(0.0,(canvas.size.x-scroll.size.x)*0.5)
func _hero_position(id: String) -> Vector2:
	var point: Vector2=points.get(id,points.get("boss",Vector2.ZERO))
	var radius: float=buttons[id].size.x*0.5 if buttons.has(id) else 72*_unit
	var left: bool=point.x>canvas.size.x*0.5
	return Vector2(point.x-radius-gnome.size.x-16*_unit if left else point.x+radius+16*_unit,point.y-gnome.size.y*0.5)
func _path_x(y: float) -> float:
	# X follows the winding path gently; the player controls only depth.
	var ids: Array=ordinary_ids.duplicate();ids.append("boss")
	var depth: float=y+scroll.size.y*0.53
	var path_x: float=points[ids.front()].x
	for i in range(ids.size()-1):
		var a: Vector2=points[ids[i]];var b: Vector2=points[ids[i+1]]
		if depth>=b.y:path_x=b.x
		elif depth>=a.y:
			var t: float=clampf((depth-a.y)/(b.y-a.y),0,1);t=t*t*(3-2*t);path_x=lerpf(a.x,b.x,t);break
		else:break
	return clampf(_balanced_x()+(path_x-canvas.size.x*0.51)*0.25,0,maxf(0,canvas.size.x-scroll.size.x))
func current_offset() -> Vector2:return Vector2(scroll.scroll_horizontal,scroll.scroll_vertical) if is_instance_valid(scroll) else Vector2.ZERO
func get_world_offset() -> Vector2:return current_offset()
func current_scroll() -> int:return int(current_offset().y)
func restore_world_offset(value: Vector2) -> void:restore_offset(value)
func restore_scroll(value: float) -> void:restore_offset(Vector2(current_offset().x,value))
func restore_offset(value: Vector2) -> void:
	stop_inertia();_apply_offset(value);update_depth()
func _apply_offset(value: Vector2) -> void:
	if is_instance_valid(scroll) and is_instance_valid(canvas):
		var y: float=clampf(value.y,0.0,maxf(0.0,canvas.size.y-scroll.size.y))
		scroll.scroll_horizontal=int(_path_x(y))
		scroll.scroll_vertical=int(y)
func _focus_offset(id: String) -> Vector2:return Vector2(_balanced_x(),clampf(float(points.get(id,Vector2.ZERO).y)-scroll.size.y*0.55,0,canvas.size.y-scroll.size.y))
func focus_current() -> void:
	if not interaction_enabled or not is_instance_valid(canvas):return
	stop_inertia()
	var target: Vector2=_focus_offset(focus_id)
	if from_id!="" and points.has(from_id) and from_id!=focus_id and not reduced_motion:
		_apply_offset(_focus_offset(from_id));gnome.position=_hero_position(from_id)
		var foot: Vector2=Vector2(gnome.size.x*0.5,gnome.size.y*0.94)
		var start: Vector2=gnome.position+foot;var end: Vector2=_target_gnome+foot
		var middle: Vector2=(start+end)*0.5
		middle.x=(points[from_id].x+points[focus_id].x)*0.5+canvas.size.x*0.045*(1 if points[from_id].x>points[focus_id].x else -1)
		var tangent: Vector2=Vector2(0,(end.y-start.y)*0.22)
		_walk_curve=Curve2D.new();_walk_curve.bake_interval=3
		_walk_curve.add_point(start,Vector2.ZERO,tangent)
		_walk_curve.add_point(middle,-tangent,tangent)
		_walk_curve.add_point(end,-tangent,Vector2.ZERO)
		_walking=true;_walk_elapsed=0;_last_walk_frame=-1;skip_button.show()
	else:cancel_transition();restore_offset(target)
	from_id=""
func cancel_transition(snap_camera: bool=true) -> void:
	stop_inertia()
	var was_walking: bool=_walking;_walking=false
	if _transition!=null and _transition.is_running():_transition.kill()
	if is_instance_valid(gnome):gnome.position=_target_gnome;gnome.texture=Art.gnome();gnome.flip_h=false
	if is_instance_valid(skip_button):skip_button.hide()
	if was_walking and snap_camera:_apply_offset(_focus_offset(focus_id))
	if reduced_motion:
		for npc in side_gnomes:npc.rotation=0
	from_id=""
func finish_transition() -> void:cancel_transition();restore_offset(_focus_offset(focus_id))
func update_depth() -> void:
	if not is_instance_valid(depth_label) or not is_instance_valid(canvas) or canvas.size.y<=0:return
	var camera_depth: float=(current_offset().y+scroll.size.y*0.5)/canvas.size.y
	var region: String="The Surface" if camera_depth<0.34 else ("The Roots" if camera_depth<0.51 else ("The Stone Layers" if camera_depth<0.66 else "The Crystal Caves"))
	if depth_label.text!=region:depth_label.text=region
func play_current() -> void:focus_current()
func set_interaction_enabled(enabled: bool) -> void:
	interaction_enabled=enabled;stop_inertia()
	_pointer_active=false;_touch_index=-1
	for control in [menu_button,current_button,skip_button]:
		if is_instance_valid(control):control.disabled=not enabled
	for control in buttons.values():control.focus_mode=Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
func _choose_node(id: String) -> void:
	if not interaction_enabled:return
	if not buttons.has(id) or buttons[id].disabled:return
	cancel_transition()
	if id=="boss" and model.best_stars(ordinary_ids.back())>0:boss_requested.emit()
	elif id!="boss" and model.is_unlocked(id):level_chosen.emit(id)
func _node_at(position: Vector2) -> String:
	for id in buttons:
		if buttons[id].get_global_rect().has_point(position):return id
	return ""
func _overlaid_control_at(position: Vector2) -> bool:
	for control in [menu_button,current_button,skip_button]:
		if is_instance_valid(control) and control.visible and control.get_global_rect().has_point(position):return true
	return false
func _begin_pointer(position: Vector2, touch_index: int=-1) -> void:
	if not interaction_enabled or _pointer_active:return
	var pressed_node: String=_node_at(position)
	# Keep the world under the finger unchanged when interrupting a walk.
	cancel_transition(false)
	_pointer_active=true;_touch_index=touch_index;_press_position=position;_last_pointer_position=position;_last_pointer_time=Time.get_ticks_usec();_last_movement_time=_last_pointer_time;_press_offset=current_offset();_pressed_node=pressed_node;_panning=false;_maximum_displacement_px=0;_drag_velocity=Vector2.ZERO
func _move_pointer(position: Vector2) -> void:
	if not _pointer_active:return
	var physical: Vector2=get_viewport().get_final_transform().basis_xform(position-_press_position)
	_maximum_displacement_px=maxf(_maximum_displacement_px,physical.length())
	if _maximum_displacement_px>=12.0-0.0001:_panning=true
	if _panning:
		_apply_offset(Vector2(0,_press_offset.y+_press_position.y-position.y));update_depth()
		var elapsed: float=clampf(float(Time.get_ticks_usec()-_last_pointer_time)/1000000.0,1.0/240.0,0.075)
		var delta: float=_last_pointer_position.y-position.y
		if absf(delta)>0.01:
			var speed: float=clampf(delta/elapsed,-1400*_unit,1400*_unit);_drag_velocity.y=lerpf(_drag_velocity.y,speed,0.45)
			_last_movement_time=Time.get_ticks_usec()
	_last_pointer_position=position;_last_pointer_time=Time.get_ticks_usec()
func _end_pointer(position: Vector2) -> void:
	if not _pointer_active:return
	_move_pointer(position)
	var choose: String=_pressed_node if not _panning and _node_at(position)==_pressed_node else ""
	var coast: bool=_panning and not reduced_motion and interaction_enabled and Time.get_ticks_usec()-_last_movement_time<140000
	_pointer_active=false;_touch_index=-1;_pressed_node="";_panning=false
	if coast and _drag_velocity.length()>45*_unit:_inertia_velocity=_drag_velocity
	if not choose.is_empty() and interaction_enabled:_choose_node(choose)
func stop_inertia() -> void:_inertia_velocity=Vector2.ZERO
func _process(delta: float) -> void:
	_sway_clock+=delta
	for i in range(side_gnomes.size()):side_gnomes[i].rotation=0 if reduced_motion else sin(_sway_clock*1.8+i*2.2)*0.023
	if _walking:
		if reduced_motion:finish_transition()
		else:
			_walk_elapsed+=delta
			var t: float=clampf(_walk_elapsed/0.8,0,1)
			var length: float=_walk_curve.get_baked_length()
			var foot: Vector2=_walk_curve.sample_baked(t*length,true)
			var ahead: Vector2=_walk_curve.sample_baked(minf(t*length+4,length),true)
			gnome.position=foot-Vector2(gnome.size.x*0.5,gnome.size.y*0.94)
			if absf(ahead.x-foot.x)>0.1:gnome.flip_h=ahead.x<foot.x
			var frame: int=int(_walk_elapsed*12)%4
			if frame!=_last_walk_frame:gnome.texture=Art.hero_walk_frame(frame);_last_walk_frame=frame
			_apply_offset(Vector2(0,foot.y-scroll.size.y*0.55))
			if t>=1:finish_transition()
	if not interaction_enabled or reduced_motion or _pointer_active:stop_inertia()
	elif _inertia_velocity.length_squared()>1.0:
		var before: Vector2=current_offset()
		var desired: Vector2=before+_inertia_velocity*minf(delta,0.04)
		_apply_offset(desired)
		var after: Vector2=current_offset()
		if (desired.y<0.0 or desired.y>canvas.size.y-scroll.size.y) and is_equal_approx(after.y,before.y):_inertia_velocity.y=0.0
		_inertia_velocity=_inertia_velocity.move_toward(Vector2.ZERO,1800*_unit*delta)
	update_depth()
func _input(event: InputEvent) -> void:
	if not interaction_enabled or not is_instance_valid(scroll):
		_pointer_active=false;_touch_index=-1;stop_inertia();return
	if event is InputEventMouseButton:
		# Godot emits mouse events as well as native touch events. Only the native
		# finger owns map gestures, including cancellation; overlay GUI keeps emulation.
		if event.device==-1:
			if not _overlaid_control_at(event.position):get_viewport().set_input_as_handled()
			return
		if event.button_index in [MOUSE_BUTTON_WHEEL_LEFT,MOUSE_BUTTON_WHEEL_RIGHT] and scroll.get_global_rect().has_point(event.position) and not _overlaid_control_at(event.position):
			get_viewport().set_input_as_handled();return
		if event.pressed:stop_inertia()
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and event.pressed and scroll.get_global_rect().has_point(event.position) and not _overlaid_control_at(event.position):
			cancel_transition()
			var offset: Vector2=current_offset();var step: float=112.0*_unit*event.factor
			offset.y+=step if event.button_index==MOUSE_BUTTON_WHEEL_DOWN else -step
			restore_offset(offset);get_viewport().set_input_as_handled()
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed and scroll.get_global_rect().has_point(event.position) and not _overlaid_control_at(event.position):_begin_pointer(event.position);get_viewport().set_input_as_handled()
			elif not event.pressed and _pointer_active and _touch_index<0:_end_pointer(event.position);get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if event.device==-1:
			if not _overlaid_control_at(event.position):get_viewport().set_input_as_handled()
		elif _pointer_active and _touch_index<0:_move_pointer(event.position);get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.pressed:stop_inertia()
		if event.canceled and _pointer_active and event.index==_touch_index:
			_pointer_active=false;_touch_index=-1;_pressed_node="";_panning=false;_drag_velocity=Vector2.ZERO;stop_inertia();get_viewport().set_input_as_handled()
		elif event.pressed and scroll.get_global_rect().has_point(event.position) and not _overlaid_control_at(event.position):_begin_pointer(event.position,event.index);get_viewport().set_input_as_handled()
		elif not event.pressed and _pointer_active and event.index==_touch_index:_end_pointer(event.position);get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and _pointer_active and event.index==_touch_index:_move_pointer(event.position);get_viewport().set_input_as_handled()
	elif event is InputEventPanGesture and scroll.get_global_rect().has_point(event.position) and not _overlaid_control_at(event.position):
		cancel_transition();restore_scroll(current_scroll()+event.delta.y*30.0*_unit);get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:_pointer_active=false;_touch_index=-1;stop_inertia()
