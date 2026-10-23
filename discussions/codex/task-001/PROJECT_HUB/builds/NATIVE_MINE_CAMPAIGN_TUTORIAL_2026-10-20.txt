GNOMIT · NATIVE MINE CAMPAIGN + FIRST VOLCANO · 20 OCTOBER 2026
IMPLEMENTED_IN_ISOLATED_PLAYTEST / HUMAN_ACCEPTANCE_PENDING / NO_MERGE

Human correction: preserve actual Blender starting world with TWO nodes:
1 on approach by the small guide, 2 at mine entrance. The initial tutorial
prototype was tied to the older campaign map. That integration is superseded.
The final normal main.tscn boots the actual native V3 GLB, not a raster/map
substitute. Exact GLB SHA 19ec82b314f75e43580408e1f42bbb2ea617f3ad41bd9767b3a97ed0893cf0d3.
Native map is a portrait SubViewport in the existing Godot game. Input scales
to that viewport; no preview/debug buttons in game. Existing logo/guide loops
remain. No Blender V3 predecessor, private game or Cradle edit.

Node1 -> existing pre-level Play -> First Crystals -> two tutorial pages.
Page1 animates one neighbour swap creating four matching minerals and Volcano.
Page2 animates triggering it and burning projectile hits (3 sample targets;
real existing budget3-5). Left/right arrows, Next and Play Level1. Escape
dismisses either page. Modal blocks live board/actions without moving gems,
consuming moves, touching RNG or writing progression. Reduced motion uses
static diagrams. Once per session; Pause -> Volcano Guide reopens it.
Only Volcano is assigned intro level1. Later intro levels are not invented.
Reward recipes and power availability have NOT been gated by new intro data.

Real win in1 -> original v2 progress/stars/Light -> same native map,2 unlocked.
Node2 -> unchanged Root Passage. The opening scene currently exposes only these
two nodes; the10 original level definitions remain unchanged, and the larger
underground/chapter navigation is future work. Existing reward Core/audio are
unchanged, including human-approved manual same-material Volcano triggering.

Fresh evidence:45 tutorial integration checks PASS, including actual arrow
mouse routing, live board blocking, unchanged Core/RNG/progress, resize,
reduced motion, Escape, focus cancellation and stale callback safety.
18 native-flow checks PASS: unpainted generated seed1,25 legal moves, actual
level1 victory, normal save v2 readback, return to native map, visible2 unlock,
then actual Root Passage.185 manual Volcano Core regressions PASS.
Actual graphical432x960 scripted capture touches the native path1 marker,
opens its real preview/Play and displays both pages before the unchanged board.
Capture receipt PASS, state preserved. No fixture victory or human-play claim
in the video. Android/performance/art acceptance remain pending.

The current local launcher now selects this candidate, with a separate save
profile. Previous pointer and predecessor442file hashes are preserved. Native
V3 art/source and the earlier campaign remain unchanged. Prefer monitor2 when
available; this graphical run sees one screen and uses index0. No new software.

READ PACKAGE: Decode NATIVE_PROJECT_PACKAGE.base64.txt to the exact ZIP listed
in PACKAGE_RECEIPT.json.txt. Independently hash and read MANIFEST.json; full
game, editable Blender source, source provenance, actual PNG/MP4, tests and
receipts are included. Run game/PLAY_CAMPAIGN.cmd with existing Godot4.7.2.
This is a complete review attachment, not executable game edits in this repo.
No rights audit closure or release/legal all-clear follows from this work.

GPT/Grok: REPORTS_ONLY review in your own task-001 REPORT. Observe actual map
and animation files; distinguish source inference from observed pixels. Focus
on correct1path/2mine flow, mini-animation clarity and modal input safety.
No art variant, engine run, source implementation, grant edit or merge without
an applicable separate human grant. Recommendation GPT-6.1 Sol / High.
