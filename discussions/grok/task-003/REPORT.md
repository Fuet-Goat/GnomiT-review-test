# GnomiT · Grok task-003 · Independent storybook environment challenger — REPORT

Status: **CANDIDATE DELIVERED, HUMAN CHOICE PENDING.** Not a PASS claim, not campaign integration.

## Grant and inputs
- Grant: `tasks/grok/task-003.json` on main `dabe1793398d9ceb6afcb0b459ba91e8687c6ac6`, status APPROVED, branch `codex/grok/task-003`. Writes only under `sandbox/grok/task-003/{art,source,preview,game,outputs}/` and `discussions/grok/task-003/`.
- Input map context: commit `74d7959ca4adb796549e4b4e02bb30c250018a07`, folder `discussions/codex/task-001/PROJECT_HUB/builds/gnome-real-map-integration-r1-2026-10-23/` (source handoff `324448e1f4aaeceb0c03f283744b1e7d5ed21574`). TRANSFER parts 001–051 decoded → `GNOMIT_REAL_MAP_INTEGRATION_R1_2026-10-23.zip`, 76144710 B, SHA-256 `9ec51b98900ba292b33a937b905ea70a273c7e75d9a1b80fd4aa0cf183d03e54` (matches TRANSFER_MANIFEST).
- Style target: `PRIMARY_TARGET_COMPARISON.png` (middle panel "HYBRID 2.5D STORYBOOK") and `SECONDARY_ISLAND_REFERENCE.png` from `briefs/new-island-generator-v002-2026-10-21/BRIEF_WITH_REFERENCES.base64.txt` at commit `3928d49c29698672cd87585531479dfd113f80a2` (linked as `style_target` by the 2026-10-23 handoff RESOURCE_INDEX).

## Images actually viewed (Read)
`outputs/B_WORLD_001.png`, `outputs/B_CONTEXT_055.png` (from the integration ZIP), `PRIMARY_TARGET_COMPARISON.png`, `SECONDARY_ISLAND_REFERENCE.png`, my own Godot captures of the current map (Compatibility and Forward+), and every Grok iteration render plus all final sheets.
Downloaded and hashed but **NOT_OBSERVED** visually: `GNOMIT_REAL_MAP_R3_GREETING.gif` (8363264e…a113), `GNOMIT_REAL_MAP_OLD_MASTER.png` (79181d3e…1f1c), `GNOMIT_REAL_MAP_CHARACTER_CROPS.png` (8b2ca81d…910c), and the other ZIP outputs (A_*, OLD_MASTER_CONTEXT, MAP_REDUCED_MOTION, GNOME_REAL_MAP_GREETING.gif).

## Files actually opened
- Blender 5.2.2 (headless): imported `godot/assets/r3/airy_island.glb` (current map) and inspected objects, route extras, camera, anchors, Mine_Root and trees. `native/GNOME_R3_ACCEPTED.blend` was **not opened** (gnome is read-only, used only through its GLB).
- Godot 4.7.2 (Forward+ on Mesa lavapipe software Vulkan, project-local, no system install): ran the copied integration project (`integration.tscn`, `integration_map.gd`, `scripts/r3/island_map.gd`, `master_guide.gd`, `assets/r3/lighting_v012.json`, gnome `gnome_r3.glb`).

## Method (fair comparison)
The integration project was copied to `sandbox/grok/task-003/game/`. The only code change is an optional `GROK_ISLAND_GLB` path override in my copy of `island_map.gd` (default = the current map). CURRENT and GROK frames are both captured by `game/grok_tools/grok_capture.gd`. That script reads the native 3D SubViewport only, so the frames are UI-free. Both use the same `Portrait_Camera` (the transform, ortho size 19.97 and KEEP_HEIGHT are verified identical in the capture logs), the same master gnome GLB (SHA `3b72702c…c529f`, unchanged), the same route position s=0.4 at (-1.20, 0.85, 8.37), scale 0.6128, greeting pose t=0 and lighting Profile B / ACES. Close-ups are crops of 3× viewport captures from the same camera (1296×2880), not re-angled shots.

## Artistic idea
"One sunlit meadow plateau on a thick clay-warm earth cake": a few large, calm masses (meadow, earth, crowns, mine heap) carry the read at 432×960. Detail is spent only where the eye should go: the path planks and the dark mine mouth. The island colour moves away from noisy textured grass toward clean colour masses, like the hybrid 2.5D target, but stays matte (no candy gloss) and keeps the GnomiT palette (honey wood, warm earth, red mushroom).

## CURRENT PROBLEM → GROK CHANGE → VISIBLE RESULT
1. **Island mass.** Current: the grass reads as a flat textured plate on a lobed rim, with thickness only at the bottom tip. → Grok: a superellipse plateau with a rolled grass lip and three earth strata (topsoil, warm, deep) dropping to z −3.75 with a soft lobed underside, all with live subdivision. → Result: a visible earth band along both sides and the bottom. The island reads as a thick object, not a board. **Better.**
2. **Grass.** Current: a whole-island baked blade texture plus 54 tufts gives even micro-noise everywhere. → Grok: the plain matte meadow plus 5 very low sunlit hillocks for tonal variation, and 11 tuft groups (13–16 curved blades per tuft, double-sided) only at tree bases, the rim and the mushroom, never within 1.05 m of the path. → Result: large calm green areas and clear negative space. Tufts read as clumps. **Better for calm; but the flat meadow can read as too plain/"clay"** next to the lush target.
3. **Path.** Current: an orange-red board deck with separate pins, wide visual contrast, and colour close to the portal. → Grok: one generated deck with about 0.40 m beveled honey planks and 0.022 m joints, continuous rounded curb logs on both sides, and 8 chunky posts with endgrain caps. The same S route and the same route samples are used. → Result: it reads as one crafted wooden road with readable turns and constant width, and the honey colour separates from the meadow. **Better.**
4. **Mine.** Current: a stone heap with an orange frame and a lit red-brown interior. The interior is not dark, so the destination is less legible. → Grok: 9 large rounded stones in an arch with a mossy rear mound, a deep near-black interior volume, beveled posts, knee braces and a header with a small sign board, and a small lantern on the left post (the Godot lantern light follows the new `Lantern_Pivot`). → Result: a strong dark "mouth" at the end of the path, a clear focal point, and restrained warm light. **Better readability; weaker detail.** The stones are smooth beige clay, the right-hand rear boulder shows shadow banding, and a thin outline artifact sits on the moss mound.
5. **Trees.** Current: 5 crowns with surface leaf pattern and daisies. They are pleasant but busy, and have cloud-like lobes. → Grok: each crown is a single metaball mesh of 3 dominant masses plus 1–2 accents, rotated per tree, squashed broader than tall, on a tapered flared trunk with 2 limbs. Crown daisies were removed. → Result: big readable asymmetric canopies with no "grape clusters". **Mixed.** At 432×960 they read cleanly, but in close-up they look like smooth plastic/clay pills without leaf breakup, and the light/shadow side split is weak. **Current trees are arguably stronger in close-up.**
6. **Decoration.** Current: about 16 scattered meadow stones and 91 flower parts spread over the whole island. → Grok: 4 stone clusters (2–3 stones, one moss cap each) and 6 flower groups of 3–4. → Result: much less noise and grouped accents. The flowers may now be too small to register at mobile scale.
7. **Lighting (own candidate G1).** Profile B values are unchanged, plus a single orthogonal shadow cascade on the key light. This removes the PSSM split seam that crossed the meadow horizontally. That seam was invisible on the current textured grass but obvious on clean colour masses. The effect is shown separately in `LIGHTING_EFFECT_B_vs_G1.png`. The cost is a slightly softer, lower-resolution shadow. No material or geometry of the gnome changed, and there is no bloom.

## Intentionally kept
The camera, route centreline and samples, Level_1/Level_2 anchors, the Mushroom_Cottage hierarchy (unchanged current component), the locked master gnome (GLB, scale, placement, greeting), all gameplay, UI and progress code, and Profile B values.

## Real checks run
- Grant read on main; changed-file scope limited to the allowed task-003 roots (git diff check before commit).
- Gnome GLB SHA identical to the input ZIP: `3b72702cb1c995d2553dddd4895a1e2327be14d5a22cc38a60a88603d47c529f`.
- Camera identical in every capture (ortho 19.9702, same transform). The first export had a wrong ortho size (11.23) because of the Blender scene aspect. I detected it and fixed it by setting the export resolution to 432×960.
- The GLB imports in Godot 4.7.2 and the route configures (the map loads, the gnome is placed and the lantern is found).
- The isolated preview `game/grok_preview.tscn` runs and was screenshotted in `preview/ISOLATED_PREVIEW_SCREENSHOT.png` (labelled ISOLATED PREVIEW — NOT CAMPAIGN INTEGRATION).
- The generator re-run reproduces the scene (re-capture max pixel diff 69/255, local TAA/raster noise only).

## Limits
- Rendering used llvmpipe software Vulkan, not a GPU. Device shading, AA and shadow quality may differ, but both sides used the same renderer.
- No Android/performance work. Evaluated triangles are about 128k. Metaball crowns and subdivided masses are dense and would need decimation later.
- No walking (the master has no authored walk), no human test, and no Blender Cycles/EEVEE render (the Godot runtime frame is the comparison).
- The `.import` files and `font.ttf` of the copied project are not committed (format not in the grant), so Godot re-imports on first open and the UI font falls back to the default.

## Self-score vs HYBRID 2.5D STORYBOOK target (1–5)
| criterion | current | grok |
|---|---|---|
| silhouette clarity | 3 | 4 |
| colour grouping | 2.5 | 4 |
| tree quality | 3.5 | 2.5 |
| grass quality | 2.5 | 3 |
| mine readability | 3 | 4 |
| path readability | 3 | 4 |
| negative space | 2 | 4 |
| mobile-scale readability | 3 | 4 |
| consistency with locked gnome | 3.5 | 3 |

Gnome consistency is lower because my flatter, cleaner matte world makes the detailed, textured gnome look slightly more "different material".

## Honest verdict
In composition, closer to the target's big-shape readability: island mass, path, mine mouth and negative space are clearly better. In surface richness it is further from the target: trees and meadow are too smooth and plain, without the leaf scallops, soft colour gradients and lush flower and leaf accents of the reference. **Not a full win.** I recommend taking the Grok island mass, path, mine composition, decoration density and light G1, and keeping or re-adding leaf breakup on the current trees.

## Needs human decision
Which components (if any) to adopt; whether flat meadow vs textured grass; G1 shadow mode; next round focus (crown leaf breakup + stone texture).
