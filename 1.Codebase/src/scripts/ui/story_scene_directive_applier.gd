extends RefCounted
class_name StorySceneDirectiveApplier
const ERROR_CONTEXT := "StoryScene"
const DIRECTIVE_SNIPPET_LIMIT := 240
var _ui: StorySceneUIBindings = null
var _asset_controller: StoryAssetController = null
var _game_state_getter: Callable = Callable()
var _debug_logger: Callable = Callable()
func configure(
		ui_bindings: StorySceneUIBindings,
		asset_controller: StoryAssetController,
		game_state_getter: Callable,
		debug_logger: Callable,
) -> void:
	_ui = ui_bindings
	_asset_controller = asset_controller
	_game_state_getter = game_state_getter
	_debug_logger = debug_logger
func apply_scene_directives(directives: Dictionary) -> void:
	if directives.is_empty():
		return
	_log_debug("[StoryScene] Applying scene directives: %s" % [str(directives.keys())])
	var scene_data: Variant = directives.get("scene")
	if scene_data is Dictionary:
		_apply_scene_settings(scene_data)
	elif scene_data != null:
		_report_directive_issue(
			"scene",
			"Scene directives must be a dictionary",
			{ "scene": scene_data },
		)
	var characters_data: Variant = directives.get("characters")
	if characters_data is Dictionary:
		_apply_character_directives(characters_data)
	elif characters_data != null:
		_report_directive_issue(
			"characters",
			"Character directives must be a dictionary",
			{ "characters": characters_data },
		)
	var assets_data: Variant = directives.get("assets")
	if assets_data is Array:
		_apply_asset_directives(assets_data)
	elif assets_data != null:
		_report_directive_issue(
			"assets",
			"Asset directives must be an array",
			{ "assets": assets_data },
		)
func _apply_scene_settings(scene_data: Dictionary) -> void:
	if not _ui:
		return
	if _ui.dynamic_background and BackgroundLoader:
		var bg_id := String(scene_data.get("background", "")).strip_edges()
		if not bg_id.is_empty():
			var texture: Texture2D = BackgroundLoader.get_background_texture(bg_id)
			if texture:
				_ui.dynamic_background.texture = texture
			else:
				_report_directive_issue(
					"background",
					"Unknown background id",
					{
						"background": bg_id,
						"scene": scene_data.duplicate(true),
					},
				)
	if _ui.atmosphere_overlay:
		var atmosphere := String(scene_data.get("atmosphere", ""))
		var lighting := String(scene_data.get("lighting", ""))
		_ui.atmosphere_overlay.color = _get_atmosphere_overlay_color(atmosphere, lighting)
func _apply_character_directives(characters_data: Dictionary) -> void:
	if not _ui:
		return
	if _ui.character_sprites.is_empty() and _ui.character_containers.is_empty():
		_report_directive_issue(
			"character_layout",
			"No character slots available in UI bindings",
			{ "characters": characters_data.keys() },
		)
		return
	var active_ids: Dictionary = { }
	for raw_id in characters_data.keys():
		var entry_variant: Variant = characters_data[raw_id]
		if not (entry_variant is Dictionary):
			_report_directive_issue(
				"character_entry",
				"Character directive payload is not a dictionary",
				{
					"character": raw_id,
					"value": entry_variant,
				},
			)
			continue
		var canonical_id := _resolve_character_id(String(raw_id))
		if canonical_id == "":
			canonical_id = String(raw_id).to_lower()
		active_ids[canonical_id] = true
		var char_data: Dictionary = entry_variant
		var expression := String(char_data.get("expression", "neutral"))
		var sprite: TextureRect = _ui.character_sprites.get(canonical_id, null)
		var container: Control = _ui.character_containers.get(canonical_id, null)
		var name_label: Label = _ui.character_name_labels.get(canonical_id, null)
		if sprite == null:
			_report_directive_issue(
				"character_slot",
				"No sprite slot available for character",
				{
					"raw_character": raw_id,
					"resolved_character": canonical_id,
					"known_characters": _ui.character_sprites.keys(),
					"directive": char_data.duplicate(true),
				},
			)
			if container:
				container.visible = false
			continue
		if container:
			container.visible = true
		if sprite:
			var texture: Texture2D = null
			if CharacterExpressionLoader:
				texture = CharacterExpressionLoader.get_character_texture(canonical_id, expression)
			if texture:
				sprite.texture = texture
				sprite.visible = true
				sprite.modulate = Color(1, 1, 1, 1)
			elif CharacterExpressionLoader:
				_report_directive_issue(
					"character_expression",
					"Unknown character or expression; texture missing",
					{
						"raw_character": raw_id,
						"resolved_character": canonical_id,
						"expression": expression,
						"directive": char_data.duplicate(true),
					},
				)
			else:
				sprite.visible = true
				sprite.modulate = Color(1, 1, 1, 1)
		if name_label and CharacterExpressionLoader:
			var game_state := _get_game_state()
			var language: String = "en"
			if game_state != null:
				language = str(game_state.current_language)
			var use_chinese: bool = language == "zh"
			var display_name: String = str(CharacterExpressionLoader.get_character_name(canonical_id, use_chinese))
			if not display_name.is_empty():
				name_label.text = display_name
	for canonical_id in _ui.character_containers.keys():
		if active_ids.has(canonical_id):
			continue
		var container: Control = _ui.character_containers[canonical_id]
		if container:
			container.visible = false
	for canonical_id in _ui.character_sprites.keys():
		if active_ids.has(canonical_id):
			continue
		var sprite: TextureRect = _ui.character_sprites[canonical_id]
		if sprite:
			sprite.visible = false
func _apply_asset_directives(assets_data: Array) -> void:
	if assets_data.is_empty():
		return
	if not _asset_controller:
		return
	var npc_entries: Array = []
	for entry in assets_data:
		if not (entry is Dictionary):
			continue
		var entry_dict: Dictionary = entry
		var has_character := entry_dict.has("character_id") or entry_dict.has("npc_id")
		if has_character:
			npc_entries.append(entry_dict)
	if not npc_entries.is_empty() and _asset_controller.has_method("display_npc_entries"):
		_asset_controller.display_npc_entries(npc_entries)
	if _asset_controller.has_method("update_assets_from_directives"):
		_asset_controller.update_assets_from_directives(assets_data)
	else:
		_asset_controller.update_asset_display()
func _get_atmosphere_overlay_color(atmosphere: String, lighting: String) -> Color:
	var atmosphere_lc := atmosphere.to_lower()
	var lighting_lc := lighting.to_lower()
	if lighting_lc.find("bright") != -1 or atmosphere_lc.find("warm") != -1:
		return Color(1, 1, 1, 0.12)
	if lighting_lc.find("dim") != -1 or lighting_lc.find("dark") != -1:
		return Color(0, 0, 0, 0.45)
	if atmosphere_lc.find("oppressive") != -1 or atmosphere_lc.find("heavy") != -1:
		return Color(0, 0, 0, 0.4)
	if atmosphere_lc.find("electric") != -1:
		return Color(0.2, 0.4, 0.8, 0.25)
	return Color(0, 0, 0, 0.25)
func _resolve_character_id(raw_id: String) -> String:
	if CharacterExpressionLoader:
		var resolved: String = str(CharacterExpressionLoader.get_canonical_id(raw_id))
		if resolved != "":
			return resolved
	return raw_id.to_lower()
func _get_game_state() -> Node:
	if _game_state_getter.is_valid():
		var value: Variant = _game_state_getter.call()
		if value is Node and is_instance_valid(value):
			return value
	return null
func _report_directive_issue(component: String, reason: String, payload) -> void:
	var snippet := _directive_payload_to_snippet(payload)
	var details := {
		"component": component,
		"reason": reason,
		"ai_payload_snippet": snippet,
	}
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Invalid AI scene directive", details)
	_log_debug("[StoryScene][DirectiveError] %s | %s | %s" % [component, reason, snippet])
func _directive_payload_to_snippet(payload) -> String:
	var snippet := ""
	if payload is Dictionary or payload is Array:
		snippet = JSON.stringify(payload)
		if snippet.is_empty():
			snippet = var_to_str(payload)
	else:
		snippet = str(payload)
	if snippet.length() > DIRECTIVE_SNIPPET_LIMIT:
		snippet = snippet.substr(0, DIRECTIVE_SNIPPET_LIMIT) + "..."
	return snippet
func _log_debug(message: String) -> void:
	if _debug_logger.is_valid():
		_debug_logger.call(message)
