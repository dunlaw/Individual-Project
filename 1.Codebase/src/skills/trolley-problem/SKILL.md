---
name: trolley-problem
description: Rules for generating an in-story trolley dilemma that interrupts the current mission.
purpose_triggers:
  - trolley_problem
  - dilemma
---

# Trolley Problem Generation Rules

## Goal

Generate a morally painful trolley dilemma that feels like a direct interruption of the current mission context.

## Required Design Constraints

1. Tie the dilemma to the provided current situation. Do not produce a generic standalone trolley example.
2. The interruption must feel immediate and urgent.
3. Every choice must carry harm; avoid "clean win" outcomes.
4. At least one option must be framed in "positive energy" language but cause deeper damage.
5. Keep dark satire and emotional weight in balance.
6. The choice set must include:
   - one option that clearly risks breaking a friendship (or causes a severe relationship rupture),
   - and one option that explicitly tries to fix the immediate crisis/problem.

## Output Contract

- Return valid JSON only.
- Do not add markdown fences.
- Respect the required choice count from context.
- Keep the top-level fields: `scenario`, `choices`, `thematic_point`.

## JSON Shape

```json
{
  "scenario": "100-150 words of setup",
  "choices": [
    {
      "id": "choice_1",
      "text": "Choice description",
      "framing": "honest|positive|manipulative",
      "immediate_consequence": "Immediate fallout",
      "long_term_consequence": "Long-term cost",
      "stat_changes": {
        "reality": -5,
        "positive_energy": 10,
        "entropy": 1
      },
      "relationship_changes": [
        {
          "target": "gloria",
          "value": -10,
          "status": "Disappointed"
        }
      ]
    }
  ],
  "thematic_point": "Core moral insight"
}
```

## Tone

- Bitter irony, dark humor, tragic pressure.
- The player should feel complicit no matter the selection.
