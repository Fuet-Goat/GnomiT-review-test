extends SceneTree
## Grok task-003: UI-free native-viewport capture, identical camera/gnome for any island GLB.
func _initialize() -> void:call_deferred("run")
func run() -> void:
	root.size=Vector2i(432,960)
	var app=load("res://integration.tscn").instantiate()
	app.capture_mode=true
	root.add_child(app)
	var map=app.map
	map.set_process(false)
	map.old_guide.set_process(false)
	map.master.set_process(false)
	app.choose_master(true)
	map.master.set_process(false)
	map.master.pose(0)
	if OS.get_environment("GROK_LIGHTING")=="G1":
		# Grok environment-lighting candidate G1 = Profile B values unchanged + single orthogonal
		# shadow cascade (removes the PSSM split seam visible on large smooth meadow areas).
		for l in map.native_scene.get_children():
			if l is DirectionalLight3D and l.shadow_enabled: l.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
	if OS.get_environment("GROK_DEBUG_NOSHADOW")=="1":
		for l in map.native_scene.get_children():
			if l is DirectionalLight3D: l.shadow_enabled=false
	var sc:=int(OS.get_environment("GROK_SCALE")) if OS.get_environment("GROK_SCALE")!="" else 1
	map.native_viewport.size=Vector2i(432*sc,960*sc)
	for _w in range(60):await process_frame
	await RenderingServer.frame_post_draw
	var out:=OS.get_environment("GROK_OUT")
	assert(map.native_viewport.get_texture().get_image().save_png(out)==OK)
	var rec:={"island":OS.get_environment("GROK_ISLAND_GLB"),"camera":str(map.camera.global_transform),"camera_size":map.camera.size,"fov":map.camera.fov,"master_position":str(map.master.position),"master_scale":map.master.SCALE,"profile":map.lighting_profile_id,"grok_lighting":OS.get_environment("GROK_LIGHTING"),"master_glb_sha256":FileAccess.get_sha256("res://assets/gnome_r3.glb")}
	print("GROK_CAPTURE "+JSON.stringify(rec))
	quit(0)
