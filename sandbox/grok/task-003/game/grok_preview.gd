extends Control
## Grok task-003: ISOLATED PREVIEW — NOT CAMPAIGN INTEGRATION.
## Loads the unchanged integration scene + locked gnome with the Grok environment GLB and light G1.
func _ready() -> void:
	OS.set_environment("GROK_ISLAND_GLB","res://assets/grok/grok_island_t003.glb")
	var app=load("res://integration.tscn").instantiate()
	add_child(app)
	for l in app.map.native_scene.get_children():
		if l is DirectionalLight3D and l.shadow_enabled: l.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
	var tag:=Label.new()
	tag.text="ISOLATED PREVIEW — NOT CAMPAIGN INTEGRATION\nGrok task-003 environment challenger"
	tag.position=Vector2(10,820); tag.size=Vector2(412,30)
	tag.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_color_override("font_color",Color("fff1c8")); tag.add_theme_color_override("font_outline_color",Color("203a33"))
	tag.add_theme_constant_override("outline_size",6); tag.add_theme_font_size_override("font_size",14)
	add_child(tag)
	if OS.get_environment("GROK_PREVIEW_SHOT")!="":
		for _i in range(90): await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_environment("GROK_PREVIEW_SHOT"))
		print("GROK_PREVIEW_OK"); get_tree().quit()
