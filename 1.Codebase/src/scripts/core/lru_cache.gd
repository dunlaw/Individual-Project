class_name LRUCache
extends RefCounted
var _capacity: int
var _cache: Dictionary = {}
var _access_order: Array[String] = []
func _init(capacity: int = 16) -> void:
	_capacity = maxi(capacity, 1)
func get_value(key: String) -> Variant:
	if not _cache.has(key):
		return null
	_promote(key)
	return _cache[key]
func put(key: String, value: Variant) -> void:
	if _cache.has(key):
		_cache[key] = value
		_promote(key)
		return
	if _cache.size() >= _capacity:
		_evict_oldest()
	_cache[key] = value
	_access_order.append(key)
func has_key(key: String) -> bool:
	return _cache.has(key)
func remove(key: String) -> void:
	if _cache.has(key):
		_cache.erase(key)
		_access_order.erase(key)
func clear() -> void:
	_cache.clear()
	_access_order.clear()
func size() -> int:
	return _cache.size()
func get_capacity() -> int:
	return _capacity
func set_capacity(new_capacity: int) -> void:
	_capacity = maxi(new_capacity, 1)
	while _cache.size() > _capacity:
		_evict_oldest()
func keys() -> Array:
	return _cache.keys()
func _promote(key: String) -> void:
	_access_order.erase(key)
	_access_order.append(key)
func _evict_oldest() -> void:
	if _access_order.is_empty():
		return
	var oldest_key: String = _access_order[0]
	_access_order.remove_at(0)
	_cache.erase(oldest_key)
