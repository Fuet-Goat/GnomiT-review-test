GNOMIT - CODEX V004 - VOLUMETRIC GNOME

Това е отделен местен кандидат от Codex, а не работа от GPT task-003.
Отвори project.godot с Godot 4.7.2 или Desktop/GnomiT Samples/v004.
Началният изглед е в три четвърти; поздравът завършва и преминава в idle.
F1 / Front: отпред. F2 / 3/4: три четвърти. F3 / Profile: профил.
F4 / Whole scene: същата оригинална камера и малък размер върху картата.
B / Show Before: запазеният v002 модел, при същото осветление и избран изглед.
G / Greet again: повторение на поздрава. M / Motion: reduced motion.
При загуба на фокус движението се изключва; върни Motion: ON, после Greet again.
При избор на изглед камерата се променя само в отделния режим за оглед.

source/gnome_volumetric_candidate.blend е редактируемият финален Blender файл.
source/predecessor_world.blend е запазеният вход; не го презаписвай.
За rebuild: Blender 5.2.2 --background --python source/build_candidate.py.
Той ползва финалните guide_v5.py и volumetric_forms.py. prepare_local_copy.py е
историческият bootstrap, не заменя финалните авторски скриптове.
След rebuild: Godot --headless --editor --import --quit --path тази_папка.
Запази animation/fps=24 в двата GLB .import файла.
Native проверки/кадри: --script res://verification/check_and_capture.gd.
Запис: --script res://tools/capture_movie.gd --write-movie output.avi --fixed-fps 30.

Реалните кадри са в renders; BEFORE_AFTER и THREE_VIEWS са само подредба на
оригиналните screenshots. Видео GNOME_VOLUME_NATIVE.mp4: 250 кадъра, 30fps, без звук.
GALLERY.html събира сравненията и записа.

50 проверки на runtime/поза/стъпала/idle/reduced motion: PASS.
Трите основни нови форми са свързани затворени mesh обекти с положителен обем.
Камерата и 1290 обекта извън гнома са запазени. Кампанията продължава да сочи v001.
Това е PC художествена проба, не окончателно визуално приемане.
Героят е с 102732 evaluated триъгълника; оптимизация/LOD за Android не е правена.
Проверките не доказват качество на изражението, походка или работа на телефон.

Документация: PROVENANCE.json, ASSET_METADATA.json, MANIFEST.json и REPORT.txt.
Няма нов звук, промяна на match-3, прогрес, grants, main или merge.
Модел/effort за следваща доработка: GPT-6.1 Sol / High.
