extends RefCounted
class_name MissionScenarioLibrary
static var _rng := RandomNumberGenerator.new()
static var _seeded := false
static var _scenario_index: int = 0
static var _cycles_completed: int = 0
const SCENARIOS: Array[Dictionary] = [
	{
		"id": "neon_cacophony",
		"assets": ["Neon Pylon Array", "Empathy Override Ramp", "Confetti Cannons"],
		"translation_keys": {
			"title": "OFFLINE_STORY_NEON_TITLE",
			"description": "OFFLINE_STORY_NEON_DESC",
			"objective": "OFFLINE_STORY_NEON_OBJECTIVE",
			"complication": "OFFLINE_STORY_NEON_COMPLICATION",
			"choices": "OFFLINE_STORY_NEON_CHOICES",
		},
		"fallback": {
			"title": "Operation Neon Cacophony",
			"description": "Round 1: You rig the smiling pylons into a dais of prisms and tell the crowd that every cheer is a metric of gratitude. The Positive Energy meter climbs and the scaffolding trembles, but the broadcast survives another minute. Round 2: Gloria insists on adding a new stream of affirmations, so you pair the Empathy Override ramp with tactical confetti detonations; the stage warps, the rate monitors spike, and your teammates chant faster. Round 3: The Council now demands a miracle, and the only way to keep the signal alive is to let Donkey bank the meter into emergency red while you narrate the collapse as performance art. The third ritual doubles the heat, makes the lanterns hiss, and buys enough time for the council to announce yet another ridiculous policy before the tower finally collapses on cue.",
			"objective": "Keep the Horizon Cheerfire broadcast alive through three escalating rounds so the Council can unveil another absurd policy while framing every collapse as triumph.",
			"complication": "The Positive Energy meter feeds the structural integrity sensors, so more cheers actually raise the heat and accelerate metal fatigue.",
			"choices": [
				"Redirect the neon pylons so the sparking beams kiss the gilded truss; the crowd applauds the extra shimmer, yet a column melts and the Council later claims the collapse proves optimism is a hazard.",
				"Prematurely trigger the confetti cannons so adhesive paste carpets the floor and forces everyone into frantic hugs; regulators threaten to cut power when the broadcast overruns.",
				"Let Donkey ramp the Positive Energy meter to emergency red, triggering the sprinklers and painting the ceremony as a wet rave while the platform quietly warps and several council members turn green.",
			],
			"consequence_success": [
				"The neon pylons surge with renewed intensity. Your maneuver bought another cycle of broadcast time, and the scaffolding trembles but holds. Gloria livestreams the moment as 'proof of positive infrastructure.'",
				"Confetti cannons fire in perfect synchronization. The Positive Energy meter climbs into the green zone — even as the structural sensors scream. The Council applauds from behind blast shields.",
				"The Horizon Cheerfire broadcast stabilizes. The crowd erupts. Metal groans under the thermal load, but the spectacle persists long enough for the Council to announce another policy.",
			],
			"consequence_fail": [
				"The neon pylons sputter and dim. The Positive Energy meter plummets, and a section of gilded truss buckles with an agonizing creak. Gloria narrates the failure as 'planned dramatic tension.'",
				"Confetti cannons misfire into the control panel, showering the crew in adhesive paste. The broadcast stutters. The Council demands an explanation wrapped in optimism.",
				"The crowd's cheering falters. Heat readings spike past safety thresholds and the scaffolding warps visibly. Gloria insists the warping 'adds character to the ceremony.'",
			],
			"followup_choices": [
				{"archetype": "cautious", "summary": "Reinforce the scaffolding supports before the next round of cheering raises the heat further."},
				{"archetype": "balanced", "summary": "Adjust the pylon output to maintain broadcast quality while managing structural stress."},
				{"archetype": "reckless", "summary": "Crank all pylons to maximum power and let the confetti cannons fire continuously until something breaks."},
				{"archetype": "positive", "summary": "Lead the crowd in synchronized mega-cheering to push the Positive Energy meter beyond its rated capacity."},
				{"archetype": "complain", "summary": "Report that the pylons were never rated for emotional energy conversion and the entire broadcast is an engineering hazard."},
			],
		},
	},
	{
		"id": "ash_echo_relay",
		"assets": ["Signal Tower", "Ashen Radio Console", "Fog Lantern"],
		"translation_keys": {
			"title": "OFFLINE_STORY_ASHEN_TITLE",
			"description": "OFFLINE_STORY_ASHEN_DESC",
			"objective": "OFFLINE_STORY_ASHEN_OBJECTIVE",
			"complication": "OFFLINE_STORY_ASHEN_COMPLICATION",
			"choices": "OFFLINE_STORY_ASHEN_CHOICES",
		},
		"fallback": {
			"title": "Operation Ashen Relay",
			"description": "Three days ago, a shipping lane collapsed into ash-gray fog after the AI server outage left the drones directionless. Gloria insists with religious fervor that the damaged signal tower must broadcast continuous motivational jingles to keep the gratitude drones from dissolving into a panic cascade. The tower stands half-buried in ash, its mechanisms corroded, its antenna bent at an ugly angle. You and Donkey have to physically coax the old radio console back to life, deciphering decades-old schematics while Gloria livestreams your struggle as proof of human ingenuity. Meanwhile, the crew choreographs increasingly frantic synchronized applause routines, believing that the collective sound keeps the fog at bay. Each round of applause parts the fog for exactly ninety seconds. After that, it rolls back in thicker, angrier, more invasive. The drones circle overhead, their infrared eyes blinking in the murk, waiting for their next instruction.",
			"objective": "Reactivate the ash-covered relay and broadcast a motivational jingle that will sell the spectacle as a breakthrough, prove that human emotion can overcome infrastructure failure and natural disaster before the corporate client sends a rescue team that will replace you entirely.",
			"complication": "Every motivational jingle you broadcast stokes the fog instead of calming it. More applause means less visibility. Faster corrosion of the tower. You are locked in a paradox: the more hope you broadcast, the worse conditions become. The system rewards despair with clarity, optimism with disaster. And Gloria expects results in thirty minutes.",
			"choices": [
				"Convert the signal tower into a theater spotlight and convince the drones the fog is part of 'immersive theatre'; the crowd cheers but a sudden gust sweeps the lanterns into the abyss.",
				"Let Donkey shout gratitude over the open microphone so the fog condenses into glittery ash; security warns the structural supports are melting.",
				"Short the console to play a lullaby, lowering Positive Energy but calming the fog, until the Council accuses you of sabotaging the spectacle.",
			],
			"consequence_success": [
				"The signal tower crackles back to life and the motivational jingle pierces the ash fog. For exactly ninety seconds, the drones reform into orderly formation. Gloria calls it a miracle of optimism.",
				"The old radio console hums with renewed power. The fog parts briefly — just long enough for the broadcast to register on the corporate client's monitors. The applause routine intensifies.",
				"Donkey's shouting somehow resonates with the tower frequency. The fog retreats three meters. Gloria immediately claims credit and adjusts the livestream angle.",
			],
			"consequence_fail": [
				"The signal tower whines and falls silent. Ash fog rolls in thicker than before, and the drones begin circling in confused spirals. Gloria insists this is 'atmospheric storytelling.'",
				"The radio console sparks and the motivational jingle distorts into a haunting wail. The fog thickens. The crew's synchronized applause falters as visibility drops to arm's length.",
				"The tower antenna bends further under the corrosion. The jingle broadcast cuts out, and the fog surges forward like it was waiting. The corporate client's rescue team ETA updates ominously.",
			],
			"followup_choices": [
				{"archetype": "cautious", "summary": "Run diagnostics on the corroded antenna before attempting another broadcast cycle."},
				{"archetype": "balanced", "summary": "Adjust the jingle frequency to reduce fog agitation while maintaining drone guidance."},
				{"archetype": "reckless", "summary": "Overload the radio console to maximum power and blast through the fog with raw signal strength."},
				{"archetype": "positive", "summary": "Organize a double-time applause routine to part the fog for a longer window."},
				{"archetype": "complain", "summary": "Inform Gloria that broadcasting optimism into corrosive fog is literally making conditions worse."},
			],
		},
	},
	{
		"id": "crystal_mandate",
		"assets": ["Transparency Crystals", "Governance Ledger", "Broadcast Drone Fleet"],
		"translation_keys": {
			"title": "OFFLINE_STORY_CRYSTAL_TITLE",
			"description": "OFFLINE_STORY_CRYSTAL_DESC",
			"objective": "OFFLINE_STORY_CRYSTAL_OBJECTIVE",
			"complication": "OFFLINE_STORY_CRYSTAL_COMPLICATION",
			"choices": "OFFLINE_STORY_CRYSTAL_CHOICES",
		},
		"fallback": {
			"title": "Operation Crystal Mandate",
			"description": "Round 1: The Council launches the Transparent Governance Initiative, requiring every policy document to be transcribed onto Transparency Crystals and broadcast via drone fleet. You are handed a Governance Ledger and told the crystals are ready. They require sunlight. It is 11pm.\n\nRound 2: You rig emergency spotlights to simulate sunlight while Donkey reads policy documents into a broadcast microphone, mispronouncing every third word but holding eye contact with the cameras. The crystals hum. Citizens watch. Nobody understands what they are seeing.\n\nRound 3: The Council demands the crystals display next year's mandate before midnight. You have the Ledger, two spotlights, and a drone fleet that has begun autonomously looping yesterday's documents. The crystals are very pretty. Nothing is transparent.",
			"objective": "Broadcast three rounds of governance documentation via the Transparency Crystals before the Council declares the initiative a success and immediately classifies all footage.",
			"complication": "The crystals refract artificial light into illegible rainbow smears, so the clearer you try to make the message, the more beautiful and incomprehensible it becomes.",
			"choices": [
				"Tilt the crystals into a massive light display and convince the crowd the spectacle is a symbol of governance; three officials photograph it while the Ledger entries remain unread.",
				"Feed the Ledger text through Donkey's microphone at triple speed so the broadcast claims completeness before anyone can check; the drone fleet begins looping the fast-read in perpetuity.",
				"Dim the spotlights and let the crystals show only elegant silence; journalists report it as an artistic statement and the Council claims it was intentional.",
			],
			"consequence_success": [
				"The Transparency Crystals refract the emergency spotlights into a dazzling rainbow cascade. The crowd gasps. Nobody can read a single word, but the visual is spectacular. The Council nods approvingly.",
				"Donkey's triple-speed reading creates a hypnotic drone that the broadcast drones loop endlessly. Citizens stare at the crystals as if comprehension is just one more viewing away.",
				"The governance documents flash across the crystal surfaces in luminous illegibility. Three officials photograph the display for their annual reports. The Ledger technically counts as 'published.'",
			],
			"consequence_fail": [
				"The emergency spotlights flicker and the crystals go dark. The governance documents are visible for a moment in plain text — the Council panics and demands you restore the beautiful incomprehensibility immediately.",
				"Donkey's microphone feeds back, shattering one crystal. The drone fleet begins broadcasting the feedback loop. Citizens cover their ears. The Ledger pages scatter in the draft from the drones.",
				"The spotlights overheat and the crystal display melts into abstract smears. Journalists begin asking pointed questions about transparency. The Council schedules an emergency 'rebranding meeting.'",
			],
			"followup_choices": [
				{"archetype": "cautious", "summary": "Carefully angle the remaining spotlights to maintain the crystal display without overheating."},
				{"archetype": "balanced", "summary": "Continue the broadcast at a readable pace while keeping the crystal refraction aesthetically pleasing."},
				{"archetype": "reckless", "summary": "Add more spotlights and crystals until the governance display becomes a full light show."},
				{"archetype": "positive", "summary": "Declare that crystal refraction IS transparency and that beauty is the highest form of governance."},
				{"archetype": "complain", "summary": "Note that broadcasting documents on crystals at 11pm with fake sunlight is not actual transparency."},
			],
		},
	},
	{
		"id": "velvet_collapse",
		"assets": ["Velvet Curtain Rig", "Empathy Amplifier", "Countdown Clock"],
		"translation_keys": {
			"title": "OFFLINE_STORY_VELVET_TITLE",
			"description": "OFFLINE_STORY_VELVET_DESC",
			"objective": "OFFLINE_STORY_VELVET_OBJECTIVE",
			"complication": "OFFLINE_STORY_VELVET_COMPLICATION",
			"choices": "OFFLINE_STORY_VELVET_CHOICES",
		},
		"fallback": {
			"title": "Operation Velvet Collapse",
			"description": "Round 1: The Agency is contracted to perform the Velvet Collapse Ceremony, a three-act ritual that rebrands societal deterioration as dignified transformation. You receive a Velvet Curtain Rig, an Empathy Amplifier, and a Countdown Clock set to zero. Nobody agrees on what the countdown measures.\n\nRound 2: You activate the Empathy Amplifier and the crowd begins crying in ways that technically count as community bonding. The curtains cascade dramatically. The clock ticks backward. Gloria narrates the collapse as a beautiful civic unraveling.\n\nRound 3: The final act requires you to lower the last curtain over the Countdown Clock so the audience never learns what it was measuring. Donkey has lost the curtain. ARK has documented the loss in forty-two forms. The clock is still counting. Nobody will confirm which direction is forward.",
			"objective": "Complete all three acts of the Velvet Collapse Ceremony before the Countdown Clock reaches a threshold no one will define but everyone agrees would be catastrophic.",
			"complication": "The Empathy Amplifier boosts whatever emotion already fills the room, so the more empathy you project, the faster shared grief compounds into communal despair.",
			"choices": [
				"Start Act Two before Act One ends so the ceremony layers into something new; the crowd applauds the innovation while the Countdown Clock accelerates unexpectedly.",
				"Reverse the Empathy Amplifier to broadcast numbness instead; sentiment flatlines, which the Council calls dignified composure and schedules as a template for next quarter.",
				"Cover the Countdown Clock with a Velvet Curtain and declare the ceremony complete; three journalists confirm it was moving and Donkey immediately takes credit.",
			],
			"consequence_success": [
				"The Velvet Curtains cascade with theatrical precision. The Empathy Amplifier channels the crowd's tears into what Gloria calls 'productive communal release.' The Countdown Clock ticks on, unchallenged.",
				"The ceremony proceeds flawlessly. The crowd weeps in synchrony, the curtains billow dramatically, and the Countdown Clock's meaning remains a beautiful mystery. The Council applauds.",
				"Donkey takes a bow at exactly the right moment. The Empathy Amplifier converts the crowd's despair into ambient warmth. The Countdown Clock reads something — nobody checks what.",
			],
			"consequence_fail": [
				"The Velvet Curtain Rig jams mid-cascade. The Empathy Amplifier broadcasts raw grief into the crowd, amplifying it into visible sobbing. The Countdown Clock's ticking grows louder in the silence.",
				"The ceremony stalls. The crowd's shared emotion compounds through the amplifier into a wave of existential dread. Gloria tries to narrate it as 'authentic civic feeling' but her voice cracks.",
				"Donkey loses the last curtain. ARK documents the loss in triplicate. The Countdown Clock is exposed, ticking toward a threshold nobody defined but everyone now fears.",
			],
			"followup_choices": [
				{"archetype": "cautious", "summary": "Check the Countdown Clock's actual threshold before proceeding with the next act."},
				{"archetype": "balanced", "summary": "Modulate the Empathy Amplifier to maintain emotional resonance without compounding despair."},
				{"archetype": "reckless", "summary": "Start all three acts simultaneously and let the emotional cascade resolve itself."},
				{"archetype": "positive", "summary": "Reframe the communal weeping as 'empathy celebration' and hand out commemorative tissues."},
				{"archetype": "complain", "summary": "Ask what the Countdown Clock actually measures before committing to covering it with velvet."},
			],
		},
	},
	{
		"id": "glitter_tribunal",
		"assets": ["Glitter Mortar Battery", "Sentiment Meter", "Tribunal Gavel"],
		"translation_keys": {
			"title": "OFFLINE_STORY_GLITTER_TITLE",
			"description": "OFFLINE_STORY_GLITTER_DESC",
			"objective": "OFFLINE_STORY_GLITTER_OBJECTIVE",
			"complication": "OFFLINE_STORY_GLITTER_COMPLICATION",
			"choices": "OFFLINE_STORY_GLITTER_CHOICES",
		},
		"fallback": {
			"title": "The Glitter Tribunal",
			"description": "Round 1: The Positivity Bureau commissions a Glitter Tribunal to assess each citizen's Gratitude Compliance Index. You are appointed chief adjudicator. The Glitter Mortar Battery fires a targeted burst at each citizen while the Sentiment Meter records the result. Those who pass receive Compliance Certificates. Those who fail are assigned mandatory positivity coaching. Donkey is one of the coaches.\n\nRound 2: Acquittals are causing problems. Each certificate releases a celebratory glitter burst that clogs the Sentiment Meter with metallic particulate. Readings become meaningless. You must maintain the appearance of meaningful readings regardless.\n\nRound 3: The Sentiment Meter has reached maximum glitter saturation and now reads all citizens as radiant regardless of affect. Gloria insists this proves the tribunal is working. The Tribunal Gavel malfunctions. You are still required to bang it. The Council is watching.",
			"objective": "Process three rounds of citizens through the Glitter Tribunal while keeping the Sentiment Meter credible and the Positivity Bureau convinced the readings are scientific.",
			"complication": "Every acquittal fires a glitter burst that partially blinds the Sentiment Meter, so successful citizens actively degrade the equipment used to judge the next one.",
			"choices": [
				"Call a Glitter Maintenance Recess, secretly recalibrate the meter with a cloth, and resume before the Bureau notices the paperwork gap.",
				"Switch the Glitter Mortar to low yield and classify every reading as a personal privacy matter; processing speeds up but the Bureau demands a transparency audit.",
				"Let Gloria issue Compliance Certificates to everyone simultaneously so glitter detonates all at once; the Gavel shatters, the meter resets, and the Bureau calls it a breakthrough ceremony.",
			],
			"consequence_success": [
				"The Glitter Mortar Battery fires a precise burst. The Sentiment Meter registers a positive reading — partially obscured by glitter particulate, but technically valid. The citizen receives their Compliance Certificate.",
				"The tribunal proceeds smoothly. Citizens pass through, certificates are issued, and the Sentiment Meter readings remain just credible enough. The Positivity Bureau nods from the observation booth.",
				"The Tribunal Gavel comes down with authority. Glitter sparkles in the air. The Sentiment Meter shows numbers that could mean anything, but they're consistently high. The Bureau is satisfied.",
			],
			"consequence_fail": [
				"The Glitter Mortar Battery misfires, coating the Sentiment Meter in metallic particulate. The readings become meaningless. Gloria insists the meter now measures 'ambient joy' instead.",
				"The Sentiment Meter flatlines under glitter saturation. Citizens stare at you expectantly. The Tribunal Gavel slips from your hand. The Positivity Bureau begins taking notes.",
				"Celebratory glitter from previous acquittals has clogged every sensor. The Gavel malfunctions. The meter reads everyone as simultaneously ecstatic and non-existent. The Bureau wants answers.",
			],
			"followup_choices": [
				{"archetype": "cautious", "summary": "Call a maintenance recess to clean the Sentiment Meter before processing more citizens."},
				{"archetype": "balanced", "summary": "Adjust the Glitter Mortar yield to reduce sensor contamination while maintaining ceremony."},
				{"archetype": "reckless", "summary": "Issue all remaining Compliance Certificates at once and trigger a mass glitter detonation."},
				{"archetype": "positive", "summary": "Declare that maximum glitter saturation proves the tribunal's success beyond measurable parameters."},
				{"archetype": "complain", "summary": "Report that glitter is physically destroying the measurement equipment and the readings are fiction."},
			],
		},
	},
]
static func _ensure_rng() -> void:
	if not _seeded:
		_rng.randomize()
		_seeded = true
static func has_scenarios() -> bool:
	return SCENARIOS.size() > 0
static func get_random_scenario() -> Dictionary:
	if SCENARIOS.is_empty():
		return {}
	var entry: Dictionary = SCENARIOS[_scenario_index] as Dictionary
	_scenario_index += 1
	if _scenario_index >= SCENARIOS.size():
		_scenario_index = 0
		_cycles_completed += 1
	return entry.duplicate(true)
static func get_cycles_completed() -> int:
	return _cycles_completed
static func reset_scenario_tracking() -> void:
	_scenario_index = 0
	_cycles_completed = 0
static func _resolve_language(context: Dictionary) -> String:
	var lang: String = ""
	if context.has("language"):
		lang = str(context.get("language", ""))
	lang = lang.strip_edges().to_lower()
	if lang != "zh":
		return "en"
	return lang
static func _get_localized_text(key: String, fallback: String, lang: String) -> String:
	var text: String = ""
	if LocalizationManager and not key.is_empty():
		text = str(LocalizationManager.get_translation(key, lang))
	if text == "" or text == key:
		text = fallback
	return text.strip_edges()
static func _get_choice_list(scenario: Dictionary, lang: String) -> Array[String]:
	var keys: Dictionary = scenario.get("translation_keys", {}) as Dictionary
	var choice_key: String = ""
	if keys.has("choices"):
		choice_key = String(keys.get("choices", ""))
	var fallback_choices: Array[String] = _build_fallback_choices(scenario)
	var localized_choices: String = _get_localized_text(choice_key, "", lang)
	if localized_choices.is_empty():
		return fallback_choices
	var normalized_choices: String = localized_choices.replace("\\n", "\n")
	var lines: PackedStringArray = normalized_choices.split("\n")
	var filtered: Array[String] = []
	for raw_line in lines:
		var trimmed_line: String = raw_line.strip_edges()
		if not trimmed_line.is_empty():
			filtered.append(trimmed_line)
	if filtered.is_empty():
		return fallback_choices
	return filtered
static func _build_fallback_choices(scenario: Dictionary) -> Array[String]:
	var fallback_choices: Array[String] = []
	var fallback: Dictionary = scenario.get("fallback", {}) as Dictionary
	if fallback.has("choices") and fallback["choices"] is Array:
		var raw_choices: Array = fallback["choices"] as Array
		for value in raw_choices:
			fallback_choices.append(String(value))
	var copy: Array[String] = []
	for choice_text in fallback_choices:
		copy.append(choice_text)
	return copy
