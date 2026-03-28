---
name: trolley-problem
description: 電車難題生成規則，要求與當前劇情強綁定並輸出 JSON。
purpose_triggers:
  - trolley_problem
  - dilemma
---

# 電車難題生成規則

## 目標

產生一個會「直接打斷當前任務」的道德兩難事件，不可脫離上下文。

## 必要約束

1. 必須與提供的 CURRENT SITUATION 直接相關，不可產生通用電車題。
2. 事件必須是立即危機（interruption / crisis）。
3. 所有選項都要有負面後果，不可出現零代價完美解。
4. 至少一個選項要用「正能量」話術包裝，但實際造成更大傷害。
5. 兼顧黑色諷刺與情緒重量，讓玩家感到自己無論如何都在共犯結構內。
6. 選項設計必須同時包含：
   - 一個明確可能「破壞友誼／關係決裂」的選項，
   - 與一個明確「嘗試修復或解決當下問題」的選項。

## 輸出契約

- 僅輸出合法 JSON。
- 不要使用 markdown code fence。
- 遵守上下文提供的 choice 數量。
- 最外層欄位固定為：`scenario`、`choices`、`thematic_point`。

## JSON 結構

```json
{
  "scenario": "100-150 字情境敘述",
  "choices": [
    {
      "id": "choice_1",
      "text": "選項敘述",
      "framing": "honest|positive|manipulative",
      "immediate_consequence": "立即後果",
      "long_term_consequence": "長期代價",
      "stat_changes": {
        "reality": -5,
        "positive_energy": 10,
        "entropy": 1
      },
      "relationship_changes": [
        {
          "target": "gloria",
          "value": -10,
          "status": "Disappointed"
        }
      ]
    }
  ],
  "thematic_point": "此兩難揭示的世界核心命題"
}
```

## 文風

- 黑色幽默、冷酷諷刺、具壓迫感。
- 讓玩家理解：每個選擇都在付出真實代價。
