extends SceneTree
var checks:=0
var failures: Array[String]=[]
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures.append(message);print("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func settle() -> void:await process_frame;await process_frame
func run() -> void:
	var levels=load("res://scripts/levels.gd")
	var store=load("res://scripts/progress.gd").new()
	store.load_progress("user://storybook_contract.json");store.reset();store.set_option("sound",false)
	check(levels.all().size()==10,"ten actual playable encounters")
	var path: Array=levels.ordinary()
	check(path.size()==7,"seven real ordinary levels before the Boss door")
	for id in ["entry","hollow","seam"]:store.record_win(id,1)
	check(not store.is_unlocked("rune") and not store.is_unlocked("lantern"),"first three ordinary wins do not skip remaining ordinary path")
	for id in path:
		check(store.is_unlocked(id),"next path level opens: "+id)
		check(store.record_win(id,1).accepted,"real path reward accepted: "+id)
	check(store.is_unlocked("rune") and store.is_unlocked("lantern"),"full path opens both free-order preparations")
	store.record_win("lantern",2)
	check(not store.is_unlocked("guardian"),"one preparation keeps final locked")
	store.record_win("rune",1)
	check(store.is_unlocked("guardian"),"both preparations open final")
	store.record_win("guardian",3)
	check(store.data.light==100,"ten distinct first-win rewards are credited once")
	store.record_win("guardian",1)
	check(store.data.light==100 and store.best_stars("guardian")==3,"replay preserves best stars and avoids repeat reward")
	var app=load("res://scripts/main.gd").new();app.save_path_override="user://storybook_ui_contract.json"
	root.add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);await settle()
	app.progress.reset();app.progress.set_option("sound",false);app.show_map();await settle()
	check(app.map_buttons.size()==8,"live map has seven real numbers and one Boss door")
	check(is_instance_valid(app.get("map_view")),"C2 map uses actual artwork view")
	check(not app.map_buttons.entry.disabled,"current map node is playable")
	check(app.map_buttons.boss.disabled,"Boss door is locked on a fresh run")
	app.progress.record_win("entry",1);app.start_level("hollow");await settle()
	check(is_instance_valid(app.first_scene) and app.board.polished_art,"second level uses same material and HUD system")
	if is_instance_valid(app.first_scene):
		check(app.goal_label.text=="0 / 12","soil goal shows actual twelve partial targets")
		var visible: String=app.first_scene.goal_caption.text.to_lower()
		check(visible.contains("soil"),"soil objective is named instead of collecting blue pieces")
	app.show_map();await settle()
	for id in path:app.progress.record_win(id,1)
	app.progress.record_win("rune",1);app.progress.record_win("lantern",1)
	app.start_level("guardian");await settle()
	check(is_instance_valid(app.first_scene) and app.board.polished_art,"Boss board shares the polished art")
	if is_instance_valid(app.first_scene):
		check(app.goal_label.text=="0 / 18","Boss collection counter uses actual goal")
		check(is_instance_valid(app.first_scene.get("secondary_goal_label")),"Boss has a separate readable rune counter")
	app.queue_free();await settle()
	for name in ["storybook_contract.json","storybook_ui_contract.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://"+name))
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://"+name+".tmp"))
	var result: Dictionary={"checks":checks,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL"}
	print("STORYBOOK_CONTRACT "+JSON.stringify(result));quit(0 if failures.is_empty() else 1)
