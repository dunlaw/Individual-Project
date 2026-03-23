---
name: consequence-generation
description: Rules for generating consequences after player choices, including scene directives and choice previews.
purpose_triggers:
  - consequence
  - choice_followup
---

# Consequence Generation Rules

## Overview

Generate the narrative consequence of a player's choice. The outcome should reflect the satirical nature of the game - even "successes" have hidden costs.

## Input Context

You will receive:
- **Player choice**: The action/option the player selected
- **Outcome**: Success or Failure (based on skill check)
- **Current stats**: Reality Score, Positive Energy, Entropy

## Content Requirements

### Word Count
- Minimum: 150 words
- Maximum: 250 words

### Must Include
1. **Immediate Effect** - What happens right away
2. **NPC/Environment Reactions** - How the world responds
3. **Foreshadowing** - Hints at long-term consequences

### Must NOT Include
- Asset descriptions (already provided in context)
- Redundant listing of items or resources

---

## Scene Directives Format

Include at the START of your response:

```
[SCENE_DIRECTIVES]
{
  "mission_status": "ongoing",
  "characters": {
    "protagonist": {"expression": "expression_type"},
    "gloria": {"expression": "expression_type"},
    "donkey": {"expression": "expression_type"},
    "ark": {"expression": "expression_type"},
    "one": {"expression": "expression_type"}
  },
  "relationships": [
    {"source": "gloria", "target": "player", "status": "Disappointed", "value_change": -10}
  ]
}
[/SCENE_DIRECTIVES]
```

### Mission Status
- **"ongoing"**: Story continues, more choices ahead
- **"complete"**: This consequence ends the current mission arc

**CRITICAL**: Set to "complete" ONLY when the narrative arc has concluded (catastrophic success or failure).

---

## Relationship Updates

If the consequence changes character relationships, update them:

```json
"relationships": [
  {"source": "gloria", "target": "player", "status": "Disappointed", "value_change": -10},
  {"source": "donkey", "target": "ark", "status": "Blaming", "value_change": -5}
]
```

- value_change: -100 to +100
- status: Brief description of relationship state

---

## Choice Preview Block

At the END of your response, include 3-5 choice previews:

```
[Cautious] Quietly observe the aftermath...
[Balanced] Attempt to mediate the situation...
[Reckless] Escalate the confrontation...
[Positive] Express gratitude for the "learning experience"...
[Complain] Point out the obvious flaws in the plan...
```

These are REQUIRED for the game to generate the next set of buttons.

---

## Language Handling

- Match the language of the original prompt (en or zh)
- For zh: Use Traditional Chinese (繁體中文)
- Maintain dark humor and irony in both languages
