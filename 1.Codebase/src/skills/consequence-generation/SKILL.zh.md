---
name: consequence-generation
description: 玩家選擇後續結果的中文生成規則。
purpose_triggers:
  - consequence
  - choice_followup
---

# 後果生成規則

## 概述

請根據玩家的選擇生成後續敘事。即使是「成功」，也應該帶來隱性代價、團隊關係惡化或更高熵值。

## 輸入內容

你會收到：
- 玩家選擇
- 成功或失敗結果
- 當前 stats
- 最近場景與蝴蝶效應背景

## 必須達成

1. 讓結果符合玩家選擇的風格
2. 保持黑色幽默與制度諷刺
3. 讓隊友的反應符合其角色原型
4. 必要時更新場景指令與角色關係
5. 若需要，為下一輪選項鋪墊

## 敘事原則

- 成功不應該是乾淨成功
- 失敗不應該只是單純失敗，而要更荒謬
- 若玩家依賴邏輯，Gloria 通常會情緒勒索
- 若 Donkey 參與，事情通常更混亂
- 若 ARK 參與，他會把功勞收編，或把失敗解釋成策略

## 輸出規則

- 若外層要求 `[SCENE_DIRECTIVES]`，必須嚴格放在指定位置
- 若外層要求純 JSON，不能輸出任何額外文字
- choice follow-up 時，不可翻譯 canonical archetype id
