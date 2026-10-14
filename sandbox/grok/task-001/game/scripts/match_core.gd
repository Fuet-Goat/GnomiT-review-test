extends RefCounted
## Deterministic match-3 rules. Grid indices are row-major; obstacles split gravity.

const GEM_KINDS := 6
const MAX_CASCADE_WAVES := 32

var cols := 0
var rows := 0
var grid: Array[int] = []
var floor: Array[int] = []
var runes: Array[int] = []
var moves_left := 0
var initial_moves := 0
var collected := 0
var collect_goal := 0
var collect_kind := 0
var won := false
var lost := false

var _goal := "collect"
var _rng := RandomNumberGenerator.new()

func setup(level: Dictionary, seed_value: int = 1) -> void:
	cols = maxi(0, int(level.get("cols", 7)))
	rows = maxi(0, int(level.get("rows", 8)))
	initial_moves = maxi(0, int(level.get("moves", 20)))
	moves_left = initial_moves
	collect_kind = int(level.get("collect_kind", 0))
	collect_goal = maxi(0, int(level.get("collect_goal", 0)))
	collected = 0
	won = false
	lost = false
	_goal = String(level.get("goal", "collect"))
	_rng.seed = seed_value
	grid.resize(cols * rows)
	grid.fill(-1)
	floor.resize(cols * rows)
	floor.fill(0)
	runes.resize(cols * rows)
	runes.fill(0)
	var mask: Variant = level.get("mask", [])
	for y in range(rows):
		for x in range(cols):
			var index := y * cols + x
			var cell := "x"
			if mask is Array and y < mask.size() and x < String(mask[y]).length():
				cell = String(mask[y]).substr(x, 1)
			elif mask is String and index < mask.length():
				cell = mask.substr(index, 1)
			if cell == ".":
				grid[index] = -2
	for value in level.get("target_cells", []):
		var index := int(value)
		if index >= 0 and index < grid.size() and grid[index] != -2:
			floor[index] = 1
	for value in level.get("rune_cells", []):
		var index := int(value)
		if index >= 0 and index < grid.size() and grid[index] != -2:
			runes[index] = 1
			grid[index] = -3
	lost = not _make_playable() or moves_left == 0

func try_swap(a: int, b: int) -> Dictionary:
	var events: Array = []
	if won or lost or not _can_swap(a, b):
		return _result(false, events)
	var before := grid.duplicate()
	_exchange(a, b)
	events.append(_event("swap", before, {"a": a, "b": b}))
	if not _has_match_at(a) and not _has_match_at(b):
		before = grid.duplicate()
		_exchange(a, b)
		events.append(_event("swap", before, {"a": a, "b": b}))
		return _result(false, events)
	moves_left -= 1
	var matches := get_matches()
	var wave := 0
	while not matches.is_empty() and wave < MAX_CASCADE_WAVES:
		_clear(matches, events)
		_fall(events)
		matches = get_matches()
		wave += 1
	# A long cascade or a dead board is rerolled into a stable board with a move.
	if not matches.is_empty() or hint_move().is_empty():
		before = grid.duplicate()
		var playable := _make_playable()
		events.append(_event("shuffle", before))
		if not playable:
			lost = true
	won = _goal_complete()
	lost = not won and (lost or moves_left <= 0)
	return _result(true, events)

func hint_move() -> Array:
	if won or lost:
		return []
	return _find_move()

func get_matches() -> Array[int]:
	var marked: Dictionary = {}
	for y in range(rows):
		var x := 0
		while x < cols:
			var start := x
			var kind := grid[y * cols + x]
			x += 1
			while x < cols and kind >= 0 and grid[y * cols + x] == kind:
				x += 1
			if kind >= 0 and x - start >= 3:
				for match_x in range(start, x):
					marked[y * cols + match_x] = true
	for x in range(cols):
		var y := 0
		while y < rows:
			var start := y
			var kind := grid[y * cols + x]
			y += 1
			while y < rows and kind >= 0 and grid[y * cols + x] == kind:
				y += 1
			if kind >= 0 and y - start >= 3:
				for match_y in range(start, y):
					marked[match_y * cols + x] = true
	var matches: Array[int] = []
	for index in marked:
		matches.append(int(index))
	matches.sort()
	return matches

func _clear(matches: Array[int], events: Array) -> void:
	var before := grid.duplicate()
	var broken: Array[int] = []
	var adjacent_runes: Dictionary = {}
	for index in matches:
		if grid[index] == collect_kind:
			collected += 1
		floor[index] = 0
		for neighbor in _neighbors(index):
			if runes[neighbor] > 0:
				adjacent_runes[neighbor] = true
		grid[index] = -1
	# Use only neighbors of actual matches; liberated runes never chain outward.
	for index in adjacent_runes:
		runes[index] = maxi(0, runes[index] - 1)
		if runes[index] == 0:
			grid[index] = -1
			broken.append(int(index))
	broken.sort()
	events.append(_event("clear", before, {"indices": matches.duplicate(), "matched": matches.duplicate(), "broken_runes": broken}))

func _fall(events: Array) -> void:
	var before := grid.duplicate()
	var falls: Array = []
	var spawn_number := 0
	for x in range(cols):
		var segment: Array[int] = []
		for y in range(rows + 1):
			var index := y * cols + x
			if y < rows and grid[index] != -2 and grid[index] != -3:
				segment.append(index)
			else:
				if not segment.is_empty():
					spawn_number = _fall_segment(segment, falls, spawn_number)
					segment.clear()
	events.append(_event("fall", before, {"falls": falls}))

func _fall_segment(segment: Array[int], falls: Array, spawn_number: int) -> int:
	var gems: Array[Dictionary] = []
	for position in range(segment.size() - 1, -1, -1):
		var index := segment[position]
		if grid[index] >= 0:
			gems.append({"from": index, "kind": grid[index]})
		grid[index] = -1
	var write_position := segment.size() - 1
	for gem in gems:
		var destination := segment[write_position]
		grid[destination] = int(gem["kind"])
		if int(gem["from"]) != destination:
			falls.append({"from": int(gem["from"]), "to": destination, "kind": int(gem["kind"])})
		write_position -= 1
	while write_position >= 0:
		var destination := segment[write_position]
		var kind := _rng.randi_range(0, GEM_KINDS - 1)
		grid[destination] = kind
		spawn_number += 1
		falls.append({"from": -spawn_number, "to": destination, "kind": kind})
		write_position -= 1
	return spawn_number

func _find_move() -> Array:
	for index in range(grid.size()):
		if grid[index] < 0:
			continue
		for neighbor in [index + 1, index + cols]:
			if not _can_swap(index, neighbor) or grid[index] == grid[neighbor]:
				continue
			_exchange(index, neighbor)
			var matches := _has_match_at(index) or _has_match_at(neighbor)
			_exchange(index, neighbor)
			if matches:
				return [index, neighbor]
	return []

func _can_swap(a: int, b: int) -> bool:
	if a < 0 or b < 0 or a >= grid.size() or b >= grid.size() or a == b:
		return false
	if grid[a] < 0 or grid[b] < 0:
		return false
	return absi(a - b) == cols or (absi(a - b) == 1 and maxi(a, b) % cols != 0)

func _has_match_at(index: int) -> bool:
	if grid[index] < 0:
		return false
	var kind := grid[index]
	var count := 1
	var cursor := index - 1
	while cursor >= 0 and (cursor + 1) % cols != 0 and grid[cursor] == kind:
		count += 1
		cursor -= 1
	cursor = index + 1
	while cursor < grid.size() and cursor % cols != 0 and grid[cursor] == kind:
		count += 1
		cursor += 1
	if count >= 3:
		return true
	count = 1
	cursor = index - cols
	while cursor >= 0 and grid[cursor] == kind:
		count += 1
		cursor -= cols
	cursor = index + cols
	while cursor < grid.size() and grid[cursor] == kind:
		count += 1
		cursor += cols
	return count >= 3

func _neighbors(index: int) -> Array[int]:
	var neighbors: Array[int] = []
	if index % cols > 0:
		neighbors.append(index - 1)
	if index % cols < cols - 1:
		neighbors.append(index + 1)
	if index >= cols:
		neighbors.append(index - cols)
	if index + cols < grid.size():
		neighbors.append(index + cols)
	return neighbors

func _make_playable() -> bool:
	for attempt in range(128):
		_fill_stable()
		if not _find_move().is_empty():
			return true
	# Deterministic fallback plants an exchangeable triple on any suitable line.
	return _plant_move()

func _fill_stable() -> void:
	for index in range(grid.size()):
		if grid[index] == -2 or grid[index] == -3:
			continue
		var choices: Array[int] = [0, 1, 2, 3, 4, 5]
		if index % cols >= 2 and grid[index - 1] >= 0 and grid[index - 1] == grid[index - 2]:
			choices.erase(grid[index - 1])
		if index >= cols * 2 and grid[index - cols] >= 0 and grid[index - cols] == grid[index - cols * 2]:
			choices.erase(grid[index - cols])
		grid[index] = choices[_rng.randi_range(0, choices.size() - 1)]

func _plant_move() -> bool:
	var original := grid.duplicate()
	for start in range(grid.size()):
		for step in [1, cols]:
			var triple: Array[int] = [start, start + step, start + step * 2]
			if triple[2] >= grid.size() or (step == 1 and start % cols > cols - 3):
				continue
			if grid[triple[0]] < 0 or grid[triple[1]] < 0 or grid[triple[2]] < 0:
				continue
			for destination in triple:
				for source in _neighbors(destination):
					if source in triple or original[source] < 0:
						continue
					for kind in range(GEM_KINDS):
						for other in range(GEM_KINDS):
							if other == kind:
								continue
							grid.assign(original)
							for index in triple:
								grid[index] = kind
							grid[destination] = other
							grid[source] = kind
							if get_matches().is_empty() and not _find_move().is_empty():
								return true
	grid.assign(original)
	return false

func _goal_complete() -> bool:
	match _goal:
		"floor":
			return floor.count(1) == 0
		"rune":
			return runes.count(1) == 0
		"boss":
			return runes.count(1) == 0 and collected >= collect_goal
		_:
			return collected >= collect_goal

func _exchange(a: int, b: int) -> void:
	var kind := grid[a]
	grid[a] = grid[b]
	grid[b] = kind

func _event(event_type: String, before: Array[int], extra: Dictionary = {}) -> Dictionary:
	var event := {"type": event_type, "before": before, "after": grid.duplicate(), "floor": floor.duplicate(), "runes": runes.duplicate()}
	event.merge(extra)
	return event

func _result(valid: bool, events: Array) -> Dictionary:
	return {"valid": valid, "events": events, "won": won, "lost": lost}
