extends "res://scripts/story_map_view.gd"
signal arrived_at_level(id: String)
const Route=preload("res://scripts/slice_route.gd")
const WALK_ATLAS=preload("res://assets/storybook/gnome_slice_walk_v1.png")
var session_state: Dictionary={}
var route=Route.new()
var avatar_s:=0.0
var target_s:=0.0
var selected_level: String=""
var journey_active:=false
var journey_paused:=false
var facing_back:=false
var facing_left:=false
var walk_distance:=0.0
var slice_enabled:=false
var slice_ready:=false
var shadow: ContactShadow
var arrival_button: Button
var _press_was_walking:=false
var _last_sprite_frame: int=-1

class ContactShadow extends Control:
 func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
 func _draw() -> void:
  for i in range(5):
   var a: float=0.035+float(i)*0.017
   draw_set_transform(size*0.5,0,Vector2(1,0.26))
   draw_circle(Vector2.ZERO,size.x*(0.5-float(i)*0.075),Color(0.14,0.07,0.025,a),true,-1,true)

func _ready() -> void:
 slice_enabled=focus_id in ["entry","hollow"] or session_state.has("avatar_s")
 if slice_enabled:
  avatar_s=clampf(float(session_state.get("avatar_s",route.dock_s("hollow") if model.best_stars("entry")>0 else 0.0)),0,accessible_s())
  target_s=clampf(float(session_state.get("target_s",avatar_s)),0,accessible_s())
  selected_level=str(session_state.get("selected_level",""))
  journey_paused=bool(session_state.get("paused",false)) and absf(target_s-avatar_s)>0.01
  facing_left=bool(session_state.get("facing_left",false))
  facing_back=bool(session_state.get("facing_back",false))
 super._ready()
 if not slice_enabled:return
 shadow=ContactShadow.new();canvas.add_child(shadow);canvas.move_child(shadow,gnome.get_index())
 arrival_button=action("Play",_open_arrived_level)
 current_button.text="Find Gnome"
 skip_button.text="Continue"
 exploration_hint.text="Drag to explore · Tap the wooden path"
 slice_ready=true
 layout()
 _sync_controls()

func accessible_s() -> float:
 return route.end_s() if model.best_stars("entry")>0 else route.dock_s("entry")
func get_session_state() -> Dictionary:
 if not slice_enabled:return {}
 return {"avatar_s":avatar_s,"target_s":target_s,"selected_level":selected_level,
  "paused":journey_active or journey_paused,"facing_left":facing_left,"facing_back":facing_back}
func layout() -> void:
 super.layout()
 if not slice_enabled or not slice_ready:return
 gnome.size=Vector2(204,204)*_unit
 gnome.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 gnome.z_index=0
 canvas.move_child(shadow,0);canvas.move_child(gnome,1)
 for id in ["entry","hollow"]:
  buttons[id].z_index=0
 var badge_locations={"entry":Vector2(550,615),"hollow":Vector2(275,812)}
 for id in badge_locations:
  points[id]=_source_to_world(badge_locations[id]);buttons[id].position=points[id]-buttons[id].size*0.5
 if side_gnomes.size()>0:
  var npc=side_gnomes[0];npc.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  npc.size=Vector2(126,136)*_unit;npc.pivot_offset=Vector2(npc.size.x*0.5,npc.size.y*0.98)
  npc.position=Vector2(0.29,0.345)*canvas.size-Vector2(npc.size.x*0.5,npc.size.y)
 _last_sprite_frame=-1
 arrival_button.size=Vector2(222,80)*_unit
 arrival_button.position=Vector2(18*_unit,size.y-arrival_button.size.y-20*_unit)
 exploration_hint.hide()
 _render_avatar()
 _sync_controls()
func _initial_position() -> void:
 if not slice_enabled:
  super._initial_position();return
 await get_tree().process_frame
 if not is_instance_valid(canvas):return
 if restored_offset.x>=0:restore_offset(restored_offset)
 else:_focus_avatar(true)
 if from_id=="entry" and model.best_stars("entry")>0:
  from_id=""
  _go_to(route.dock_s("hollow"),"hollow")
 else:from_id=""
 _render_avatar();_sync_controls()

func _apply_offset(value: Vector2) -> void:
 if not slice_enabled:
  super._apply_offset(value);return
 if is_instance_valid(scroll) and is_instance_valid(canvas):
  scroll.scroll_vertical=int(clampf(value.y,0,maxf(0,canvas.size.y-scroll.size.y)))
  scroll.scroll_horizontal=int(clampf(current_offset().x,0,maxf(0,canvas.size.x-scroll.size.x)))
func _source_to_world(p: Vector2) -> Vector2:return p/Route.SOURCE_SIZE*canvas.size
func _world_to_source(p: Vector2) -> Vector2:return p/canvas.size*Route.SOURCE_SIZE
func avatar_foot() -> Vector2:return _source_to_world(route.point(avatar_s))
func _frame_texture(index: int) -> AtlasTexture:
 var texture=AtlasTexture.new();texture.atlas=WALK_ATLAS
 # Trim cell edges containing spill from adjacent illustrations, without editing alpha.
 var region=Rect2(Vector2((index%3)*512+76,int(index/3)*512+24),Vector2(420,472))
 if index>=3:region=Rect2(Vector2((index%3)*512+88,512),Vector2(424,472))
 texture.region=region;texture.filter_clip=true;return texture
func _render_avatar() -> void:
 if not slice_ready:return
 var step: int=[0,1,2,1][int(walk_distance/12.0)%4] if journey_active and not reduced_motion else 1
 var frame: int=step+(3 if facing_back else 0)
 if frame!=_last_sprite_frame:
  gnome.texture=_frame_texture(frame);_last_sprite_frame=frame
 gnome.flip_h=facing_left
 var pivot=Vector2(0.46,0.975) if not facing_back else Vector2(0.46,0.965)
 if facing_left:pivot.x=1.0-pivot.x
 gnome.position=avatar_foot()-gnome.size*pivot
 shadow.size=Vector2(83,35)*_unit
 shadow.position=avatar_foot()-shadow.size*Vector2(0.5,0.5)
 shadow.queue_redraw()

func _sync_controls() -> void:
 if not slice_ready:return
 var arrived: bool=not journey_active and not journey_paused and not selected_level.is_empty() and absf(avatar_s-route.dock_s(selected_level))<0.01 and model.is_unlocked(selected_level)
 arrival_button.visible=arrived
 arrival_button.text="Play Level 1" if selected_level=="entry" else "Play Level 2"
 arrival_button.disabled=not interaction_enabled
 skip_button.visible=journey_paused and absf(target_s-avatar_s)>0.01
 skip_button.disabled=not interaction_enabled
func _go_to(s: float,id: String="") -> void:
 if not interaction_enabled or s>accessible_s()+0.01:return
 stop_inertia()
 selected_level=id;target_s=clampf(s,0,accessible_s())
 journey_paused=false;journey_active=absf(target_s-avatar_s)>0.01
 _sync_controls()
 if not journey_active:_arrive()
func _arrive() -> void:
 journey_active=false;journey_paused=false
 _render_avatar();_sync_controls()
 if not selected_level.is_empty() and model.is_unlocked(selected_level):
  arrived_at_level.emit(selected_level)
func _open_arrived_level() -> void:
 if not slice_enabled or not interaction_enabled or journey_active or journey_paused:return
 if selected_level.is_empty() or not model.is_unlocked(selected_level):return
 if absf(avatar_s-route.dock_s(selected_level))>0.01:return
 arrived_at_level.emit(selected_level)
func _choose_node(id: String) -> void:
 if not slice_enabled:
  super._choose_node(id);return
 if id not in ["entry","hollow"]:
  if not buttons.has(id) or buttons[id].disabled:return
  # Outside this slice the existing alpha10 entry flow is preserved.
  slice_enabled=false
  if is_instance_valid(shadow):shadow.hide()
  if is_instance_valid(arrival_button):arrival_button.hide()
  super._choose_node(id);return
 if not interaction_enabled:return
 if not model.is_unlocked(id):
  _show_route_hint("Finish Level 1 to open this passage.")
  return
 _go_to(route.dock_s(id),id)
func _show_route_hint(text: String) -> void:
 if not slice_ready:return
 exploration_hint.text=text;exploration_hint.show()
 exploration_hint.size=Vector2(size.x-32*_unit,34*_unit)
 exploration_hint.position=Vector2(16*_unit,size.y-126*_unit)
 exploration_hint.add_theme_font_size_override("font_size",int(22*_unit))

func _begin_pointer(position: Vector2,touch_index: int=-1) -> void:
 if not slice_enabled:
  super._begin_pointer(position,touch_index);return
 if not interaction_enabled or _pointer_active:return
 _press_was_walking=journey_active
 cancel_transition(false)
 _pointer_active=true;_touch_index=touch_index;_press_position=position
 _last_pointer_position=position;_last_pointer_time=Time.get_ticks_usec();_last_movement_time=_last_pointer_time
 _press_offset=current_offset();_pressed_node=_node_at(position);_panning=false;_maximum_displacement_px=0;_drag_velocity=Vector2.ZERO
func _end_pointer(position: Vector2) -> void:
 if not slice_enabled:
  super._end_pointer(position);return
 if not _pointer_active:return
 _move_pointer(position)
 var dragged: bool=_panning
 var id: String=_pressed_node if not dragged and _node_at(position)==_pressed_node else ""
 var coast: bool=dragged and not reduced_motion and interaction_enabled and Time.get_ticks_usec()-_last_movement_time<140000
 _pointer_active=false;_touch_index=-1;_pressed_node="";_panning=false
 if coast and _drag_velocity.length()>45*_unit:_inertia_velocity=_drag_velocity
 if not interaction_enabled:return
 if dragged:
  _sync_controls();return
 if not id.is_empty():_choose_node(id);return
 var hit: Dictionary=route.closest(_world_to_source(canvas.get_global_transform().affine_inverse()*position))
 if hit.distance>Route.HALF_WIDTH:
  _sync_controls();return
 if hit.s>accessible_s()+0.01:
  _show_route_hint("Finish Level 1 to open this passage.");return
 exploration_hint.hide();_go_to(hit.s)

func _overlaid_control_at(position: Vector2) -> bool:
 if slice_enabled and is_instance_valid(arrival_button) and arrival_button.visible and arrival_button.get_global_rect().has_point(position):return true
 return super._overlaid_control_at(position)
func cancel_transition(snap_camera: bool=true) -> void:
 if not slice_enabled:
  super.cancel_transition(snap_camera);return
 stop_inertia()
 if journey_active:journey_paused=true
 journey_active=false;_walking=false;from_id=""
 _sync_controls()
func finish_transition() -> void:
 if not slice_enabled:
  super.finish_transition();return
 if interaction_enabled and journey_paused:_go_to(target_s,selected_level)
func focus_current() -> void:
 if not slice_enabled:
  super.focus_current();return
 if not interaction_enabled:return
 cancel_transition(false);_focus_avatar(true)
func _focus_avatar(immediate: bool=false,delta: float=0.0) -> void:
 if not is_instance_valid(canvas):return
 var foot: Vector2=avatar_foot()
 var target=Vector2(clampf(foot.x-size.x*0.5,0,maxf(0,canvas.size.x-size.x)),clampf(foot.y-size.y*0.62,0,maxf(0,canvas.size.y-size.y)))
 var value: Vector2=target if immediate else current_offset().lerp(target,1.0-exp(-7.0*delta))
 scroll.scroll_horizontal=int(value.x);scroll.scroll_vertical=int(value.y)
func set_interaction_enabled(enabled: bool) -> void:
 if slice_enabled and not enabled:cancel_transition(false)
 super.set_interaction_enabled(enabled)
 _sync_controls()
func _process(delta: float) -> void:
 if not slice_enabled:
  super._process(delta);return
 _walking=false
 super._process(delta)
 if journey_active and interaction_enabled and not _pointer_active:
  var old: float=avatar_s
  var speed: float=100.0 # Original-art pixels/second; proportional to world scale.
  avatar_s=move_toward(avatar_s,target_s,speed*minf(delta,0.05))
  var movement: Vector2=route.point(avatar_s)-route.point(old)
  if movement.length_squared()>0.001:
   facing_back=movement.y<0
   if absf(movement.x)>0.1:facing_left=movement.x<0
  walk_distance+=absf(avatar_s-old)
  _render_avatar();_focus_avatar(false,delta)
  if absf(target_s-avatar_s)<0.01:_arrive()
 elif slice_ready:
  _render_avatar()
  if _pointer_active or _inertia_velocity.length_squared()>1.0:
   var source_y: float=(current_offset().y+size.y*0.62)/canvas.size.y*Route.SOURCE_SIZE.y
   var p: Vector2=Route.ROAD.front()
   for i in range(Route.ROAD.size()-1):
    var a: Vector2=Route.ROAD[i];var b: Vector2=Route.ROAD[i+1]
    if source_y>=b.y:p=b
    elif source_y>=a.y:
     p=a.lerp(b,(source_y-a.y)/(b.y-a.y));break
    else:break
   var desired_x: float=clampf(_source_to_world(p).x-size.x*0.5,0,maxf(0,canvas.size.x-size.x))
   scroll.scroll_horizontal=int(lerpf(current_offset().x,desired_x,1.0-exp(-5.0*delta)))
func _notification(what: int) -> void:
 super._notification(what)
 if slice_enabled and what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:cancel_transition(false)
