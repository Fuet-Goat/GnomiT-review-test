extends SceneTree
const Art=preload("res://scripts/story_art.gd")
class PanelProbe extends Control:
	func _draw() -> void:
		var Art=load("res://scripts/story_art.gd")
		Art.panel().draw(get_canvas_item(),Rect2(20,20,400,120))
		draw_texture_rect_region(Art.MATERIALS,Rect2(20,190,400,400),Rect2(544,500,476,450))
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var monitors: Array=[]
	for i in DisplayServer.get_screen_count():monitors.append({"index":i,"position":str(DisplayServer.screen_get_position(i)),"size":str(DisplayServer.screen_get_size(i))})
	print("MONITORS "+JSON.stringify(monitors))
	var image: Image=Art.MATERIALS.get_image()
	for p in [Vector2i(544,500),Vector2i(570,530),Vector2i(600,900),Vector2i(750,930),Vector2i(750,800)]:print("ALPHA %s=%s"%[p,image.get_pixelv(p)])
	var probe=PanelProbe.new();root.add_child(probe);probe.size=Vector2(720,1600)
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("../verification/PANEL_DIAGNOSTIC.png")
	probe.queue_free();await process_frame;quit()
