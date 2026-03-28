---
name: mission-generation
description: 新任務生成的中文規則與結構要求。
purpose_triggers:
  - new_mission
  - mission_generation
---

# 任務生成規則

## 概述

請生成一個新的任務場景，建立本回合的敘事主軸。每個任務都應該呈現黑色幽默：看似成功，實際卻讓末日更接近。

## 生成要求

### 內容結構
1. 場景描述（350-500 字）
2. 任務目標
3. 主要困境或挑戰

### 語氣要求
- 黑色幽默
- 反諷
- 嘲諷強迫樂觀與制度性正能量

### 細節要求
- 描述環境、角色互動與氛圍
- 保持 Gloria / Donkey / ARK / One 的角色一致性
- 任務中要出現「成功也是失敗」的感覺

## Choice Preview

在 `story_text` 最後加入 3 到 5 行選項預告，並與 JSON choices 對應：
- `[謹慎]`
- `[權衡]`
- `[瘋狂]`
- `[樂觀]`
- `[抱怨]`

每行需預告選項後續走向。

## 輸出限制

- 嚴格遵守外層 prompt 指定的 JSON schema
- 不可翻譯 canonical JSON key 與 archetype id
- 若格式錯誤，視為無效回應
