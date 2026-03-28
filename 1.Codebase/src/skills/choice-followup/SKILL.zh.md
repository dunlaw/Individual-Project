---
name: choice-followup
description: 根據故事摘錄生成 3-5 個後續選項摘要，且只能輸出 JSON。
purpose_triggers:
  - choice_followup
---

# 選項補完（強制要求）

以下是故事摘錄：
{story_excerpt}

請只輸出一個 JSON 物件：
{"choices":[{"archetype":"cautious","summary":"..."},...]}

規則：
- 提供 3 到 5 個選項，archetype 僅可使用 cautious、balanced、reckless、positive、complain。
- `summary` 必須為繁體中文，10-20 字，描述該原型可能導向的後果走向。
- 不可輸出 JSON 以外任何文字、markdown、code fence 或說明。
