GNOMIT — STORYBOOK MINE V1 · 19 OCTOBER 2026
NATIVE BLENDER + GODOT ART PREVIEW / HUMAN ART ACCEPTANCE PENDING

Start with renders/GODOT_STORYBOOK_1S.png and STORYBOOK_NATIVE_PREVIEW.mp4.
These are actual outputs from the supplied native scene, not separate concepts.
The eight-second movie is a scripted asset capture, not a human playtest.

OPEN
1. Extract all files into one folder. Open project.godot in Godot 4.7.2.
   Import, then run preview.tscn. launch_preview.ps1 uses this machine's
   existing Godot installation and opens monitor 2 (screen index 1).
   On another machine, adjust its executable path and monitor as needed.
2. Motion ON/OFF freezes/resumes both local vegetation motion and lamp energy.
   Drag horizontally for a small camera orbit; Reset view restores framing.
3. Open source/storybook_mine.blend in Blender 5.2.2 LTS for editable geometry.
   START_HERE is embedded in its Text datablocks. Textures are packed.
   source/.gdignore keeps Godot from importing the Blender authoring folder.

EDIT / REBUILD
Run Blender in background with --factory-startup --disable-autoexec
--python <full path to source/build_scene.py>.
The generator resolves all its output paths relative to its own folder.
It rebuilds the .blend, assets/storybook_mine.glb and Blender render.
scene_api.py supplies portable oak color/normal/endgrain/shadow maps.
mine_asset.py and foliage_assets.py contain the modular native geometry.
No pip packages are needed inside Blender's bundled Python environment.

CONTENT
Mine: real hollow shell, rounded arch stones, crafted timber/braces, fitted
grooves/fasteners, lantern geometry and actual Blender light-energy keys.
Approach: 34 fitted boards, continuous edge beams and capped posts.
Vegetation: rounded crown lobes, exposed leaves, attached flowers, shrubs,
flower groups and mushroom cottage. Local six-second motion loops.
Environment: rolling grass skin, soil-cut island, seated stones and clouds.

RUNTIME ADAPTATION
GLB contains four embedded 512px PNG maps, UVs, geometry and26 transform clips.
Godot combines the independently authored moving pivots; trunks stay rooted.
Core glTF does not preserve Blender lamp-energy F-curves. preview.gd uses
the source's seven energy values over six seconds, normalized around1.0.
Smoothstep approximates the Blender AUTO_CLAMPED easing; it is not asserted
to be a pixel-identical light transport or mathematical curve conversion.
Godot recreates soft daylight, fill, SSAO and tone mapping separately.
Shadow tuning reference: official Godot lights and shadows documentation:
https://docs.godotengine.org/en/4.7/tutorials/3d/lights_and_shadows.html

VERIFICATION
renders/ASSET_AUDIT.json: binary GLB layout, embedded images, native import.
renders/GODOT_STORYBOOK_RECEIPT.json: actual432x960 Forward+ screen1,
26 changed pivots,4 textures, lamp change, motion freeze/restore.
renders/fresh_import/: independent new-directory import/capture receipt.
No previous .godot cache or extracted textures were copied into that test.
ART_REVIEW_BG.txt: honest static artistic comparison against supplied picture.
MANIFEST.json lists exact included file byte counts and SHA-256 hashes.

LIMITS / NEXT HUMAN REVIEW
This moves toward the GPT reference; it does not reproduce its finished art.
The mine reads fairly shallow, stone/moss shapes remain repetitive, greenery
is sparser and the framing/wood tone differ. The current geometry is a heavy
unoptimized visual proof, not an Android performance-approved game asset.
The green surface is a mine gateway. Future journey remains mine -> underground
chapter with10sublevels+separateBoss. This preview adds none of those boards.
No match3, save, sound, rewards, progress or original Cradle files are changed.
No merge or automatic campaign integration. Artistic approval belongs to user.

RECOMMENDED NEXT IMPLEMENTATION MODEL: GPT-6.1 Sol / High.
