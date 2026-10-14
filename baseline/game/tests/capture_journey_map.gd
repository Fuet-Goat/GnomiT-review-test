extends SceneTree
var app
var base: String
var started: int
var frames: Array=[]
func _initialize() -> void:
	create_timer(60).timeout.connect(func() -> void:print("JOURNEY_CAPTURE TIMEOUT");quit(99))
	call_deferred("run")
func wait(seconds: float) -> void:await create_timer(seconds).timeout
func settle() -> void:await process_frame;await process_frame
func snapshot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(base+"/"+name+".png")
	frames.append({"name":name,"elapsed_ms":Time.get_ticks_msec()-started,"screen":app.current_screen,"offset":str(app.map_view.current_offset()) if is_instance_valid(app.map_view) else "none","seed":app.seed_counter,"light":app.progress.data.light})
func touch(position: Vector2, pressed: bool) -> void:
	var e=InputEventScreenTouch.new();e.position=root.get_final_transform()*position;e.index=0;e.pressed=pressed;Input.parse_input_event(e)
func tap(position: Vector2) -> void:
	touch(position,true);await wait(0.1);touch(position,false);await settle()
func drag(position: Vector2, delta: Vector2) -> void:
	touch(position,true);await wait(0.1)
	for i in range(1,15):
		var e=InputEventScreenDrag.new();e.index=0;e.position=root.get_final_transform()*(position+delta*float(i)/14.0);e.relative=root.get_final_transform().basis_xform(delta/14.0);Input.parse_input_event(e);await wait(0.025)
	touch(position+delta,false);await wait(0.5)
func run() -> void:
	base=ProjectSettings.globalize_path("res://../verification/journey_runtime");DirAccess.make_dir_recursive_absolute(base)
	for suffix in ["",".tmp"]:DirAccess.remove_absolute(base+"/capture_save.json"+suffix)
	root.size=Vector2i(432,960)
	app=load("res://scripts/main.gd").new();app.save_path_override=base+"/capture_save.json";root.add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);started=Time.get_ticks_msec();await wait(0.8)
	await snapshot("01_SURFACE")
	await drag(app.map_view.buttons.entry.get_global_rect().get_center(),Vector2(0,-380))
	await snapshot("02_DRAG_FROM_NUMBER")
	app.map_view.restore_scroll(app.map_view.points.hollow.y-app.map_view.size.y*0.55);await settle()
	await tap(app.map_view.buttons.hollow.get_global_rect().get_center());await wait(0.4)
	if app.current_screen!="map" or is_instance_valid(app.modal):push_error("Locked tap changed screen");quit(2);return
	await snapshot("03_LOCKED_TAP_STAYS_MAP")
	await tap(app.map_view.current_button.get_global_rect().get_center());await wait(0.35)
	await tap(app.map_view.buttons.entry.get_global_rect().get_center());await wait(0.4)
	if app.current_screen!="play":push_error("Direct tap failed");quit(3);return
	app.core.setup(app.current_level,42);app.board.setup(app.core,false);app._update_hud();await wait(0.6)
	await snapshot("04_DIRECT_PLAY")
	for pair in [[10,11],[29,36],[39,40]]:
		await app._on_swap(pair[0],pair[1]);await wait(0.35)
	await wait(0.6);await snapshot("05_ACTUAL_VICTORY")
	if not app.core.won:push_error("Actual play did not win");quit(4);return
	app._continue_after_win();await settle();await snapshot("06_WALK_START")
	await wait(0.3);await snapshot("07_WALK_MIDDLE")
	await wait(0.6);await snapshot("08_NEXT_NODE")
	await wait(0.5)
	await drag(Vector2(app.map_view.size.x*0.5,app.map_view.size.y*0.5),Vector2(0,-550));await snapshot("09_EXPLORE_DEEPER")
	app.map_view.reduced_motion=true;app.map_view.cancel_transition();app.map_view.focus_current();await wait(0.4);await snapshot("10_REDUCED_STILL")
	var report={"status":"PASS","frames":frames,"proof":"Live Godot rendering with scripted native map touch events and actual seed42 board swaps; not human gameplay or Android.","screen_index":0,"moves_left":app.core.moves_left,"light":app.progress.data.light,"stars":app.progress.best_stars("entry")}
	var f=FileAccess.open(base+"/RUNTIME_REPORT.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close();print("JOURNEY_CAPTURE "+JSON.stringify(report));app.queue_free();await settle();quit()
