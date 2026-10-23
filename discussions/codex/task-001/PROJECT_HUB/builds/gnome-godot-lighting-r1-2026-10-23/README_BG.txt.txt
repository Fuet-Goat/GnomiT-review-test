GNOMIT — GODOT LIGHTING R1 — 2026-10-23

START
Launch_Lighting_R1.cmd opens candidate B with the same Replay/Reduced Motion/Detail.
Godot4.7.2 is required at the configured path; its binary is not bundled.
Alternatively import godot/project.godot and run. Baseline A is godot/baseline.tscn.
Accepted predecessor is preserved, not overwritten; no campaign/selector changes.

WHAT CHANGED
Only lighting.gd: neutral ambient(.36), procedural sky reflection environment,
key .95 at(-40,-28,0), fill .8, rim1.0, larger fill/rim source sizes, SSAO adjustment,
PCF key shadows with opacity.5, blur3 and angular size0 (PCSS noise probe rejected).
The old AgX/tone mapping, main camera, model, texture/shader payload and controls
are unchanged. preview.gd, glb and import configuration have exact predecessor bytes.
The subclass does not edit mesh materials, uniforms, bones, keys or actor placement.

REVIEW
LIGHTING_A_B.png: accepted Godot A(left), Lighting R1 B(right), same pose/camera.
M2_A_B_001/055.png: same views with Blender M2/R3 reference column.
FACE_M2_A_B.png: equal 222x222 crops of actual source pixels, no enlargement.
MAP_SIZE_1_TO_1.png: equal unscaled crops. Historical M2 world atleft; isolated
Godot A/B atmiddle/right. The full432x960 map controls are also included.
Map uses frozen priorM2 placement plus camera matching the current selected map.
The new hero is NOT integrated into the campaign. Omnis are translated/scaled to
this diagnostic placement, identical setup rule forA/B; shadow range100 for the map.
Its inferred rest projection is41.48631889197188px, not an Android/runtime footprint
or a claimed measurement of animated/occluded campaign gameplay.
GODOT_LIGHTING_R1_GREETING.gif: actual Godot frames, no generated/synthetic motion.
Review GIF loops and uses256-colour quantisation; native6-second action is finite.

CHECKS
Actual importer joint/rest/foot checks: PASS. Replay/reduced-motion assertions passed
in the captured app. New source/scene is parsed and executed by Godot.
Accepted native SHA0335bcc275bfbc8e3b7d3ea43bde2fad6c8ece5281a750007290ef154ac8bffc.
GLB SHA3b72702cb1c995d2553dddd4895a1e2327be14d5a22cc38a60a88603d47c529f.
All original materials/animation/skin payload remains in this exact GLB.
The accepted DQ-to-LBS sampled difference up to2.5392876868mm remains inherited.
No Android optimisation/profile; the studio model remains874805 triangles.

OBSERVATIONS / LIMITS
B reads more neutral in beard/skin, with clearer broad teal highlights and ground
contact. The final shadow is moderated, though it remains a directional cast shadow.
Lantern remains its simple baked warm pane; boot reflections are noticeable. Materials
were deliberately not changed. Human lighting choice is PENDING, not automatically PASS.
No new sleeve separation/hole is visible. The accepted torso-patch crease remains.

SOURCES
godot/preview.gd = exact accepted controls/camera source; lighting.gd = only lighting.
verification/lighting_stills.gd and lighting_motion_map.gd generated actual PNGs.
source/compose_lighting.py composes source pixels with labels and quantises GIF;
it does not retouch colours. It references historical local M2 map PNG for comparison.
Original Blender reference PNGs and accepted .blend are included.
Procedural reflection sky is runtime Godot configuration, no external HDR texture.
Raw144 movie PNGs are omitted from ZIP; their SHA-256 values are in receipts.
.godot import cache is excluded and regenerates from the included import config.
Failed probes are documented in logs; final receipts are STILL_CAPTURE,
MOTION_MAP_CAPTURE, FREEZE_MEDIA_RECEIPT and godot/verification/IMPORT_VALIDATION.
MANIFEST.json binds all files except itself; external .sha256.txt binds the ZIP.
Remote readback receipts are published afterward without changing this frozen ZIP.
