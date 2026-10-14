# GnomiT First Boss Implementation Plan
> For agentic workers: execute with the shared interfaces below; parent integrates and performs one fresh final review.
Goal: playable six-level native Godot skeleton through the first Boss with map, save and animations.
Architecture: RefCounted match core, static level catalog and save/progression service; animated BoardView independent from core; main Control owns navigation/HUD/chamber/results.
Tech Stack: installed Godot 4.7.2, GDScript, native SVG/drawing, existing owned PNG/font assets when suitable.
Spec: docs/superpowers/specs/2026-10-11-gnomit-first-boss-design.md
Global constraints: new project only, no Cradle edits; no timer; 2 preparations + final; 1-3 actual earned stars; live UI text; Windows build.
Review focus: invalid swaps spending moves; rune/hole gravity stranded; close/replay duplicate rewards; interrupted animation affecting progression; tiny desktop/portrait layout and result navigation.
## Tasks
1. Match rules + core tests (core implementer).
Files scripts/match_core.gd, tests/test_core.gd.
API setup(level:Dictionary, seed_value:int=1), try_swap(a:int,b:int)->Dictionary, hint_move()->Array.
Fields cols, rows, grid, floor, runes, moves_left, initial_moves, collected, collect_goal, collect_kind, won, lost.
Flat row-major arrays. grid >=0 kinds0..5, -2 hole, -1 empty, -3 sealed rune; floor/runes integers.
Result valid/events/won/lost. Each event has type,before,after,floor,runes,matched/broken_runes or falls as relevant. swap a/b; clear indices; fall falls dictionaries from/to/kind; shuffle snapshots.
- [ ] Behavioral tests RED then implementation then GREEN: no prematch/dead board, invalid nonadjacent/matchless swaps, rune adjacency, partial floor, segment gravity, cascade collection, win/loss.
2. Levels + progression/save (parent).
Files scripts/levels.gd, scripts/progress.gd, tests/test_progress.gd.
Catalog returns 6 dictionaries with id/name/description/cols/rows/mask/moves/goal/collect_kind/collect_goal/target_cells/rune_cells.
- [ ] Tests RED then GREEN: sequential 3 ordinary unlocks, free preparation order, final requires both, best stars/rewards once, reload/corrupt fallback.
3. Animated board + app UI (board implementer and parent).
Board API setup(core,reduced=false), animate_result(result:Dictionary) awaitable, show_hint(pair:Array); signal swap_requested(a,b); busy state.
BoardView owns board animation/input/art; parent main owns map/chamber/menu/HUD/result and save.
- [ ] Import/parse tests, scripted gameplay scenes, GUI screenshots at portrait/desktop; check visible goals and actual stars.
4. Integration/verification/build/review (parent).
- [ ] Core + progress suites; seeded solver run every level; import clean and headless app smoke.
- [ ] Fresh independent code review, fix consequential findings, export native Windows EXE.
- [ ] Launch EXE, record observed UI if tool permits; package EXE + source + run instructions + verification receipts.
