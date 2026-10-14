extends SceneTree
var failures: Array[String]=[]
var checks:=0
var observations: Array=[]
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures.append(message)
func fingerprint(c) -> String:
	return JSON.stringify({"grid":c.grid,"floor":c.floor,"runes":c.runes,"moves":c.moves_left,"collected":c.collected,"won":c.won,"lost":c.lost,"rng":c._rng.state}).sha256_text()
func settle() -> void:
	await process_frame;await process_frame
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var app=load("res://scripts/main.gd").new()
	app.save_path_override="user://first_crystals_tests.json"
	root.add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await settle();app.progress.set_option("sound",false);app.start_level("entry");await settle()
	app.core.setup(app.current_level,42031);app.board.setup(app.core);app._update_hud()
	check(is_instance_valid(app.first_scene) and app.board.polished_art,"entry uses real sprite scene")
	check(app.board._gem_textures.size()==6,"six real sprite atlas regions")
	check(app.first_scene.title.text=="FIRST CRYSTALS" and app.first_scene.move_caption.text=="MOVES","English first scene captions")
	check(app.first_scene._bold_font.variation_opentype.has(TextServerManager.get_primary_interface().name_to_tag("wght")),"variable font uses actual integer axis tag")
	check(app.board._excavated.is_empty(),"new run begins with untouched soil")
	var previous: String=fingerprint(app.core)
	for viewport in [Vector2i(720,1600),Vector2i(360,800),Vector2i(432,960),Vector2i(720,1280)]:
		root.size=viewport;await settle();app._resize_stage();app.first_scene.layout();await settle()
		var view=app.first_scene
		var area: Rect2=Rect2(Vector2.ZERO,view.size)
		for node in [view.moves_label,view.goal_label,view.move_caption,view.goal_caption,view.hint_button,view.pause_button,view.exit_button,view.gnome]:
			check(area.grow(1).encloses(node.get_rect()),"live control bounds "+node.name+str(viewport))
		check(view.move_caption.autowrap_mode==TextServer.AUTOWRAP_OFF,"moves caption never breaks")
		check(view.moves_label.text==str(app.core.moves_left) and view.goal_label.text=="0 / 12","compact numeric HUD")
		check(not view.board.get_rect().intersects(view.hud_rects.moves) and not view.board.get_rect().intersects(view.hud_rects.helper),"HUD and gnome outside board")
		check(fingerprint(app.core)==previous,"layout never mutates gameplay")
		observations.append({"viewport":str(viewport),"scene":str(view.size),"cell":view.board._cell_size(),"hud":str(view.hud_rects)})
	root.size=Vector2i(720,1600);await settle()
	app.show_pause();check(app._paused and is_instance_valid(app.modal),"pause visible")
	app._close_modal();check(not app._paused,"pause closes")
	var count: int=app.core.collected
	app.first_scene.reduced_motion=true;app.first_scene.on_goal_piece(app.board.global_position)
	check(app.first_scene.trails.orbs.is_empty(),"reduced motion has no flight")
	check(app.core.collected==count and fingerprint(app.core)==previous,"goal animation never changes Core")
	app._update_hud();app.first_scene.reduced_motion=false
	var invalid: Array=[]
	for a in range(app.core.grid.size()):
		for b in [a+1,a+app.core.cols]:
			if b>=app.core.grid.size():continue
			var clone=load("res://scripts/match_core.gd").new();clone.setup(app.current_level,42031)
			var result: Dictionary=clone.try_swap(a,b)
			if not result.valid and app.core.grid[a]>=0 and app.core.grid[b]>=0 and abs(a%app.core.cols-b%app.core.cols)+abs(a/app.core.cols-b/app.core.cols)==1:invalid=[a,b];break
		if not invalid.is_empty():break
	check(not invalid.is_empty(),"invalid neighbor pair available")
	if not invalid.is_empty():
		app.board._last_swap=invalid.duplicate();await app._on_swap(invalid[0],invalid[1])
		check(app.core.moves_left==app.core.initial_moves,"invalid swap spends no move")
		check(app.board._excavated.is_empty(),"invalid swap leaves soil untouched")
		check(not app.board.busy and app.board._display_grid==app.core.grid,"invalid animation returns exact board")
	var pair: Array=app.core.hint_move()
	await app._on_swap(pair[0],pair[1])
	check(app.core.moves_left==app.core.initial_moves-1,"valid swap spends exactly one move")
	check(not app.board._excavated.is_empty(),"valid match exposes bedrock")
	var dug: Dictionary=app.board._excavated.duplicate()
	var normal_state: String=fingerprint(app.core)
	app.board.queue_redraw();await settle()
	check(app.board._excavated==dug,"redraw cannot excavate terrain")
	check(not app.board.busy and app.board._display_grid==app.core.grid,"sprite cascade ends on exact Core board")
	check(app.first_scene.goal_label.text=="%d / 12"%mini(12,app.core.collected),"goal HUD reaches semantic count")
	app.start_level("entry");await settle()
	check(app.board._excavated.is_empty(),"retry starts fresh visual excavation")
	app.core.setup(app.current_level,42031);app.board.setup(app.core,true);app.first_scene.reduced_motion=true;app._update_hud()
	await app._on_swap(pair[0],pair[1])
	check(fingerprint(app.core)==normal_state,"reduced motion reaches same gameplay state")
	check(app.board._excavated==dug,"reduced motion exposes same cells")
	var atlas: Image=app.board._gem_atlas.get_image()
	check(atlas.get_size()==Vector2i(1536,1024),"atlas uniform 3 by 2 geometry")
	check(atlas.get_pixel(0,0).a==0.0 and atlas.get_pixel(1535,1023).a==0.0,"treasure atlas has real transparent corners")
	app.show_map();await settle();check(not is_instance_valid(app.first_scene),"entry art isolated from map")
	var receipt: Dictionary={"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"observations":observations,"proof":"HEADLESS_NATIVE_LAYOUT_AND_GAMEPLAY_PRESENTATION","physical_phone_test":false}
	var f=FileAccess.open("../verification/first_scene_checks.json",FileAccess.WRITE);f.store_string(JSON.stringify(receipt, "  "));f.close()
	atlas=null;app.queue_free();await settle()
	print(JSON.stringify(receipt));quit(0 if failures.is_empty() else 1)
