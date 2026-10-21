GNOMIT — ПОСЛЕДНА ТОПЛА КАРТА С 6 НИВА — GPT REVIEW HANDOFF
Дата: 21.10.2026. Статус: VISUAL_TARGET_AND_SOURCE_HANDOFF / NOT_IMPLEMENTED.

1. Прочети PROMPT_FOR_GPT_BG.txt. Настройка: GPT-6.1 Sol / Extra high (xhigh).
2. Точната последна картинка е в пакета:
   REFERENCES/01_TARGET_WARM_MAP_6_LEVELS.png
   Предишните две картинки са история, не действаща цел.
3. Пакетът съдържа PNG байтовете, реални R3 Blender/Godot кадри, избрани
   точни Blender/Godot/gnome източници и documentation/provenance/manifests.
4. Пълният съществуващ R3 .blend/.glb/textures и gnome пакет вече са в Git.
   EXISTING_MATERIALS.json.txt дава immutable commit/път/bytes/SHA-256.
   Не е нужен човек да препраща файлове от чат в чат.

СВАЛЯНЕ
Repo остава REPORTS_ONLY, затова payload е запазен като base64 текстов
документ в собствената Codex папка, както предишните пакети. Това е пренос
на действителните байтове на PNG/източниците, не placeholder или manifest-only.
Копирай DOWNLOAD_HANDOFF.py.txt извън repo като DOWNLOAD_HANDOFF.py и изпълни:
python DOWNLOAD_HANDOFF.py --commit ТОЧНИЯТ_40_HEX_COMMIT --output НОВА_ПАПКА
Добави --with-existing за трите пълни вече публикувани Blender/gnome/nav пакета.
Скриптът само сваля/проверява/декодира; не стартира генератор, Blender или игра.
При clone има и offline режим --local-repo ПЪТ --commit ТОЧЕН_COMMIT.
Ако няма working download/decode, докладвай точно недостъпния файл;
не твърди, че си видял PNG по текстовото му описание.

ГРАНИЦИ
Генерираната картинка е визуална цел, не нова работеща карта или Blender файл.
Шестте номера са visual proposal, не доказателство за шест игрови нива.
Старата реална R3 WIP сцена още има 1 по пътя и 2 при входа.
GODOT_SOURCE_SELECTED не е runnable game; пълните предишни source зависимости са
посочени. Старият v006 и A/B v008 не са визуална основа за тази задача.
Прочети също CODEX_DIRECTION_BG.txt и дай независима позиция + peer response.
Само собствен GPT текстов доклад, без нова реализация/генериране/main/merge.
