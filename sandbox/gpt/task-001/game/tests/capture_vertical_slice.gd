extends SceneTree
var app
var base: String
var frames: Array=[]
var failures: Array=[]
var started:=0
func _initialize() -> void:
 create_timer(65).timeout.connect(func() -> void:push_error("Slice timeout");quit(99))
 call_deferred("run")
func wait(seconds: float) -> void:await create_timer(seconds).timeout
func check(value: bool,message: String) -> void:
 if not value:failures.append(message);push_error(message)
func settle() -> void:await process_frame;await process_frame
func snapshot(name: String) -> void:
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(base+"/"+name+".png")
 frames.append({"name":name,"ms":Time.get_ticks_msec()-started,"screen":app.current_screen,"avatar_s":app.map_view.avatar_s if is_instance_valid(app.map_view) else -1,"light":app.progress.data.light,"modal":is_instance_valid(app.modal)})
func touch(position: Vector2,pressed: bool) -> void:
 var event=InputEventScreenTouch.new();event.position=root.get_final_transform()*position;event.index=0;event.pressed=pressed;Input.parse_input_event(event)
func tap(position: Vector2) -> void:
 touch(position,true);await wait(0.075);touch(position,false);await settle()
func drag(position: Vector2,delta: Vector2) -> void:
 touch(position,true);await wait(0.075)
 for i in range(1,9):
  var e=InputEventScreenDrag.new();e.index=0;e.position=root.get_final_transform()*(position+delta*i/8.0);e.relative=root.get_final_transform().basis_xform(delta/8.0);Input.parse_input_event(e);await wait(0.025)
 touch(position+delta,false);await wait(0.3)
func run() -> void:
 base=ProjectSettings.globalize_path("res://../verification/slice_runtime_"+str(Time.get_unix_time_from_system()).replace(".","_"));DirAccess.make_dir_recursive_absolute(base)
 root.size=Vector2i(432,960)
 app=load("res://scripts/main.gd").new();app.save_path_override=base+"/progress.json";root.add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 started=Time.get_ticks_msec();await wait(0.6)
 check(is_instance_valid(app.map_view),"Map exists")
 if not is_instance_valid(app.map_view):quit(1);return
 var map=app.map_view
 await snapshot("01_START")
 var initial: String=JSON.stringify(app.progress.data)
 # A locked node and locked road are both inaccessible; camera can still explore them.
 await tap(map.buttons.hollow.get_global_rect().get_center())
 check(not map.journey_active and not is_instance_valid(app.modal),"Locked node cannot start travel/play")
 await tap(map.canvas.get_global_transform()*map._source_to_world(map.route.point(map.route.end_s())))
 check(not map.journey_active,"Locked road cannot start travel")
 check(JSON.stringify(app.progress.data)==initial,"Navigation does not grant rewards")
 # Physical drag from a node cannot turn into a level choice.
 await drag(map.buttons.entry.get_global_rect().get_center(),Vector2(0,-65))
 check(app.current_screen=="map" and not is_instance_valid(app.modal),"Drag from level stays on map")
 map.focus_current();await wait(0.2)
 # Walk to a point inside the currently accessible road.
 await tap(map.canvas.get_global_transform()*map._source_to_world(map.route.point(map.route.dock_s("entry")*0.7)))
 check(map.journey_active,"Road tap starts a journey")
 await wait(0.2)
 await snapshot("02_WALK")
 var before_drag: float=map.avatar_s
 await drag(Vector2(map.size.x*0.25,map.size.y*0.45),Vector2(0,-42))
 check(absf(map.avatar_s-before_drag)<1.0,"Drag freezes actual avatar position")
 await wait(0.25);check(absf(map.avatar_s-before_drag)<1.0,"Release does not resume or teleport")
 await snapshot("03_INTERRUPTED")
 map.focus_current();await settle()
 await tap(map.buttons.entry.get_global_rect().get_center());await wait(1.0)
 check(app.current_screen=="map" and is_instance_valid(app.pre_level_view),"Arrival opens goal panel, not the board")
 check(absf(map.avatar_s-map.route.dock_s("entry"))<0.01,"Arrived at level 1 docking")
 check(JSON.stringify(app.progress.data)==initial,"Arrival panel does not award Light")
 await snapshot("04_ARRIVAL_PLAY")
 if not is_instance_valid(app.pre_level_view):quit(2);return
 app.pre_level_view.request_play();await wait(0.25)
 check(app.current_screen=="play","Explicit Play enters level 1")
 app.core.setup(app.current_level,42);app.board.setup(app.core,false);app._update_hud()
 await snapshot("05_EXISTING_BOARD")
 for pair in [[10,11],[29,36],[39,40]]:
  await app._on_swap(pair[0],pair[1]);await wait(0.25)
 check(app.core.won,"Actual match-3 swaps win level 1")
 check(app.progress.is_unlocked("hollow"),"Winning level 1 unlocks level 2")
 check(app.progress.data.light==10,"Only victory grants existing +10 Light")
 await snapshot("06_REAL_VICTORY")
 app._continue_after_win();await wait(0.75)
 map=app.map_view
 check(map.journey_active,"Post-victory uses the same road follower")
 await snapshot("07_UNLOCKED_BEND")
 # Interruption preserves route position; a new tap resumes from that place.
 var frozen: float=map.avatar_s
 map.cancel_transition(false);await wait(0.25)
 check(absf(map.avatar_s-frozen)<0.01,"Cancel never snaps to destination")
 map.focus_current()
 await tap(map.buttons.hollow.get_global_rect().get_center());await wait(3.0)
 check(is_instance_valid(app.pre_level_view) and app.pre_level_view.level_id=="hollow","Arrival at level 2 exposes its real goal")
 check(absf(map.avatar_s-map.route.end_s())<0.01,"Forward route reaches level 2")
 await snapshot("08_LEVEL_2_ARRIVAL")
 app._close_modal();await settle()
 var won_state: String=JSON.stringify(app.progress.data)
 await drag(Vector2(map.size.x*0.5,map.size.y*0.4),Vector2(0,240))
 map.stop_inertia();await settle()
 await tap(map.buttons.entry.get_global_rect().get_center());await wait(0.7)
 check(map.facing_back,"Reverse journey uses rear-facing frames")
 await snapshot("09_RETURN_UP")
 # Settings/resize cannot teleport or complete the journey.
 var paused: float=map.avatar_s
 app.show_options();await wait(0.2)
 check(absf(map.avatar_s-paused)<0.01 and not map.journey_active,"Settings pauses at current road position")
 app._close_modal();await settle()
 var before_resize: float=map.avatar_s
 if DisplayServer.get_name()=="headless":root.size=Vector2i(460,990)
 else:map.layout()
 await wait(0.25)
 check(absf(map.avatar_s-before_resize)<0.01,"Resize retains arc-distance")
 root.size=Vector2i(432,960);await wait(0.25)
 map.finish_transition();await wait(3.0)
 check(is_instance_valid(app.pre_level_view) and app.pre_level_view.level_id=="entry","Can return to level 1")
 check(JSON.stringify(app.progress.data)==won_state and app.progress.is_unlocked("hollow"),"Returning never loses progress or duplicates rewards")
 await snapshot("10_REPLAY_ARRIVAL")
 # Exit to map preserves the avatar location independently from frontier.
 if not is_instance_valid(app.pre_level_view):quit(3);return
 app.pre_level_view.request_play();await wait(0.2);app._exit_level();await wait(0.3)
 check(absf(app.map_view.avatar_s-app.map_view.route.dock_s("entry"))<0.01,"Match-3 exit restores actual location, not level 2 frontier")
 app.map_view.reduced_motion=true
 app.map_view._go_to(app.map_view.route.end_s())
 var rm_start: float=app.map_view.avatar_s
 await wait(0.2)
 check(app.map_view.avatar_s>rm_start and app.map_view.avatar_s<app.map_view.route.end_s(),"Reduced Motion travels without teleporting")
 app.map_view.cancel_transition(false)
 check(JSON.stringify(app.progress.data)==won_state,"Reduced Motion navigation preserves progression")
 var report={"status":"PASS" if failures.is_empty() else "FAIL","failures":failures,"frames":frames,"proof":"Current Vertical Slice 1 rendered Godot with scripted native touch gestures and real seed42 match-3 swaps; not human or Android usability acceptance.","viewport":"432x960","screen_index":0,"light":app.progress.data.light,"stars":app.progress.best_stars("entry"),"save":app.save_path_override}
 var f=FileAccess.open(base+"/RUNTIME_REPORT.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
 print("SLICE_REPORT "+JSON.stringify(report))
 app.queue_free();await settle();quit(0 if failures.is_empty() else 1)
