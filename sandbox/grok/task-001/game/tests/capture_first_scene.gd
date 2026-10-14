extends SceneTree
var app
var observations: Array=[]
var base: String
func _initialize() -> void:call_deferred("run")
func wait(seconds: float) -> void:await create_timer(seconds).timeout
func snapshot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image=root.get_texture().get_image()
	image.save_png(base+"/"+name+".png")
	observations.append({"name":name,"moves":app.core.moves_left,"collected":app.core.collected,"won":app.core.won,"image":base+"/"+name+".png"})
func tap(index: int) -> void:
	var down=InputEventScreenTouch.new();down.index=0;down.position=app.board._center(index);down.pressed=true;app.board._gui_input(down)
	await wait(0.18)
	var up=InputEventScreenTouch.new();up.index=0;up.position=app.board._center(index);up.pressed=false;app.board._gui_input(up)
func swap_pair(a: int,b: int) -> void:
	await tap(a);await wait(0.25);await tap(b)
	while app.board.busy:await process_frame
	await wait(0.6)
func run() -> void:
	base=ProjectSettings.globalize_path("res://../verification/runtime_final")
	DirAccess.make_dir_recursive_absolute(base)
	app=load("res://scripts/main.gd").new();app.save_path_override=base+"/capture_save.json"
	root.add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await wait(0.4);app.start_level("entry");app.core.setup(app.current_level,42);app.board.setup(app.core);app._update_hud()
	await wait(1);await snapshot("FIRST_CRYSTALS_START")
	var invalid: Array=[]
	for a in range(app.core.grid.size()):
		for b in app.core._neighbors(a):
			var c=load("res://scripts/match_core.gd").new();c.setup(app.current_level,42)
			if app.core.grid[a]>=0 and app.core.grid[b]>=0 and not c.try_swap(a,b).valid:invalid=[a,b];break
		if not invalid.is_empty():break
	await swap_pair(invalid[0],invalid[1]);await snapshot("FIRST_CRYSTALS_INVALID_RETURN")
	var ordinal:=0
	for pair in [[10,11],[29,36],[39,40]]:
		await swap_pair(pair[0],pair[1])
		ordinal+=1
		if ordinal==1:await snapshot("FIRST_CRYSTALS_EXCAVATED")
		if app.core.won:break
	await wait(1.3)
	var terminal_moves: int=app.core.moves_left
	var escape=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;app._unhandled_key_input(escape)
	await app._on_swap(10,11)
	var terminal_guard: bool=is_instance_valid(app.modal) and app._paused and not app.board.busy and app.core.moves_left==terminal_moves
	await snapshot("FIRST_CRYSTALS_VICTORY")
	var report: Dictionary={"terminal_result_guard":terminal_guard,"runtime":"REAL_GODOT_OPENGL_SCENE","user_input":"SCRIPTED_SCREEN_TOUCH_HANDLERS","seed":42,"actions":[[10,11],[29,36],[39,40]],"generated_video":false,"physical_pixel8a_test":false,"observations":observations,"excavated_cells":app.board._excavated.size(),"won":app.core.won,"moves":app.core.moves_left,"collected":app.core.collected,"version":ProjectSettings.get_setting("application/config/version")}
	var f=FileAccess.open(base+"/RUNTIME_CAPTURE.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
	print(JSON.stringify(report));quit(0 if app.core.won and terminal_guard else 1)
