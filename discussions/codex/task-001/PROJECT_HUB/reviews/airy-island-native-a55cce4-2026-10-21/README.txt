GNOMIT AIRY ISLAND — ACTUAL NATIVE BLENDER REVIEW
Read REPORT.txt. 01_GPT_EXACT is the unmodified GPT source build;
02_CODEX_NORMALS_FIX is the separately rebuilt one-fix derivative.
Both include .blend, embedded-texture GLB, SOURCE and actual render.
REVIEW contains measured reopen/reimport evidence, source receipts and logs.
REFERENCE is the user-provided middle-panel visual target, not new authored art.

Open 02_CODEX_NORMALS_FIX/gnomit_airy_island_v001.blend in Blender with auto-run
scripts disabled. Numpad0 shows the portrait camera; F12 renders. This is a
static art candidate, not a game executable. Existing campaign is unchanged.

Rebuild in a new output directory using local Blender5.2.2:
blender --background --factory-startup --disable-autoexec --python-exit-code 1
  --python ABS/02_CODEX_NORMALS_FIX/SOURCE/build_scene.py --
  --output ABS/NEW_OUTPUT --seed 402121 --render-mode draft
Put this as ONE shell command with appropriately quoted absolute paths.
Source files must remain together, including scene_settings.json.
No network, add-ons, external image textures or services needed by generator.

The REVIEW/TOOLS helpers retain actual original absolute paths for evidence;
adapt them if rerunning elsewhere. Do not overwrite the preserved candidates.
Read PROVENANCE.json and each candidate's PROVENANCE; documentation does not
certify exclusive rights. MANIFEST.json verifies all other archive entries.
Next GPT source task: PROMPT_FOR_GPT_R2_BG.txt, GPT-6.1 Sol / High.
