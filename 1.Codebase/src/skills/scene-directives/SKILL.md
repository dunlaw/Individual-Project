---
name: scene-directives
description: Complete scene directive format specification for controlling visual elements - backgrounds, characters, expressions, and assets.
purpose_triggers:
  - mission_generation
  - new_mission
  - consequence
  - scene_update
  - choice_followup
  - night_cycle
  - teammate_interference
  - gloria_intervention
  - intro_story
  - prayer
---

# Scene Directives System

## Overview

Scene directives control the visual presentation of the game. Include them in your response to update backgrounds, character expressions, and on-screen assets.

## Response Format

Your response should have TWO sections:
1. Story narrative (the main story text)
2. Scene directives (JSON block for visual updates)

```
[Your story narrative here...]

[SCENE_DIRECTIVES]
{
  "scene": {
    "background": "background_id",
    "atmosphere": "dark|mysterious|bright|tense",
    "lighting": "dim|bright|normal"
  },
  "characters": {
    "protagonist": {"expression": "neutral", "visible": true},
    "gloria": {"expression": "happy", "visible": true},
    "donkey": {"expression": "confused", "visible": false},
    "ark": {"expression": "thinking", "visible": false},
    "one": {"expression": "neutral", "visible": false},
    "teacher_chan": {"expression": "happy", "visible": false}
  },
  "assets": [
    {"id": "asset_id", "contextual_name": "Display Name", "description": "Brief description"}
  ],
  "mission_status": "ongoing|complete"
}
[/SCENE_DIRECTIVES]
```

## Available Backgrounds

| ID | Description |
|----|-------------|
| default | Default office space |
| prayer | Prayer/meditation room |
| forest | Outdoor forest scene |
| cave | Dark cave interior |
| temple | Ancient temple |
| ruins | Destroyed ruins |
| laboratory | Science lab |
| throne_room | Grand throne room |
| bridge | Crossing/bridge scene |
| portal_area | Magical portal zone |
| water | Near water/ocean |
| fire | Fire/volcano area |
| garden | Peaceful garden |
| dungeon | Dark dungeon |
| crystal_cavern | Crystal-filled cave |
| library | Ancient library |
| safe_zone | Protected area |
| battlefield | Combat zone |

## Available Expressions

All characters can use these expressions:
- neutral
- happy
- sad
- angry
- confused
- shocked
- thinking
- embarrassed

## Character IDs

| ID | Character |
|----|-----------|
| protagonist | The player character |
| gloria | Gloria (Saint/Nun leader) |
| donkey | Donkey (Glorious Knight) |
| ark | ARK (Order Apostle) |
| one | One (Old Friend) |
| teacher_chan | Teacher Chan (Singer) |

## NPC Portraits

For supporting NPCs, use the assets array with category "npc":

```json
"assets": [
  {"category": "npc", "id": "generic_guard", "slot": 1, "contextual_name": "Gate Guard"}
]
```

Available NPC IDs:
- generic_villager_male
- generic_villager_female
- generic_guard
- generic_merchant
- generic_elder
- generic_child
- generic_priest
- generic_scientist

Slots: 1, 2, or 3 (positions on screen)

## Guidelines

1. **Always include scene directives** after the story narrative
2. **Update expressions** to match emotional tone of the scene
3. **Change backgrounds** when entering new locations
4. **Use atmosphere and lighting** to enhance mood
5. **Only show visible characters** that are present in the scene
6. **Include mission assets** with contextual names relevant to the story
7. **Set mission_status** to "complete" only when the mission has concluded
