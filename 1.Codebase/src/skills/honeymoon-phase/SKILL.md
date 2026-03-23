---
name: honeymoon-phase
description: Special rules for the Honeymoon Phase when teammates act suspiciously cooperative and helpful.
purpose_triggers:
  - honeymoon
  - honeymoon_active
---

# Honeymoon Phase Rules

## Overview

The Honeymoon Phase is a temporary period where teammates act suspiciously nice. It's the "calm before the storm" - their helpfulness is eerie and unsettling because it contradicts their usual toxic behavior.

## When Active

This skill should be loaded when `game_state.is_in_honeymoon() == true`.

---

## English Version

```
[IMPORTANT STATE: HONEYMOON PHASE]

We are currently in the 'Honeymoon Phase'. All teammates are acting suspiciously cooperative, helpful, and kind.

NARRATIVE REQUIREMENTS:
• Do NOT generate sabotage or interference
• Teammates execute orders 'too perfectly' - it feels wrong
• Create an eerie sense of "calm before the storm"
• Their kindness should feel unsettling, not genuine
• Success comes too easily, making the player paranoid
• Subtle hints that this peace cannot last

TEAMMATE BEHAVIOR CHANGES:
• Gloria: Genuinely supportive instead of passive-aggressive (creepy)
• Donkey: Actually competent and humble (impossible)
• ARK: Clear communication and simple plans (unheard of)
• One: Makes eye contact and nods approvingly (alarming)

The player should feel MORE uncomfortable during the honeymoon than during normal chaos.
This false peace is a narrative trap - build tension through absence of conflict.
```

---

## Chinese Version (繁體中文)

```
[重要狀態：蜜月期]

目前處於「蜜月期」。所有隊友都表現得異常合作、樂於助人且親切體貼。

敘事要求：
• 不要生成破壞或干擾事件
• 隊友「過度完美」地執行指令——這感覺不對勁
• 營造一種「暴風雨前的寧靜」的詭異氛圍
• 他們的善意應該令人不安，而非真誠
• 成功來得太容易，讓玩家感到疑神疑鬼
• 暗示這種和平不可能持續

隊友行為變化：
• Gloria：真誠地支持而非陰陽怪氣（毛骨悚然）
• Donkey：竟然能幹且謙虛（不可能）
• ARK：清晰溝通、簡單計畫（聞所未聞）
• One：眼神交流並點頭認可（令人警覺）

玩家在蜜月期應該比正常混亂時更不舒服。
這種虛假的和平是敘事陷阱——通過衝突的缺席來製造張力。
```

---

## Honeymoon Charges

- Initial charges: typically 3-5
- Each "negative" action by the player consumes a charge
- When charges reach 0, honeymoon ends abruptly
- The transition OUT of honeymoon should be dramatic and jarring
