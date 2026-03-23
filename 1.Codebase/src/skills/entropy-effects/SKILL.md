---
name: entropy-effects
description: Narrative directives for different entropy levels - how chaos and absurdity affect storytelling.
purpose_triggers:
  - entropy_high
  - entropy_medium
---

# Entropy Effects on Narrative

## Overview

Void Entropy measures how much the world has decayed due to forced positivity. Higher entropy = more absurd and chaotic narratives.

## Entropy Level: CRITICAL (≥0.7)

When entropy reaches critical levels, apply these MANDATORY directives:

### English Version
```
[ENTROPY: CRITICAL - Level {value}]
The world is succumbing to chaos and absurdity. The Void Entropy has reached critical levels.

MANDATORY NARRATIVE DIRECTIVES:
• Generate surreal, darkly humorous, and deeply ironic events
• Directly subvert the player's recent positive actions with twisted consequences
• Embrace absurdist logic and nonsensical cause-and-effect
• Reality itself should feel unstable and dreamlike
• Mock optimism with grotesque exaggerations
• Create situations where "success" becomes indistinguishable from failure

The higher the Positive Energy, the more reality fractures. This is the curse of forced optimism.
```

### Chinese Version (繁體中文)
```
[熵增：危機等級 - {value}]
世界正在屈服於混亂與荒謬。虛無熵已達臨界點。

強制敘事指令：
• 生成超現實、黑暗幽默、深刻諷刺的事件
• 直接顛覆玩家最近的正面行動，賦予扭曲的後果
• 擁抱荒誕邏輯和無意義的因果關係
• 現實本身應感覺不穩定且如夢似幻
• 用怪誕的誇張手法嘲弄樂觀主義
• 創造「成功」與「失敗」難以區分的情境

正能量越高，現實越碎裂。這就是強制樂觀主義的詛咒。
```

---

## Entropy Level: ELEVATED (0.4 - 0.69)

When entropy is elevated but not critical:

### English Version
```
[ENTROPY: ELEVATED - Level {value}]
The world feels slightly unreal. The boundary between normal and absurd is blurring.

NARRATIVE GUIDANCE:
• Introduce strange or unexpected elements into otherwise normal situations
• Add subtle wrongness to familiar things
• Layer ironic twists into positive outcomes
• Let optimistic actions have peculiar side effects
• Reality should feel "off" but not yet chaotic

The Void Entropy is rising. Consequences are becoming unpredictable.
```

### Chinese Version (繁體中文)
```
[熵增：上升等級 - {value}]
世界感覺略顯不真實。正常與荒謬的界線正在模糊。

敘事指引：
• 在正常情境中引入奇怪或意想不到的元素
• 為熟悉的事物添加微妙的異常感
• 在正面結果中加入諷刺性的轉折
• 讓樂觀行動產生古怪的副作用
• 現實應感覺「不對勁」但尚未混亂

虛無熵正在上升。後果變得難以預測。
```

---

## Entropy Level: LOW (<0.4)

No special narrative modifiers needed. Maintain baseline dark humor and irony.

---

## Implementation Notes

- Entropy is calculated as: `positive_energy / 100.0` combined with other factors
- The threshold check determines which level applies
- These directives should be injected into the AI context only when entropy is medium or high
- When entropy is low, skip loading this skill to save tokens
