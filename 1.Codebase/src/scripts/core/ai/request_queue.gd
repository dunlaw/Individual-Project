extends RefCounted
class_name AIRequestQueue
class QueueEntry extends RefCounted:
	var prompt: String = ""
	var callback: Callable = Callable()
	var context: Dictionary = {}
	var force_mock: bool = false
	func _init(p_prompt: String, p_callback: Callable, p_context: Dictionary, p_force_mock: bool) -> void:
		prompt = p_prompt
		callback = p_callback if not p_callback.is_null() else Callable()
		context = p_context.duplicate(true)
		force_mock = p_force_mock
var _entries: Array[QueueEntry] = []
var _debug_delegate: Callable = Callable()
func configure(debug_delegate: Callable) -> void:
	_debug_delegate = debug_delegate
	_entries.clear()
func enqueue(prompt: String, callback: Callable, context: Dictionary, force_mock: bool, provider_label: String) -> void:
	var entry := QueueEntry.new(prompt, callback, context, force_mock)
	_entries.append(entry)
	_emit_debug(
		"request_queued",
		{
			"provider": provider_label,
			"queue_size": _entries.size(),
			"prompt_chars": prompt.length(),
		},
	)
func is_empty() -> bool:
	return _entries.is_empty()
func size() -> int:
	return _entries.size()
func take_next(provider_label: String) -> QueueEntry:
	if _entries.is_empty():
		return null
	var next_entry: QueueEntry = _entries.pop_front()
	_emit_debug(
		"request_dequeued",
		{
			"provider": provider_label,
			"queue_size": _entries.size(),
		},
	)
	return next_entry
func clear() -> void:
	_entries.clear()
func _emit_debug(stage: String, payload: Dictionary) -> void:
	if _debug_delegate.is_null():
		return
	_debug_delegate.call(stage, payload)
