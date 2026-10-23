GNOMIT — HOME START — РЕАЛНА BLENDER КОМПОЗИЦИОННА ПРОБА
21.10.2026. Етап1: домът е преместен до гнома при началото на пътеката.
Статус: NATIVE_COMPOSITION_PAIR_VERIFIED / HUMAN_ART_ACCEPTANCE_PENDING.

ОТВОРИ
RESULT/gnomit_home_start_composition_v001.blend — избраната editable сцена.
RESULT/RENDERS/03_COMPARISON_NATIVE_PIXELS.png — контрол A и кандидат B.
RESULT/RENDERS/02_HOME_START_432x960.png — действителният Blender рендер B.
REFERENCE/TARGET_HOME_START.png — генерираната визуална цел, не native render.
В Blender: отвори с изключено Auto Run, Numpad0 за камерата, F12 за рендер.
Сцената съдържа отделния оригинален Cottage и същия наличен native гном.

ЧЕСТНО СРАВНЕНИЕ
Оригиналният R3 beauty няма гном. Затова A е точният native R3 + същия гном
при старта; B мести само Mushroom_Cottage root (translation/yaw) и неговите
13 потомци. 633 други записа за обекти са проверени без разлика.
Камерата, светлината, world/view, геометрията на пътя/дървета/мината,
материалните слотове, позата/мащабът на гнома и разпръснатата украса се пазят.
Fingerprint-ите не са изчерпателен hash на всеки shader/modifier/curve параметър.

КАКВО ДОКАЗАХМЕ
Blender5.2.2 LTS: два реални 432x960 рендера при еднакви192samples/seed/frame.
Избраната .blend е отворена и рендерирана в нов процес. Ререндерът има63 RGB
пиксела с разлика до1 от255; не твърдим byte/pixel identity. Статистиката е
в PIXEL_AND_ORIGINALS_CHECK.json. GLB header/resources/route/anchors/camera
и свеж Blender reimport са проверени. World-only GLB изключва гнома, защото
runtime вече го управлява като отделен модел. Старите изходни .blend файлове
са сверени отново по SHA-256 и са непроменени.

ОГРАНИЧЕНИЯ И СЛЕДВАЩ РЕД
Това е само композиция. Сегашната врата е тясна/тъмна, а между нея и първите
дъски има тревна пролука. Не е добавен праг/свързваща пътека и не е сменен
моделът, за да не смесваме промяната с друго художествено решение.
Няма ново топло осветление,6 UI номера, нов поздрав, нови playable нива,
Godot интеграция, Android измерване или промяна на лични сейвове.
Планираният ред е: композиция -> отделен светлинен контрол ->6 visual markers
-> поздрав. Това не е обещание, че всички следващи етапи вече са изпълнени.

ПОВТОРЕНИЕ
SOURCE/build_composition.py и SOURCE/verify_composition.py работят относително
към папката си. За ново изпълнение копирай SOURCE/, INPUTS/ и SOURCE_BASELINE/
в НОВА работна папка без RESULT/. Пусни Blender background/factory-startup/
disable-autoexec/python-exit-code1 с --python NEW/SOURCE/build_composition.py,
после verify_composition.py. Не презаписвай стария RESULT или source модели.
check_pixels_and_sources.py изисква Pillow и измерва разликите, не ги прикрива.
GLB не носи Cycles world/area lights/AgX представянето; не е drop-in runtime.
