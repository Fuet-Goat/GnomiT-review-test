extends Control
signal level_chosen(id: String)
signal back_requested
const Art=preload("res://scripts/story_art.gd")
var model
var buttons: Dictionary={}
var gnome: TextureRect
var header: Label
var slots: Label
var instruction: Label
var back: Button
var _unit:=1.0
var _ready_boss:=false
var _won:=false
var _clock:=0.0
func configure(progress) -> void:model=progress
func label(text: String, font_size: int) -> Label:
	var l=Label.new();l.text=text;l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font",Art.font());l.add_theme_font_size_override("font_size",font_size);l.add_theme_color_override("font_color",Color("fff1ce"));l.add_theme_color_override("font_outline_color",Color("30212b"));l.add_theme_constant_override("outline_size",3);add_child(l);return l
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);resized.connect(layout)
	_ready_boss=model.is_unlocked("guardian");_won=model.best_stars("guardian")>0
	header=label("CRYSTAL GUARDIAN",36)
	slots=label("%s RUNE     %s LANTERN     %s BOSS"%["◆" if model.best_stars("rune")>0 else "◇","◆" if model.best_stars("lantern")>0 else "◇","◆" if _won else "◇"],25)
	instruction=label("Passage open! Replay for more stars." if _won else ("Both lights are ready. Play the Guardian!" if _ready_boss else "Play both preparations in any order."),24)
	instruction.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	for id in ["rune","lantern","guardian"]:
		var b=TextureButton.new();b.ignore_texture_size=true;b.stretch_mode=TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		b.texture_normal=Art.material(3 if id=="guardian" else (0 if model.best_stars(id)>0 else 1));b.texture_hover=b.texture_normal;b.texture_pressed=b.texture_normal;b.texture_disabled=b.texture_normal
		b.disabled=not model.is_unlocked(id);b.pressed.connect(func() -> void:level_chosen.emit(id));add_child(b);buttons[id]=b
		var caption: Label=label("RUNE" if id=="rune" else ("LANTERN" if id=="lantern" else "BOSS"),31);remove_child(caption);b.add_child(caption);caption.name="Caption"
		var state: Label=label("★".repeat(model.best_stars(id)) if model.best_stars(id)>0 else ("READY · PLAY" if id=="guardian" and _ready_boss else ("LOCKED" if b.disabled else "PLAY")),24);remove_child(state);b.add_child(state);state.name="State"
		if id!="guardian":
			var icon=TextureRect.new();icon.texture=Art.material(5) if id=="rune" else Art.treasure(3);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;icon.name="Icon";b.add_child(icon)
		b.self_modulate=Color("a0a6b0") if b.disabled else Color.WHITE
	gnome=TextureRect.new();gnome.texture=Art.gnome(_ready_boss);gnome.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;gnome.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;gnome.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(gnome)
	back=Button.new();back.text="Back to Map";back.pressed.connect(func() -> void:back_requested.emit());back.add_theme_font_size_override("font_size",26);add_child(back)
	layout()
func layout() -> void:
	if header==null:return
	_unit=size.x/720.0
	header.position=Vector2(15,28)*_unit;header.size=Vector2(size.x-30*_unit,66*_unit);header.add_theme_font_size_override("font_size",int(36*_unit))
	slots.position=Vector2(12,117)*_unit;slots.size=Vector2(size.x-24*_unit,44*_unit);slots.add_theme_font_size_override("font_size",int(23*_unit))
	instruction.position=Vector2(35,177)*_unit;instruction.size=Vector2(size.x-70*_unit,74*_unit);instruction.add_theme_font_size_override("font_size",int(24*_unit))
	var positions: Dictionary={"rune":Vector2(size.x*0.25,size.y*0.35),"lantern":Vector2(size.x*0.75,size.y*0.35),"guardian":Vector2(size.x*0.5,size.y*0.72)}
	for id in positions:
		var b: TextureButton=buttons[id];var extent: float=(280 if id=="guardian" else 228)*_unit;b.size=Vector2.ONE*extent;b.position=positions[id]-b.size*0.5
		var caption: Label=b.get_node("Caption");caption.position=Vector2(0,extent*(0.56 if id=="guardian" else 0.46));caption.size=Vector2(extent,extent*0.18);caption.add_theme_font_size_override("font_size",int(31*_unit))
		var state: Label=b.get_node("State");state.position=Vector2(-10*_unit,extent*0.86);state.size=Vector2(extent+20*_unit,40*_unit);state.add_theme_font_size_override("font_size",int(24*_unit))
		if b.has_node("Icon"):
			var icon: TextureRect=b.get_node("Icon");icon.position=Vector2(extent*0.28,extent*0.14);icon.size=Vector2.ONE*extent*0.44
	gnome.position=Vector2(16*_unit,size.y*0.54);gnome.size=Vector2(160,210)*_unit
	back.position=Vector2(28*_unit,size.y-88*_unit);back.size=Vector2(size.x-56*_unit,64*_unit)
	queue_redraw()
func _process(delta: float) -> void:
	if not model.option("reduced_motion"):_clock+=delta;queue_redraw()
func _draw() -> void:
	if size.x<=0 or header==null:return
	var source=Rect2(0,Art.MAP.get_height()*0.48,Art.MAP.get_width(),Art.MAP.get_height()*0.52)
	draw_texture_rect_region(Art.MAP,Rect2(Vector2.ZERO,size),source)
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.03,0.02,0.12,0.24))
	Art.panel().draw(get_canvas_item(),Rect2(Vector2(18,25)*_unit,Vector2(size.x-36*_unit,78*_unit)))
	Art.panel(Color(0.66,0.72,0.88)).draw(get_canvas_item(),Rect2(Vector2(20,111)*_unit,Vector2(size.x-40*_unit,143*_unit)))
	for id in ["rune","lantern"]:
		var b: TextureButton=buttons[id];var a: Vector2=b.position+b.size*Vector2(0.5,0.92);var boss: TextureButton=buttons.guardian;var end: Vector2=boss.position+boss.size*Vector2(0.5,0.12)
		var points=PackedVector2Array([a,a.lerp(end,0.45)+Vector2(-30 if id=="rune" else 30,0)*_unit,end])
		draw_polyline(points,Color("463320"),18*_unit,true)
		draw_polyline(points,Color("ffe395") if model.best_stars(id)>0 else Color("9a8467"),6*_unit,true)
		if _ready_boss and not model.option("reduced_motion"):
			var t: float=fmod(_clock*0.65,1.0);draw_circle(a.lerp(end,t),8*_unit,Color("fff1b6"),true,-1,true)
