extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var bank=load("res://scripts/rock_audio.gd").new();root.add_child(bank);await process_frame
	bank.play_cue("move");bank.stop_all();bank.play_cue("move")
	var move_voice: AudioStreamPlayer=bank.players[posmod(bank._next-1,bank.players.size())]
	var move_stream: AudioStream=move_voice.stream
	for i in range(4):
		await create_timer(0.035).timeout;bank.play_cue("break")
	var continuous: bool=move_voice.playing and move_voice.stream==move_stream
	print("VOICE_CONTINUITY "+JSON.stringify({"status":"PASS" if continuous else "FAIL","move_scrape_still_playing":continuous,"elapsed_target_seconds":0.14,"movement_length_seconds":move_stream.get_length(),"voices":bank.players.size()}))
	bank.stop_all()
	for player in bank.players:player.stream=null
	move_stream=null;move_voice=null;await create_timer(0.15).timeout;bank.queue_free();bank=null;await process_frame;await process_frame;quit(0 if continuous else 1)
