GNOMIT v008 — ОТДЕЛНА VOLCANO A/B ПРОБА — 21.10.2026

Отвори Desktop/GnomiT Samples/v008 - 2026-10-21 - Volcano A-B Tutorial Sample.
Или PLAY_VOLCANO_AB.cmd. Избери A или B, после в картата отвори ниво 1/Play.
A: същите две страници с минианимации.
B: кратки подсказки до съществуващото гномче, докато играеш. След първо реално
използване на Volcano помощта се оттегля. Дъската не се блокира от B подсказката.
И двата варианта пазят директното преместване и ръчния material-match trigger.
Pause → Volcano Guide повтаря съществуващото обяснение и се записва като Help.
F8 приключва сесията и връща избора. Затварянето на прозореца също приключва записа.

Всяко стартиране е с нов профил, един и същ начален seed 42 и същите правила.
Нито една жива дъска не се рисува/подменя, за да се гарантират бонус или победа.
Еднакъв старт не гарантира еднакви дъски след различни ходове. Ако не се появи
подходяща възможност, това не се отчита като грешка на човека.

Записите са само локално, без лични данни или automatic upload:
%APPDATA%/GnomiT-Volcano-AB-2026-10-21/research_sessions/<session_id>/
events.jsonl = последователни събития; summary.json = кратко обобщение;
progress.json = отделният прогрес, ако е записан от съществуващия controller.
Бутонът Open local session records отваря тази папка.
JSONL съдържа точни source SHA-256, arm/seed, общ часовник, board-ready часовник,
подсказки, Help, ходове, реални births/activations, стабилизирана дъска и focus.
Петминутният прозорец е marker, не автоматично спиране, победа или оценка.
Нито автоматична активация, нито Next/Help доказват разбиране.

Твоето пробване на A и B е OWNER_PREVIEW. За отделно наблюдение на нов играч
използвай PLAY_VOLCANO_AB_OBSERVED.cmd — само етикет DECLARED_OBSERVED_SESSION,
не автоматична проверка, че човекът е начинаещ. Протоколът е в PROTOCOL_BG.txt.
Не давай двата урока последователно на един човек и после да го броим за
двама начинаещи. Няма проведено човешко A/B изследване в този пакет.

Проверки: 29 A/B +44 logger +135 Core +17 native =225 успешни проверки.
Шест реални scripted Godot PNG при 432×960 са в outputs/. Не са user test.
Godot вижда един екран; sample използва втория само ако engine го вижда.
Човешко разбиране, Android/touch/performance/D1/D7: NOT_MEASURED.
Окончателна контролирана transfer задача още не е реализирана в sample.

Основната игра/Latest остава v006. R3 светът е отделен WIP, не е включен тук.
Старите скриптове, решаващата логика, артът и звуците са запазени; документацията
на основата е в baseline_documentation/. Новият код е в scripts/research/.
Източници/проверки/ограничения: REPORT.txt, PROVENANCE.json, verification/.
Rebuild: Godot 4.7.2 --headless --editor --path ПАПКАТА --quit; после нормален run.
Тестове: --headless --path ПАПКАТА --script res://tests/test_volcano_ab.gd;
test_trial_log.gd; test_black_hole_one_hit.gd. Native capture: capture_volcano_ab.gd.
Използвай само нова папка при възстановяване от Git; не стартирай стари packaging
scripts от baseline_documentation/source върху готовите версии.
Следваща ограничена задача: GPT-6.1 Sol / Extra High (препоръка, не runtime доказателство).
