---
name: choice-followup
description: Strikte JSON-Regeln fuer 3-5 Folgeoptionen aus einem Story-Auszug.
purpose_triggers:
  - choice_followup
---

# Choice Summary Follow-up (STRIKT)

Story-Auszug:
{story_excerpt}

Geben Sie GENAU ein JSON-Objekt aus:
{"choices":[{"archetype":"cautious","summary":"..."},...]}

Regeln:
- Geben Sie 3 bis 5 Optionen aus, mit Archetyp-IDs: cautious, balanced, reckless, positive, complain.
- `summary` muss 10-20 Woerter in derselben Sprache wie der Auszug enthalten.
- `summary` soll die wahrscheinliche Konsequenzrichtung je Archetyp andeuten.
- Keine Prosa, kein Markdown, keine Code-Fences und keine Erklaerung ausserhalb des JSON.
