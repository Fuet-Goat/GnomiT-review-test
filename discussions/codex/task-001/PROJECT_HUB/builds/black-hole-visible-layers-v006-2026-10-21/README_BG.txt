GNOMIT v006 — ВИДИМИ СЛОЕВЕ

Новото е малкото число върху всяка оранжева клетка. То показва оставащите
слоеве. Black Hole удря веднъж: 3→2, 2→1, 1→0. При 0 оранжевото изчезва.
В тази тестова подредба шест оранжеви клетки стават три с числа 2, 1 и 1.
SOIL 3 означава три клетки с почва, а не общ сбор на оставащите слоеве.

PLAY_BLACK_HOLE_TEST.cmd отваря теста. Размени Storm и Tornado в средата;
Reset възстановява същата подредба. Show move изпълнява същата размяна.
Това е авторска тестова подредба, не доказателство за изиграно ниво.

PLAY_CAMPAIGN.cmd и Desktop/GnomiT Samples/v006 отварят нормалната игра.
Latest сочи v006. Същият save профил и прогрес остават; v005 е запазена.
Няма нови правила, арт или звук. Числата са интерфейс, нарисуван в Godot.

ПРОВЕРКИ: 135 Core + 23 реален controller + 10 native проверки PASS.
Native screenshot-ите са от действителния renderer при 432×960; проверени
са моментът преди/при/след удара и същият краен резултат с reduced motion.
Човешка проба и Android/performance приемане остават за следваща проверка.
Godot вижда един екран, затова използва наличния, индекс 0.

Повторение с Godot 4.7.2: --headless --path ПАПКАТА --editor --import --quit;
после --script res://tests/test_black_hole_one_hit.gd и test_black_hole_campaign.gd.
Native: --script res://tests/capture_black_hole_one_hit.gd без --headless.
Промени/произход: source/IMPLEMENTATION.diff, BASE_INPUTS.json, PROVENANCE.json.
source/finalize_visible_layers.py е еднократен packaging/activation script;
не го стартирай повторно върху готовата версия. ZIP е пълният проект без engine/cache.

Модел/effort: GPT-6.1 Sol / High.
