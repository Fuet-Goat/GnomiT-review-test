extends RefCounted
static func all() -> Array:
	return [
	  {
	    "id": "entry",
	    "name": "First Crystals",
	    "chapter": "The Surface",
	    "description": "Collect 12 diamonds. Match three or more treasures.",
	    "cols": 7,
	    "rows": 8,
	    "mask": [
	      ".xxxxx.",
	      ".xxxxx.",
	      "xxxxxxx",
	      "xxxxxxx",
	      "xxxxxxx",
	      "xxxxxxx",
	      ".xxxxx.",
	      ".xxxxx."
	    ],
	    "moves": 26,
	    "goal": "collect",
	    "collect_kind": 3,
	    "collect_goal": 12,
	    "target_cells": [],
	    "rune_cells": [],
	    "depth": 10
	  },
	  {
	    "id": "hollow",
	    "name": "Root Passage",
	    "chapter": "The Roots",
	    "description": "Clear the 12 glowing soil tiles. Holes split the falling treasures.",
	    "cols": 7,
	    "rows": 8,
	    "mask": [
	      "xxxxxxx",
	      "xxxxxxx",
	      "xx...xx",
	      "xx...xx",
	      "xxxxxxx",
	      "xx...xx",
	      "xxxxxxx",
	      ".xxxxx."
	    ],
	    "moves": 32,
	    "goal": "floor",
	    "collect_kind": 3,
	    "collect_goal": 0,
	    "target_cells": [
	      0,
	      1,
	      5,
	      6,
	      7,
	      8,
	      12,
	      13,
	      28,
	      29,
	      33,
	      34
	    ],
	    "rune_cells": [],
	    "depth": 20
	  },
	  {
	    "id": "seam",
	    "name": "Golden Seam",
	    "chapter": "The Soil",
	    "description": "Clear only the glowing soil. Use the rest of the board to make matches.",
	    "cols": 7,
	    "rows": 8,
	    "mask": [
	      ".xxxxx.",
	      "xxxxxxx",
	      "xxx.xxx",
	      "xxx.xxx",
	      "xxxxxxx",
	      "xx...xx",
	      "xxxxxxx",
	      ".xxxxx."
	    ],
	    "moves": 34,
	    "goal": "floor",
	    "collect_kind": 3,
	    "collect_goal": 0,
	    "target_cells": [
	      8,
	      9,
	      10,
	      11,
	      12,
	      14,
	      15,
	      16,
	      18,
	      19,
	      20,
	      28,
	      29,
	      30,
	      31,
	      32,
	      33,
	      34
	    ],
	    "rune_cells": [],
	    "depth": 30
	  },
	  {
	    "moves": 32,
	    "rows": 8,
	    "cols": 7,
	    "goal": "collect",
	    "rune_cells": [],
	    "target_cells": [],
	    "chapter": "The Dew Caves",
	    "collect_goal": 16,
	    "description": "Collect 16 pearls from the shimmering grotto.",
	    "depth": 40,
	    "id": "pearl",
	    "mask": [
	      ".xxxxx.",
	      "xxxxxxx",
	      "xxx.xxx",
	      "xxxxxxx",
	      "xxxxxxx",
	      "xxx.xxx",
	      "xxxxxxx",
	      ".xxxxx."
	    ],
	    "collect_kind": 5,
	    "name": "Pearl Grotto"
	  },
	  {
	    "moves": 34,
	    "rows": 8,
	    "cols": 8,
	    "goal": "collect",
	    "rune_cells": [],
	    "target_cells": [],
	    "chapter": "The Ore Caves",
	    "collect_goal": 20,
	    "description": "Collect 20 pieces of gold-bearing rock.",
	    "depth": 50,
	    "id": "goldore",
	    "mask": [
	      ".xxxxxx.",
	      "xxxxxxxx",
	      "xx.xx.xx",
	      "xx.xx.xx",
	      "xxxxxxxx",
	      "xxxxxxxx",
	      ".xxxxxx.",
	      "..xxxx.."
	    ],
	    "collect_kind": 2,
	    "name": "Golden Veins"
	  },
	  {
	    "moves": 36,
	    "rows": 9,
	    "cols": 7,
	    "goal": "floor",
	    "rune_cells": [],
	    "target_cells": [
	      8,
	      9,
	      11,
	      12,
	      14,
	      15,
	      16,
	      18,
	      19,
	      20,
	      36,
	      37,
	      38,
	      39,
	      40,
	      41
	    ],
	    "chapter": "The Deep Soil",
	    "collect_goal": 0,
	    "description": "Clear 16 glowing soil tiles.",
	    "depth": 60,
	    "id": "terraces",
	    "mask": [
	      ".xxxxx.",
	      "xxxxxxx",
	      "xxx.xxx",
	      "xx...xx",
	      "xxx.xxx",
	      "xxxxxxx",
	      "xxxxxxx",
	      "xxxxxxx",
	      ".xxxxx."
	    ],
	    "collect_kind": 3,
	    "name": "Mossy Terraces"
	  },
	  {
	    "moves": 38,
	    "rows": 9,
	    "cols": 8,
	    "goal": "floor",
	    "rune_cells": [],
	    "target_cells": [
	      10,
	      13,
	      16,
	      17,
	      18,
	      19,
	      20,
	      21,
	      22,
	      23,
	      48,
	      49,
	      50,
	      51,
	      52,
	      53,
	      54,
	      55
	    ],
	    "chapter": "The Quiet Depths",
	    "collect_goal": 0,
	    "description": "Clear 18 glowing soil tiles.",
	    "depth": 70,
	    "id": "bridge",
	    "mask": [
	      "..xxxx..",
	      ".xxxxxx.",
	      "xxxxxxxx",
	      "xxx..xxx",
	      "xx....xx",
	      "xxx..xxx",
	      "xxxxxxxx",
	      ".xxxxxx.",
	      "..xxxx.."
	    ],
	    "collect_kind": 3,
	    "name": "Crystal Bridge"
	  },
	  {
	    "id": "rune",
	    "name": "Free the Runes",
	    "chapter": "Preparation A",
	    "description": "Match beside each sealed rune to free it.",
	    "cols": 7,
	    "rows": 8,
	    "mask": [
	      ".xxxxx.",
	      "xxxxxxx",
	      "xxxxxxx",
	      "xxxxxxx",
	      "xxxxxxx",
	      "xxxxxxx",
	      "xxxxxxx",
	      ".xxxxx."
	    ],
	    "moves": 30,
	    "goal": "rune",
	    "collect_kind": 3,
	    "collect_goal": 0,
	    "target_cells": [],
	    "rune_cells": [
	      16,
	      18,
	      38
	    ],
	    "depth": 80
	  },
	  {
	    "id": "lantern",
	    "name": "Charge the Lantern",
	    "chapter": "Preparation B",
	    "description": "Collect 16 diamonds to charge the lantern.",
	    "cols": 7,
	    "rows": 8,
	    "mask": [
	      ".xxxxx.",
	      "xxxxxxx",
	      "xxxxxxx",
	      "xx...xx",
	      "xx...xx",
	      "xxxxxxx",
	      "xxxxxxx",
	      ".xxxxx."
	    ],
	    "moves": 32,
	    "goal": "lantern",
	    "collect_kind": 3,
	    "collect_goal": 16,
	    "target_cells": [],
	    "rune_cells": [],
	    "depth": 80
	  },
	  {
	    "id": "guardian",
	    "name": "Crystal Guardian",
	    "chapter": "First Boss",
	    "description": "Free three runes and collect 18 diamonds to light the Guardian.",
	    "cols": 7,
	    "rows": 8,
	    "mask": [
	      "..xxx..",
	      ".xxxxx.",
	      "xxxxxxx",
	      "xxx.xxx",
	      "xxxxxxx",
	      ".xxxxx.",
	      "xxxxxxx",
	      "..xxx.."
	    ],
	    "moves": 38,
	    "goal": "boss",
	    "collect_kind": 3,
	    "collect_goal": 18,
	    "target_cells": [],
	    "rune_cells": [
	      16,
	      18,
	      38
	    ],
	    "depth": 90
	  }
	]
static func get_level(level_id: String) -> Dictionary:
	for level in all():
		if level.id == level_id:
			return level.duplicate(true)
	return {}
static func ordinary() -> Array:
	return ["entry","hollow","seam","pearl","goldore","terraces","bridge"]
static func preparations() -> Array:
	return ["rune","lantern"]
static func stars_for(moves_left: int, initial_moves: int) -> int:
	if moves_left >= int(ceil(float(initial_moves) * 0.5)):
		return 3
	if moves_left >= int(ceil(float(initial_moves) * 0.25)):
		return 2
	return 1
