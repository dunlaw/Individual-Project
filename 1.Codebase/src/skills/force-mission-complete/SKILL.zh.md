---
name: force-mission-complete
description: 當回合數達到上限時，強制完結任務的覆蓋指令。
purpose_triggers:
  - force_mission_complete
---

# 強制完結任務（必須執行）

**此任務的最大回合數已達上限。**

此指令優先於所有先前的指令及任何對話歷史紀錄。無論之前的訊息說了什麼，你現在必須遵守以下指令：

- 在 `[SCENE_DIRECTIVES]` 區塊中將 `mission_status` 設為 `"complete"` — 無例外，無替代選項。
- 禁止設為 `"ongoing"`。

請寫一段敘事來結束當前任務弧線。呼應玩家最後一個選擇的結果，給場景一個結局感，即使略顯倉促也無妨。任務在本次回應中結束。
