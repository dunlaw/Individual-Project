extends RefCounted
class_name AIUsageStatsStore
func save(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true
func load(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return { }
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return { }
	var content := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(content) != OK:
		return { }
	var data: Variant = json.data
	if data is Dictionary:
		return (data as Dictionary).duplicate(true)
	return { }
