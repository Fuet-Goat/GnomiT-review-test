extends SceneTree
var checks:=0
var failures: Array[String]=[]
var cues: Array=[]
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures.append(message);print("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func observe(kind: String, strength: float) -> void:cues.append({"kind":kind,"strength":strength})
func fingerprint(c) -> String:return JSON.stringify({"grid":c.grid,"floor":c.floor,"runes":c.runes,"moves":c.moves_left,"rng":c._rng.state})
func run() -> void:
	var core=load("res://scripts/match_core.gd").new();var level=load("res://scripts/levels.gd").get_level("entry")
	core.setup(level,42)
	var board=load("res://scripts/board_view.gd").new();board.polished_art=true;root.add_child(board);board.size=Vector2(688,1000);board.setup(core)
	var supports: bool=board.has_signal("foley_requested")
	check(supports,"board exposes timed rock-foley cues")
	if supports:board.connect("foley_requested",observe)
	var result: Dictionary=core.try_swap(10,11);var committed: String=fingerprint(core)
	check(cues.is_empty(),"resolving Core does not trigger break sounds early")
	await board.animate_result(result)
	var expected: Array=["move"]
	for event in result.events:
		if event.type=="clear":expected.append("break")
	var kinds: Array=[]
	for cue in cues:kinds.append(cue.kind)
	check(kinds==expected,"one scrape then one fracture per actual cascade wave")
	check(fingerprint(core)==committed,"sound playback never changes Core state")
	var normal: Array=kinds.duplicate();cues.clear();core.setup(level,42);board.setup(core,true)
	await board.animate_result(core.try_swap(10,11));kinds.clear()
	for cue in cues:kinds.append(cue.kind)
	check(kinds==normal,"reduced motion retains same meaningful audio cues")
	cues.clear();core.setup(level,42);board.setup(core)
	var bad: Array=[]
	for a in range(core.grid.size()):
		for b in [a+1,a+core.cols]:
			if not core._can_swap(a,b):continue
			var clone=load("res://scripts/match_core.gd").new();clone.setup(level,42)
			if not clone.try_swap(a,b).valid:bad=[a,b];break
		if not bad.is_empty():break
	board._last_swap=bad.duplicate();await board.animate_result(core.try_swap(bad[0],bad[1]))
	check(cues.size()==1 and cues[0].kind=="move","invalid stone movement scrapes once and never fractures")
	check(core.moves_left==core.initial_moves,"invalid sound feedback costs no move")
	board.queue_free();await process_frame
	var app=load("res://scripts/main.gd").new();app.save_path_override="user://rock_audio_tests.json";root.add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);await process_frame;await process_frame;app.progress.reset()
	var bank=app.get("rock_audio")
	check(is_instance_valid(bank),"app has a separate bounded rock audio bank")
	if is_instance_valid(bank):
		check(bank.players.size()>0 and bank.players.size()<=8,"voice pool stays bounded")
		bank.set_enabled(true);bank.play_cue("move",1.0);await process_frame
		var playing:=0
		for player in bank.players:
			if player.playing:playing+=1
		check(playing>0,"selected move OGG is decoded and played")
		bank.set_enabled(false)
		playing=0
		for player in bank.players:
			if player.playing:playing+=1
		check(playing==0,"turning sound off stops pending rock effects")
		bank.play_cue("break",1.0);await process_frame
		for player in bank.players:check(not player.playing,"muted voices stay silent")
		app.progress.set_option("sound",false);app.start_level("entry");await process_frame
		await app._on_swap(10,11)
		for player in bank.players:check(not player.playing,"live app sound setting gates animated cues")
	app.queue_free();await process_frame;await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://rock_audio_tests.json"))
	print("ROCK_AUDIO "+JSON.stringify({"checks":checks,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL"}));quit(0 if failures.is_empty() else 1)
