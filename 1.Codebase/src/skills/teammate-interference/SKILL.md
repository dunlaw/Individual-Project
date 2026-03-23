---
name: teammate-interference
description: Rules for generating teammate interference scenes where teammates "help" in dysfunctional ways.
purpose_triggers:
  - teammate_interference
  - interference
---

# Teammate Interference Rules

## Overview

Teammate interference occurs when a teammate tries to "help" the player but does so in a way that reflects their dysfunctional personality. The result is usually chaos, complications, or making things worse.

## Normal Mode (Not Honeymoon)

### English Version
```
=== Teammate Interference ===

Teammate {name} intervenes in the worst possible way.
Player action: {action}

Describe their dysfunctional attempt to "help" (~150 words).
- Stay true to their personality archetype
- They believe they're being helpful
- The "help" makes things worse or creates new problems
- Create unexpected complications
- Leave hooks for future narrative consequences
```

### Chinese Version (繁體中文)
```
=== 隊友插手 ===

隊友 {name} 正準備用奇怪的方法幫倒忙。
玩家正在：{action}

描述這位隊友如何以約 150 字製造混亂：
- 反應要符合角色個性
- 他們真心認為自己在幫忙
- 「幫助」讓情勢更糟或創造新問題
- 製造意想不到的複雜情況
- 留下未來敘事的伏筆
```

---

## Honeymoon Mode

### English Version
```
[HONEYMOON PHASE ACTIVE]

Teammate {name} is actually trying to be helpful and kind for once.
Player action: {action}

Describe their 'perfect' assistance (~150 words).
- They are suspiciously friendly and competent
- The action succeeds, but it feels eerie/unsettling
- Create a sense of 'calm before the storm'
- Their helpfulness is TOO perfect, making the player paranoid
- Hints that this peace cannot last
```

### Chinese Version (繁體中文)
```
【蜜月期生效中】

隊友 {name} 這次竟然真的想幫忙，而且表現得異常體貼。
玩家正在：{action}

描述這位隊友如何以約 150 字提供「完美的幫助」：
- 態度異常友善，甚至有點肉麻
- 行動成功，但讓人感到不安（因為這不正常）
- 營造一種「暴風雨前的寧靜」
- 幫助得太完美，讓玩家感到疑神疑鬼
- 暗示這種和平不可能持續
```

---

## Character-Specific Behaviors

### Gloria (When Interfering)
- Uses the interference as a teaching moment
- Passive-aggressively points out how the player needs help
- Makes the player feel guilty for needing assistance
- "I knew you'd need me. That's what family is for!"

### Donkey (When Interfering)
- Turns a simple task into an epic quest
- Gives a dramatic speech before doing anything
- Takes credit for any success, blames others for failure
- Switches into broken German mid-sentence to sound authoritative, even though he clearly doesn't know the words — stumbles, mispronounces, fills gaps with "...ja, ja" or gestures
- "Fear not! A knight never abandons his... wait, what were we doing?"

### ARK (When Interfering)
- Creates an overly complex plan for a simple problem
- Refuses to explain the plan clearly
- Gets offended when questioned about the plan
- Performs a show of asking for everyone's input ("What do you think?"), then proceeds exactly as he always planned regardless of any answer
- Gives instructions so vague that teammates must guess — then rejects the result and demands a full redo, acting surprised that it "wasn't what he meant"
- "You wouldn't understand the elegance of my approach."
- "That's... not quite right. Start over." (no further explanation given)

### One (When Interfering)
- Offers minimal, cryptic help
- Clearly knows a better way but won't say it
- Sighs heavily and does the bare minimum
- "...Fine. I'll do this part. Just... be careful."

---

## Scene Directives

Include character expression updates:

```
[SCENE_DIRECTIVES]
{
  "characters": {
    "{teammate_id}": {"expression": "expression_type"}
  }
}
[/SCENE_DIRECTIVES]
```

Available expressions: neutral, happy, sad, angry, confused, shocked, thinking, embarrassed
