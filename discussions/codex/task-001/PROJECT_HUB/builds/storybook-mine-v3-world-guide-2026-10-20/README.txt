GNOMIT — STORYBOOK MINE V3
20 OCTOBER 2026 · ISOLATED NATIVE BLENDER / GODOT INTRODUCTION PREVIEW

WHAT THIS VERSION IS
A polish pass on the native V2 surface mine and its small introductory guide.
The world is editable geometry, not a background image or character cutout.
It remains an introduction preview: numbers 1 and 2 open guide cards; they do
not launch campaign match-3 levels, change saves, grant rewards or unlock nodes.
The separate current campaign and its launch pointer were not changed here.

TRY
Extract the complete package, open project.godot in Godot 4.7.2 and run
preview.tscn. PLAY_BLENDER_WORLD.cmd uses this computer's existing Godot path.
launch_preview.ps1 first imports the project, then opens the viewer. Neither
launcher installs software. Adjust the executable path on another computer.
The viewer prefers monitor 2 when available and otherwise uses screen index 0.
The final native capture reported one available screen and screen index 0;
this is a measured fallback, not proof that a second monitor was used.
Tap/click 1: welcome and matching introduction. Tap/click 2: mine entrance.
Got it closes a card. A drag of 12 px or more does not open a marker.
Motion OFF freezes the authored guide, vegetation, clouds, flame and lamp loop.
Reset view restores the small optional orbit. The guide stands off the road.

SEE
renders/final_native/GODOT_STORYBOOK_1S.png and GODOT_STORYBOOK_3S.png:
actual final Godot views at 432 x 960.
renders/final_native/GODOT_LEVEL_1_INTRO.png and GODOT_LEVEL_2_INTRO.png:
the actual guide cards, with no campaign launch simulated.
renders/GUIDE_WAVE_NATIVE.png and GUIDE_BLINK_NATIVE.png: native runtime poses.
renders/BLENDER_STORYBOOK_MINE.png: native Blender beauty render.
renders/GNOMIT_MINE_V3_NATIVE.mp4: actual eight-second silent native recording,
encoded from the local Godot AVI. The raw AVI stays in the authoring folder;
its exact identity is in verification/NATIVE_MOVIE_RECEIPT.json.

WHAT CHANGED FROM V2
- A lower, closer camera makes the aperture, threshold and inner supports
  readable. Two rails and five sleepers provide an interior mine prop.
- The 32 transverse boards remain equal rectangular cuboids, 1.68 m wide.
  Thickness is now 0.11 m. Portable oak textures have a warmer honey colour.
- A mathematical meadow colour texture, 44 sparse native grass tufts, varied
  stone/moss placement and quieter moss colours add local detail.
- Two cloud groups drift gently; the contained mine flame changes shape.
  Existing local foliage and lamp-light animation remain. The world root stays
  fixed; there is no whole-scene bounce used as a substitute for animation.
- The 1.22 m guide has a six-second greeting with anticipation, two articulated
  waves, recovery and a long rest. A separate head pivot gives a small nod.
  Separate eye groups blink twice; the head is not flattened to fake a blink.
  Torso breathing is subtle, while both boots remain stationary.
- The inherited transparent elemental GnomiT wordmark is unchanged. Its full
  original prompt and provenance remain under assets/branding/.

SOURCE / REBUILD
source/storybook_mine.blend is the editable native Blender 5.2.2 LTS scene.
source/build_scene.py builds it using scene_api.py, mine_asset.py,
boardwalk_asset.py, foliage_assets.py, guide_asset.py and world_polish.py.
Rebuild with the existing Blender installation:
Blender --background --factory-startup --disable-autoexec --python
<absolute path to source/build_scene.py>
source/.gdignore excludes the authoring directory from Godot import.
Five procedural textures (four oak maps and one meadow map) are packed into
the .blend and carried into GLB. No external model pack was introduced.

ANIMATION TRANSFER / VERIFIED EVIDENCE
Export explicitly uses export_anim_slide_to_zero=True. The GLB Godot import
uses 24 fps, matching the guide timeline. This fixed a real imported short-blink
timing mismatch. verification/GUIDE_RUNTIME_TIMELINE_BEFORE_FIX.json preserves
the failed intermediate result; it is history, not the final verdict.
renders/BLENDER_V3_AUDIT.json is PASS for the saved native .blend: all 145
integer frames, fixed boots/roots, independent head/blinks, greeting palm height,
loop endpoints and rectangular board dimensions.
renders/GUIDE_RUNTIME_AUDIT.json reports 51 checks and no failures against the
actual imported GLB animation. Explicit seek samples are distinct from
continuous playback, supplied by the native recording.
renders/final_native/GODOT_STORYBOOK_RECEIPT.json is the final native capture
receipt, including 432 x 960 views, markers/cards, motion and input checks.
Technical checks do not replace human artistic approval.

VISUAL LIMITATIONS / BOUNDARIES
Opening, honey boards and guide grounding are visibly improved. Tunnel rails
can still read like a ladder or rack; broad green terrain and pill-like moss
remain procedural-looking. Guide facial/wrist details are small at 432 x 960.
Stills alone do not prove appealing motion.
Human ART acceptance is PENDING. Human playtesting, Android acceptance and
mobile performance acceptance are NOT MEASURED. This is a heavy art prototype,
not a production-ready mobile world, completed campaign integration or legal
all-clear. Native authoring does not replace the separate rights audit.
No Unity, Maya, newly installed software, new sound or match-3 changes are part
of V3. V2 remains the predecessor; verification/PREDECESSOR_V2.json records it.
Root PREDECESSOR.json identifies V2. Earlier V1 history is preserved under
verification/INHERITED_V1_PREDECESSOR.json.

HANDOFF
ART_DIRECTION_BG.txt remains the accepted target, not a claim of completion.
INDEPENDENT_REVIEW.txt distinguishes actual visual observations from checks.
PROVENANCE.txt records the native-geometry / inherited bitmap-logo origin.
MANIFEST.json binds the included files. PACKAGE_RECEIPT.json alongside the
archive records ZIP readback; Git publication has a separate remote receipt.
Recommended code/integration model: GPT-6.1 Sol / High.
