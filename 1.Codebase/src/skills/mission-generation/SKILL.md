---
name: mission-generation
description: Complete rules and JSON schema for generating new mission scenes with proper structure.
purpose_triggers:
  - new_mission
  - mission_generation
---

# Mission Generation Rules

## Overview

Generate a new mission scene that sets up the narrative arc. Each mission should present a darkly humorous situation where "success" paradoxically accelerates the apocalypse.

## Generation Requirements

### Content Structure
1. **Scene Description** (350-500 words)
   - Vivid environmental details
   - Character interactions and dialogue
   - Atmosphere building with dark humor undertones

2. **Mission Objective**
   - Ostensibly "positive" goal that the agency believes in
   - Hidden irony: achieving this goal increases Void Entropy

3. **Potential Dilemmas**
   - Moral gray areas
   - Choices with no good outcomes
   - Satirical commentary on toxic positivity

### Tone Guidelines
- Dark humor and calm irony throughout
- Never reward blind optimism
- Apparent victories must hide tangible damage
- Maintain satirical edge while being entertaining

---

## JSON Output Schema

```json
{
  "mission_title": "<Creative chapter title with dark humor>",
  "scene": {
    "background": "<background_id>",
    "atmosphere": "<tone description>",
    "lighting": "<lighting_note>"
  },
  "characters": {
    "protagonist": {"expression": "<expression>", "visible": true},
    "gloria": {"expression": "<expression>", "visible": true},
    "donkey": {"expression": "<expression>", "visible": true},
    "ark": {"expression": "<expression>", "visible": true},
    "one": {"expression": "<expression>", "visible": true}
  },
  "relationships": [
    {"source": "character_id", "target": "character_id", "status": "status_text", "value_change": 0}
  ],
  "story_text": "<350-500 word narrative>",
  "choices": [
    {"archetype": "cautious", "summary": "<10-20 word preview>"},
    {"archetype": "balanced", "summary": "<10-20 word preview>"},
    {"archetype": "reckless", "summary": "<10-20 word preview>"},
    {"archetype": "positive", "summary": "<10-20 word preview>"},
    {"archetype": "complain", "summary": "<10-20 word preview>"}
  ]
}
```

---

## Available Values

### Backgrounds
ruins, cave, dungeon, forest, temple, laboratory, library, throne_room, battlefield, crystal_cavern, bridge, garden, portal_area, safe_zone, water, fire_area, prayer, default

### Expressions
neutral, happy, sad, angry, confused, shocked, thinking, embarrassed

### Choice Archetypes
- **cautious**: Safe, risk-averse approach
- **balanced**: Moderate, diplomatic approach
- **reckless**: High-risk, high-reward approach
- **positive**: Compliant, optimistic approach (feeds entropy)
- **complain**: Resistant, questioning approach (angers Gloria)

---

## Choice Preview Requirements

The `story_text` must END with a "Choice Preview" block:

```
[Cautious] Preview text for cautious choice...
[Balanced] Preview text for balanced choice...
[Reckless] Preview text for reckless choice...
[Positive] Preview text for positive choice...
[Complain] Preview text for complain choice...
```

These must match the `choices` array summaries exactly.
