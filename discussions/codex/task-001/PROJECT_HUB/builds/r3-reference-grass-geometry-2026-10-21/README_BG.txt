GNOMIT — GRASS REFERENCE CORRECTION — NATIVE BLENDER TRIAL
21.10.2026. NATIVE_ART_CANDIDATE / HUMAN_VISUAL_CHOICE_PENDING / NOT_IN_GAME.

The prior material-only A/B trials did not meet the intended grassy reference.
They remain preserved in the prior folder/commit, not accepted or silently replaced.
This candidate adds actual short curved, folded grass blades and a fine fringe.
Only grass changes: the original scene geometry/transforms, camera/lights/world,
path, guide, house, trees, stones and existing flowers stay in place.

Open FINAL/GNOMIT_REFERENCE_GRASS.blend with Auto Run off.
FINAL/RENDERS/01_REFERENCE_GRASS_432x960.png is the actual final192sample native render.
02_BEFORE_TRIAL_REFERENCE.png compares unchanged native baseline / candidate /
the concept. Native columns are original432x960 pixels. Only concept is resized.
The concept includes unimplemented UI and different golden lighting.
RESULT/ retains the sharper first geometry draft; FINAL/ is softer/narrower.

Rebuild in a NEW folder: copy INPUTS/ and SOURCE/ there without RESULT/ or FINAL/.
Blender5.2.2 background --factory-startup --disable-autoexec --python-exit-code1
--python NEW/SOURCE/build_reference_grass.py, then refine_reference_grass.py.
Guard utility is the preserved own script from the earlier native trial.
Seed261021; full dimensions, colours and actual counts are in FINAL_RECEIPT.json.

Inspection + fresh native reopen + real192sample rendering performed.
647 original recorded geometry/transforms and646 original material assignments
preserved. GrassCap slot0 receives a new copied material. Two new grass meshes.
Old material node inputs/links preserved; original grass lip/tuft materials fixed.
Checks do not inventory every Blender property. Blade footprint masking samples
roots/midpoints/tips, not an exhaustive geometric intersection proof.

Visible grass improvement is clear at native size. Reference fidelity remains
partial: grass is still fairly uniform/speckled; golden light and full prop style
are not changed in this bounded grass step. No human acceptance asserted.
No runtime export/bake/mobile optimisation, Godot build, game/save/main change.
The229k grass triangle count is native art evidence, not an Android budget.
