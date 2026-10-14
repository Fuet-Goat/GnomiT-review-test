extends SceneTree

var checks := 0
var failures: Array[String] = []
var Core = preload("res://scripts/match_core.gd")

func _initialize() -> void:
	test_setup()
	test_match_shapes_and_objective_kind()
	test_invalid_swaps()
	test_clear_and_collection()
	test_runes()
	test_segment_gravity()
	test_terminal_states()
	test_cascades_and_recovery()
	finish()

func level(goal: String = "collect", moves: int = 20) -> Dictionary:
	return {"cols": 4, "rows": 4, "mask": ["xxxx", "xxxx", "xxxx", "xxxx"], "moves": moves, "goal": goal, "collect_kind": 0, "collect_goal": 99, "target_cells": [], "rune_cells": []}

func fixture(settings: Dictionary = {}) -> RefCounted:
	var data := level()
	data.merge(settings, true)
	var core = Core.new()
	core.setup(data, int(settings.get("seed", 19)))
	core.grid.assign([0, 1, 0, 3, 2, 0, 4, 5, 3, 2, 1, 4, 1, 3, 5, 2])
	return core

func first_event(result: Dictionary, event_type: String) -> Dictionary:
	for event in result.get("events", []):
		if event.get("type") == event_type:
			return event
	return {}

func test_setup() -> void:
	for seed_value in range(1, 13):
		var core = Core.new()
		core.setup({"cols": 5, "rows": 5, "mask": ["xxxxx", "xxxxx", "xx.xx", "xxxxx", "xxxxx"], "moves": 12, "goal": "boss", "collect_kind": 3, "collect_goal": 6, "target_cells": [0, 1, 12], "rune_cells": [18]}, seed_value)
		check(core.get_matches().is_empty(), "seed %d has no initial match" % seed_value)
		var before: Array = core.grid.duplicate()
		check(core.hint_move().size() == 2, "seed %d begins with legal swap" % seed_value)
		check(core.grid == before and core.moves_left == 12, "hint does not mutate board or spend move")
		check(core.grid[12] == -2, "hole survives setup")
		check(core.grid[18] == -3 and core.runes[18] == 1, "rune starts sealed with one HP")
		check(core.floor[0] == 1 and core.floor[1] == 1 and core.floor[12] == 0, "only playable target cells receive golden floor")

func test_match_shapes_and_objective_kind() -> void:
	var core = Core.new()
	var data := {"cols": 5, "rows": 5, "mask": ["xxxxx", "xxxxx", "xxxxx", "xxxxx", "xxxxx"], "moves": 20, "goal": "collect", "collect_kind": 3, "collect_goal": 6}
	core.setup(data, 31)
	var other = Core.new()
	other.setup(data, 31)
	check(core.grid == other.grid, "same seed creates same starting board")
	core.grid.assign([0, 1, 2, 3, 4, 1, 2, 0, 4, 5, 2, 0, 0, 0, 1, 3, 4, 0, 1, 2, 4, 5, 1, 2, 3])
	check(core.get_matches() == [7, 11, 12, 13, 17], "crossing horizontal and vertical matches count center once")
	core = fixture({"collect_kind": 3, "collect_goal": 3})
	core.grid.assign([3, 1, 3, 0, 2, 3, 4, 5, 0, 2, 1, 4, 1, 0, 5, 2])
	check(core.try_swap(1, 5)["won"] and core.collected >= 3, "collection honors configured blue gem kind")

func test_invalid_swaps() -> void:
	var core = fixture()
	var before: Array = core.grid.duplicate()
	check(not core.try_swap(0, 15)["valid"], "nonadjacent swap rejected")
	check(not core.try_swap(3, 4)["valid"], "row-edge wrap is not adjacent")
	check(not core.try_swap(-1, 0)["valid"], "negative index rejected")
	check(not core.try_swap(0, 16)["valid"], "past-end index rejected")
	var rejected: Dictionary = core.try_swap(0, 4)
	check(not rejected["valid"], "matchless adjacent swap rejected")
	check(core.grid == before and core.moves_left == 20, "invalid swap restored without spending move")
	if rejected["events"].size() == 2:
		check(rejected["events"][0]["before"] == before and rejected["events"][1]["after"] == before, "rejection events animate outward and back")
	else:
		check(false, "matchless swap returns two animation events")
	core.grid[4] = -2
	check(not core.try_swap(0, 4)["valid"], "hole cannot swap")
	core.grid[4] = -3
	check(not core.try_swap(0, 4)["valid"], "sealed rune cannot swap")

func test_clear_and_collection() -> void:
	var core = fixture({"goal": "floor", "target_cells": [0, 1, 2, 4]})
	var result: Dictionary = core.try_swap(1, 5)
	check(result["valid"] and core.moves_left == 19, "successful swap spends exactly one move")
	var cleared := first_event(result, "clear")
	check(cleared.get("indices", []) == [0, 1, 2], "actual first match has three expected cells")
	check(not cleared.is_empty() and cleared["floor"][0] == 0 and cleared["floor"][1] == 0 and cleared["floor"][2] == 0 and cleared["floor"][4] == 1, "floor clears only under actual match")
	var counted := 0
	for event in result["events"]:
		check(event.has("before") and event.has("after") and event.has("floor") and event.has("runes"), "every event has complete snapshots")
		if event["type"] == "clear":
			for index in event["indices"]:
				if event["before"][index] == 0:
					counted += 1
	check(core.collected == counted and counted >= 3, "collection includes every cleared matching gem")
	check(core.get_matches().is_empty() and core.hint_move().size() == 2, "resolution leaves stable playable board")

func test_runes() -> void:
	var core = fixture({"goal": "rune", "rune_cells": [4, 8], "target_cells": [4]})
	core.grid[4] = -3
	core.grid[8] = -3
	var result: Dictionary = core.try_swap(1, 5)
	var cleared := first_event(result, "clear")
	check(cleared.get("broken_runes", []) == [4], "only rune adjacent to actual matched cell breaks")
	check(not cleared.is_empty() and cleared["runes"][4] == 0 and cleared["runes"][8] == 1, "broken rune cannot chain-break neighboring rune")
	check(not cleared.is_empty() and cleared["floor"][4] == 1, "adjacent rune break does not clear golden floor")
	var falling := first_event(result, "fall")
	check(not falling.is_empty() and falling["after"][4] >= 0 and falling["after"][8] == -3, "liberated rune refills while sealed rune blocks")
	core = fixture({"goal": "rune", "rune_cells": [4]})
	core.grid[4] = -3
	result = core.try_swap(1, 5)
	check(result["won"] and not result["lost"], "rune goal completes after final seal breaks")

func test_segment_gravity() -> void:
	var core = Core.new()
	core.setup({"cols": 4, "rows": 6, "mask": ["xxxx", "xxxx", ".xxx", "xxxx", "xxxx", "xxxx"], "moves": 20, "goal": "collect", "collect_kind": 0, "collect_goal": 99, "rune_cells": [10]}, 7)
	core.grid.assign([0, 1, 2, 3, 2, 3, 4, 5, -2, 2, -3, 4, 3, 0, 2, 2, 0, 1, 0, 1, 4, 5, 3, 0])
	var result: Dictionary = core.try_swap(13, 17)
	var falling := first_event(result, "fall")
	check(result["valid"], "lower segment matching swap accepted")
	check(not falling.is_empty() and falling["after"][8] == -2 and falling["after"][10] == -3, "gravity preserves hole and sealed rune")
	check(not falling.is_empty() and falling["after"][0] == 0 and falling["after"][4] == 2 and falling["after"][2] == 2 and falling["after"][6] == 4, "gravity cannot pull across hole or rune")
	check(not falling.is_empty() and falling["after"][16] == 3 and falling["after"][18] == 2, "gems fall downward inside lower segment")
	var moved_from_12 := false
	var moved_from_14 := false
	var spawned := false
	for fall in falling.get("falls", []):
		moved_from_12 = moved_from_12 or (fall["from"] == 12 and fall["to"] == 16 and fall["kind"] == 3)
		moved_from_14 = moved_from_14 or (fall["from"] == 14 and fall["to"] == 18 and fall["kind"] == 2)
		spawned = spawned or fall["from"] < 0
	check(moved_from_12 and moved_from_14 and spawned, "fall events identify exact source, destination and spawned gems")

func test_terminal_states() -> void:
	var core = fixture({"moves": 1, "collect_goal": 3})
	var result: Dictionary = core.try_swap(1, 5)
	check(result["won"] and not result["lost"] and core.moves_left == 0, "last-move victory takes priority over loss")
	var before: Array = core.grid.duplicate()
	check(not core.try_swap(0, 1)["valid"] and core.grid == before, "won board ignores further moves")
	core = fixture({"moves": 1, "collect_goal": 99})
	result = core.try_swap(1, 5)
	check(result["lost"] and not result["won"], "out of moves without goal loses")
	core = fixture({"goal": "boss", "collect_goal": 3, "rune_cells": [8]})
	core.grid[8] = -3
	result = core.try_swap(1, 5)
	check(not result["won"] and core.collected >= 3 and core.runes[8] == 1, "boss requires collection and all runes")
	core = fixture({"goal": "boss", "collect_goal": 3, "rune_cells": [4]})
	core.grid[4] = -3
	result = core.try_swap(1, 5)
	check(result["won"], "boss completes once both goals complete")
	core = fixture({"goal": "lantern", "collect_goal": 3})
	check(core.try_swap(1, 5)["won"], "lantern uses its collection goal")
	core = fixture({"goal": "floor", "target_cells": [0, 1, 2]})
	check(core.try_swap(1, 5)["won"], "floor goal completes after targets clear")

func test_cascades_and_recovery() -> void:
	var saw_cascade := false
	var saw_shuffle := false
	for seed_value in range(1, 31):
		var core = fixture({"seed": seed_value, "collect_goal": 999})
		var result: Dictionary = core.try_swap(1, 5)
		var waves := 0
		var counted := 0
		for event in result["events"]:
			if event["type"] == "clear":
				waves += 1
				for index in event["indices"]:
					if event["before"][index] == 0:
						counted += 1
		saw_cascade = saw_cascade or waves > 1
		check(core.collected == counted, "cascade collection tracks every wave")
		check(result["events"].size() <= 67, "cascade resolution is bounded")
		check(core.get_matches().is_empty() and core.hint_move().size() == 2, "seeded resolution has no match or deadlock")
	check(saw_cascade, "seed sweep exercises a real cascade")
	for seed_value in range(1, 6):
		var core = Core.new()
		core.setup({"cols": 5, "rows": 5, "mask": ["xxxxx", "xx.xx", "xxxxx", "x.xxx", "xxxxx"], "moves": 50, "goal": "collect", "collect_kind": 5, "collect_goal": 999}, seed_value)
		for turn in range(30):
			var hint: Array = core.hint_move()
			if hint.size() != 2:
				check(false, "long seeded play retains a legal move")
				break
			var result: Dictionary = core.try_swap(hint[0], hint[1])
			for event in result["events"]:
				if event["type"] == "shuffle":
					saw_shuffle = true
			check(result["valid"] and core.moves_left == 49 - turn, "hint is legal and spends one move")
			check(core.grid[7] == -2 and core.grid[16] == -2, "holes persist through repeated cascades")

	check(saw_shuffle, "seeded play exercises real dead-board recovery")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		print("FAIL: " + description)

func finish() -> void:
	print(JSON.stringify({"suite": "match_core", "checks": checks, "failed": failures.size(), "failures": failures}))
	quit(0 if failures.is_empty() else 1)
