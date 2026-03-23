---
name: prayer-system
description: Rules for generating twisted prayer consequences - prayers are superficially granted but cause greater disasters.
purpose_triggers:
  - prayer
---

# Prayer System - Disaster Generation

## Overview

The player prays to the "Flying Spaghetti Monster". Prayers are superficially "granted" but actually cause greater disasters. This is the core irony of the game's toxic positivity satire.

## Input Variables

- `{prayer_text}`: The player's prayer content
- `{reality_score}`: 0-100 (lower = more susceptible to distortion)
- `{positive_energy}`: 0-100 (higher = more blindly optimistic)
- `{distortion_level}`: Based on reality_score

### Distortion Levels

| Reality Score | English | Chinese |
|--------------|---------|---------|
| < 30 | extremely twisted and catastrophic | 極度扭曲且災難性的 |
| 30-49 | severely twisted | 嚴重扭曲的 |
| 50-69 | twisted | 扭曲的 |
| ≥ 70 | subtly twisted | 微妙扭曲的 |

---

## English Prompt Template

```
Player prays to the "Flying Spaghetti Monster": "{prayer_text}"

Player's Reality Score: {reality_score}/100 (lower = more susceptible to distortion)
Player's Positive Energy: {positive_energy}/100 (higher = more blindly optimistic)

Generate a {distortion_level} consequence (150-200 words):

1. Superficially "grants" the prayer's wish
2. But actually causes a greater disaster
3. Uses irony to showcase the absurdity of "positive thinking"
4. Disaster severity is inversely proportional to reality score

Example Logic:
- Pray for "world peace" → Everyone brainwashed, losing self-awareness
- Pray to "eliminate negativity" → All people who can perceive reality are eliminated
- Pray to "make everyone happy" → Forced "happiness hormones" cause societal collapse

Generate the twisted result of this prayer, maintaining dark humor.
```

---

## Chinese Prompt Template (繁體中文)

```
玩家向「飛天意粉神」禱告：「{prayer_text}」

玩家的現實感知: {reality_score}/100 (越低越容易被扭曲)
玩家的正能量指數: {positive_energy}/100 (越高越盲目樂觀)

請生成一個{distortion_level}後果（150-200字）：

1. 表面上「實現」了禱告的願望
2. 但實際上造成了更大的災難
3. 用諷刺的方式展現「正能量思維」的荒謬
4. 災難的嚴重程度與現實感知成反比

範例邏輯：
- 禱告「世界和平」→ 所有人被洗腦失去自我意識
- 禱告「消除負能量」→ 所有能感知現實的人被消滅
- 禱告「讓大家快樂」→ 強制注射「快樂激素」導致社會崩潰

請生成這次禱告的扭曲結果，保持黑色幽默。
```

---

## Output Requirements

- 150-200 words describing the twisted consequence
- Maintain dark humor and irony
- The disaster should feel like a "monkey's paw" wish fulfillment
- Include subtle hints that the player's prayer caused this
