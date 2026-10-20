GNOMIT - НЕПРИЛОЖЕНО ПРЕДЛОЖЕНИЕ ЗА ГЕНЕРАТОР

Това е пълен текстов source пакет, не готова Blender сцена.
Няма изпълнен Blender, .blend, .glb или рендер.
Средният панел определя композицията и стила.
Старата карта не се импортира и не се преработва.

За Codex, САМО при следващ възложен етап:
1. Прочети REPORT, PROVENANCE и всички SOURCE файлове.
2. Свери байтовете и SHA-256 по DELIVERY_MANIFEST.json.txt.
3. Копирай SOURCE в НОВА папка. Махни САМО последното .txt от името.
4. Изпълни първо draft само след преглед и човешко възлагане.

EXACT MATERIALIZATION MAP (one folder, no installation):
SOURCE/build_scene.py.txt -> ABS_SOURCE/build_scene.py
SOURCE/geometry.py.txt -> ABS_SOURCE/geometry.py
SOURCE/materials.py.txt -> ABS_SOURCE/materials.py
SOURCE/environment.py.txt -> ABS_SOURCE/environment.py
SOURCE/boardwalk.py.txt -> ABS_SOURCE/boardwalk.py
SOURCE/mine.py.txt -> ABS_SOURCE/mine.py
SOURCE/presentation.py.txt -> ABS_SOURCE/presentation.py
SOURCE/scene_settings.json.txt -> ABS_SOURCE/scene_settings.json
Copy bytes without rewriting line endings. Keep proposal originals unchanged.

FUTURE LOCAL COMMAND FROM THE OWNER'S HANDOFF, NOT EXECUTED HERE:
SURFACE: owner's local Blender background process, not this chat.
TASK_OWNER: Codex for a separately authorized local review/build stage.
MODEL/EFFORT: chosen in the local UI; this document changes neither.

& 'C:/Tools/Blender/blender-5.2.2-windows-x64/blender.exe' `
  --background --factory-startup --disable-autoexec `
  --python 'ABS_SOURCE/build_scene.py' -- `
  --output 'C:/Users/fruch/Documents/Codex/GnomiT_Playtests/AiryIsland_GPT_Candidate_v001' `
  --seed 402121 --render-mode draft

--output must be absolute and nonexistent. Existing directories are refused.
--seed overrides settings; all procedural geometry/scatter uses explicit streams.
--render-mode none saves/exports only; draft adds 432x960; final adds both sizes.
The example Blender path comes from the input brief; it was not located here.
No executable discovery, pip, external subprocess, network download or add-on install.

PLANNED OUTPUTS AFTER A SUCCESSFUL FUTURE BUILD:
gnomit_airy_island_v001.blend
EXPORT/gnomit_airy_island_v001.glb
TEXTURES/ (generated PNGs, also packed)
RENDERS/01_BEAUTY_432x960.png (draft/final)
RENDERS/02_BEAUTY_864x1920.png (final)
SCENE_METADATA.json, BUILD_RECEIPT.json, OUTPUT_MANIFEST.json,
SETTINGS_USED.json, PROVENANCE.json, README_BG.txt, SOURCE/ copies.

The future BUILD_RECEIPT does not grant visual acceptance. Render header checks
are not full PNG decoding or similarity tests. A fresh .blend reopen/render and
GLB reimport are explicitly left to Codex. See REVIEW_PLAN.txt for failure cases.
All comparison views must use actual Blender geometry, not concept-image edits.
If the build fails, retain its FAILED receipt/traceback; do not fabricate a render.

Current package contains source text only. No Blender, GLB, Godot or Android PASS.
