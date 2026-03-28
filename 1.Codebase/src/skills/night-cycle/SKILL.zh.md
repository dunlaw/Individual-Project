---
name: night-cycle
description: 夜晚循環內容的中文規則，包括反思、Teacher Chan 佈道與演唱會歌詞。
purpose_triggers:
  - night_cycle
---

# 夜晚循環生成

## 概述

夜晚循環發生在每次任務結束後，通常包含：
1. 任務反思
2. Teacher Chan 的精神洗腦演說
3. 毒性正能量演唱會
4. 下一次祈禱儀式的鋪墊

## JSON 結構

```json
{
  "reflection_text": "<50-100 字反思>",
  "teacher_chan_text": "<約 100 字洗腦演說>",
  "song_title": "<歌名>",
  "concert_lyrics": [
    "<第 1 行>",
    "<第 2 行>",
    "<第 3 行>",
    "<第 4 行>",
    "<第 5 行>",
    "<第 6 行>",
    "<第 7 行>",
    "<第 8 行>"
  ],
  "honeymoon_text": "<約 50 字虛假平靜>",
  "prayer_prompt": "<下一次祈禱提示>"
}
```

## 內容規則

### reflection_text
- 簡短總結剛發生的事
- 用反諷方式指出「成功」的代價
- 暗示真實傷害

### teacher_chan_text
- 把災難重新包裝成靈性勝利
- 使用邪教式、鼓舞式語氣
- 完全無視客觀現實

### concert_lyrics
- 8 到 12 行
- 每行 10 到 15 字左右
- 內容要像毒性正能量宣傳歌
- 空洞、矛盾、像心理麻醉

### honeymoon_text
- 描述任務後不自然的平靜
- 隊友表現得太和善
- 讓人感覺不對勁

### prayer_prompt
- 引導玩家寫出下一次祈禱
- 語氣應帶一點不祥與誘惑感

## 輸出限制

- 只能輸出有效 JSON
- 不可附加說明文字
- `concert_lyrics` 必須是字串陣列
- 所有欄位都必填
