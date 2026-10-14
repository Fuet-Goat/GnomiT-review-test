extends SceneTree
var app
var cues: Array=[]
func _initialize() -> void:call_deferred("run")
func on_cue(kind: String, strength: float) -> void:cues.append({"frame":Engine.get_process_frames(),"kind":kind,"strength":strength})
func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("../verification/runtime/"+name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("../verification/runtime"))
	root.gui_disable_input=true
	app=load("res://scripts/main.gd").new();app.save_path_override="user://alpha4_native_capture.json";root.add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);app.set_process_unhandled_key_input(false)
	await create_timer(0.6).timeout;app.progress.reset();app.progress.set_option("sound",true);app.show_map();await create_timer(0.8).timeout;await snap("MAP_NEW_GNOME")
	app.start_level("entry");await create_timer(0.5).timeout;app.core.setup(app.current_level,42);app.board.setup(app.core);app._update_hud();app.board.foley_requested.connect(on_cue)
	await snap("BOARD_NEW_GNOME");await create_timer(0.5).timeout
	app.board._last_swap=[1,2];await app._on_swap(1,2);await create_timer(0.3).timeout
	# Restart deterministic entry after the deliberately invalid neighbor feedback.
	app.core.setup(app.current_level,42);app.board.setup(app.core);app._update_hud()
	for pair in [[10,11],[29,36],[39,40]]:
		app.board._press(app.board._center(pair[0]));app.board._release(app.board._center(pair[0]));await create_timer(0.2).timeout
		await app._on_swap(pair[0],pair[1]);await create_timer(0.35).timeout
	await create_timer(0.8).timeout;await snap("VICTORY_NEW_GNOME");await create_timer(1.0).timeout
	app._continue_after_win();await create_timer(1.0).timeout;await snap("MAP_NEXT_NEW_GNOME")
	var image: Image=load("res://assets/storybook/gnome_lantern_poses_v2.png").get_image()
	var receipt={"cues":cues,"won":app.core.won,"star_count":app.progress.best_stars("entry"),"screen_index":DisplayServer.window_get_current_screen(),"sprite_size":str(image.get_size()),"transparent_corners":image.get_pixel(0,0).a==0 and image.get_pixel(image.get_width()-1,image.get_height()-1).a==0,"input":"scripted native PC capture; not human playtesting"}
	var f=FileAccess.open("../verification/runtime/capture_receipt.json",FileAccess.WRITE);f.store_string(JSON.stringify(receipt,"  "));f.close()
	print("ALPHA4_CAPTURE "+JSON.stringify(receipt))
	app.rock_audio.stop_all();app.audio.stop();app.audio.stream=null;image=null;app.queue_free();await process_frame;await process_frame;quit()
