GNOMIT v009 — R3 GRASS APPLIED — 21.10.2026

Run PLAY_GRASS.cmd or Desktop/GnomiT Samples/v009 - 2026-10-21 - R3 Grass Applied.
Godot4.7.2; main.tscn; portrait432x960. Preferred monitor2 when available;
Godot currently reports one monitor, so it opens on screen0. No payment/install.
New custom user folder: GnomiT-R3-Grass-Applied-2026-10-21.
Previous game version, saves and shortcuts are preserved.

Applied the displayed grass candidate to a copy of R3_Island_Journey.
Includes the previously shown HomeStart cottage beside the gnome; new grass
clearance matches that composition. No extra rearrangement, six-level UI,
new rules, new audio or new animation added. Two existing surface levels remain.
The actual existing controller, progress, level definitions, reward logic and
sound scripts are byte-identical. Only two R3 presentation adapters changed.
One world-only GLB excludes the static guide; existing animated guide remains.

Native editable sources: native/GRASS_SOURCE.blend (exact shown candidate),
native/GRASS_RUNTIME_EXPORT.blend (runtime derivative), native/grass_ground_baked.png.
All .blend sources are ignored by Godot via native/.gdignore; Godot uses GLB.
New procedural ground colour was baked to1024x2048 for portability. Grass uses
original mesh vertex colours and shaders/reference_grass.gdshader. Scene lighting
is existing R3 Godot lighting, so it differs from a Cycles render/reference concept.
Blender exporter: tools/export_grass_world.py, Blender5.2.2, background/factory startup.
Source candidate provenance: e4bbaa48629c5f8a9073fde700afeeb6555f2126 in review repo,
PROJECT_HUB/builds/r3-reference-grass-geometry-2026-10-21/. Input SHA in receipts.
New authored work is export/bake/shader integration; old asset provenance is inherited.
No downloaded asset, new sound or new AI-generated raster image was introduced.
Origin documentation does not establish exclusive ownership or legal clearance.

Verification: fresh import without Blender auto-import;34 scripted checks pass:
map and both grass meshes/vertex colours, route161samples, exactly one guide,
existing2markers, level1 travel/goals/Play, both Volcano tutorial pages,
valid move and completed animation, return to map with grass intact.
Screenshots outputs/01..05 are actual432x960 game captures, not Blender render.
59 inherited .gd files unchanged; two changed presentation adapters are recorded.

A wrong UV binding originally caused a black rim; resolved by making the baked
GrassRuntimeUV render-active. Final GLB material explicitly references texCoord1.
Final screenshots inspected after correction. First failed imports/UV draft are
retained locally for history; they do not describe final import/visual state.
Testing is scripted, not human usability. No level win test or Android/performance
acceptance is claimed. Desktop art trial retains detailed native grass geometry.
