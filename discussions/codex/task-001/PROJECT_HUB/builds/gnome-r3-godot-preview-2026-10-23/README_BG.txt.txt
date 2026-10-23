GNOMIT — ACCEPTED R3: ISOLATED GODOT PREVIEW — 2026-10-23

START
Double-click Launch_R3_Preview.cmd with Godot4.7.2 installed at its configured path.
Alternatively import godot/project.godot into Godot4.7.2 and run the project.
Replay greeting: original finite six-second action. Repeated click cannot restart it.
Reduced motion: immediate calm rest, greeting suppressed. Detail: sleeve close-up.
The app chooses monitor2 if available; this capture session detected one display.
No campaign save, gameplay scene or CURRENT_GNOMIT selector was changed.

BASELINE
native/GNOME_R3_ACCEPTED.blend is byte-identical to the accepted R3 Blender candidate.
R4 form/M2 finish/RigR3 sleeve/greeting remain locked. No blink added.
The old cosmetic torso-patch seam is retained, not fixed secretly during export.

REAL EVIDENCE
outputs/GODOT_R3_GREETING.gif: actual Godot viewport frames, not generated images.
The review GIF loops; the native action does not. Its decoded length is6000ms.
outputs/BLENDER_GODOT_KEYPOSES.png compares same poses/framing in separate studios.
outputs/GODOT_SLEEVE_KEYPOSES.png shows actual Godot detail stills.
Godot joint comparison at seven times: PASS, max2.40274005136598e-7m; rest0, foot nodes0.
GLB skin comparison:405 reference points, seven times, valid rest correspondence.
Godot/glTF matrix skinning differs from Blender Preserve Volume dual quaternions:
sampled maximum2.5392876868mm, RMS0.163346929mm. Strict0.1mm vertex parity FAIL remains
explicit in GLB_SKIN_PARITY.json. Joint PASS is not an exact-deformation PASS.
Both boot meshes have zero sampled GLB deformation relative to Blender.
Human Godot visual acceptance: PENDING. Android/performance: NOT_MEASURED.

TRANSPORT
Blender procedural beard/brow/iris/lantern fields were baked to textures on RAM-only
material copies; accepted native materials were not edited or saved. Arbitrary
shader mixtures require a PBR approximation. Godot uses its own AgX studio lighting
and SSAO. Neither pixel-identical colour nor matching area-light response is claimed.
Exporter starts key times at0.0 and ends6.0. Godot import is24fps with AnimationPlayer
optimiser/compression disabled. Initial one-frame-offset/fps30/optimised diagnostics
are preserved separately, with final PASS receipt identified in godot/verification/.
The original high-resolution studio geometry was exported without decimation.
Complexity:874805 triangles,445842 exported vertices,28 meshes. This is not a final
Android asset budget or a performance result. No engine executable is bundled.

SOURCES / REPRODUCIBILITY
source/export_preview.py uses the included accepted .blend and Blender5.2.2 only.
To reproduce, use a fresh work folder with source/, native/, documentation/ and empty
godot/assets/,godot/verification/; the script refuses an existing output GLB.
source/baked_transport_textures/ contains the actual baked PBR transport images.
godot/assets/gnome_r3.glb.import is essential: keep24fps and the disabled optimiser.
Godot regenerates .godot/ cache on first import; this cache is intentionally excluded.
verify_import.gd is named validate_import.gd in godot/verification/. Run it with:
Godot --headless --path godot --script verification/validate_import.gd
source/validate_glb_skin.py uses NumPy and measures the actual GLB against included
blender_reference.json; it reports MEASURED and explicit threshold flags.
verification/capture.gd captures144 fixed-time poses and functional playback checks.
It is not a realtime frame-rate benchmark. Raw PNG frame hashes are in the capture
receipt; the144 raw full PNGs are omitted from ZIP to avoid bulk duplication.
compose_godot_preview.py uses Pillow; the Blender comparison input paths name the
prior local R3 render directory. The composed comparison and accepted native are
included for review; that prior raw Blender sequence is not copied into this ZIP.

MANIFEST.json lists SHA-256 and bytes of every included file except itself.
The external .sha256.txt identifies the frozen ZIP. Remote publication/readback
receipts are written afterward in the Git handoff, not retrofitted into this archive.
