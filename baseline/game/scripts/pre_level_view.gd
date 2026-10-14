extends Control
signal closed
signal play_requested(id: String)
const Art=preload("res://scripts/story_art.gd")
const Levels=preload("res://scripts/levels.gd")
var level_id: String=""
var level: Dictionary={}
var unlocked:=false
var stars: int=0
var lock_reason: String=""
var reduced_motion:=false
var goal_icons: Array=[]
var goal_cards: Array=[]
var play_button: Button
var close_button: Button
var panel: Control
var guide: TextureRect
var level_caption: Label
var name_label: Label
var chapter_label: Label
var stars_label: Label
var moves_label: Label
var description_label: RichTextLabel
var lock_label: RichTextLabel
var _summary: Dictionary={}
var _committed:=false
var reward_available:=false
var reward_label: Label
var _unit:=1.0

class Card extends Control:
	var tint: Color=Color.WHITE
	func _draw() -> void:
		Art.panel(tint).draw(get_canvas_item(),Rect2(Vector2.ZERO,size))

func configure(data: Dictionary, earned: int, available: bool, reason: String, reduced: bool) -> void:
	level=data.duplicate(true);level_id=level.get("id","");stars=earned;unlocked=available;lock_reason=reason;reduced_motion=reduced
	var goals: Array=[]
	match level.get("goal","collect"):
		"floor":goals.append({"type":"floor","kind":-1,"count":level.get("target_cells",[]).size()})
		"rune":goals.append({"type":"rune","kind":-1,"count":level.get("rune_cells",[]).size()})
		"boss":
			goals.append({"type":"rune","kind":-1,"count":level.get("rune_cells",[]).size()})
			goals.append({"type":"lantern","kind":level.get("collect_kind",3),"count":level.get("collect_goal",0)})
		_:goals.append({"type":"lantern" if level.get("goal")=="lantern" else "collect","kind":level.get("collect_kind",3),"count":level.get("collect_goal",0)})
	_summary={"id":level_id,"name":level.get("name",""),"moves":level.get("moves",0),"stars":stars,"unlocked":unlocked,"goals":goals,"lock_reason":lock_reason}

func get_summary() -> Dictionary:return _summary.duplicate(true)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
	resized.connect(layout)
	var shade=ColorRect.new();shade.color=Color(0.02,0.03,0.08,0.63);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(shade)
	panel=Card.new();panel.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(panel)
	guide=TextureRect.new();guide.texture=Art.gnome();guide.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;guide.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;guide.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(guide)
	var ordinary: int=Levels.ordinary().find(level_id)
	level_caption=label("LEVEL %d"%(ordinary+1) if ordinary>=0 else ("BOSS" if level_id=="guardian" else "PREPARATION"),25)
	name_label=label(level.get("name",""),36);name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	chapter_label=label(level.get("chapter",""),21);chapter_label.add_theme_color_override("font_color",Color("ace5c0"))
	stars_label=label("★".repeat(stars)+"☆".repeat(3-stars),49);stars_label.add_theme_color_override("font_color",Color("ffdc75"))
	moves_label=label("%d MOVES"%level.get("moves",0),30)
	description_label=paragraph(level.get("description",""),25)
	reward_label=label("FIRST WIN · +10 LIGHT" if reward_available else "BEST STARS SAVED · REPLAY",23)
	reward_label.add_theme_color_override("font_color",Color("bce9a5"))
	lock_label=paragraph(lock_reason,24);lock_label.visible=not unlocked;lock_label.add_theme_color_override("default_color",Color("ffe0ac"))
	for data in _summary.goals:
		var card=Card.new();card.tint=Color("b9a589");card.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(card);goal_cards.append(card)
		var icon=TextureRect.new();icon.texture=Art.SOIL if data.type=="floor" else (Art.material(5) if data.type=="rune" else Art.treasure(data.kind))
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(icon);goal_icons.append(icon)
		var count=Label.new();count.name="Count";count.text=str(data.count);count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;count.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;count.mouse_filter=Control.MOUSE_FILTER_IGNORE
		count.add_theme_font_override("font",Art.font());count.add_theme_color_override("font_color",Color("fff6d8"));card.add_child(count)
		var caption=Label.new();caption.name="Caption";caption.text="SOIL" if data.type=="floor" else ("RUNES" if data.type=="rune" else ("LANTERN" if data.type=="lantern" else "COLLECT"))
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;caption.add_theme_font_override("font",Art.font());caption.add_theme_color_override("font_color",Color("fff1c4"));card.add_child(caption)
	play_button=Button.new();play_button.text="PLAY" if unlocked else "LOCKED";play_button.disabled=not unlocked;play_button.pressed.connect(request_play)
	play_button.add_theme_font_override("font",Art.font());play_button.add_theme_color_override("font_color",Color("fff9d7"));play_button.add_theme_color_override("font_outline_color",Color("284c23"));play_button.add_theme_constant_override("outline_size",3)
	for state in ["normal","hover","pressed","disabled"]:
		var skin=StyleBoxFlat.new();skin.bg_color=Color("479938") if state=="normal" else (Color("62b447") if state=="hover" else (Color("32772c") if state=="pressed" else Color("5d626a")))
		skin.border_color=Color("ffd472") if state!="disabled" else Color("b7a786");skin.set_border_width_all(4);skin.set_corner_radius_all(30);skin.shadow_color=Color(0.1,0.04,0.01,0.6);skin.shadow_size=5;skin.shadow_offset=Vector2(0,5);play_button.add_theme_stylebox_override(state,skin)
	panel.add_child(play_button)
	close_button=Button.new();close_button.text="×";close_button.pressed.connect(func() -> void:closed.emit());close_button.add_theme_stylebox_override("normal",Art.round_button());close_button.add_theme_stylebox_override("hover",Art.round_button());panel.add_child(close_button)
	layout()
	if not reduced_motion:
		panel.scale=Vector2.ONE*0.94;panel.modulate.a=0.0
		var tween=create_tween().set_parallel(true);tween.tween_property(panel,"scale",Vector2.ONE,0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT);tween.tween_property(panel,"modulate:a",1.0,0.14)
	if unlocked:play_button.grab_focus()
	else:close_button.grab_focus()

func label(text: String, font_size: int) -> Label:
	var node=Label.new();node.text=text;node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;node.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_override("font",Art.font());node.add_theme_font_size_override("font_size",font_size);node.add_theme_color_override("font_color",Color("fff4d1"));node.add_theme_color_override("font_outline_color",Color("41291b"));node.add_theme_constant_override("outline_size",2);panel.add_child(node);return node

func paragraph(text: String, font_size: int) -> RichTextLabel:
	var node=RichTextLabel.new();node.bbcode_enabled=true;node.text="[center]%s[/center]"%text;node.scroll_active=false;node.fit_content=false;node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_override("normal_font",Art.font());node.add_theme_font_size_override("normal_font_size",font_size);node.add_theme_color_override("default_color",Color("fff4d1"));node.add_theme_color_override("font_outline_color",Color("41291b"));node.add_theme_constant_override("outline_size",2);panel.add_child(node);return node

func layout() -> void:
	if not is_instance_valid(panel):return
	var width: float=minf(620.0,maxf(260.0,size.x-52.0))
	_unit=width/620.0
	var height: float=(812.0 if not unlocked else 700.0)*_unit
	if height>size.y-32.0:
		_unit=(size.y-32.0)/(812.0 if not unlocked else 700.0);width=620.0*_unit;height=size.y-32.0
	panel.size=Vector2(width,height);panel.position=(size-panel.size)*0.5;panel.pivot_offset=panel.size*0.5;panel.queue_redraw()
	guide.position=Vector2(23,18)*_unit;guide.size=Vector2(170,177)*_unit
	level_caption.position=Vector2(186,26)*_unit;level_caption.size=Vector2(365,43)*_unit;level_caption.add_theme_font_size_override("font_size",int(25*_unit))
	name_label.position=Vector2(174,72)*_unit;name_label.size=Vector2(386,97)*_unit;name_label.add_theme_font_size_override("font_size",int(36*_unit))
	chapter_label.position=Vector2(183,169)*_unit;chapter_label.size=Vector2(368,33)*_unit;chapter_label.add_theme_font_size_override("font_size",int(21*_unit))
	stars_label.position=Vector2(50,211)*_unit;stars_label.size=Vector2(520,65)*_unit;stars_label.add_theme_font_size_override("font_size",int(49*_unit))
	moves_label.position=Vector2(50,278)*_unit;moves_label.size=Vector2(520,47)*_unit;moves_label.add_theme_font_size_override("font_size",int(30*_unit))
	var count: int=goal_cards.size()
	var card_width: float=(520.0-16.0*(count-1))/maxi(1,count)
	for i in range(count):
		var card: Control=goal_cards[i];card.position=Vector2(50.0+i*(card_width+16.0),338)*_unit;card.size=Vector2(card_width,124)*_unit;card.queue_redraw()
		var icon: TextureRect=goal_icons[i];icon.position=Vector2(card_width*0.5-80,12)*_unit;icon.size=Vector2(88,88)*_unit
		var number: Label=card.get_node("Count");number.position=Vector2(card_width*0.5+9,15)*_unit;number.size=Vector2(66,73)*_unit;number.add_theme_font_size_override("font_size",int(41*_unit))
		var caption: Label=card.get_node("Caption");caption.position=Vector2(5,90)*_unit;caption.size=Vector2(card_width-10,28)*_unit;caption.add_theme_font_size_override("font_size",int(22*_unit))
	description_label.position=Vector2(42,476)*_unit;description_label.size=Vector2(536,62)*_unit;description_label.add_theme_font_size_override("normal_font_size",int(25*_unit))
	reward_label.position=Vector2(42,542)*_unit;reward_label.size=Vector2(536,32)*_unit;reward_label.add_theme_font_size_override("font_size",int(23*_unit))
	lock_label.position=Vector2(44,574)*_unit;lock_label.size=Vector2(532,100)*_unit;lock_label.add_theme_font_size_override("normal_font_size",int(24*_unit))
	play_button.position=Vector2(68,690 if not unlocked else 586)*_unit;play_button.size=Vector2(484,82)*_unit;play_button.add_theme_font_size_override("font_size",int(39*_unit))
	close_button.position=Vector2(536,12)*_unit;close_button.size=Vector2(74,74)*_unit;close_button.add_theme_font_size_override("font_size",int(36*_unit))

func request_play() -> void:
	if not unlocked or _committed:return
	_committed=true;play_button.disabled=true;play_requested.emit(level_id)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_TAB:
		var focused: Control=get_viewport().gui_get_focus_owner()
		if unlocked and not _committed and focused==close_button:play_button.grab_focus()
		else:close_button.grab_focus()
		get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if _committed:return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and not panel.get_rect().has_point(event.position):
		accept_event();closed.emit()
	elif event is InputEventScreenTouch and not event.pressed and not panel.get_rect().has_point(event.position):
		accept_event();closed.emit()
