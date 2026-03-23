extends RefCounted
class_name SettingsMenuDisplaySection
static func coerce_vector2i(value: Variant, fallback: Vector2i) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		var vec: Vector2 = value
		return Vector2i(roundi(vec.x), roundi(vec.y))
	if value is Array:
		var arr: Array = value
		if arr.size() >= 2:
			return Vector2i(int(arr[0]), int(arr[1]))
	return fallback
static func get_closest_resolution_key(size: Vector2i, resolutions: Dictionary) -> int:
	var best_key: int = 0
	var best_score: int = 2147483647
	for key_variant: Variant in resolutions.keys():
		var key: int = int(key_variant)
		var candidate_variant: Variant = resolutions.get(key, resolutions[0])
		var candidate: Vector2i = coerce_vector2i(candidate_variant, resolutions[0])
		var score: int = int(abs(candidate.x - size.x) + abs(candidate.y - size.y))
		if score < best_score:
			best_score = score
			best_key = key
	return best_key
static func normalize_resolution(requested: Vector2i, resolutions: Dictionary, fallback: Vector2i) -> Vector2i:
	var effective := requested
	if effective.x <= 0 or effective.y <= 0:
		effective = fallback
	var nearest_key := get_closest_resolution_key(effective, resolutions)
	var normalized_variant: Variant = resolutions.get(nearest_key, resolutions[0])
	return coerce_vector2i(normalized_variant, resolutions[0])
static func get_option_metadata(option: OptionButton, index: int) -> String:
	if option == null:
		return ""
	if index < 0 or index >= option.item_count:
		return ""
	var meta: Variant = option.get_item_metadata(index)
	if typeof(meta) == TYPE_STRING:
		var meta_str: String = meta
		if not meta_str.is_empty():
			return meta_str
	return option.get_item_text(index)
static func populate_font_option(option: OptionButton, items: Array) -> void:
	if option == null:
		return
	option.clear()
	for item in items:
		var font_name := String(item)
		option.add_item(font_name)
		option.set_item_metadata(option.item_count - 1, font_name)
static func select_option_by_metadata(option: OptionButton, target: String, fallback: String) -> String:
	if option == null:
		return fallback
	var resolved := fallback
	var selected_idx := 0
	for i in range(option.item_count):
		var meta: Variant = option.get_item_metadata(i)
		var meta_str := ""
		if typeof(meta) == TYPE_STRING:
			meta_str = meta
		var text := option.get_item_text(i)
		if meta_str == target or text == target:
			selected_idx = i
			resolved = meta_str if not meta_str.is_empty() else text
			break
	option.select(selected_idx)
	var chosen := get_option_metadata(option, selected_idx)
	return chosen if not chosen.is_empty() else resolved
