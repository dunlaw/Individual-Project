---
name: choice-followup
description: Strict JSON-only rules for generating 3-5 follow-up choice summaries from a story excerpt.
purpose_triggers:
  - choice_followup
---

# Choice Summary Follow-up (STRICT)

Story excerpt:
{story_excerpt}

Output EXACTLY one JSON object:
{"choices":[{"archetype":"cautious","summary":"..."},...]}

Rules:
- Provide 3 to 5 choices using archetypes: cautious, balanced, reckless, positive, complain.
- `summary` must be 10-20 words in the same language as the excerpt.
- `summary` should describe the likely consequence route for each archetype.
- Do NOT include prose, markdown, code fences, or explanations outside the JSON object.
