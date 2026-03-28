extends Node
signal font_size_changed(scale: float)
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
const ERROR_CONTEXT := "FontManager"
enum FontSize {
	TINY = 0,
	SMALL = 1,
	NORMAL = 2,
	LARGE = 3,
	HUGE = 4,
}
var font_size_multipliers = {
	FontSize.TINY: 0.75,
	FontSize.SMALL: 0.85,
	FontSize.NORMAL: 1.0,
	FontSize.LARGE: 1.25,
	FontSize.HUGE: 1.5,
}
var current_font_size: int = FontSize.NORMAL
var current_multiplier: float = 1.0
const FALLBACK_FONT: Font = preload("res://1.Codebase/src/assets/font/LibreBaskerville-Bold.ttf")
const CJK_FONT: Font = preload("res://1.Codebase/src/assets/font/NotoSansCJKsc-Regular.otf")
const DEFAULT_EN_FONT := "Trajan Pro"
const DEFAULT_ZH_FONT := "Noto Sans SC"
const DEFAULT_DE_FONT := "Berlin Type"
const FONT_CATALOG := {
	DEFAULT_EN_FONT: { "font": preload("res://1.Codebase/src/assets/font/TrajanPro-Bold.otf"), "languages": ["en"] },
	"Libre Baskerville": { "font": FALLBACK_FONT, "languages": ["en"] },
	"Play": { "font": preload("res://1.Codebase/src/assets/font/Play-Regular.ttf"), "languages": ["en"] },
	"Ticketing": { "font": preload("res://1.Codebase/src/assets/font/Ticketing.ttf"), "languages": ["en"] },
	"Britannic": { "font": preload("res://1.Codebase/src/assets/font/britrdn_.ttf"), "languages": ["en"] },
	DEFAULT_ZH_FONT: { "font": CJK_FONT, "languages": ["zh"] },
	"Chiron Go Round": { "font": preload("res://1.Codebase/src/assets/font/ChironGoRoundTCVF.ttf"), "languages": ["zh"] },
	DEFAULT_DE_FONT: { "font": preload("res://1.Codebase/src/assets/font/BerlinType-Bold.otf"), "languages": ["de"] },
}
var REGISTERED_FONTS: Array[Font] = []
var _selected_fonts := {
	"en": DEFAULT_EN_FONT,
	"zh": DEFAULT_ZH_FONT,
	"de": DEFAULT_DE_FONT,
}
var _active_font: Font = null
var _tree_connected: bool = false
var _cached_controls: Dictionary = {}
var _cache_initialized: bool = false
func _report_info(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_info(ERROR_CONTEXT, message, details)
func _report_warning(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, message, details)
func _report_error(message: String, details: Dictionary = {}) -> void:
	ErrorReporterBridge.report_error(ERROR_CONTEXT, message, -1, false, details)
func _ready():
	_build_registered_fonts()
	load_font_settings()
	_register_font_fallbacks()
	_connect_tree_hooks()
	_connect_localization_signal()
	apply_language_font(_get_current_language())
	_report_info("Initialized. Font size: %s" % get_font_size_name())
func set_font_size(size: int):
	if size in font_size_multipliers:
		current_font_size = size
		current_multiplier = font_size_multipliers[size]
		font_size_changed.emit(current_multiplier)
		_report_info("Font size changed to: %s (%sx)" % [get_font_size_name(), current_multiplier])
func get_font_size() -> int:
	return current_font_size
func get_multiplier() -> float:
	return current_multiplier
func get_font_size_name() -> String:
	match current_font_size:
		FontSize.TINY:
			return "Tiny"
		FontSize.SMALL:
			return "Small"
		FontSize.NORMAL:
			return "Normal"
		FontSize.LARGE:
			return "Large"
		FontSize.HUGE:
			return "Huge"
		_:
			return "Unknown"
func get_scaled_font_size(base_size: int) -> int:
	return int(float(base_size) * current_multiplier)
func apply_to_label(label: Label, base_size: int):
	if label:
		label.add_theme_font_size_override("font_size", get_scaled_font_size(base_size))
func apply_to_button(button: Button, base_size: int):
	if button:
		button.add_theme_font_size_override("font_size", get_scaled_font_size(base_size))
func apply_to_rich_text(rich_text: RichTextLabel, base_size: int):
	if rich_text:
		rich_text.add_theme_font_size_override("normal_font_size", get_scaled_font_size(base_size))
func save_font_settings():
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("display", "font_size", current_font_size)
	config.set_value("display", "font_en", get_selected_font("en"))
	config.set_value("display", "font_zh", get_selected_font("zh"))
	config.save("user://settings.cfg")
func load_font_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		current_font_size = int(config.get_value("display", "font_size", FontSize.NORMAL))
		current_multiplier = font_size_multipliers.get(current_font_size, 1.0)
		var en_font := String(config.get_value("display", "font_en", DEFAULT_EN_FONT))
		var zh_font := String(config.get_value("display", "font_zh", DEFAULT_ZH_FONT))
		var de_font := String(config.get_value("display", "font_de", DEFAULT_DE_FONT))
		_selected_fonts["en"] = _resolve_font_key_for_language("en", en_font)
		_selected_fonts["zh"] = _resolve_font_key_for_language("zh", zh_font)
		_selected_fonts["de"] = _resolve_font_key_for_language("de", de_font)
func _build_registered_fonts() -> void:
	REGISTERED_FONTS.clear()
	for font_key in FONT_CATALOG.keys():
		var entry: Dictionary = FONT_CATALOG[font_key]
		var font: Font = entry.get("font", null)
		if font != null and not REGISTERED_FONTS.has(font):
			REGISTERED_FONTS.append(font)
func _register_font_fallbacks() -> void:
	if FALLBACK_FONT == null:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Fallback font is null, skipping fallback registration")
		return
	if not _is_font_valid(FALLBACK_FONT):
		ErrorReporterBridge.report_error(ERROR_CONTEXT, "Fallback font is invalid")
		return
	if CJK_FONT == null:
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "CJK font is null, Chinese text may not display correctly")
	elif not _is_font_valid(CJK_FONT):
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "CJK font is invalid, Chinese text may not display correctly")
	var theme_fonts := _get_theme_fonts()
	for font in REGISTERED_FONTS:
		if font == null:
			ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Skipping null font in registered fonts")
			continue
		_apply_fallbacks_to_font(font, "registered")
	for font in theme_fonts:
		_apply_fallbacks_to_font(font, "theme")
func _is_font_valid(font: Font) -> bool:
	if font == null:
		return false
	if font is FontFile:
		var font_file = font as FontFile
		if font_file.data.is_empty() and font_file.resource_path.is_empty():
			return false
	elif font is FontVariation:
		var variation := font as FontVariation
		if variation.base_font == null:
			return false
		return _is_font_valid(variation.base_font)
	return true
func _apply_fallbacks_to_font(font: Font, source: String) -> void:
	if not _is_font_valid(font):
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Skipping invalid font", { "source": source })
		return
	if not font.has_method("get_fallbacks") or not font.has_method("add_fallback"):
		return
	if font == CJK_FONT:
		return
	var fallbacks := font.get_fallbacks()
	if CJK_FONT != null and _is_font_valid(CJK_FONT) and not (CJK_FONT in fallbacks):
		font.add_fallback(CJK_FONT)
		_report_info("Added CJK fallback to: %s (%s)" % [font.resource_path, source])
	if font == FALLBACK_FONT:
		return
	if not _is_font_valid(FALLBACK_FONT):
		ErrorReporterBridge.report_error(ERROR_CONTEXT, "Fallback font is invalid, cannot add as fallback")
		return
	if FALLBACK_FONT in fallbacks:
		return
	font.add_fallback(FALLBACK_FONT)
func _get_theme_fonts() -> Array[Font]:
	var fonts: Array[Font] = []
	var themes: Array = []
	var project_theme: Theme = ThemeDB.get_project_theme()
	if project_theme != null:
		themes.append(project_theme)
	var default_theme: Theme = ThemeDB.get_default_theme()
	if default_theme != null and default_theme != project_theme:
		themes.append(default_theme)
	for theme in themes:
		if theme == null:
			continue
		var default_font: Font = theme.get_default_font()
		if default_font != null and not fonts.has(default_font):
			fonts.append(default_font)
		for type_name in theme.get_type_list():
			for font_name in theme.get_font_list(type_name):
				var themed_font: Font = theme.get_font(font_name, type_name)
				if themed_font != null and not fonts.has(themed_font):
					fonts.append(themed_font)
	return fonts
func get_safe_font(primary_font: Font) -> Font:
	if _is_font_valid(primary_font):
		return primary_font
	ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Primary font invalid, using fallback")
	return FALLBACK_FONT if _is_font_valid(FALLBACK_FONT) else null
func get_available_fonts_for_language(language: String) -> Array[String]:
	var lang := language if not language.is_empty() else "en"
	var options: Array[String] = []
	var preferred := _get_default_font_for_language(lang)
	if _font_supports_language(preferred, lang):
		options.append(preferred)
	for key in FONT_CATALOG.keys():
		if key == preferred:
			continue
		var entry: Dictionary = FONT_CATALOG[key]
		var langs: Array = entry.get("languages", [])
		if lang in langs and not (key in options):
			options.append(key)
	return options
func get_selected_font(language: String) -> String:
	if language == "zh":
		return _selected_fonts.get("zh", DEFAULT_ZH_FONT)
	if language == "de":
		return _selected_fonts.get("de", DEFAULT_DE_FONT)
	return _selected_fonts.get("en", DEFAULT_EN_FONT)
func set_selected_font(language: String, font_key: String) -> void:
	var lang := language if language in ["zh", "de"] else "en"
	var resolved := _resolve_font_key_for_language(lang, font_key)
	_selected_fonts[lang] = resolved
	save_font_settings()
func apply_language_font(language: String) -> void:
	var lang := language
	if lang.is_empty():
		lang = _get_current_language()
	var font_key := get_selected_font(lang)
	var font_res := _get_font_resource(font_key)
	var safe_font := get_safe_font(font_res)
	if safe_font == null:
		return
	_active_font = safe_font
	_apply_fallbacks_to_font(safe_font, "selected")
	_apply_theme_default_font(safe_font)
	_apply_font_to_open_controls(safe_font)
	_register_font_fallbacks()
func _connect_tree_hooks() -> void:
	if _tree_connected:
		return
	var tree := get_tree()
	if tree == null:
		return
	if not tree.node_added.is_connected(_on_tree_node_added):
		tree.node_added.connect(_on_tree_node_added)
	if not tree.node_removed.is_connected(_on_tree_node_removed):
		tree.node_removed.connect(_on_tree_node_removed)
	_tree_connected = true
func _connect_localization_signal() -> void:
	if not LocalizationManager:
		return
	if not LocalizationManager.has_signal("language_changed"):
		return
	if not LocalizationManager.language_changed.is_connected(_on_language_changed):
		LocalizationManager.language_changed.connect(_on_language_changed)
func _on_language_changed(new_language: String) -> void:
	apply_language_font(new_language)
func _on_tree_node_added(node: Node) -> void:
	if node is Control:
		_cached_controls[node] = true
		if _active_font != null:
			_apply_font_to_control(node as Control, _active_font, {})
func _on_tree_node_removed(node: Node) -> void:
	if node is Control:
		_cached_controls.erase(node)
func _initialize_control_cache() -> void:
	if _cache_initialized:
		return
	var tree := get_tree()
	if tree == null:
		return
	var root := tree.get_root()
	if root == null:
		return
	var controls := root.find_children("*", "Control", true, false)
	for node in controls:
		_cached_controls[node] = true
	_cache_initialized = true
func _apply_font_to_open_controls(font: Font) -> void:
	_initialize_control_cache()
	if _cached_controls.is_empty():
		return
	var themed: Dictionary = {}
	var invalid_nodes: Array = []
	for node in _cached_controls:
		if is_instance_valid(node):
			var control := node as Control
			_apply_font_to_control(control, font, themed)
		else:
			invalid_nodes.append(node)
	for invalid_node in invalid_nodes:
		_cached_controls.erase(invalid_node)
func _apply_font_to_control(control: Control, font: Font, themed: Dictionary) -> void:
	if control == null or font == null:
		return
	if control is Label or control is Button or control is RichTextLabel or control is LineEdit or control is TextEdit:
		control.add_theme_font_override("font", font)
	var theme: Theme = control.theme
	if theme == null:
		return
	if themed.has(theme):
		return
	theme.set_default_font(font)
	themed[theme] = true
func _resolve_font_key_for_language(language: String, requested: String) -> String:
	var options := get_available_fonts_for_language(language)
	if requested in options:
		return requested
	return _get_default_font_for_language(language)
func _get_font_resource(font_key: String) -> Font:
	if not FONT_CATALOG.has(font_key):
		return FALLBACK_FONT
	var entry: Dictionary = FONT_CATALOG[font_key]
	return entry.get("font", FALLBACK_FONT)
func _apply_theme_default_font(font: Font) -> void:
	if font == null:
		return
	var themes: Array = []
	var project_theme: Theme = ThemeDB.get_project_theme()
	if project_theme != null:
		themes.append(project_theme)
	var default_theme: Theme = ThemeDB.get_default_theme()
	if default_theme != null and default_theme != project_theme:
		themes.append(default_theme)
	for theme in themes:
		if theme:
			theme.set_default_font(font)
func _get_current_language() -> String:
	if ServiceLocator:
		var game_state: Node = ServiceLocator.get_game_state()
		if game_state and game_state.has_method("get"):
			var raw_lang: Variant = game_state.get("current_language")
			if typeof(raw_lang) == TYPE_STRING and not String(raw_lang).is_empty():
				return String(raw_lang)
	if LocalizationManager and LocalizationManager.has_method("get_language"):
		return LocalizationManager.get_language()
	return "en"
func _get_default_font_for_language(language: String) -> String:
	if language == "zh":
		return DEFAULT_ZH_FONT
	if language == "de":
		return DEFAULT_DE_FONT
	return DEFAULT_EN_FONT
func _font_supports_language(font_key: String, language: String) -> bool:
	if not FONT_CATALOG.has(font_key):
		return false
	var langs: Array = FONT_CATALOG[font_key].get("languages", [])
	return language in langs
