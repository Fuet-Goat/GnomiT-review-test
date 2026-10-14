# GnomiT single-finger journey

Implements the user-approved bounded map specification. Keep the ten existing levels, match-3 rules, objectives, progression and chosen stone audio. English UI; Windows preview uses screen index 0.

## Controls

Drag vertically with one finger or left mouse button, including from a node. A maximum excursion below 12 physical window pixels is a tap; 12 or more is a drag. Finger down reveals the earlier part of the route. Short release inertia is clamped at both ends. The horizontal camera coordinate follows route bends gently; finger X does not roam freely. Tap an unlocked node to start its existing level directly. Locked nodes do nothing. Current Level recenters the map.

## Guide

The guide stands outside the current unlocked badge. A first win at the current node starts a curved 0.8-second walk toward the newly unlocked node, with four sprite frames and camera follow. Replays do not rewind or repeat guide progress. Skip finishes the same state. Two supporting miners are fixed in world coordinates, ignore input, and sway only by rotation. Reduced Motion removes inertia, walking and sway, using immediate destination placement.

## Verification

Current-contract suites: test_journey_map.gd and test_journey_edges.gd. Existing core, progression, save recovery, board, presentation, audio and ten-level runtime suites remain relevant. Native input is exercised in Godot on PC; physical Android validation is pending. Runtime capture uses actual swaps and recorded Godot frames, not generated animation or a human test.

Historical tests test_candy_navigation.gd and test_world_map.gd preserve predecessor preview/free-X contracts; they are not the current navigation specification. They are retained without weakening their assertions. Complete immutable predecessors remain in their separate worktrees/builds.
