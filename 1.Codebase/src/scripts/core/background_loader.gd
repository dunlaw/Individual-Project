extends Node
const ERROR_CONTEXT := "BackgroundLoader"
const VERBOSE_LOGS := GameConstants.Debug.ENABLE_VERBOSE_LOGS
var backgrounds: Dictionary = {
	"default": {
		"path": "res://1.Codebase/src/assets/backgrounds/story_scene_background.png",
		"name": "Default Scene",
		"tags": ["default"],
	},
	"menu": {
		"path": "res://1.Codebase/src/assets/backgrounds/menu_background_dark.png",
		"name": "Dark Menu",
		"tags": ["menu", "dark"],
	},
	"journal": {
		"path": "res://1.Codebase/src/assets/backgrounds/journal_background.png",
		"name": "Journal",
		"tags": ["journal", "paper"],
	},
	"prayer": {
		"path": "res://1.Codebase/src/assets/backgrounds/prayer_background.png",
		"name": "Prayer Chamber",
		"tags": ["ritual", "mystical", "indoor"],
	},
	"forest": {
		"path": "res://1.Codebase/src/assets/backgrounds/Forest.png",
		"name": "Forest",
		"tags": ["nature", "outdoor", "green"],
	},
	"cave": {
		"path": "res://1.Codebase/src/assets/backgrounds/cave.png",
		"name": "Cave",
		"tags": ["dark", "underground", "stone"],
	},
	"temple": {
		"path": "res://1.Codebase/src/assets/backgrounds/Temple.png",
		"name": "Temple",
		"tags": ["mystical", "religious", "indoor"],
	},
	"ruins": {
		"path": "res://1.Codebase/src/assets/backgrounds/Ruins.png",
		"name": "Ruins",
		"tags": ["ancient", "outdoor", "stone"],
	},
	"laboratory": {
		"path": "res://1.Codebase/src/assets/backgrounds/Laboratory.png",
		"name": "Laboratory",
		"tags": ["tech", "indoor", "science"],
	},
	"throne_room": {
		"path": "res://1.Codebase/src/assets/backgrounds/throne_room.png",
		"name": "Throne Room",
		"tags": ["royal", "indoor", "grand"],
	},
	"bridge": {
		"path": "res://1.Codebase/src/assets/backgrounds/Bridge.png",
		"name": "Bridge",
		"tags": ["outdoor", "crossing", "danger"],
	},
	"portal_area": {
		"path": "res://1.Codebase/src/assets/backgrounds/portal_area.png",
		"name": "Portal Area",
		"tags": ["mystical", "magic", "transportation"],
	},
	"water": {
		"path": "res://1.Codebase/src/assets/backgrounds/water.png",
		"name": "Waterside",
		"tags": ["nature", "water", "outdoor"],
	},
	"fire": {
		"path": "res://1.Codebase/src/assets/backgrounds/Fire Area.png",
		"name": "Fire Area",
		"tags": ["danger", "hot", "hazard"],
	},
	"garden": {
		"path": "res://1.Codebase/src/assets/backgrounds/Garden.png",
		"name": "Garden",
		"tags": ["nature", "peaceful", "outdoor"],
	},
	"dungeon": {
		"path": "res://1.Codebase/src/assets/backgrounds/dungeon.png",
		"name": "Dungeon",
		"tags": ["dark", "underground", "prison"],
	},
	"crystal_cavern": {
		"path": "res://1.Codebase/src/assets/backgrounds/crystal_cavern.png",
		"name": "Crystal Cavern",
		"tags": ["mystical", "underground", "bright"],
	},
	"library": {
		"path": "res://1.Codebase/src/assets/backgrounds/Library.png",
		"name": "Library",
		"tags": ["indoor", "knowledge", "books"],
	},
	"safe_zone": {
		"path": "res://1.Codebase/src/assets/backgrounds/safe_zone.png",
		"name": "Safe Zone",
		"tags": ["safe", "rest", "campfire"],
	},
	"battlefield": {
		"path": "res://1.Codebase/src/assets/backgrounds/battlefield.png",
		"name": "Battlefield",
		"tags": ["combat", "outdoor", "danger"],
	},
}
const DEFAULT_BG_CACHE_CAPACITY := 10
var texture_cache: LRUCache = LRUCache.new(DEFAULT_BG_CACHE_CAPACITY)
func _ready():
	_preload_common_backgrounds()
func _exit_tree() -> void:
	texture_cache.clear()
func _preload_common_backgrounds():
	var common_ids = ["default", "menu", "journal", "prayer"]
	for bg_id in common_ids:
		if backgrounds.has(bg_id):
			get_background_texture(bg_id)
func get_background_texture(bg_id: String) -> Texture2D:
	var cached = texture_cache.get_value(bg_id)
	if cached != null:
		return cached
	if not backgrounds.has(bg_id):
		ErrorReporterBridge.report_warning(ERROR_CONTEXT, "Unknown background ID: %s, falling back to default" % bg_id, { "bg_id": bg_id })
		bg_id = "default"
		cached = texture_cache.get_value(bg_id)
		if cached != null:
			return cached
	if not backgrounds.has(bg_id):
		ErrorReporterBridge.report_error(ERROR_CONTEXT, "Default background not found")
		return null
	var bg_data = backgrounds[bg_id]
	var path = bg_data.get("path", "")
	if ResourceLoader.exists(path):
		var texture = load(path)
		if texture:
			texture_cache.put(bg_id, texture)
			if bg_data.get("is_placeholder", false):
				_debug_log("Using placeholder for '%s', consider adding proper background" % bg_id)
			else:
				_debug_log("Loaded background: %s" % bg_id)
			return texture
		ErrorReporterBridge.report_error(
			ERROR_CONTEXT,
			"Failed to load background: %s from path: %s" % [bg_id, path],
			ErrorCodes.Assets.BACKGROUND_LOAD_FAILED,
			false,
			{ "bg_id": bg_id, "path": path },
		)
		return null
	ErrorReporterBridge.report_error(
		ERROR_CONTEXT,
		"Background resource not found: %s at path: %s" % [bg_id, path],
		ErrorCodes.Assets.BACKGROUND_LOAD_FAILED,
		false,
		{ "bg_id": bg_id, "path": path },
	)
	return null
func get_background_by_tags(tags: Array) -> String:
	for bg_id in backgrounds.keys():
		var bg_data = backgrounds[bg_id]
		var bg_tags = bg_data.get("tags", [])
		for tag in tags:
			if tag in bg_tags:
				return bg_id
	return "default"
func get_all_background_ids() -> Array:
	return backgrounds.keys()
func get_background_info(bg_id: String) -> Dictionary:
	return backgrounds.get(bg_id, { })
func get_backgrounds_for_ai_prompt() -> String:
	var lines: Array[String] = []
	lines.append("")
	lines.append("=== Available Scene Backgrounds ===")
	lines.append("When generating scene directives, choose a background id from the list below.")
	lines.append("")
	var categories = {
		"Indoor Locations": ["temple", "laboratory", "throne_room", "dungeon", "library"],
		"Outdoor Locations": ["forest", "ruins", "bridge", "garden", "battlefield", "water"],
		"Mystical Locations": ["portal_area", "crystal_cavern", "prayer"],
		"Safe Areas": ["safe_zone"],
		"Hazardous Areas": ["cave", "fire"],
	}
	for category in categories.keys():
		lines.append("**%s:**" % category)
		for bg_id in categories[category]:
			if backgrounds.has(bg_id):
				var bg_data = backgrounds[bg_id]
				var name: String = bg_data.get("name", bg_id)
				var tags: Array = bg_data.get("tags", [])
				lines.append("- %s (id: %s) | tags: %s" % [name, bg_id, ", ".join(tags)])
		lines.append("")
	lines.append("In [SCENE_DIRECTIVES] JSON, set scene.background to one of the ids above.")
	lines.append('Example: "scene": {"background": "forest", "atmosphere": "mysterious", "lighting": "dim"}')
	return "\n".join(lines)
func clear_cache():
	texture_cache.clear()
	_debug_log("Texture cache cleared")
func reload_backgrounds():
	clear_cache()
	_preload_common_backgrounds()
	_debug_log("Backgrounds reloaded")
func _debug_log(message: String) -> void:
	if VERBOSE_LOGS:
		ErrorReporterBridge.report_info(ERROR_CONTEXT, message)
