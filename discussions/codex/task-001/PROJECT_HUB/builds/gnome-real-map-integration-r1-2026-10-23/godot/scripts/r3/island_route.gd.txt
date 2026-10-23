extends RefCounted
## Authored R3 road samples; arc length in metres, independent of progression.
var points: Array[Vector3] = []
var lengths: Array[float] = [0.0]
var docks: Dictionary = {}
const HALF_WIDTH := 0.62

func configure(model: Node3D) -> bool:
	var source := model.find_child("Road_Centerline", true, false)
	var extras: Dictionary = source.get_meta("extras", {}) if source != null else {}
	if source == null or not extras.has("sample_points_json"):
		push_error("R3 native route extras missing; no replacement route is invented.")
		return false
	var raw: Variant = JSON.parse_string(String(extras.sample_points_json))
	if not raw is Array or raw.size() < 2: return false
	for p in raw:
		# glTF transforms the nodes to Y-up, but exporter custom JSON stays Z-up.
		points.append(Vector3(float(p[0]), float(p[2]), -float(p[1])))
	for i in range(1, points.size()):
		lengths.append(lengths.back() + points[i - 1].distance_to(points[i]))
	for pair in [["entry", "Level_1_Anchor"], ["hollow", "Level_2_Anchor"]]:
		var anchor := model.find_child(pair[1], true, false) as Node3D
		if anchor == null: return false
		docks[pair[0]] = closest(anchor.global_position).s
	return true

func end_s() -> float: return lengths.back()
func dock_s(id: String) -> float: return float(docks.get(id, 0.0))
func point(s: float) -> Vector3:
	s = clampf(s, 0.0, end_s())
	for i in range(points.size() - 1):
		if s <= lengths[i + 1]:
			return points[i].lerp(points[i + 1], (s - lengths[i]) / maxf(0.001, lengths[i + 1] - lengths[i]))
	return points.back()

func closest(p: Vector3) -> Dictionary:
	var best := {"s": 0.0, "distance": INF}
	for i in range(points.size() - 1):
		var line := points[i + 1] - points[i]
		var t := clampf((p - points[i]).dot(line) / line.length_squared(), 0.0, 1.0)
		var d := p.distance_to(points[i] + line * t)
		if d < best.distance: best = {"s": lengths[i] + line.length() * t, "distance": d}
	return best

func screen_closest(p: Vector2, camera: Camera3D) -> Dictionary:
	var best := {"s": 0.0, "distance": INF, "tolerance": 0.0}
	for i in range(points.size() - 1):
		var a := camera.unproject_position(points[i])
		var b := camera.unproject_position(points[i + 1])
		var line := b - a
		var t := clampf((p - a).dot(line) / maxf(0.001, line.length_squared()), 0.0, 1.0)
		var d := p.distance_to(a + line * t)
		if d < best.distance:
			var q := points[i].lerp(points[i + 1], t)
			var width := camera.unproject_position(q + Vector3.RIGHT * HALF_WIDTH).distance_to(camera.unproject_position(q))
			best = {"s": lerpf(lengths[i], lengths[i + 1], t), "distance": d, "tolerance": maxf(11.0, width + 3.0)}
	return best
