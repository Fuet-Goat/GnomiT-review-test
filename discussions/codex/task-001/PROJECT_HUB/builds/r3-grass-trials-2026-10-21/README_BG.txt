GNOMIT — ДВЕ НАШИ BLENDER ПРОБИ САМО НА ТРЕВАТА
21.10.2026. NATIVE_MATERIAL_TRIALS / HUMAN_CHOICE_PENDING / NOT_IN_GAME.

Отвори FINAL/01_GRASS_A.blend или FINAL/02_GRASS_B.blend с Auto Run off.
FINAL/RENDERS/03_COMPARISON_BASE_A_B.png показва еднакъв native кадър:
сегашна трева, по-мека A и по-текстурна B. Пикселите не са преоразмерени.
04_NATIVE_LAWN_PIXEL_ZOOM.png е изрично4x nearest-neighbour увеличение.
Сравнявай първо пълния432x960 кадър, после детайла.

Само Island_Grass_Cap slot0 ползва ново копие на материала.646 други object
records, старите материали, camera/light/world/render настройки и source .blend
са проверени без промяна. Проверките не обхващат всеки възможен shader property.
Няма нова геометрия, туфи/цветя, осветление, анимация, нива или game integration.
Procedural Noise/Bump графите работят в native Blender; bake/runtime shader
за Godot още не е изпълнен. Няма обещание за мобилна производителност.

Първите настройки в RESULT/ се оказаха визуално слаби при432x960 и са запазени.
FINAL/ съдържа ревизия с по-едра/силна фина структура. Има два вида материал,
не експеримент само с една променлива. A е слаба разлика; B е по-четима,
но може да прилича на сресана/филцова повърхност. Няма избран final победител.

SOURCE/ съдържа код и точни параметри; INPUTS/ съдържа exact native source.
За повторение копирай SOURCE/ и INPUTS/ в НОВА папка без RESULT/ и FINAL/;
пусни Blender background/factory-startup/disable-autoexec/python-exit-code1
с --python NEW/SOURCE/build_grass_trials.py, после refine_grass_trials.py.
Камера/светлина/seed/frame/samples са наследени от входния .blend.
Не презаписвай предходните резултати. Всички нови материали са процедурни,
без свалена текстура или нова генерирана bitmap картинка.
