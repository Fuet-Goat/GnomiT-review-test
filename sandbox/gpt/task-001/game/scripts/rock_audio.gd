extends Node
## Small independent voice pool: presentation pitch never touches the match RNG.
const MOVE=preload("res://assets/sfx/stone_move_cartoon_selected_v1.ogg")
const BREAK=preload("res://assets/sfx/stone_break_full_v1.wav")
const VOICES:=8
const BUS_NAME: String="GnomiT Stone Foley"
var players: Array[AudioStreamPlayer]=[]
var enabled:=true
var _next:=0
var _variation:=RandomNumberGenerator.new()
func _ready() -> void:
	_variation.randomize()
	if AudioServer.get_bus_index(BUS_NAME)<0:
		AudioServer.add_bus();var index: int=AudioServer.bus_count-1
		AudioServer.set_bus_name(index,BUS_NAME)
		var limiter=AudioEffectHardLimiter.new();limiter.ceiling_db=-3.0
		AudioServer.add_bus_effect(index,limiter)
	for i in VOICES:
		var player=AudioStreamPlayer.new();player.bus=BUS_NAME;add_child(player);players.append(player)
func set_enabled(value: bool) -> void:
	enabled=value
	if not enabled:stop_all()
func stop_all() -> void:
	for player in players:player.stop()
func play_cue(kind: String, strength: float=1.0) -> void:
	if not enabled or players.is_empty() or kind not in ["move","break"]:return
	var slot: int=_next
	# Reuse a finished effect before cutting an active scrape during rapid cascades.
	for offset in range(players.size()):
		var candidate: int=(_next+offset)%players.size()
		if not players[candidate].playing:
			slot=candidate;break
	var player: AudioStreamPlayer=players[slot]
	_next=(slot+1)%players.size()
	player.stop();player.stream=MOVE if kind=="move" else BREAK
	player.pitch_scale=_variation.randf_range(0.96,1.04)
	# Leave mix headroom for overlapping stone contacts and the separate victory chime.
	player.volume_db=(-10.0 if kind=="move" else -9.0)+linear_to_db(clampf(strength,0.7,1.15))
	player.play()
