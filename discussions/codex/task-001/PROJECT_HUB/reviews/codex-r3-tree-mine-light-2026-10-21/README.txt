CODEX R3 NATIVE ART PREVIEW
Open R3_SELECTED/gnomit_airy_island_v001.blend with autoexec disabled.
Numpad0 camera; F12 render. The GLB and all8 editable generator/settings files
are in the same selected directory. Not a playable Godot sample.
COMPARISON/R2_VS_CODEX_R3.png is side-by-side actual render pixels with labels.
DRAFT01_PRESERVED retains the first attempt, its source, model and outputs.
VERIFICATION records native reopen/protected geometry/GLB checks. REPORT names
remaining limits and observed glossy highlights; human acceptance stays pending.

Rebuild with local Blender5.2.2 into a NEW absolute output directory:
blender --background --factory-startup --disable-autoexec --python-exit-code 1
 --python ABS/R3_SELECTED/SOURCE/build_scene.py --
 --output ABS/NEW_OUTPUT --seed 402121 --render-mode final
Put the entire command on one line with appropriate shell quoting.
No external textures/addons/network needed.
For verification elsewhere, adapt the original absolute paths in REVIEW/TOOLS.
Generator basename v001 is retained from the source contract, not game version.
MANIFEST hashes every other entry. Actual Git download verification is separate
because it occurs after the archive is created. No game integration or merge.
