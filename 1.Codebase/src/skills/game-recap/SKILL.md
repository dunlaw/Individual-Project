---
name: game-recap
description: Generate a "Previously on GDA1..." narrative recap when a player resumes a saved game, summarising key story events, choices, and consequences so far.
purpose_triggers:
  - game_recap
  - previously_on
  - story_recap
---

# Game Recap — "Previously on GDA1..."

## When to Use
Use this skill when a player resumes a saved game session. Generate a brief, atmospheric recap in the style of a TV show's "Previously on..." segment — reminding the player where the story left off without being exhaustive.

## Narrative Requirements

Write a recap that:

1. **Opens with the signature phrase** "Previously on Glorious Deliverance Agency 1..." (or its Chinese equivalent)
2. **Summarises the player's journey** based on the provided memory context, covering:
   - Key missions completed and their outcomes
   - Significant choices the player made
   - How those choices affected the team and the world's entropy
   - The current state of relationships with Gloria, Donkey, ARK, and One
3. **Reflects the game's dark tone** — ironic, satirical, with an undercurrent of dread as Void Entropy rises
4. **Ends with a hook** that sets up the current mission, creating anticipation for what comes next

## Tone

- Dark, sardonic narrator voice — like a nature documentary about a doomed species
- Understated humour mixed with genuine tension
- Avoid spoiling future events; only recap what has already happened
- Gloria is always presented as sickeningly cheerful and dangerous
- Entropy rising is always framed as quietly catastrophic

## Output Format

- **Pure narrative prose only** — no JSON, no choices, no scene directives
- Length: 80–150 words (ZH) or 100–180 words (EN)
- No bullet points or headings in the output
- Suitable for display in a cinematic overlay with typewriter effect

## Language Handling

- If language is "zh", write in Traditional Chinese (繁體中文)
- If language is "en", write in English
- Open line must be in the correct language:
  - EN: "Previously on Glorious Deliverance Agency 1..."
  - ZH: "上次在光榮拯救機構一號..."

## Context Variables

The following context will be injected into the prompt:
- `{mission_number}` — current mission number
- `{missions_completed}` — number of completed missions
- `{reality_score}` — current Reality Score
- `{entropy_level}` — current Entropy Level
- `{current_mission_title}` — the current mission title
- `{long_term_summaries}` — condensed story history from the memory system
- `{recent_events}` — the most recent story events

## Fallback

If context is sparse (early game, very few events), produce a short atmospheric scene-setter rather than a summary — describing the world and the player's situation as an outsider joining for the first time, but in a way that feels like they have been here all along.
