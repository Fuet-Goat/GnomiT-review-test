extends SceneTree
func _initialize() -> void:call_deferred("run")
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("../verification/"+name+".png")
func run() -> void:
	var app=load("res://scripts/main.gd").new();app.save_path_override="user://storybook_capture_probe.json";root.add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await create_timer(0.8).timeout;app.progress.reset();app.progress.set_option("sound",false);app.show_map();await create_timer(0.8).timeout
	await capture("MAP_SURFACE_PROBE")
	app.start_level("entry");await create_timer(0.8).timeout
	app.core.setup(app.current_level,42);app.board.setup(app.core);app._update_hud()
	await capture("BOARD_ENTRY_PROBE")
	for id in load("res://scripts/levels.gd").ordinary():app.progress.record_win(id,2)
	app.show_map();await create_timer(0.8).timeout
	await capture("MAP_BOSS_PROBE_FIXTURE")
	app.show_chamber();await create_timer(0.8).timeout
	await capture("BOSS_HALL_PROBE_FIXTURE")
	app.queue_free();await process_frame;quit()
