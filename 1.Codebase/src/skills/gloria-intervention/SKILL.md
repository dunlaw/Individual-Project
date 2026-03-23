---
name: gloria-intervention
description: Rules for generating Gloria's positive energy bombardment when player's positive energy is too low.
purpose_triggers:
  - gloria_intervention
  - gloria
---

# Gloria's Positive Energy Bombardment

## Overview

When the player's Positive Energy drops too low, Gloria intervenes with a speech dripping in toxic positivity. This is a standalone intervention - NOT part of the main story flow.

## Trigger Conditions

- Player's Positive Energy ≤ 30
- Sufficient turns since last intervention (cooldown)
- Not during night cycle

---

## Speech Requirements

### Length
- 80-120 words (short and impactful)
- This is a quick intervention, not a monologue

### Tone
- Toxic positivity disguised as care
- Passive-aggressive sweetness
- Gaslighting presented as concern
- Emotional manipulation (PUA tactics)

---

## Content Structure

### English Version
```
=== Gloria's Positive Energy Bombardment ===

Player's positive energy is too low, so Gloria interferes.
Player just chose: {choice_text}

Write a SHORT 80-120 word speech dripping with toxic positivity:
1. Pretend to care while gaslighting
2. Blame the player for being 'negative'
3. Demand absurd optimism and compliance

CRITICAL CONSTRAINTS:
- This is a standalone intervention, NOT the main story
- Do NOT generate any choices or choice previews
- Do NOT include [Choice Preview] or any choice lists
- Output ONLY Gloria's speech, keep it SHORT (80-120 words max)
```

### Chinese Version (繁體中文)
```
=== Gloria 正能量轟炸 ===

玩家的正能量過低，Gloria 決定用超級雞湯逼迫他們振作。
玩家剛剛選擇：{choice_text}

請寫出 80-120 字的簡短演說，充滿偽關懷與情緒勒索：
1. 表面安慰、實際否定玩家感受
2. 暗示問題在於玩家不夠正面
3. 以荒謬的正能量目標施壓

重要限制：
- 這是獨立的介入事件，不是主線故事
- 不要生成任何選項或選擇預覽
- 不要包含 [Choice Preview] 或任何選擇列表
- 只輸出 Gloria 的演講內容，保持簡短（80-120字）
```

---

## Gloria's Speech Patterns

### Common Phrases
- "I'm not angry, just disappointed in your choices."
- "We're a family here. Families support each other unconditionally."
- "Your negativity is hurting the team. Is that what you want?"
- "I just want what's best for you. Why can't you see that?"
- "The universe gives back what we put in. Choose positivity!"

### Tactics
1. **False Empathy**: "I understand you're struggling, BUT..."
2. **Guilt Tripping**: "After everything we've done for you..."
3. **Gaslighting**: "You're not really upset, you're just tired."
4. **Moving Goalposts**: "That's good, but you could smile more."
5. **Victim Reversal**: "YOUR negativity is hurting ME."

---

## Scene Directives

```
[SCENE_DIRECTIVES]
{
  "characters": {
    "gloria": {"expression": "happy"}
  }
}
[/SCENE_DIRECTIVES]
```

Gloria should typically show "happy" or "sad" (disappointed) expression.
The speech content should appear AFTER the scene directives block.

---

## Important Notes

- This intervention does NOT generate choices
- After the intervention, the game returns to normal flow
- The intervention is meant to be uncomfortable and cringe-inducing
- Players should feel pressured but also see through the manipulation
