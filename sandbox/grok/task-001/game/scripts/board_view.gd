extends Control
## A snapshot-driven board. The core may already contain the final cascade state.
## All animation works on local snapshots; the board never mutates the core.
signal swap_requested(a: int, b: int)
signal foley_requested(kind: String, strength: float)
signal goal_piece_cleared(global_center: Vector2)
signal terrain_target_cleared(global_center: Vector2)
signal rune_freed(global_center: Vector2)
const Art=preload("res://scripts/story_art.gd")
var polished_art := false
var _gem_atlas: Texture2D
var _gem_textures: Array = []
var _polished_styles: Array = []
var _terrain_styles: Array = []
var _soil_fade_styles: Array = []
# Presentation-only excavation: goals and gameplay remain owned by Core.
var _excavated: Dictionary = {}

const GEM_COLORS := [Color("ef537a"), Color("ab86f5"), Color("ffb449"), Color("48bfe8"), Color("5cdbac"), Color("f8e9a2")]
const HOLE := -2
const RUNE := -3

var busy := false
var reduced_motion := false
var _core: RefCounted
var _cols := 7
var _rows := 8
var _display_grid: Array = []
var _display_floor: Array = []
var _display_runes: Array = []
var _selected := -1
var _pressed := -1
var _press_position := Vector2.ZERO
var _pointer_position := Vector2.ZERO
var _last_swap: Array = []
var _hint: Array = []
var _hint_until := 0.0
var _clock := 0.0
var _epoch := 0
var _tween: Tween
var _moving: Array = []
var _hidden: Dictionary = {}
var _clearing: Dictionary = {}
var _releases: Dictionary = {}
var _particles: Array = []
var _motion_t := 0.0
var _landing_t := 0.0
var _effect_t := 0.0
var _shuffle_t := 0.0
var _invalid := false
var _hover := -1
var _falling := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(300, 350)
	clip_contents = true
	mouse_exited.connect(func() -> void: _hover = -1; queue_redraw())
	resized.connect(queue_redraw)
	if polished_art:
		_gem_atlas=Art.TREASURES
		for kind in range(6):
			var texture=AtlasTexture.new();texture.atlas=_gem_atlas
			texture.region=Rect2(Vector2(kind%3,kind/3)*Vector2(_gem_atlas.get_width()/3.0,_gem_atlas.get_height()/2.0),Vector2(_gem_atlas.get_width()/3.0,_gem_atlas.get_height()/2.0))
			_gem_textures.append(texture)
		for color in [Color("244c60"),Color("28586b")]:
			var skin=StyleBoxFlat.new();skin.bg_color=color;skin.border_color=Color("73a4a7");skin.set_border_width_all(1);skin.set_corner_radius_all(9);_polished_styles.append(skin)
		for color in [Color("95673e"),Color("a87444")]:
			var soil=StyleBoxFlat.new();soil.bg_color=color;soil.border_color=Color("e6b471");soil.set_border_width_all(2);soil.set_corner_radius_all(11);_terrain_styles.append(soil);_soil_fade_styles.append(soil.duplicate())
	set_process(true)

func setup(core: RefCounted, reduced: bool = false) -> void:
	_epoch += 1
	if is_instance_valid(_tween):
		_tween.kill()
	_core = core
	reduced_motion = reduced
	_cols = int(core.get("cols"))
	_rows = int(core.get("rows"))
	_display_grid = _copy_array(core.get("grid"))
	_display_floor = _copy_array(core.get("floor"))
	_display_runes = _copy_array(core.get("runes"))
	_selected = -1
	_pressed = -1
	_hint.clear()
	_last_swap.clear()
	_moving.clear()
	_hidden.clear()
	_clearing.clear()
	_releases.clear()
	_particles.clear()
	_excavated.clear()
	_invalid = false
	_shuffle_t = 0.0
	busy = false
	queue_redraw()

func _copy_array(value: Variant) -> Array:
	if value == null:
		return []
	return Array(value).duplicate()

func _board_rect() -> Rect2:
	var cell_size: float = maxf(1.0, minf((size.x - 28.0) / maxf(1.0, float(_cols)), (size.y - 28.0) / maxf(1.0, float(_rows))))
	var extent := Vector2(cell_size * _cols, cell_size * _rows)
	return Rect2((size - extent) * 0.5, extent)

func _cell_size() -> float:
	return _board_rect().size.x / maxf(1.0, float(_cols))

func _center(index: int) -> Vector2:
	var board := _board_rect()
	var step := _cell_size()
	return board.position + Vector2(float(index % _cols) + 0.5, float(index / _cols) + 0.5) * step

func _cell_at(point: Vector2) -> int:
	var board := _board_rect()
	if not board.has_point(point):
		return -1
	var local := point - board.position
	var index: int = int(local.y / _cell_size()) * _cols + int(local.x / _cell_size())
	return index if _is_gem(index) else -1

func _is_gem(index: int) -> bool:
	return index >= 0 and index < _display_grid.size() and int(_display_grid[index]) >= 0

func _neighbors(a: int, b: int) -> bool:
	return absi(a % _cols - b % _cols) + absi(a / _cols - b / _cols) == 1

func _gui_input(event: InputEvent) -> void:
	if busy or _core == null:
		return
	# Native mouse and touch are both supported; discard their synthetic duplicates.
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(event.position)
		else:
			_release(event.position)
		accept_event()
	elif event is InputEventMouseMotion:
		_pointer_position = event.position
		_hover = _cell_at(event.position)
		queue_redraw()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_press(event.position)
		else:
			_release(event.position)
		accept_event()
	elif event is InputEventScreenDrag:
		_pointer_position = event.position
		queue_redraw()
		accept_event()

func _press(point: Vector2) -> void:
	_pressed = _cell_at(point)
	_press_position = point
	_pointer_position = point
	_hint.clear()
	if _pressed < 0:
		_selected = -1
	queue_redraw()

func _release(point: Vector2) -> void:
	var index := _cell_at(point)
	if _pressed < 0 or index < 0:
		_selected = -1
		_pressed = -1
		queue_redraw()
		return
	if point.distance_to(_press_position) > _cell_size() * 0.24:
		if _neighbors(_pressed, index):
			_request_swap(_pressed, index)
		else:
			_selected = -1
	elif _selected == index:
		_selected = -1
	elif _selected >= 0:
		if _neighbors(_selected, index):
			_request_swap(_selected, index)
		else:
			_selected = -1
	else:
		_selected = index
	_pressed = -1
	queue_redraw()

func _request_swap(a: int, b: int) -> void:
	_selected = -1
	_hint.clear()
	_last_swap = [a, b]
	swap_requested.emit(a, b)

func show_hint(pair: Array) -> void:
	_selected = -1
	_hint.clear()
	if not busy and pair.size() == 2 and _is_gem(int(pair[0])) and _is_gem(int(pair[1])) and _neighbors(int(pair[0]), int(pair[1])):
		_hint = pair.duplicate()
		_hint_until = _clock + 4.0
	queue_redraw()

func animate_result(result: Dictionary) -> void:
	if _core == null:
		return
	_epoch += 1
	var epoch := _epoch
	busy = true
	_selected = -1
	_pressed = -1
	_hint.clear()
	_invalid = false
	var events: Array = result.get("events", [])
	var move_cued:=false
	for event in events:
		if epoch != _epoch or not is_inside_tree():
			return
		if event.has("before"):
			_display_grid = _copy_array(event["before"])
		var event_type := String(event.get("type", ""))
		if event_type=="swap" and not move_cued and _is_gem(int(event.get("a",-1))) and _is_gem(int(event.get("b",-1))):
			foley_requested.emit("move",1.0);move_cued=true
		if reduced_motion:
			if event_type == "clear":
				_prepare_clear(event)
				_effect_t = 0.7
				queue_redraw()
				await _wait(0.055)
			else:
				queue_redraw()
				await _wait(0.035)
		else:
			match event_type:
				"swap", "swap_back", "revert":
					await _animate_swap(event, epoch)
				"clear":
					await _animate_clear(event, epoch)
				"fall":
					await _animate_fall(event, epoch)
				"shuffle":
					await _animate_shuffle(epoch)
				_:
					await _wait(0.04)
		if epoch != _epoch:
			return
		_apply_after(event)
		_clearing.clear()
		_releases.clear()
		queue_redraw()
	if not bool(result.get("valid", false)):
		_invalid = true
		if events.is_empty() and _last_swap.size()==2 and _is_gem(int(_last_swap[0])) and _is_gem(int(_last_swap[1])):
			foley_requested.emit("move",0.85)
		if events.is_empty() and _last_swap.size() == 2 and not reduced_motion:
			var before := _display_grid.duplicate()
			await _animate_swap({"a": _last_swap[0], "b": _last_swap[1], "before": before}, epoch)
			if epoch != _epoch:
				return
			var middle := before.duplicate()
			middle[int(_last_swap[0])] = before[int(_last_swap[1])]
			middle[int(_last_swap[1])] = before[int(_last_swap[0])]
			_display_grid = middle
			await _animate_swap({"a": _last_swap[0], "b": _last_swap[1], "before": middle}, epoch)
		queue_redraw()
		await _wait(0.08 if reduced_motion else 0.16)
	if epoch != _epoch:
		return
	_display_grid = _copy_array(_core.get("grid"))
	_display_floor = _copy_array(_core.get("floor"))
	_display_runes = _copy_array(_core.get("runes"))
	_moving.clear()
	_hidden.clear()
	_clearing.clear()
	_releases.clear()
	_invalid = false
	_last_swap.clear()
	busy = false
	queue_redraw()

func _apply_after(event: Dictionary) -> void:
	if polished_art and String(event.get("type",""))=="clear":
		for index in event.get("indices",event.get("matched",[])):
			_excavated[int(index)]=true
	if event.has("after"):
		_display_grid = _copy_array(event["after"])
	if event.has("floor"):
		_display_floor = _copy_array(event["floor"])
	if event.has("runes"):
		_display_runes = _copy_array(event["runes"])

func _wait(seconds: float) -> void:
	if is_inside_tree():
		await get_tree().create_timer(seconds, false).timeout

func _animate_swap(event: Dictionary, epoch: int) -> void:
	var a := int(event.get("a", -1))
	var b := int(event.get("b", -1))
	if not _is_gem(a) or not _is_gem(b):
		await _wait(0.05)
		return
	_moving = [{"from": a, "to": b, "kind": int(_display_grid[a])}, {"from": b, "to": a, "kind": int(_display_grid[b])}]
	_hidden = {a: true, b: true}
	_motion_t = 0.0
	_falling = false
	_tween = create_tween()
	_tween.tween_property(self, "_motion_t", 1.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	queue_redraw()
	await _wait(0.19)
	if epoch == _epoch:
		_motion_t = 1.0
		_moving.clear()
		_hidden.clear()

func _prepare_clear(event: Dictionary) -> void:
	var cleared: Array=event.get("indices",event.get("matched",[]))
	if not cleared.is_empty():foley_requested.emit("break",clampf(0.7+cleared.size()*0.035,0.8,1.15))
	_clearing.clear()
	_releases.clear()
	for raw_index in event.get("indices", event.get("matched", [])):
		var index := int(raw_index)
		_clearing[index] = true
		if polished_art and _is_gem(index) and _core.collect_goal>0 and int(_display_grid[index])==_core.collect_kind:
			goal_piece_cleared.emit(get_global_transform()*_center(index))
		if _is_gem(index) and not reduced_motion:
			_spawn_burst(_center(index), GEM_COLORS[int(_display_grid[index]) % 6], 10 if polished_art else 8,"chip" if int(_display_grid[index]) in [1,2,3,4] else "light")
			if polished_art and not _excavated.has(index):
				_spawn_burst(_center(index)+Vector2(0,_cell_size()*0.2),Color("a97948"),9,"soil")
	var next_floor: Array = _copy_array(event.get("floor", _display_floor))
	for index in range(mini(_display_floor.size(), next_floor.size())):
		if int(_display_floor[index]) > 0 and int(next_floor[index]) == 0:
			_releases[index] = true
			terrain_target_cleared.emit(get_global_transform()*_center(index))
			if not reduced_motion:
				_spawn_burst(_center(index), Color("ffcf6b"), 9)
	for raw_index in event.get("broken_runes", []):
		var index := int(raw_index)
		_releases[index] = true
		rune_freed.emit(get_global_transform()*_center(index))
		if not reduced_motion:
			_spawn_burst(_center(index), Color("bdefff"), 14)

func _animate_clear(event: Dictionary, epoch: int) -> void:
	_prepare_clear(event)
	_effect_t = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "_effect_t", 1.0, 0.23).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	queue_redraw()
	await _wait(0.24)
	if epoch == _epoch:
		_effect_t = 1.0

func _animate_fall(event: Dictionary, epoch: int) -> void:
	_moving.clear()
	_hidden.clear()
	var spawn_counts: Dictionary = {}
	var longest := 1.0
	for fall in event.get("falls", []):
		var source := int(fall.get("from", -1))
		var target := int(fall.get("to", -1))
		if target < 0 or target >= _display_grid.size():
			continue
		var motion: Dictionary = {"from": source, "to": target, "kind": int(fall.get("kind", 0))}
		if source < 0:
			var column := target % _cols
			var segment_top := target / _cols
			while segment_top > 0:
				var above := (segment_top - 1) * _cols + column
				if int(_display_grid[above]) == HOLE or int(_display_grid[above]) == RUNE:
					break
				segment_top -= 1
			var segment_key := segment_top * _cols + column
			var count := int(spawn_counts.get(segment_key, 0))
			spawn_counts[segment_key] = count + 1
			motion["spawn_row"] = float(segment_top - 1 - count)
			longest = maxf(longest, float(target / _cols) - float(motion["spawn_row"]))
		else:
			_hidden[source] = true
			longest = maxf(longest, float(target / _cols - source / _cols))
		_hidden[target] = true
		_moving.append(motion)
	_motion_t = 0.0
	_landing_t = 0.0
	_falling = true
	var duration := clampf(0.16 + longest * 0.025, 0.20, 0.42)
	_tween = create_tween()
	_tween.tween_property(self, "_motion_t", 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "_landing_t", 1.0, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	queue_redraw()
	await _wait(duration + 0.11)
	if epoch == _epoch:
		_motion_t = 1.0
		_landing_t = 1.0
		_moving.clear()
		_hidden.clear()
		_falling = false

func _animate_shuffle(epoch: int) -> void:
	_shuffle_t = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "_shuffle_t", 1.0, 0.24)
	await _wait(0.25)
	if epoch == _epoch:
		_shuffle_t = 0.0

func _process(delta: float) -> void:
	_clock += delta
	if not _hint.is_empty() and _clock > _hint_until:
		_hint.clear()
	for index in range(_particles.size() - 1, -1, -1):
		var particle: Dictionary = _particles[index]
		particle["age"] = float(particle["age"]) + delta
		particle["position"] = Vector2(particle["position"]) + Vector2(particle["velocity"]) * delta
		particle["velocity"] = Vector2(particle["velocity"]) + Vector2(0, 75) * delta
		if float(particle["age"]) >= float(particle["life"]):
			_particles.remove_at(index)
	queue_redraw()

func _spawn_burst(point: Vector2, color: Color, count: int, material: String="light") -> void:
	for index in range(count):
		var angle := TAU * float(index) / float(count) + float(index % 3) * 0.17
		var speed := _cell_size() * (1.0 + float(index % 4) * 0.23)
		_particles.append({"position": point, "velocity": Vector2.from_angle(angle) * speed, "color": color, "age": 0.0, "life": 0.38 + float(index % 3) * 0.06, "size": (3.0 if material=="soil" else 1.6) + float(index % 3), "material": material})
	while _particles.size() > 220:
		_particles.pop_front()

func _draw() -> void:
	if _display_grid.is_empty() or _cols <= 0 or _rows <= 0:
		return
	var step := _cell_size()
	for index in range(_display_grid.size()):
		if int(_display_grid[index]) == HOLE:
			continue
		_draw_cell(index, step)
	for index in range(_display_grid.size()):
		var kind := int(_display_grid[index])
		if kind >= 0 and not _hidden.has(index):
			var shrink := 1.0
			var alpha := 1.0
			if _clearing.has(index):
				shrink = 1.0 + sin(minf(1.0,_effect_t*2.6) * PI) * 0.27 - pow(_effect_t,1.6) * 0.86
				alpha = 1.0 - _effect_t
			elif _shuffle_t > 0.0:
				shrink = 1.0 - sin(_shuffle_t * PI) * 0.7
			var gem_center: Vector2=_center(index)
			if polished_art and (index==_selected or index==_pressed):
				gem_center.y-=step*0.035;shrink*=1.08
			_draw_gem(gem_center, kind, step * 0.36 * shrink, alpha)
		elif kind == RUNE:
			_draw_rune(_center(index), step, index)
	for motion in _moving:
		var target := int(motion["to"])
		var end := _center(target)
		var start := _center(int(motion["from"])) if int(motion["from"]) >= 0 else Vector2(end.x, _board_rect().position.y + (float(motion.get("spawn_row", -1.0)) + 0.5) * step)
		var point := start.lerp(end, _motion_t)
		if _falling and _motion_t >= 0.999:
			point.y -= sin(_landing_t * PI) * step * 0.065
		var squish:=Vector2.ONE
		if polished_art and _falling:
			if _motion_t<0.999:squish=Vector2(0.95,1.06)
			else:squish=Vector2(1.0+sin(_landing_t*TAU)*0.10,1.0-sin(_landing_t*TAU)*0.11)
		_draw_gem(point, int(motion["kind"]), step * 0.36, 1.0,squish)
	for index in _clearing:
		var color: Color = GEM_COLORS[int(_display_grid[index]) % 6] if _is_gem(int(index)) else Color("fce7ba")
		color.a = 1.0 - _effect_t
		draw_arc(_center(int(index)), step * (0.20 + _effect_t * 0.38), 0.0, TAU, 32, color, 2.2, true)
		if polished_art:
			draw_circle(_center(int(index)),step*(0.22+_effect_t*0.18),Color(1,1,0.9,(1-_effect_t)*0.15),true,-1,true)
			_draw_sparkle(_center(int(index)),step*(0.15+_effect_t*0.32),Color(1,1,0.85,1-_effect_t))
	for index in _releases:
		var color := Color(1.0, 0.83, 0.45, 1.0 - _effect_t)
		draw_arc(_center(int(index)), step * (0.38 + _effect_t * 0.12), 0.0, TAU, 32, color, 3.0, true)
		_draw_sparkle(_center(int(index)), step * (0.20 + _effect_t * 0.13), color)
	if _selected >= 0:
		_draw_selection(_selected, Color("ffdc8d"), 1.0)
	if _pressed >= 0 and _selected != _pressed:
		_draw_selection(_pressed, Color("e7f5ff"), 0.55)
	if _hover >= 0 and not busy and _selected != _hover:
		_draw_selection(_hover, Color("abd6db"), 0.22)
	for index in _hint:
		var intensity := 0.75 if reduced_motion else 0.60 + sin(_clock * 5.0) * 0.22
		_draw_selection(int(index), Color("ffecaf"), intensity)
		_draw_sparkle(_center(int(index)) + Vector2(step * 0.27, -step * 0.27), step * 0.065, Color(1.0, 0.94, 0.68, intensity))
	if _hint.size() == 2:
		draw_line(_center(int(_hint[0])), _center(int(_hint[1])), Color(1.0, 0.91, 0.61, 0.5), 2.0, true)
	if _invalid:
		for index in _last_swap:
			_draw_selection(int(index), Color("fb8279"), 0.8)
	for particle in _particles:
		var color: Color = particle["color"]
		color.a = 1.0 - float(particle["age"]) / float(particle["life"])
		if String(particle.get("material","light")) in ["soil","chip"]:
			var p: Vector2=particle["position"];var r: float=particle["size"]
			draw_colored_polygon(PackedVector2Array([p+Vector2(-r,-r*0.6),p+Vector2(r*0.7,-r),p+Vector2(r,r*0.6),p+Vector2(-r*0.7,r)]),color)
		else:_draw_sparkle(Vector2(particle["position"]), float(particle["size"]), color)

func _draw_cell(index: int, step: float) -> void:
	var center := _center(index)
	var rect := Rect2(center - Vector2.ONE * step * 0.5, Vector2.ONE * step)
	if polished_art and not _polished_styles.is_empty():
		var parity: int=(index%_cols+int(index/_cols))%2
		var dug: bool=_excavated.has(index)
		var skin: StyleBoxFlat=_polished_styles[parity] if dug else _terrain_styles[parity]
		if not dug and _clearing.has(index):
			var fade: StyleBoxFlat=_soil_fade_styles[parity]
			fade.bg_color=skin.bg_color.lerp(_polished_styles[parity].bg_color,_effect_t)
			fade.border_color=skin.border_color.lerp(_polished_styles[parity].border_color,_effect_t)
			skin=fade
		skin.draw(get_canvas_item(),rect.grow(-2.0))
		if not dug:
			var soil_alpha: float=1.0-_effect_t if _clearing.has(index) else 1.0
			for grain in range(3):
				var offset:=Vector2(-0.33+grain*0.32,0.34-0.03*(index%3))*step
				draw_circle(center+offset,step*(0.014+grain*0.004),Color(0.36,0.23,0.12,soil_alpha*0.6),true,-1,true)
		else:
			draw_line(center+Vector2(-0.34,0.3)*step,center+Vector2(-0.2,0.34)*step,Color(0.68,0.85,0.88,0.26),1.5,true)
		var pos:=Vector2i(index%_cols,int(index/_cols))
		var dirs: Array=[Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]
		var bounds: Array=[[rect.position,rect.position+Vector2(0,step)],[rect.position+Vector2(step,0),rect.end],[rect.position,rect.position+Vector2(step,0)],[rect.position+Vector2(0,step),rect.end]]
		for side in range(4):
			var neighbor: Vector2i=pos+dirs[side]
			var exposed: bool=neighbor.x<0 or neighbor.x>=_cols or neighbor.y<0 or neighbor.y>=_rows
			if not exposed:exposed=int(_display_grid[neighbor.y*_cols+neighbor.x])==HOLE
			if exposed:
				draw_line(bounds[side][0],bounds[side][1],Color("233d52"),8,true)
				draw_line(bounds[side][0],bounds[side][1],Color("8fdef4"),3,true)
		if index<_display_floor.size() and int(_display_floor[index])>0:
			draw_rect(rect.grow(-5),Color("ffe095"),false,3.0,true)
			_draw_sparkle(center+Vector2(-0.33,0.32)*step,step*0.075,Color("ffeaaa"))
		return
	draw_rect(rect.grow(-1.0), Color("112939"))
	draw_rect(rect.grow(-4.0), Color("183445"))
	draw_line(rect.position + Vector2(4, 5), rect.position + Vector2(step - 4, 5), Color(0.31, 0.46, 0.50, 0.28), 1.0, true)
	draw_rect(rect.grow(-1.5), Color("4a3a31"), false, 3.0)
	draw_rect(rect.grow(-3.0), Color("8f7851"), false, 1.0)
	var amber := index < _display_floor.size() and int(_display_floor[index]) > 0
	if amber:
		draw_rect(rect.grow(-5.0), Color(0.97, 0.68, 0.22, 0.8), false, 2.0)
		_draw_sparkle(center + Vector2(-step * 0.34, step * 0.34), step * 0.055, Color("ffcd70"))
	var x := index % _cols
	var y := index / _cols
	var directions := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	var edges := [[rect.position, rect.position + Vector2(0, step)], [rect.position + Vector2(step, 0), rect.end], [rect.position, rect.position + Vector2(step, 0)], [rect.position + Vector2(0, step), rect.end]]
	for side in range(4):
		var neighbor: Vector2i = Vector2i(x, y) + directions[side]
		var exposed := neighbor.x < 0 or neighbor.x >= _cols or neighbor.y < 0 or neighbor.y >= _rows
		if not exposed:
			exposed = int(_display_grid[neighbor.y * _cols + neighbor.x]) == HOLE
		if exposed:
			draw_line(edges[side][0], edges[side][1], Color("543d2c"), 8.0, true)
			draw_line(edges[side][0], edges[side][1], Color("b49862"), 2.0, true)

func _gem_shape(kind: int) -> PackedVector2Array:
	match kind % 6:
		0:
			return PackedVector2Array([Vector2(0, -1.10), Vector2(0.86, 0), Vector2(0, 1.10), Vector2(-0.86, 0)])
		1:
			return PackedVector2Array([Vector2(-0.50, -0.92), Vector2(0.50, -0.92), Vector2(0.85, -0.53), Vector2(0.85, 0.55), Vector2(0.48, 0.92), Vector2(-0.48, 0.92), Vector2(-0.85, 0.55), Vector2(-0.85, -0.53)])
		2:
			return PackedVector2Array([Vector2(0, -1.0), Vector2(1.02, 0.82), Vector2(-1.02, 0.82)])
		3:
			return PackedVector2Array([Vector2(0, -1.02), Vector2(0.89, -0.52), Vector2(0.89, 0.52), Vector2(0, 1.02), Vector2(-0.89, 0.52), Vector2(-0.89, -0.52)])
		4:
			return PackedVector2Array([Vector2(0.30, -1.1), Vector2(0.86, -0.38), Vector2(0.73, 0.39), Vector2(0, 0.95), Vector2(-0.74, 0.51), Vector2(-0.78, -0.23), Vector2(-0.36, -0.78)])
		_:
			return PackedVector2Array([Vector2(0, -1.08), Vector2(0.32, -0.34), Vector2(1.0, 0), Vector2(0.32, 0.34), Vector2(0, 1.08), Vector2(-0.32, 0.34), Vector2(-1.0, 0), Vector2(-0.32, -0.34)])

func _draw_gem(center: Vector2, kind: int, radius: float, alpha: float, stretch: Vector2=Vector2.ONE) -> void:
	if alpha <= 0.0 or radius < 0.3:
		return
	if polished_art and not _gem_textures.is_empty():
		var extent: Vector2=Vector2.ONE*radius*2.65*stretch
		draw_texture_rect(_gem_textures[kind%6],Rect2(center-extent*0.5,extent),false,Color(1,1,1,alpha))
		return
	var color: Color = GEM_COLORS[kind % 6]
	color.a = alpha
	var outline := _gem_shape(kind)
	var points := PackedVector2Array()
	var shadow := PackedVector2Array()
	for point in outline:
		points.append(center + point * radius)
		shadow.append(center + point * radius + Vector2(0, radius * 0.14))
	draw_colored_polygon(shadow, Color(0.01, 0.035, 0.06, alpha * 0.7))
	draw_colored_polygon(points, color.darkened(0.24))
	var inner := PackedVector2Array()
	for point in outline:
		inner.append(center + point * radius * 0.81)
	draw_colored_polygon(inner, color)
	var facet_center := center + Vector2(-radius * 0.10, -radius * 0.08)
	for index in range(inner.size()):
		var facet_color := color.lightened(0.26) if index < inner.size() / 2 else color.darkened(0.18)
		facet_color.a = alpha
		draw_colored_polygon(PackedVector2Array([facet_center, inner[index], inner[(index + 1) % inner.size()]]), facet_color)
	var contour := points.duplicate()
	contour.append(points[0])
	draw_polyline(contour, Color(color.r * 0.55, color.g * 0.62, color.b * 0.7, alpha), 1.5, true)
	draw_line(center + Vector2(-radius * 0.31, -radius * 0.40), center + Vector2(radius * 0.07, -radius * 0.60), Color(1, 1, 0.94, alpha * 0.8), maxf(1.5, radius * 0.065), true)
	draw_circle(center + Vector2(-radius * 0.31, -radius * 0.40), maxf(1.0, radius * 0.055), Color(1, 1, 1, alpha * 0.9), true, -1.0, true)

func _draw_rune(center: Vector2, step: float, index: int) -> void:
	if polished_art:
		draw_texture_rect(Art.material(5),Rect2(center-Vector2.ONE*step*0.47,Vector2.ONE*step*0.94),false)
		for pip in range(mini(3,int(_display_runes[index]))):
			draw_circle(center+Vector2((pip-1)*step*0.12,step*0.30),step*0.035,Color("ffe9a2"),true,-1,true)
		return
	var glow := 0.12 if reduced_motion else 0.12 + sin(_clock * 2.2 + float(index)) * 0.03
	draw_circle(center, step * 0.42, Color(0.40, 0.72, 0.91, glow), true, -1.0, true)
	var radius := step * 0.34
	var stone := PackedVector2Array([center + Vector2(-0.75, -0.80) * radius, center + Vector2(0.57, -1.0) * radius, center + Vector2(0.95, -0.33) * radius, center + Vector2(0.73, 0.88) * radius, center + Vector2(-0.57, 0.94) * radius, center + Vector2(-0.95, 0.2) * radius])
	draw_colored_polygon(stone, Color("465362"))
	var contour := stone.duplicate()
	contour.append(stone[0])
	draw_polyline(contour, Color("8496a7"), 2.0, true)
	var rune_color := Color("e8d694")
	draw_line(center + Vector2(0, -radius * 0.66), center + Vector2(0, radius * 0.62), rune_color, 2.4, true)
	draw_polyline(PackedVector2Array([center + Vector2(-radius * 0.5, -radius * 0.36), center + Vector2(0, -radius * 0.66), center + Vector2(radius * 0.49, -radius * 0.33), center + Vector2(0, -radius * 0.03), center + Vector2(-radius * 0.43, radius * 0.27)]), rune_color, 2.4, true)
	if index < _display_runes.size():
		for pip in range(mini(3, int(_display_runes[index]))):
			draw_circle(center + Vector2((float(pip) - float(mini(3, int(_display_runes[index])) - 1) * 0.5) * step * 0.10, step * 0.29), step * 0.025, rune_color, true, -1.0, true)

func _draw_selection(index: int, color: Color, alpha: float) -> void:
	if index < 0 or index >= _display_grid.size():
		return
	var step := _cell_size()
	color.a *= alpha
	var rect := Rect2(_center(index) - Vector2.ONE * step * 0.435, Vector2.ONE * step * 0.87)
	draw_rect(rect, color, false, 2.5, true)
	color.a *= 0.16
	draw_rect(rect.grow(-1.0), color)

func _draw_sparkle(center: Vector2, radius: float, color: Color) -> void:
	draw_line(center - Vector2(radius, 0), center + Vector2(radius, 0), color, 1.4, true)
	draw_line(center - Vector2(0, radius), center + Vector2(0, radius), color, 1.4, true)
	draw_circle(center, radius * 0.25, color, true, -1.0, true)
