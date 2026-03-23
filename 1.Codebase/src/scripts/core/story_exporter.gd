extends RefCounted
class_name StoryExporter
const ERROR_CONTEXT := "StoryExporter"
const ErrorReporterBridge = preload("res://1.Codebase/src/scripts/core/error_reporter_bridge.gd")
func generate_html(game_state: Node, butterfly_tracker: Node) -> String:
	var data := _collect_data(game_state, butterfly_tracker)
	return _build_html(data)
func save_to_file(html_content: String, file_path: String) -> bool:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		ErrorReporterBridge.report_error(ERROR_CONTEXT, "Failed to open file for writing: %s" % file_path, -1, false, {})
		return false
	file.store_string(html_content)
	file.close()
	return true
func get_default_filename(game_state: Node) -> String:
	var mission_count := 0
	if game_state and game_state.has_method("get") or "missions_completed" in game_state:
		mission_count = game_state.missions_completed
	var date := Time.get_datetime_dict_from_system()
	return "GDA_Story_%04d-%02d-%02d.html" % [date.year, date.month, date.day]
func _collect_data(game_state: Node, butterfly_tracker: Node) -> Dictionary:
	var data: Dictionary = {}
	if game_state:
		data["reality_score"] = game_state.reality_score
		data["positive_energy"] = game_state.positive_energy
		data["entropy_level"] = game_state.entropy_level
		data["missions_completed"] = game_state.missions_completed
		data["current_mission"] = game_state.current_mission
		data["current_mission_title"] = game_state.current_mission_title
		data["game_phase"] = game_state.game_phase
		data["player_skills"] = game_state.player_skills.duplicate() if game_state.player_skills else {}
		data["event_log"] = game_state.event_log.duplicate() if game_state.event_log else []
	else:
		data["reality_score"] = 50
		data["positive_energy"] = 50
		data["entropy_level"] = 0
		data["missions_completed"] = 0
		data["current_mission"] = 0
		data["current_mission_title"] = ""
		data["game_phase"] = "honeymoon"
		data["player_skills"] = {}
		data["event_log"] = []
	if butterfly_tracker:
		data["recorded_choices"] = butterfly_tracker.recorded_choices.duplicate(true)
		data["current_scene"] = butterfly_tracker.current_scene_number
	else:
		data["recorded_choices"] = []
		data["current_scene"] = 0
	data["export_date"] = Time.get_datetime_dict_from_system()
	return data
func _build_html(data: Dictionary) -> String:
	var choices: Array = data.get("recorded_choices", [])
	var events: Array = data.get("event_log", [])
	var missions_completed: int = data.get("missions_completed", 0)
	var scene_count: int = data.get("current_scene", 0)
	var html := ""
	html += _html_head()
	html += "<body>\n"
	html += _cover_page(data)
	html += _stats_summary(data)
	html += _choice_chronicle(choices, scene_count)
	html += _events_section(events)
	html += _closing_page(data)
	html += "</body>\n</html>\n"
	return html
func _html_head() -> String:
	return """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>My Story – Glorious Deliverance Agency</title>
<style>
  :root {
    --parchment: #fdf6e3;
    --ink: #2c2416;
    --ink-light: #5c4a30;
    --gold: #b8860b;
    --gold-light: #d4a843;
    --red-dark: #8b1a1a;
    --teal: #1a5c5c;
    --shadow: rgba(0,0,0,0.15);
    --minor-color: #2e7d32;
    --major-color: #e65100;
    --critical-color: #b71c1c;
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    background: #d4c9a8;
    font-family: Georgia, 'Times New Roman', serif;
    color: var(--ink);
    line-height: 1.8;
  }

  .book {
    max-width: 820px;
    margin: 40px auto;
    background: var(--parchment);
    box-shadow: 0 4px 40px var(--shadow), inset 0 0 80px rgba(0,0,0,0.03);
    border-left: 6px solid var(--gold);
    border-right: 2px solid var(--gold-light);
  }

  .page {
    padding: 60px 70px;
    border-bottom: 1px solid rgba(184,134,11,0.2);
  }

  /* Cover */
  .cover {
    text-align: center;
    padding: 80px 70px;
    background: linear-gradient(160deg, #1a2340 0%, #0d1520 100%);
    color: #e8d5a0;
  }
  .cover .game-logo {
    font-size: 11px;
    letter-spacing: 6px;
    text-transform: uppercase;
    color: var(--gold-light);
    margin-bottom: 40px;
  }
  .cover h1 {
    font-size: 2.8em;
    font-weight: normal;
    letter-spacing: 2px;
    color: #f5e6b8;
    margin-bottom: 12px;
    text-shadow: 0 2px 8px rgba(0,0,0,0.5);
  }
  .cover .subtitle {
    font-size: 1.1em;
    color: #c8b880;
    font-style: italic;
    margin-bottom: 50px;
  }
  .cover .divider {
    border: none;
    border-top: 1px solid var(--gold);
    width: 60%;
    margin: 30px auto;
    opacity: 0.5;
  }
  .cover .meta {
    font-size: 0.85em;
    color: #a09060;
    letter-spacing: 1px;
  }
  .cover .stat-pill {
    display: inline-block;
    background: rgba(184,134,11,0.2);
    border: 1px solid var(--gold);
    border-radius: 20px;
    padding: 6px 20px;
    margin: 6px;
    font-size: 0.9em;
    color: var(--gold-light);
  }

  /* Section headings */
  .section-title {
    font-size: 1.6em;
    color: var(--red-dark);
    border-bottom: 2px solid var(--gold);
    padding-bottom: 10px;
    margin-bottom: 30px;
    letter-spacing: 1px;
  }
  .section-subtitle {
    font-size: 0.9em;
    color: var(--ink-light);
    font-style: italic;
    margin-top: -20px;
    margin-bottom: 30px;
  }

  /* Stats summary */
  .stats-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 20px;
    margin: 20px 0;
  }
  .stat-card {
    background: rgba(184,134,11,0.06);
    border: 1px solid rgba(184,134,11,0.3);
    border-radius: 8px;
    padding: 20px;
    text-align: center;
  }
  .stat-card .label {
    font-size: 0.78em;
    text-transform: uppercase;
    letter-spacing: 2px;
    color: var(--ink-light);
    margin-bottom: 8px;
  }
  .stat-card .value {
    font-size: 2.4em;
    color: var(--gold);
    font-weight: bold;
    line-height: 1;
  }
  .stat-card .value.low  { color: var(--critical-color); }
  .stat-card .value.mid  { color: var(--major-color); }
  .stat-card .value.high { color: var(--minor-color); }

  .skills-row {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
    margin-top: 20px;
  }
  .skill-tag {
    background: rgba(26,92,92,0.08);
    border: 1px solid rgba(26,92,92,0.3);
    border-radius: 4px;
    padding: 5px 14px;
    font-size: 0.85em;
    color: var(--teal);
  }

  /* Choice chronicle */
  .choice-entry {
    margin-bottom: 32px;
    border-left: 4px solid var(--gold-light);
    padding-left: 20px;
    position: relative;
  }
  .choice-entry.minor  { border-left-color: var(--minor-color); }
  .choice-entry.major  { border-left-color: var(--major-color); }
  .choice-entry.critical { border-left-color: var(--critical-color); }

  .choice-header {
    display: flex;
    align-items: baseline;
    gap: 12px;
    margin-bottom: 8px;
  }
  .choice-scene {
    font-size: 0.75em;
    color: var(--ink-light);
    letter-spacing: 1px;
    text-transform: uppercase;
    white-space: nowrap;
  }
  .choice-badge {
    font-size: 0.68em;
    text-transform: uppercase;
    letter-spacing: 1px;
    padding: 2px 10px;
    border-radius: 10px;
    font-weight: bold;
  }
  .choice-badge.minor    { background: #e8f5e9; color: var(--minor-color); border: 1px solid var(--minor-color); }
  .choice-badge.major    { background: #fff3e0; color: var(--major-color); border: 1px solid var(--major-color); }
  .choice-badge.critical { background: #ffebee; color: var(--critical-color); border: 1px solid var(--critical-color); }

  .choice-text {
    font-size: 1.05em;
    color: var(--ink);
    line-height: 1.6;
    margin-bottom: 10px;
  }

  .choice-stats {
    font-size: 0.78em;
    color: var(--ink-light);
    font-style: italic;
  }

  .consequence-list {
    margin-top: 10px;
    padding: 10px 14px;
    background: rgba(183,28,28,0.04);
    border-radius: 4px;
    border: 1px solid rgba(183,28,28,0.15);
  }
  .consequence-list .label {
    font-size: 0.75em;
    text-transform: uppercase;
    letter-spacing: 1px;
    color: var(--critical-color);
    margin-bottom: 6px;
  }
  .consequence-item {
    font-size: 0.85em;
    color: var(--ink-light);
    padding: 2px 0;
    padding-left: 12px;
    position: relative;
  }
  .consequence-item::before {
    content: "→";
    position: absolute;
    left: 0;
    color: var(--critical-color);
  }

  /* Events */
  .event-item {
    font-size: 0.88em;
    color: var(--ink-light);
    padding: 6px 0;
    border-bottom: 1px dotted rgba(184,134,11,0.2);
    display: flex;
    gap: 12px;
  }
  .event-type {
    font-size: 0.72em;
    text-transform: uppercase;
    letter-spacing: 1px;
    color: var(--gold);
    white-space: nowrap;
    min-width: 140px;
  }

  /* Closing */
  .closing {
    text-align: center;
  }
  .closing .phase-label {
    font-size: 0.85em;
    letter-spacing: 3px;
    text-transform: uppercase;
    color: var(--gold);
    margin-bottom: 20px;
  }
  .closing blockquote {
    font-size: 1.1em;
    font-style: italic;
    color: var(--ink-light);
    margin: 30px auto;
    max-width: 500px;
    padding: 20px 30px;
    border-left: 3px solid var(--gold);
    text-align: left;
  }
  .closing .entropy-note {
    font-size: 0.85em;
    color: var(--ink-light);
    margin-top: 20px;
  }

  .no-data {
    color: var(--ink-light);
    font-style: italic;
    padding: 20px 0;
  }

  @media print {
    body { background: white; }
    .book { box-shadow: none; margin: 0; max-width: 100%; border: none; }
    .page { padding: 40px; }
    .choice-entry { page-break-inside: avoid; }
  }
</style>
</head>
"""
func _cover_page(data: Dictionary) -> String:
	var date: Dictionary = data.get("export_date", {})
	var date_str := ""
	if not date.is_empty():
		date_str = "%04d-%02d-%02d" % [date.get("year", 0), date.get("month", 0), date.get("day", 0)]
	var missions: int = data.get("missions_completed", 0)
	var choices_count: int = (data.get("recorded_choices", []) as Array).size()
	var scene_count: int = data.get("current_scene", 0)
	var phase: String = data.get("game_phase", "honeymoon")
	var phase_label := _phase_display_name(phase)
	return """<div class="cover">
  <div class="game-logo">✦ Glorious Deliverance Agency ✦</div>
  <h1>My Playthrough Story</h1>
  <p class="subtitle">A unique chronicle of choices, consequences, and chaos</p>
  <hr class="divider">
  <div style="margin: 24px 0;">
    <span class="stat-pill">%d Missions</span>
    <span class="stat-pill">%d Choices</span>
    <span class="stat-pill">%d Scenes</span>
    <span class="stat-pill">%s</span>
  </div>
  <hr class="divider">
  <div class="meta">Generated on %s</div>
</div>
""" % [missions, choices_count, scene_count, phase_label, date_str]
func _stats_summary(data: Dictionary) -> String:
	var reality: int = data.get("reality_score", 50)
	var positive: int = data.get("positive_energy", 50)
	var entropy: int = data.get("entropy_level", 0)
	var skills: Dictionary = data.get("player_skills", {})
	var reality_class := _value_class(reality, true)
	var positive_class := _value_class(positive, false)
	var skills_html := ""
	if not skills.is_empty():
		for skill_name in skills:
			var skill_val = skills[skill_name]
			skills_html += '<span class="skill-tag">%s: %s</span>\n' % [
				_escape(skill_name.capitalize()), _escape(str(skill_val))
			]
	var skills_section := ""
	if not skills_html.is_empty():
		skills_section = '<div class="skills-row">%s</div>' % skills_html
	return """<div class="page">
  <h2 class="section-title">Final State</h2>
  <p class="section-subtitle">Where the journey left you</p>
  <div class="stats-grid">
    <div class="stat-card">
      <div class="label">Reality Score</div>
      <div class="value %s">%d</div>
    </div>
    <div class="stat-card">
      <div class="label">Positive Energy</div>
      <div class="value %s">%d</div>
    </div>
    <div class="stat-card">
      <div class="label">Entropy Level</div>
      <div class="value">%d</div>
    </div>
  </div>
  %s
</div>
""" % [reality_class, reality, positive_class, positive, entropy, skills_section]
func _choice_chronicle(choices: Array, _scene_count: int) -> String:
	if choices.is_empty():
		return """<div class="page">
  <h2 class="section-title">The Chronicle of Choices</h2>
  <p class="no-data">No choices have been recorded yet. Play some missions to build your story.</p>
</div>
"""
	var entries_html := ""
	for choice in choices:
		entries_html += _choice_entry_html(choice)
	return """<div class="page">
  <h2 class="section-title">The Chronicle of Choices</h2>
  <p class="section-subtitle">Every fork in the road that shaped your story</p>
  %s
</div>
""" % entries_html
func _choice_entry_html(choice: Dictionary) -> String:
	var choice_text: String = _escape(str(choice.get("choice_text", "Unknown choice")))
	var choice_type: String = str(choice.get("choice_type", "minor")).to_lower()
	var scene_num: int = choice.get("scene_number", 0)
	var stats: Dictionary = choice.get("stats_at_time", {})
	var consequences: Array = choice.get("consequences", [])
	var badge_label := choice_type.capitalize()
	var stats_html := ""
	if not stats.is_empty():
		var r = stats.get("reality", "?")
		var p = stats.get("positive", "?")
		var e = stats.get("entropy", "?")
		stats_html = '<div class="choice-stats">At this moment — Reality: %s · Positive Energy: %s · Entropy: %s</div>' % [r, p, e]
	var consequences_html := ""
	var triggered_consequences: Array = []
	for c in consequences:
		if c.get("triggered", false):
			triggered_consequences.append(c)
	if not triggered_consequences.is_empty():
		var items := ""
		for c in triggered_consequences:
			var desc: String = _escape(str(c.get("description", "A consequence manifested.")))
			var severity: String = str(c.get("severity", "medium"))
			items += '<div class="consequence-item">[%s] %s</div>\n' % [severity.capitalize(), desc]
		consequences_html = '<div class="consequence-list"><div class="label">Butterfly Effects</div>%s</div>' % items
	return """<div class="choice-entry %s">
  <div class="choice-header">
    <span class="choice-scene">Scene %d</span>
    <span class="choice-badge %s">%s</span>
  </div>
  <div class="choice-text">%s</div>
  %s
  %s
</div>
""" % [choice_type, scene_num, choice_type, badge_label, choice_text, stats_html, consequences_html]
func _events_section(events: Array) -> String:
	if events.is_empty():
		return ""
	var shown_events := events.slice(0, min(events.size(), 50))
	var items_html := ""
	for event in shown_events:
		var event_type: String = _escape(str(event.get("type", "event")))
		var details: Dictionary = event.get("details", {})
		var detail_str := ""
		if not details.is_empty():
			var parts: Array = []
			for key in details:
				parts.append("%s: %s" % [key, str(details[key])])
			detail_str = parts.slice(0, 3).reduce(func(a, b): return a + " · " + b, parts[0] if not parts.is_empty() else "")
		items_html += '<div class="event-item"><span class="event-type">%s</span><span>%s</span></div>\n' % [
			event_type.replace("_", " "),
			_escape(detail_str)
		]
	var note := ""
	if events.size() > 50:
		note = '<p style="font-size:0.8em; color: #888; margin-top:12px;">… and %d more events</p>' % (events.size() - 50)
	return """<div class="page">
  <h2 class="section-title">Key Events</h2>
  <p class="section-subtitle">Significant moments from the log</p>
  %s
  %s
</div>
""" % [items_html, note]
func _closing_page(data: Dictionary) -> String:
	var reality: int = data.get("reality_score", 50)
	var entropy: int = data.get("entropy_level", 0)
	var phase: String = data.get("game_phase", "honeymoon")
	var choices_count: int = (data.get("recorded_choices", []) as Array).size()
	var phase_label := _phase_display_name(phase)
	var ending_quote := _ending_quote(reality, entropy)
	return """<div class="page closing">
  <div class="phase-label">%s</div>
  <h2 class="section-title" style="text-align:center; border:none;">The Story Continues…</h2>
  <blockquote>%s</blockquote>
  <p class="entropy-note">
    This playthrough recorded <strong>%d choices</strong>.<br>
    Every decision shaped the entropy of the world.
  </p>
  <hr style="margin: 40px auto; width: 40%%; border: none; border-top: 1px solid #b8860b; opacity: 0.4;">
  <p style="font-size: 0.75em; color: #999; letter-spacing: 1px;">
    GLORIOUS DELIVERANCE AGENCY · PLAYTHROUGH EXPORT
  </p>
</div>
""" % [phase_label, ending_quote, choices_count]
func _phase_display_name(phase: String) -> String:
	match phase.to_lower():
		"honeymoon": return "Honeymoon Phase"
		"normal":    return "Normal Phase"
		"crisis":    return "Crisis Phase"
		_:           return phase.capitalize()
func _value_class(value: int, invert: bool) -> String:
	if invert:
		if value >= 70: return "high"
		if value >= 40: return "mid"
		return "low"
	else:
		if value <= 30: return "high"
		if value <= 60: return "mid"
		return "low"
func _ending_quote(reality: int, entropy: int) -> String:
	if reality <= 20:
		return "Reality had become a distant memory. The system won — or did it? Perhaps losing one's grip on reality is the first step toward a different kind of freedom."
	elif entropy >= 80:
		return "The world had grown chaotic beyond recognition. Yet in the entropy, there was something honest — a reflection of the truth that order was always just a comfortable illusion."
	elif reality >= 80:
		return "Against all odds, clarity prevailed. You saw through the performance, the manufactured smiles, the weaponized positivity. You kept your grip on what was real."
	else:
		return "Somewhere between compliance and rebellion, between the real and the constructed, your story carved its own path through the Glorious Deliverance Agency."
func _escape(text: String) -> String:
	return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")
