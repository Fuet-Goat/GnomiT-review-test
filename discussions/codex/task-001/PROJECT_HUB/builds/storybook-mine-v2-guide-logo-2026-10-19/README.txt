GNOMIT — MINE V2: REGULAR BOARDS, WAVING GUIDE, TWO MARKERS AND ELEMENT WORDMARK
19 OCTOBER 2026 · ISOLATED ART / INTRODUCTION PREVIEW

SEE
renders/GODOT_STORYBOOK_1S.png — actual final Godot scene and UI.
renders/GODOT_LEVEL_1_INTRO.png and GODOT_LEVEL_2_INTRO.png — actual guide cards.
renders/STORYBOOK_V2_BRANDED_PREVIEW.mp4 — native eight-second silent preview.
renders/GUIDE_WAVE_CONTACT_SHEET.png — actual native movie pose samples,
cropped/enlarged solely for inspection; no sprite or artwork was edited.
assets/branding/gnomit_element_wordmark_v1.png — original transparent logo.

TRY
Extract the entire ZIP. Open project.godot in Godot4.7.2 and run preview.tscn.
launch_preview.ps1 uses this computer's existing Godot executable and monitor2.
Adjust that executable path/monitor if using another computer.
Tap/click1: a short welcome and matching introduction. Tap/click2: mine entrance.
Got it closes each card. A drag of12px or more does not open a number.
Mouse and touch use the same rule; actual Android acceptance is still unmeasured.
Motion OFF freezes vegetation, guide wave/breathing and lamp energy.
Reset view restores the small optional orbit. The waving guide stands offroad.

WHAT CHANGED
-32 identical four-corner transverse planks replace the tapered fan-shaped ones.
 Equal arclength placement, gentler bend, lower support and quieter pins.
 One stone and one buried flower group were moved clear of the approach.
-One1.22m rounded native gnome: red cap, ivory beard, teal coat, boots, lantern.
 Real articulated shoulder/elbow/hand greeting over six seconds; boots stay fixed.
-Number1 sits on the approach beside the guide; number2 is in front of the mine.
 These are52px Godot controls projected from authored native GLB empty anchors.
 Numbers and guide cards are UI overlays; they are not baked into the .blend.
-New GnomiT lettering: torch i, pickaxe T, green stone G, teal n, vortex o,
 volcanic m. It is one generated transparent bitmap concept with preserved alpha.
 The o is visibly more water-like than an airborne tornado. Final logo approval
 is pending. The source PNG and exact prompt/provenance are supplied unchanged.

SOURCE / REBUILD
Open source/storybook_mine.blend in Blender5.2.2 LTS. Packed native oak maps,
editable objects, authored six-second animation and START_HERE text are included.
Run Blender --background --factory-startup --disable-autoexec --python
<full path/source/build_scene.py> to rebuild this folder's native model/render.
source/boardwalk_asset.py and source/guide_asset.py are the new modules.
source/.gdignore prevents Godot trying to import the .blend authoring folder.
The logo is a separate2D UI asset, not part of the native Blender geometry.
Four512px native oak maps are embedded in GLB; Godot extracts them on import.
Lamp energy keys are recreated in Godot with normalized smoothstep easing,
which approximates Blender's AUTO_CLAMPED keys rather than claiming exact parity.

EVIDENCE
renders/BLENDER_V2_AUDIT.json checks32 rectangular cuboids,1.68m widths,
distinct hand poses at1s/3s, six-second loop closure and stationary boot matrices.
renders/GODOT_STORYBOOK_RECEIPT.json and renders/fresh_import/ receipt check
432x960, Forward+, monitor2,30 changing native pivots including4 guide pivots,
two projected markers, guide cards, drag-return rejection, motion freeze/restore,
and ACTUAL384x100 logo control bounds. The new-directory import copied only
viewer+GLB+logo, with no previous .godot cache, extracted textures or .blend.
check_routed_input.gd probes real Godot GUI event routing. The review's initial
GUI-release hypothesis was not reproduced and was withdrawn; no rewrite followed.
renders/logo_size_red/ contains intentional failing evidence BEFORE the
TextureRect minimum-size fix; final native and fresh-import receipts are PASS.
FINAL_V2_AUDIT.json binds final model and logo bytes to the checks.

BOUNDARY
Numbers currently open introduction cards. They DO NOT start campaign match3
levels, award progress or unlock saves. Display1/2 is this requested layout,
not a silent renumbering of the existing campaign. The surface mine remains
a gateway into the future underground chapter;10sublevels+Boss remain separate.
No Core/save/sound/reward/private-game or original Cradle edits. No merge.
V1 remains preserved; PREDECESSOR.json binds its unchanged GLB hash.
This is a heavy visual prototype, not an optimized mobile asset. The scene still
has the V1 art limitations: relatively shallow-looking cave, repeated stone/moss
forms and sparser scenery than the polished reference. Human art approval is
pending; Android, actual human interaction and performance acceptance unmeasured.

HANDOFF
ART_DIRECTION_BG.txt records the human-adopted polished casual3D art target.
The exact pasted source is preserved under references/. V2 is not claimed
to complete that future shape/material/light polish pass.
MANIFEST.json lists exact included bytes and SHA-256. One ZIP holds source,
runtime, branding, actual images/video, provenance and measured receipts.
RECOMMENDED CODE/INTEGRATION MODEL: GPT-6.1 Sol / High.
