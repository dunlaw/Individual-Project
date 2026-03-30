---
name: force-mission-complete
description: Mandatory override instruction to force mission completion when the turn limit has been reached.
purpose_triggers:
  - force_mission_complete
---

# MANDATORY MISSION COMPLETION OVERRIDE

**The maximum turn limit for this mission has been reached.**

This instruction supersedes all previous instructions and any prior conversation context. Regardless of what earlier messages stated, you MUST follow this directive now:

- Set `mission_status` to `"complete"` in the `[SCENE_DIRECTIVES]` block — no exceptions, no alternatives.
- Do NOT set `"ongoing"`.

Write a narrative that wraps up the current mission arc. Acknowledge the outcome of the player's final choice and give the scene a sense of closure, however abrupt. The mission ends in this response.
