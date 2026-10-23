GNOMIT — REAL MAP CONTEXT R1 — 2026-10-23

Отвори Launch_Map_Integration_R1.cmd или godot/project.godot с Godot4.7.2.
Двигателят не е включен. Пробата предпочита monitor2, когато съществува.
Бутони: Old guide / Master R3, Find / Replay, Reduced. Влаченето разглежда картата.

КАКВО Е ГОТОВО
Заключеният R4/M2/RigR3 master е поставен на действителната избрана карта,
до къщичката, върху началото на дървената пътека. Същата позиция и yaw като
стария герой; scale .61279296875 от приетата M2 map-scale проба.
Светът, тревата, дърветата, мината, пътеката и оригиналната камера са точни копия.
Двата съществуващи маркера1/2 са запазени. Нови нива не са създавани.

СВЕТЛИНАТА Е КОНТЕКСТНА ПРОВЕРКА
Картата използва оригиналния profileB/ACES. Заключеното studio LightingR1B е
AgX и е запазено byte-identical в reference/lighting.gd. Не променяме глобалната
светлина на картата, за да скрием разлика; това не е нов lighting approval.

УМИШЛЕНО ОГРАНИЧЕНИЕ
Master има поздрав, но няма authored walking clip/leg rig за ходене.
Старият map gait изисква други Guide_* nodes. Затова тази проба блокира
route taps/travel вместо да плъзга героя или да измисля походка. Самият оригинален
map script остава непроменен, ограниченията са само в нов subclass.
Няма campaign integration, промени в match3, save, audio, нива или селектора.
Progress е временен in-memory stub без load/save. Собствен user directory.

ДОКАЗАТЕЛСТВА
95 автоматизирани контекстни проверки PASS: поставяне/камера/visibility,
спиране на route travel, drag,10bones/rest endpoints, foot-node/root stability,
finite greeting/replay/reduced motion/focus и midgreeting A/B/reset regressions.
Foot node checks не са измерване на всички skinnedvertices/contact shadows.
144 действителни Godot frames@24fps, GIF decoded6000ms. GIF се повтаря само
за преглед; native animation е finite. GIF palette256 е загубна компресия.
Raw144PNG са изключени от ZIP, технитеSHA са в CONTEXT_VALIDATION.json.
Outputs включва full432x960 A/B, greeting, rest/reduced и diagnostic4xcrops.
Няма измерена realtimeFPS, Android profile или човешки playtest.

ПРОИЗХОД / ЗАПАЗВАНЕ
MasterGLB и nativeblend са byte-identical. Нови Blender edits/exports няма.
INPUT_SNAPSHOT идентифицира всички копирани mapinputs и проверените оригинали.
Техническата документация не замества независим исторически лицензионен преглед.
MANIFEST свързва съдържанието; externalSHA свързва ZIP. Remoteproof е отделен
след създаването на неизменния ZIP.

ОТДЕЛНО: GROK TASK003 Е АКТИВИРАН
Main dabe1793398d9ceb6afcb0b459ba91e8687c6ac6, ownerPR8. Само новият grant.
Task001/002 са непроменени. Добавен е required approved_at timestamp.
Grok може да направи независим environment challenger, но не да пипа този
master или да merge-ва/заменя приетата игра. Proof и точният grant са включени.

СЛЕД ТАЗИ ПРОБА
Човешка оценка в реалната карта е PENDING. Android optimisation се прави
в отделно копие след визуален избор; master не се decimate-ва.
