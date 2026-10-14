extends RefCounted
const Levels=preload("res://scripts/levels.gd")
const VERSION: int = 2
const IDS: Array = ["entry","hollow","seam","pearl","goldore","terraces","bridge","rune","lantern","guardian"]
var save_path: String = "user://gnomit_storybook_progress_v2.json"
var data: Dictionary = {}
var last_error: String = ""
var _load_blocked:=false
func _init() -> void:
	data = fresh_data()
func fresh_data() -> Dictionary:
	return {"version":VERSION,"stars":{},"claimed":[],"light":0,"options":{"reduced_motion":false,"sound":true,"fullscreen":false}}
func load_progress(path: String = "user://gnomit_storybook_progress_v2.json") -> void:
	save_path = path
	data = fresh_data()
	last_error="";_load_blocked=false
	if not FileAccess.file_exists(save_path):
		return
	var f: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		_load_blocked=true
		last_error = "Saved progress could not be read. It stays untouched. Use New Expedition to restart."
		return
	var reader: JSON = JSON.new()
	var parse_error: Error = reader.parse(f.get_as_text())
	f.close()
	var parsed: Variant = reader.data
	if parse_error != OK or not parsed is Dictionary or parsed.get("version",0) != VERSION:
		_load_blocked=true
		last_error = "Saved progress is damaged. It stays untouched. Use New Expedition to restart."
		return
	var saved_stars: Variant = parsed.get("stars",{})
	if saved_stars is Dictionary:
		for id in IDS:
			var value: Variant = saved_stars.get(id,0)
			if value is int or value is float:
				if int(value) > 0:
					data.stars[id] = clampi(int(value),1,3)
	var saved_claimed: Variant = parsed.get("claimed",[])
	if saved_claimed is Array:
		for id in IDS:
			if id in saved_claimed and best_stars(id) > 0:
				data.claimed.append(id)
	data.light = data.claimed.size() * 10
	var saved_options: Variant = parsed.get("options",{})
	if saved_options is Dictionary:
		for key in data.options:
			if saved_options.get(key) is bool:
				data.options[key] = saved_options[key]
	# Ignore malformed impossible chains from edited/corrupt data.
	for id in IDS:
		if best_stars(id) > 0 and not prerequisites_met(id):
			data.stars.erase(id)
			data.claimed.erase(id)
	data.light = data.claimed.size() * 10
func prerequisites_met(id: String) -> bool:
	var path: Array=Levels.ordinary()
	var index: int=path.find(id)
	if index>=0:return index==0 or best_stars(path[index-1])>0
	if id in Levels.preparations():return best_stars(path.back())>0
	if id=="guardian":return best_stars("rune")>0 and best_stars("lantern")>0
	return false
func is_unlocked(id: String) -> bool:
	return id in IDS and prerequisites_met(id)
func best_stars(id: String) -> int:
	return int(data.stars.get(id,0))
func total_stars() -> int:
	var total: int = 0
	for id in IDS:
		total += best_stars(id)
	return total
func record_win(id: String, stars: int) -> Dictionary:
	if not is_unlocked(id):
		return {"accepted":false,"first_win":false,"reward":0,"stars":0,"saved":false}
	var first: bool = id not in data.claimed
	data.stars[id] = maxi(best_stars(id),clampi(stars,1,3))
	if first:
		data.claimed.append(id)
		data.light += 10
	var saved: bool = persist()
	return {"accepted":true,"first_win":first,"reward":10 if first else 0,"stars":best_stars(id),"saved":saved}
func option(key: String) -> bool:
	return bool(data.options.get(key,false))
func set_option(key: String, value: bool) -> void:
	if key in data.options:
		data.options[key] = value
		persist()
func persist() -> bool:
	if _load_blocked:return false
	var tmp: String = save_path + ".tmp"
	var f: FileAccess = FileAccess.open(tmp,FileAccess.WRITE)
	if f == null:
		last_error = "Could not save your progress."
		return false
	f.store_string(JSON.stringify(data))
	f.flush()
	f.close()
	var error: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp),ProjectSettings.globalize_path(save_path))
	if error != OK:
		last_error = "Could not replace the save file."
		return false
	last_error = ""
	return true
func reset() -> bool:
	_load_blocked=false
	data = fresh_data()
	return persist()
