extends SceneTree

var app
var checks:=0
var failures: Array[String]=[]
var trace: Array=[]
var save_path: String

class EventTrace extends Node:
	var events: Array=[]
	func _input(event: InputEvent) -> void:
		if event is InputEventScreenTouch or event is InputEventMouseButton:
			events.append({"type":event.get_class(),"device":event.device,"pressed":event.pressed,"canceled":event.canceled})

func _initialize() -> void:
	create_timer(75).timeout.connect(func() -> void:print("JOURNEY TIMEOUT");quit(99))
	call_deferred("run")
func check(ok: bool, why: String) -> void:
	checks+=1
	if not ok:failures.append(why);print("FAIL: "+why)
func settle() -> void:await process_frame;await process_frame
func wait(seconds: float) -> void:await create_timer(seconds).timeout
func touch(position: Vector2, pressed: bool, index: int=0, canceled: bool=false) -> void:
	var e=InputEventScreenTouch.new();e.position=root.get_final_transform()*position;e.index=index;e.pressed=pressed;e.canceled=canceled;Input.parse_input_event(e)
func move(position: Vector2, index: int=0) -> void:
	var e=InputEventScreenDrag.new();e.position=root.get_final_transform()*position;e.index=index;Input.parse_input_event(e)
func click(position: Vector2, pressed: bool) -> void:
	var e=InputEventMouseButton.new();e.position=root.get_final_transform()*position;e.global_position=e.position;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;e.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0;Input.parse_input_event(e)
func center(id: String) -> Vector2:
	app.map_view.restore_scroll(app.map_view.points[id].y-app.map_view.size.y*0.52);await settle()
	return app.map_view.buttons[id].get_global_rect().get_center()
func reset_map(reduced: bool=true) -> void:
	app.progress.reset();app.progress.set_option("sound",false);app.progress.set_option("reduced_motion",reduced)
	app._saved_map_scroll=-1;app._saved_map_offset=Vector2(-1,-1);app._return_from_id="";app.show_map();await settle()
func run() -> void:
	save_path=ProjectSettings.globalize_path("res://../verification/journey_test_save.json")
	DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
	for suffix in ["",".tmp"]:DirAccess.remove_absolute(save_path+suffix)
	root.size=Vector2i(432,960)
	app=load("res://scripts/main.gd").new();app.save_path_override=save_path;root.add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);await wait(0.15)
	var logger=EventTrace.new();root.add_child(logger)
	for window in [Vector2i(432,960),Vector2i(720,1600)]:
		root.size=window;await settle();app._resize_stage();await settle()
		for physical in [0.0,11.9,12.0,12.1]:
			await reset_map()
			var p: Vector2=await center("entry")
			var logical_delta: Vector2=root.get_final_transform().affine_inverse().basis_xform(Vector2(physical,0))
			var before: int=app.seed_counter
			touch(p,true);await settle();move(p+logical_delta);await settle()
			touch(p+logical_delta,false);await settle()
			var should_play: bool=physical<12.0
			check((app.current_screen=="play")==should_play,"12 physical pixel tap boundary "+str(physical)+" at "+str(window))
			check(app.seed_counter==before+(1 if should_play else 0),"tap starts exactly one board; drag starts none "+str(physical)+" "+str(window))
			check(not is_instance_valid(app.pre_level_view),"node gesture does not open pre-level screen "+str(physical))
		await reset_map()
		var p: Vector2=await center("entry")
		touch(p,true);await settle();move(p+Vector2(0,-90));await settle();move(p);await settle();touch(p,false);await settle()
		check(app.current_screen=="map","out-and-back drag never becomes a tap "+str(window))
		p=await center("hollow")
		var seed: int=app.seed_counter
		touch(p,true);await settle();touch(p,false);await settle()
		check(app.current_screen=="map" and app.seed_counter==seed and not is_instance_valid(app.modal),"locked node cannot start or open modal "+str(window))
		app._close_modal();await settle()
		p=await center("entry")
		logger.events.clear();touch(p,true);await settle();touch(p,false,0,true);await settle()
		check(app.current_screen=="map" and app.seed_counter==seed,"canceled native touch cannot start a board "+str(window))
		trace.append({"window":str(window),"canceled_events":logger.events.duplicate()})
		touch(p,true);await settle();move(p-Vector2(0,100));await settle();touch(p-Vector2(0,100),false,0,true);await settle()
		check(app.current_screen=="map" and app.seed_counter==seed,"canceled drag on number cannot start a level")
		var canceled_y: int=app.map_view.current_scroll();await wait(0.06)
		check(app.map_view.current_scroll()==canceled_y,"cancellation leaves no inertia")
		touch(p,true);await settle();touch(p+Vector2(80,0),true,1);move(p+Vector2(0,-110),1);touch(p,false,1);await settle()
		check(app.current_screen=="map","second finger cannot release or select primary node")
		touch(p,false,0,true);await settle()
		var v=app.map_view
		v.restore_scroll(900);await settle();var before: Vector2=v.current_offset()
		p=Vector2(v.size.x*0.5,v.size.y*0.5)
		touch(p,true);await settle();move(p+Vector2(100,170));await settle();touch(p+Vector2(100,170),false);await settle()
		check(v.current_offset().y<before.y-150,"finger down reveals upper path")
		check(absf(v.current_offset().x-before.x)<=v.size.x*0.17,"horizontal following remains narrow during diagonal drag")
		before=v.current_offset();touch(p,true);await settle();move(p+Vector2(200,0));await settle();touch(p+Vector2(200,0),false);await settle()
		check(absf(v.current_offset().x-before.x)<2 and absf(v.current_offset().y-before.y)<2,"horizontal-only finger cannot freely pan world")
		v.restore_scroll(-9999);await settle();check(v.current_scroll()==0,"surface clamps at top")
		check(v.canvas.get_global_rect().grow(1).encloses(v.scroll.get_global_rect()),"top clamp has no empty artwork")
		v.restore_scroll(99999);await settle();check(v.canvas.get_global_rect().grow(1).encloses(v.scroll.get_global_rect()),"deep clamp has no empty artwork")
		var hero_rect: Rect2=v.gnome.get_rect()
		check(not hero_rect.intersects(v.buttons.entry.get_rect()),"idle guide never covers current badge")
		var npcs=v.get("side_gnomes")
		check(npcs is Array and npcs.size()<=2 and npcs.size()>0,"at most two side gnomes exist")
		if npcs is Array:
			for npc in npcs:
				check(npc.mouse_filter==Control.MOUSE_FILTER_IGNORE,"side gnome never captures input")
				var fixed: Vector2=npc.position;await wait(0.08);check(npc.position==fixed and is_zero_approx(npc.rotation),"reduced motion keeps side gnome completely still")
	root.size=Vector2i(432,960);await settle();app._resize_stage();await settle()
	await reset_map(false)
	var v=app.map_view;v.restore_scroll(900);await settle();var p=Vector2(v.size.x*0.5,v.size.y*0.5)
	for npc in v.side_gnomes:
		var position: Vector2=npc.position;var rotation: float=npc.rotation;await wait(0.1)
		check(npc.position==position and not is_equal_approx(npc.rotation,rotation),"ordinary side sway rotates without translation")
	touch(p,true);await settle()
	for i in range(1,5):move(p-Vector2(0,i*40));await wait(0.02)
	touch(p-Vector2(0,160),false);await settle();var released: int=v.current_scroll();await wait(0.08)
	check(v.current_scroll()>released,"quick release continues with short inertia")
	await wait(1.0);var stopped: int=v.current_scroll();await wait(0.12);check(v.current_scroll()==stopped,"inertia comes to rest")
	v.restore_scroll(900);await settle();touch(p,true);await settle();move(p-Vector2(0,160));await wait(0.22);touch(p-Vector2(0,160),false);await settle();released=v.current_scroll();await wait(0.1)
	check(v.current_scroll()==released,"holding still before release prevents stale fling")
	v.reduced_motion=true;v.restore_scroll(900);await settle();touch(p,true);await settle();move(p-Vector2(0,160));await settle();touch(p-Vector2(0,160),false);await settle();released=v.current_scroll();await wait(0.1)
	check(v.current_scroll()==released,"reduced motion disables inertia")
	var menu_point: Vector2=v.menu_button.get_global_rect().get_center();touch(menu_point,true);await settle();touch(menu_point,false);await settle()
	check(is_instance_valid(app.modal),"native touch opens existing settings overlay")
	app._close_modal();await settle()
	await reset_map(false);p=await center("entry");click(p,true);await settle();click(p,false);await settle()
	check(app.current_screen=="play","mouse short click directly starts current level")
	if app.current_screen!="play":app._close_modal();app.start_level("entry");await settle()
	app.core.setup(app.current_level,42);app.board.setup(app.core,true);app.first_scene.reduced_motion=true;app._update_hud()
	for pair in [[10,11],[29,36],[39,40]]:await app._on_swap(pair[0],pair[1])
	check(app.core.won and app.progress.best_stars("entry")>0,"actual swaps win and save first passage")
	app._continue_after_win();await settle();v=app.map_view
	var start: Vector2=v.gnome.position;check(v.focus_id=="hollow" and v.skip_button.visible,"first win starts walk toward next current node")
	await wait(0.35);var middle: Vector2=v.gnome.position
	check(middle.distance_to(start)>20,"hero actually moves along route before arriving")
	check(v.scroll.get_global_rect().encloses(v.gnome.get_global_rect()),"camera keeps walking guide visible")
	await wait(0.55);check(not v.skip_button.visible,"walk finishes near 0.8 seconds")
	check(not v.gnome.get_rect().intersects(v.buttons.hollow.get_rect()),"arrival is outside new current badge")
	var finish: Vector2=v.gnome.position;check(finish.distance_to(middle)>20,"walk has intermediate positions, not a teleport")
	p=await center("entry");touch(p,true);await settle();touch(p,false);await settle()
	app.core.setup(app.current_level,42);app.board.setup(app.core,true);app.first_scene.reduced_motion=true;app._update_hud()
	for pair in [[10,11],[29,36],[39,40]]:await app._on_swap(pair[0],pair[1])
	app._continue_after_win();await settle();check(app.map_view.focus_id=="hollow" and not app.map_view.skip_button.visible,"replaying old win cannot restart or send guide backward")
	var view=load("res://scripts/story_map_view.gd").new();view.configure(app.progress,load("res://scripts/levels.gd").ordinary(),"hollow",true,"entry");root.add_child(view);await settle()
	check(not view.skip_button.visible and not view.gnome.get_rect().intersects(view.buttons.hollow.get_rect()),"reduced motion immediately arrives without walking")
	view.queue_free();logger.queue_free();app.queue_free();await settle()
	var result={"checks":checks,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL","native_event_trace":trace,"scope":"PC native input events; not a physical Android test"}
	var f=FileAccess.open(ProjectSettings.globalize_path("res://../verification/JOURNEY_MAP_TEST.json"),FileAccess.WRITE);f.store_string(JSON.stringify(result,"\t"));f.close()
	print("JOURNEY_MAP "+JSON.stringify(result));quit(0 if failures.is_empty() else 1)
