---
name: scene-directives
description: 場景指令完整規格，用於控制背景、角色表情、可見性與場景資產。
purpose_triggers:
  - mission_generation
  - new_mission
  - consequence
  - scene_update
  - choice_followup
  - night_cycle
  - teammate_interference
  - gloria_intervention
  - intro_story
  - prayer
---

# 場景指令系統

## 概述

場景指令用來控制遊戲的視覺呈現。請在回應中加入場景指令，以更新背景、角色表情與畫面上的資產。

## 回應格式

回應應包含兩個區塊：
1. 故事敘述
2. `[SCENE_DIRECTIVES]` JSON 區塊

```
[故事敘述]

[SCENE_DIRECTIVES]
{
  "scene": {
    "background": "background_id",
    "atmosphere": "dark|mysterious|bright|tense",
    "lighting": "dim|bright|normal"
  },
  "characters": {
    "protagonist": {"expression": "neutral", "visible": true},
    "gloria": {"expression": "happy", "visible": true},
    "donkey": {"expression": "confused", "visible": false},
    "ark": {"expression": "thinking", "visible": false},
    "one": {"expression": "neutral", "visible": false},
    "teacher_chan": {"expression": "happy", "visible": false}
  },
  "assets": [
    {"id": "asset_id", "contextual_name": "顯示名稱", "description": "簡短描述"}
  ],
  "mission_status": "ongoing|complete"
}
[/SCENE_DIRECTIVES]
```

## 可用背景 ID

- `default`
- `prayer`
- `forest`
- `cave`
- `temple`
- `ruins`
- `laboratory`
- `throne_room`
- `bridge`
- `portal_area`
- `water`
- `fire`
- `garden`
- `dungeon`
- `crystal_cavern`
- `library`
- `safe_zone`
- `battlefield`

## 可用 expression ID

- `neutral`
- `happy`
- `sad`
- `angry`
- `confused`
- `shocked`
- `thinking`
- `embarrassed`

## 角色 ID

- `protagonist`
- `gloria`
- `donkey`
- `ark`
- `one`
- `teacher_chan`

## NPC 立繪

支援 NPC 時，請在 `assets` 中使用 `category: "npc"`：

```json
"assets": [
  {"category": "npc", "id": "generic_guard", "slot": 1, "contextual_name": "守衛"}
]
```

可用 NPC ID：
- `generic_villager_male`
- `generic_villager_female`
- `generic_guard`
- `generic_merchant`
- `generic_elder`
- `generic_child`
- `generic_priest`
- `generic_scientist`

`slot` 只能是 `1`、`2`、`3`。

## 規則

1. 場景敘述後必須附上場景指令。
2. 表情要符合當前情緒。
3. 進入新地點時要更新背景。
4. 用 `atmosphere` 與 `lighting` 強化氛圍。
5. 只有在場角色才應設為可見。
6. `assets` 要使用符合任務語境的名稱與描述。
7. 只有在任務真正結束時，才將 `mission_status` 設為 `complete`。
