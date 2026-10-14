extends SceneTree
var failures: Array[String]=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var app=load("res://scripts/main.gd").new();app.save_path_override="user://storybook_presentation.json";root.add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);await process_frame;await process_frame
	app.progress.reset();app.progress.set_option("sound",false)
	for id in load("res://scripts/levels.gd").ordinary():app.progress.record_win(id,1)
	app.progress.record_win("rune",1);app.progress.record_win("lantern",1);app.start_level("guardian");await process_frame
	# Simulate Core's already-resolved cascade while rendering only its first rune release.
	app.core.collected=15;app.core.runes.fill(0)
	app.first_scene.on_rune(Vector2.ZERO)
	if app.goal_label.text!="0 / 18":failures.append("first rune event must not jump diamond flight count")
	if app.first_scene.secondary_goal_label.text!="FREE RUNES   1 / 3":failures.append("first rune release displays one freed rune")
	app.first_scene.on_rune(Vector2.ZERO)
	if app.first_scene.secondary_goal_label.text!="FREE RUNES   2 / 3":failures.append("second release remains incremental")
	app._update_hud()
	if app.goal_label.text!="15 / 18" or app.first_scene.secondary_goal_label.text!="FREE RUNES   3 / 3":failures.append("final sync reaches semantic Core state")
	if app.core.collected!=15:failures.append("presentation cannot mutate Core collection")
	app.queue_free();await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://storybook_presentation.json"))
	print("PRESENTATION_ORDER "+JSON.stringify({"checks":5,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL"}));quit(0 if failures.is_empty() else 1)
