extends Control
## Decorative underground scenery. Navigation and all live UI belong to main.
var scene_mode: String = "map":
	set(value):
		scene_mode = value
		queue_redraw()
var reduced_motion := false:
	set(value):
		reduced_motion = value
		queue_redraw()
var guardian_light: float = 0.0:
	set(value):
		guardian_light = clampf(value, 0.0, 1.0)
		queue_redraw()
var route_points: Array = []:
	set(value):
		route_points = value
		queue_redraw()
## Per-node unlocked flags; a route to node i uses route_open[i].
var route_open: Array = []:
	set(value):
		route_open = value
		queue_redraw()
var _clock := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	set_process(true)

func _process(delta: float) -> void:
	if not reduced_motion:
		_clock += delta
		queue_redraw()

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	_draw_depth_gradient()
	_draw_surface()
	_draw_roots()
	_draw_cave()
	_draw_ambient()
	if scene_mode == "map":
		_draw_route()
	elif scene_mode == "chamber":
		_draw_guardian()

func _draw_depth_gradient() -> void:
	var colors := [Color("122e3b"), Color("20413e"), Color("252e35"), Color("182535"), Color("111d31"), Color("0b1a2b")]
	var stops := [0.0, 0.15, 0.25, 0.48, 0.76, 1.0]
	for stripe in range(90):
		var y := float(stripe) / 90.0
		var segment := 0
		while segment < stops.size() - 2 and y > float(stops[segment + 1]):
			segment += 1
		var blend := (y - float(stops[segment])) / (float(stops[segment + 1]) - float(stops[segment]))
		var color: Color = colors[segment].lerp(colors[segment + 1], clampf(blend, 0.0, 1.0))
		draw_rect(Rect2(0, y * size.y, size.x, size.y / 90.0 + 1.0), color)
	# The broad center remains quiet beneath live controls.
	var shade := PackedVector2Array([Vector2(size.x * 0.18, 0), Vector2(size.x * 0.82, 0), Vector2(size.x * 0.74, size.y), Vector2(size.x * 0.26, size.y)])
	draw_colored_polygon(shade, Color(0.015, 0.045, 0.075, 0.16))

func _draw_surface() -> void:
	var horizon := size.y * 0.16
	var ridge := PackedVector2Array([Vector2(0, horizon + 12), Vector2(0, horizon)])
	for sample in range(25):
		var x := float(sample) * size.x / 24.0
		var y := horizon + sin(float(sample) * 0.66) * size.y * 0.005 + sin(float(sample) * 1.3) * size.y * 0.002
		ridge.append(Vector2(x, y))
	ridge.append(Vector2(size.x, horizon + 12))
	draw_colored_polygon(ridge, Color("365c45"))
	for sample in range(34):
		var x := float(sample) * size.x / 33.0
		var y := horizon + sin(float(sample) * 0.66) * size.y * 0.004
		var height := size.y * (0.005 + float(sample % 4) * 0.0015)
		draw_line(Vector2(x, y), Vector2(x + height * 0.35, y - height), Color("619064"), maxf(1.0, size.x / 520.0), true)
	# Side silhouettes suggest the entrance without competing with the title.
	for side in [-1, 1]:
		var x := size.x * (0.075 if side < 0 else 0.925)
		draw_line(Vector2(x, 0), Vector2(x + side * size.x * 0.028, horizon), Color("172d30"), size.x * 0.022, true)
		draw_circle(Vector2(x + side * size.x * 0.013, horizon * 0.35), size.x * 0.09, Color("1a3737"), true, -1.0, true)
		draw_circle(Vector2(x - side * size.x * 0.025, horizon * 0.15), size.x * 0.065, Color("23403c"), true, -1.0, true)

func _draw_roots() -> void:
	for side in [-1, 1]:
		for root_index in range(5):
			var edge := size.x * (0.04 + float(root_index) * 0.026)
			if side > 0:
				edge = size.x - edge
			var points := PackedVector2Array()
			for sample in range(9):
				var t := float(sample) / 8.0
				var drift := sin(t * 4.0 + float(root_index) * 0.72) * size.x * 0.026
				points.append(Vector2(edge + drift, size.y * (0.17 + t * (0.30 + float(root_index % 2) * 0.055))))
			draw_polyline(points, Color("443c34"), size.x * 0.012, true)
			draw_polyline(points, Color("66533d"), size.x * 0.003, true)
			var branch_start: Vector2 = points[4]
			var branch_end := branch_start + Vector2(float(-side) * size.x * 0.034, size.y * 0.06)
			draw_line(branch_start, branch_end, Color("544735"), size.x * 0.004, true)
		_mushroom(Vector2(size.x * (0.083 if side < 0 else 0.918), size.y * 0.37), size.x * 0.041, Color("cf865d"))
		_mushroom(Vector2(size.x * (0.127 if side < 0 else 0.87), size.y * 0.39), size.x * 0.025, Color("a18eb8"))

func _draw_cave() -> void:
	var left := PackedVector2Array([Vector2(0, size.y * 0.44), Vector2(size.x * 0.06, size.y * 0.50), Vector2(size.x * 0.10, size.y * 0.59), Vector2(size.x * 0.04, size.y * 0.71), Vector2(size.x * 0.13, size.y * 0.87), Vector2(size.x * 0.04, size.y), Vector2(0, size.y)])
	var right := PackedVector2Array()
	for point in left:
		right.append(Vector2(size.x - point.x, point.y))
	draw_colored_polygon(left, Color("182c3a"))
	draw_colored_polygon(right, Color("182c3a"))
	for side in [-1, 1]:
		for stone in range(5):
			var x := size.x * (0.022 + float(stone % 2) * 0.034)
			if side > 0:
				x = size.x - x
			var y := size.y * (0.53 + float(stone) * 0.092)
			var radius := size.x * (0.046 + float(stone % 3) * 0.011)
			draw_circle(Vector2(x, y), radius, Color(0.16, 0.23, 0.29, 0.7), true, -1.0, true)
			var color := Color("6a91b9") if stone % 2 == 0 else Color("9986bc")
			_crystal(Vector2(x + float(-side) * radius * 0.38, y), radius * 0.32, radius * 0.90, color)
			_crystal(Vector2(x + float(-side) * radius * 0.72, y + radius * 0.18), radius * 0.22, radius * 0.58, color.darkened(0.1))
		_mushroom(Vector2(size.x * (0.09 if side < 0 else 0.91), size.y * 0.91), size.x * 0.045, Color("6ca6ae"))
	var floor_points := PackedVector2Array([Vector2(0, size.y), Vector2(0, size.y * 0.965), Vector2(size.x * 0.22, size.y * 0.99), Vector2(size.x * 0.52, size.y * 0.979), Vector2(size.x * 0.8, size.y * 0.99), Vector2(size.x, size.y * 0.96), Vector2(size.x, size.y)])
	draw_colored_polygon(floor_points, Color("243747"))

func _mushroom(base: Vector2, radius: float, color: Color) -> void:
	draw_line(base, base - Vector2(0, radius * 0.75), Color("a4a491"), radius * 0.18, true)
	var cap := PackedVector2Array([base + Vector2(-radius, -radius * 0.65)])
	for sample in range(13):
		var angle := PI + PI * float(sample) / 12.0
		cap.append(base + Vector2(cos(angle) * radius, sin(angle) * radius * 0.58 - radius * 0.65))
	draw_colored_polygon(cap, color.darkened(0.16))
	draw_line(base + Vector2(-radius * 0.88, -radius * 0.65), base + Vector2(radius * 0.88, -radius * 0.65), color.lightened(0.18), maxf(1.0, radius * 0.07), true)
	draw_circle(base + Vector2(-radius * 0.32, -radius * 0.93), radius * 0.10, Color(0.91, 0.92, 0.76, 0.54), true, -1.0, true)

func _crystal(base: Vector2, width: float, height: float, color: Color) -> void:
	var crystal := PackedVector2Array([base + Vector2(-width, 0), base + Vector2(-width * 0.73, -height * 0.68), base + Vector2(0, -height), base + Vector2(width * 0.81, -height * 0.62), base + Vector2(width, 0)])
	draw_colored_polygon(crystal, color.darkened(0.27))
	draw_colored_polygon(PackedVector2Array([base, base + Vector2(0, -height), base + Vector2(width * 0.81, -height * 0.62), base + Vector2(width, 0)]), color)
	draw_line(base + Vector2(-width * 0.73, -height * 0.68), base + Vector2(0, -height), color.lightened(0.30), 1.2, true)

func _draw_ambient() -> void:
	for sparkle in range(23):
		var side := sparkle % 2
		var x := size.x * (0.027 + float(sparkle % 6) * 0.025)
		if side == 1:
			x = size.x - x
		var y := size.y * (0.23 + float(sparkle) * 0.031)
		var glow := 0.4 if reduced_motion else 0.22 + (sin(_clock * 1.2 + float(sparkle) * 1.84) + 1.0) * 0.15
		var point := Vector2(x, y)
		draw_circle(point, 3.0, Color(0.63, 0.85, 0.78, glow * 0.18), true, -1.0, true)
		draw_circle(point, 0.8 + float(sparkle % 2) * 0.4, Color(0.76, 0.90, 0.73, glow), true, -1.0, true)

func _draw_route() -> void:
	for index in range(route_points.size() - 1):
		var from := Vector2(route_points[index]) * size
		var to := Vector2(route_points[index + 1]) * size
		var open := index + 1 < route_open.size() and bool(route_open[index + 1])
		var curve := PackedVector2Array()
		for sample in range(25):
			var t := float(sample) / 24.0
			var point := from.lerp(to, t)
			point.x += sin(t * PI) * size.x * 0.035 * (-1.0 if index % 2 == 0 else 1.0)
			curve.append(point)
		if open:
			draw_polyline(curve, Color(0.95, 0.73, 0.38, 0.12), 8.0, true)
			draw_polyline(curve, Color("967746"), 3.0, true)
			draw_polyline(curve, Color("d5b679"), 1.1, true)
		else:
			for sample in range(0, curve.size() - 1, 2):
				draw_line(curve[sample], curve[mini(sample + 1, curve.size() - 1)], Color(0.41, 0.47, 0.49, 0.45), 2.1, true)

func _draw_guardian() -> void:
	var center := size * Vector2(0.5, 0.58)
	var scale_factor := minf(size.x / 720.0, size.y / 1100.0)
	var light := guardian_light
	var halo_color := Color(0.37, 0.72, 0.81, 0.08 + light * 0.17)
	var breath := 1.0 if reduced_motion else 1.0 + sin(_clock * 1.7) * 0.02
	draw_circle(center, 89.0 * scale_factor * breath, halo_color, true, -1.0, true)
	draw_circle(center, 69.0 * scale_factor, Color(0.28, 0.61, 0.77, light * 0.12), true, -1.0, true)
	draw_set_transform(center, 0, Vector2.ONE * scale_factor)
	# Friendly rounded stone silhouette with small leafy ears.
	draw_colored_polygon(PackedVector2Array([Vector2(-46, -34), Vector2(-68, -48), Vector2(-61, -12), Vector2(-42, 8)]), Color("586d69"))
	draw_colored_polygon(PackedVector2Array([Vector2(46, -34), Vector2(68, -48), Vector2(61, -12), Vector2(42, 8)]), Color("586d69"))
	var outline := PackedVector2Array([Vector2(-32, -54), Vector2(29, -57), Vector2(49, -33), Vector2(54, 16), Vector2(35, 49), Vector2(0, 58), Vector2(-38, 46), Vector2(-54, 10), Vector2(-50, -28)])
	draw_colored_polygon(outline, Color("425769"))
	var contour := outline.duplicate()
	contour.append(outline[0])
	draw_polyline(contour, Color("849389"), 2.1, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-32, -54), Vector2(0, -28), Vector2(-20, 5), Vector2(-50, -28)]), Color("566b77"))
	draw_colored_polygon(PackedVector2Array([Vector2(29, -57), Vector2(49, -33), Vector2(20, 5), Vector2(0, -28)]), Color("5c717a"))
	draw_polyline(PackedVector2Array([Vector2(-30, -38), Vector2(-34, -18), Vector2(-42, -6)]), Color("9aab9a"), 1.1, true)
	draw_polyline(PackedVector2Array([Vector2(38, 25), Vector2(22, 31), Vector2(17, 46)]), Color("718b8c"), 1.1, true)
	var eye_color := Color("85a7ac").lerp(Color("f5d986"), light)
	for side in [-1, 1]:
		var eye := Vector2(float(side) * 21, -2)
		if light < 0.15:
			draw_arc(eye - Vector2(0, 2), 9, 0.0, PI, 12, eye_color, 2.6, true)
		else:
			draw_circle(eye, 11, Color(eye_color.r, eye_color.g, eye_color.b, 0.17 + light * 0.30), true, -1.0, true)
			draw_circle(eye, 6.4, eye_color, true, -1.0, true)
			draw_circle(eye + Vector2(-1, 0), 2.8, Color("273745"), true, -1.0, true)
			draw_circle(eye + Vector2(-2, -3), 1.9, Color("fff6d7"), true, -1.0, true)
	draw_arc(Vector2(0, 13), 18, 0.15, PI - 0.15, 20, Color("b9bba2"), 2.4, true)
	var forehead := Color("6ca0b3").lerp(Color("ffdb7d"), light)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -44), Vector2(7, -34), Vector2(0, -23), Vector2(-7, -34)]), forehead)
	draw_line(Vector2(-5, -34), Vector2(0, -42), forehead.lightened(0.25), 1.2, true)
	draw_set_transform(Vector2.ZERO)
