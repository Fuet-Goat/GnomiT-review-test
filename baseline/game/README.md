# GnomiT — Single Finger Journey

A portrait match-3 adventure made with Godot 4.7.2. The expedition starts in a sunny village and follows a winding route downward into the earth. Current playable version: **0.1.0-alpha10-single-finger**.

GnomiT is a separate project from Cradle of Gnome. This version preserves its ten existing levels, match-3 rules, objectives, progression, and chosen stone sounds. The interface is English.

## Play and inspect

Download the [alpha10 Windows package](https://github.com/Fuet-Goat/GnomiT/releases/tag/v0.1.0-alpha10-single-finger), unzip it, and run `WINDOWS/GnomiT.exe`. The package includes the complete playable source, a real runtime recording, screenshots, verification receipts, and a SHA-256 manifest. The packaged gameplay commit is `ec25a831a0e35577a9f8043482445603768a514d`; subsequent publication commits add documentation and evidence only.

<img src="docs/preview/map-surface.png" alt="GnomiT surface map before playing" width="216"> <img src="docs/preview/map-next-node.png" alt="GnomiT guide beside the next unlocked node after winning" width="216">

[Watch the recorded map and gameplay run](docs/preview/journey-runtime.mp4). It was rendered from the exported EXE's embedded pack using Godot, scripted native gestures, and actual seed-42 gameplay swaps. It is not a generated video or a human playtest.

## Map controls

- Drag vertically with one finger or the left mouse button, including when starting on a number. Finger down reveals the earlier part of the route.
- A maximum excursion below **12 physical screen pixels** is a tap; 12 or more is a drag. Moving out and back remains a drag.
- Tap an unlocked node to start its existing level directly. Locked nodes do nothing. The Boss entrance opens the existing preparation chamber.
- Release a quick drag for short, bounded inertia. The horizontal camera coordinate follows route bends gently; neither finger X nor horizontal mouse-wheel events can roam freely.
- **Current Level** recenters the guide. After a first win at the current node, the guide walks along a curved path for about **0.8 seconds**, with camera follow. **Skip** completes the same transition. Replays do not rewind progression.
- The guide stands outside the current badge. Two supporting miners keep fixed world positions, ignore input, and sway only by rotation.
- **Settings → Reduced Motion** disables inertia, walking, and side-character sway, using immediate destination placement.

## How the change works

| File | Responsibility |
| --- | --- |
| [`scripts/story_map_view.gd`](scripts/story_map_view.gd) | Native gesture ownership, physical tap threshold, vertical camera movement, bounded inertia, curved guide walk, side miners, resize and reduced-motion handling. |
| [`scripts/main.gd`](scripts/main.gd) | Direct node-to-gameplay routing, existing Boss chamber, saved progression, and gating guide movement to first wins at the current node. |
| [`scripts/story_art.gd`](scripts/story_art.gd) | Existing art and new transparent walk/supporting-miner atlases. |
| [`tests/test_journey_map.gd`](tests/test_journey_map.gd) | 77 native gesture, camera, replay, guide, and gameplay integration checks. |
| [`tests/test_journey_edges.gd`](tests/test_journey_edges.gd) | 68 overlay, cancellation, physical boundary, resize, Skip, Boss, reduced-motion, and horizontal-wheel checks. |

The gameplay implementation is in [`ec25a831`](https://github.com/Fuet-Goat/GnomiT/commit/ec25a831a0e35577a9f8043482445603768a514d). [Compare the alpha8 baseline with alpha10](https://github.com/Fuet-Goat/GnomiT/compare/dd46945957f7f1cfd7fb3b8369ffb7788bf003f3...ec25a831a0e35577a9f8043482445603768a514d).

## Run from source

Open `project.godot` in Godot **4.7.2**, or use the console engine:

```powershell
godot --headless --editor --path . --import --quit
godot --path .
```

Current navigation and live-level verification:

```powershell
godot --headless --path . --script res://tests/test_journey_map.gd
godot --headless --path . --script res://tests/test_journey_edges.gd
godot --headless --path . --script res://tests/test_storybook_runtime.gd
```

The tests use isolated fixture saves, not the player's save. Navigation results and fixtures are written to `../verification/`; other suites use their own fixture filenames under Godot `user://`.

## Verification and review

[Recorded evidence](docs/verification/VERIFICATION_SUMMARY.json) contains **145 native navigation checks**, passing against the source and again against the exported pack, actual victories in all ten levels, and 50 selected-seed campaign wins. [The final independent code review](docs/verification/JOURNEY_CODE_REVIEW_FINAL.txt) closes the tap-during-walk, resize, and horizontal-wheel defects found during development.

[Fresh checks before Git publication](docs/verification/publication/SUMMARY.json) pass all 14 current suites: 9,529 suite-reported checks plus a successful voice-continuity outcome. All 136 inventoried product files have identical hashes before and after that run.

Evidence files preserve their original bytes. Their source hashes refer to the Windows build snapshot retained in the release ZIP; Git may normalize source line endings on other systems. `UNCHANGED_GAMEPLAY_BYTES.json` records the observed newline-only difference in the audio source.

Physical **Pixel 8a / Android testing remains pending**. These are PC native-event and scripted gameplay checks; they do not establish touch ergonomics on a real phone, human playtesting, or balance for every generated board.

`test_candy_navigation.gd` and `test_world_map.gd` preserve historical preview/free-X contracts. They are retained unchanged as predecessor evidence and are not current navigation acceptance suites. Use the journey suites above. [`docs/progress.md`](docs/progress.md) describes the older initial skeleton; the current contract is [`docs/SINGLE_FINGER_JOURNEY_2026-10-14.md`](docs/SINGLE_FINGER_JOURNEY_2026-10-14.md).

For an independent bot review, start with [`docs/REVIEW_REQUEST.md`](docs/REVIEW_REQUEST.md). Repository access is required because this repository is private.
