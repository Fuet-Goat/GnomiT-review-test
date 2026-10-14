extends SceneTree

const Core = preload("res://scripts/match_core.gd")
const Levels = preload("res://scripts/levels.gd")
const SEEDS := [1, 7, 19, 42, 73]
const BEAM_WIDTH := 6
const BUDGET_MS := 52000
var started := 0
var checks := 0
var failures: Array[String] = []
var runs: Array[Dictionary] = []

func _initialize() -> void:
	started = Time.get_ticks_msec()
	test_stars()
	for level in Levels.all():
		validate_catalog(level)
		for seed_value in SEEDS:
			if Time.get_ticks_msec() - started > BUDGET_MS:
				failures.append("solver time budget reached before %s seed %d" % [level["id"], seed_value])
				finish()
				return
			runs.append(play(level, seed_value))
	finish()

func test_stars() -> void:
	check(Levels.stars_for(0, 26) == 1, "last-move win earns one star")
	check(Levels.stars_for(6, 26) == 1, "below 25 percent earns one star")
	check(Levels.stars_for(7, 26) == 2, "ceil 25 percent earns two stars")
	check(Levels.stars_for(12, 26) == 2, "below 50 percent earns two stars")
	check(Levels.stars_for(13, 26) == 3, "50 percent earns three stars")
	check(Levels.stars_for(5, 20) == 2 and Levels.stars_for(10, 20) == 3, "exact integer thresholds earn two and three stars")

	for sample in [[30, 0, 1], [30, 7, 1], [30, 8, 2], [30, 14, 2], [30, 15, 3], [32, 0, 1], [32, 7, 1], [32, 8, 2], [32, 15, 2], [32, 16, 3], [34, 0, 1], [34, 8, 1], [34, 9, 2], [34, 16, 2], [34, 17, 3], [38, 0, 1], [38, 9, 1], [38, 10, 2], [38, 18, 2], [38, 19, 3]]:
		check(Levels.stars_for(sample[1], sample[0]) == sample[2], "catalog budget %d with %d moves left earns %d stars" % sample)

func validate_catalog(level: Dictionary) -> void:
	var cols := int(level["cols"])
	var rows := int(level["rows"])
	check(level["mask"].size() == rows, "%s has expected mask row count" % level["id"])
	for row in level["mask"]:
		check(String(row).length() == cols, "%s has expected mask width" % level["id"])
	for key in ["target_cells", "rune_cells"]:
		var seen: Dictionary = {}
		for value in level[key]:
			var index := int(value)
			check(index >= 0 and index < cols * rows, "%s %s index is in bounds" % [level["id"], key])
			if index < 0 or index >= cols * rows:
				continue
			var row := int(float(index) / float(cols))
			check(String(level["mask"][row]).substr(index % cols, 1) != ".", "%s %s is on active mask cell" % [level["id"], key])
			check(not seen.has(index), "%s %s contains no duplicate index" % [level["id"], key])
			seen[index] = true
	var core = Core.new()
	core.setup(level, 1)
	check(core.floor.count(1) == level["target_cells"].size(), "%s materializes every floor target" % level["id"])
	check(core.runes.count(1) == level["rune_cells"].size(), "%s materializes every rune target" % level["id"])
	for value in level["target_cells"]:
		var index := int(value)
		check(has_match_line(core, index), "%s floor target can belong to a physical three-cell line" % level["id"])
	for value in level["rune_cells"]:
		var index := int(value)
		var reachable := false
		for neighbor in core._neighbors(index):
			if core.grid[neighbor] >= 0 and has_match_line(core, neighbor):
				reachable = true
		check(reachable, "%s rune has an adjacent cell in a physical match line" % level["id"])

func has_match_line(core: RefCounted, index: int) -> bool:
	for step in [1, core.cols]:
		for offset in range(3):
			var start: int = index - offset * int(step)
			var last: int = start + 2 * int(step)
			if start < 0 or last >= core.grid.size():
				continue
			if step == 1 and start % core.cols > core.cols - 3:
				continue
			if core.grid[start] != -2 and core.grid[start + step] != -2 and core.grid[last] != -2:
				return true
	return false

func clone_core(source: RefCounted) -> RefCounted:
	var copy = Core.new()
	copy.cols = source.cols
	copy.rows = source.rows
	copy.grid.assign(source.grid)
	copy.floor.assign(source.floor)
	copy.runes.assign(source.runes)
	copy.moves_left = source.moves_left
	copy.initial_moves = source.initial_moves
	copy.collected = source.collected
	copy.collect_goal = source.collect_goal
	copy.collect_kind = source.collect_kind
	copy.won = source.won
	copy.lost = source.lost
	copy._goal = source._goal
	copy._rng.seed = source._rng.seed
	copy._rng.state = source._rng.state
	return copy

func legal_pairs(core: RefCounted) -> Array:
	var pairs: Array = []
	if core.won or core.lost:
		return pairs
	for index in range(core.grid.size()):
		for neighbor in [index + 1, index + core.cols]:
			if not core._can_swap(index, neighbor) or core.grid[index] == core.grid[neighbor]:
				continue
			core._exchange(index, neighbor)
			var valid: bool = core._has_match_at(index) or core._has_match_at(neighbor)
			core._exchange(index, neighbor)
			if valid:
				pairs.append([index, neighbor])
	return pairs

func objective_score(core: RefCounted, level: Dictionary) -> float:
	if core.won:
		return 100000.0 + float(core.moves_left)
	match String(level["goal"]):
		"floor":
			return float(level["target_cells"].size() - core.floor.count(1)) * 100.0
		"rune":
			return float(level["rune_cells"].size() - core.runes.count(1)) * 200.0
		"boss":
			return float(level["rune_cells"].size() - core.runes.count(1)) * 200.0 + float(mini(core.collected, core.collect_goal)) * 20.0
		_:
			return float(mini(core.collected, core.collect_goal)) * 100.0

func potential(core: RefCounted, level: Dictionary) -> float:
	var cells: Array[int] = []
	if String(level["goal"]) == "floor":
		for index in range(core.floor.size()):
			if core.floor[index] == 1:
				cells.append(index)
	elif String(level["goal"]) in ["rune", "boss"]:
		for index in range(core.runes.size()):
			if core.runes[index] == 1:
				for neighbor in core._neighbors(index):
					if core.grid[neighbor] >= 0:
						cells.append(neighbor)
	var result := 0.0
	for index in cells:
		var best := 0
		for step in [1, core.cols]:
			for offset in range(3):
				var start: int = index - offset * int(step)
				var last: int = start + 2 * int(step)
				if start < 0 or last >= core.grid.size() or (step == 1 and start % core.cols > core.cols - 3):
					continue
				if core.grid[start] < 0 or core.grid[start + step] < 0 or core.grid[last] < 0:
					continue
				var first: int = core.grid[start]
				var second: int = core.grid[start + step]
				var third: int = core.grid[last]
				var count := 2 if first == second or first == third or second == third else 1
				best = maxi(best, count)
		result += float(best)
	return result

func ranked_children(core: RefCounted, level: Dictionary) -> Array:
	var children: Array = []
	for pair in legal_pairs(core):
		var copy = clone_core(core)
		var result: Dictionary = copy.try_swap(pair[0], pair[1])
		if not result["valid"]:
			failures.append("solver generated illegal pair")
			continue
		var activity := 0
		for event in result["events"]:
			if event["type"] == "clear":
				activity += event["indices"].size()
		var score := objective_score(copy, level)
		children.append({"pair": pair, "core": copy, "score": score, "rank": score + potential(copy, level) * 0.2 + float(activity) * 0.01})
	children.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["rank"]) > float(b["rank"]))
	return children

func choose(core: RefCounted, level: Dictionary) -> Dictionary:
	var children := ranked_children(core, level)
	if children.is_empty():
		return {}
	var best: Dictionary = children[0]
	var best_value := -INF
	for index in range(mini(BEAM_WIDTH, children.size())):
		var child: Dictionary = children[index]
		var value := float(child["rank"])
		if not child["core"].won and not child["core"].lost:
			var grandchildren := ranked_children(child["core"], level)
			if not grandchildren.is_empty():
				value = float(child["rank"]) * 0.3 + float(grandchildren[0]["rank"]) * 0.7
		if value > best_value:
			best_value = value
			best = child
	return best

func play(level: Dictionary, seed_value: int) -> Dictionary:
	var core = Core.new()
	core.setup(level, seed_value)
	check(not core.lost and core.get_matches().is_empty() and core.hint_move().size() == 2, "%s seed %d starts stable and playable" % [level["id"], seed_value])
	var path: Array = []
	while not core.won and not core.lost and core.moves_left > 0:
		if Time.get_ticks_msec() - started > BUDGET_MS:
			break
		var choice := choose(core, level)
		if choice.is_empty():
			break
		var pair: Array = choice["pair"]
		var predicted: RefCounted = choice["core"]
		var before_moves: int = core.moves_left
		var result: Dictionary = core.try_swap(pair[0], pair[1])
		check(result["valid"] and core.moves_left == before_moves - 1, "%s seed %d commits a legal one-move swap" % [level["id"], seed_value])
		check(core.grid == predicted.grid and core.floor == predicted.floor and core.runes == predicted.runes and core.collected == predicted.collected and core._rng.state == predicted._rng.state, "simulation clone predicts committed real-core state")
		check(core.get_matches().is_empty(), "committed campaign move leaves no unresolved match")
		for index in range(core.grid.size()):
			var row := int(float(index) / float(core.cols))
			if String(level["mask"][row]).substr(index % core.cols, 1) == ".":
				check(core.grid[index] == -2, "catalog hole persists in real campaign play")
		path.append(pair)
	check(core.won, "%s seed %d wins within catalog move budget" % [level["id"], seed_value])
	var record := {"level": String(level["id"]), "seed": seed_value, "won": core.won, "lost": core.lost, "moves_used": core.initial_moves - core.moves_left, "moves_left": core.moves_left, "initial_moves": core.initial_moves, "collected": core.collected, "collect_goal": core.collect_goal, "floor_left": core.floor.count(1), "runes_left": core.runes.count(1), "stars": Levels.stars_for(core.moves_left, core.initial_moves) if core.won else 0, "path": path}
	print("CAMPAIGN_RUN " + JSON.stringify(record))
	return record

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		print("FAIL: " + message)

func finish() -> void:
	var wins := 0
	for run in runs:
		if run["won"]:
			wins += 1
	print("CAMPAIGN_SUMMARY " + JSON.stringify({"suite": "campaign", "checks": checks, "failed": failures.size(), "failures": failures, "runs": runs.size(), "wins": wins, "seeds": SEEDS, "elapsed_ms": Time.get_ticks_msec() - started, "solver": "six-candidate beam, two-ply real-core simulation with cloned RNG", "limitation": "selected-seed balance evidence, not a proof for all boards or human play"}))
	quit(0 if failures.is_empty() else 1)
