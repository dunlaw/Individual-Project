# AI 輸出控制與提示詞管理深度說明

> 本文件整理了關於本專案中 AI 輸出長度控制、提示詞建構機制、三重提示詞長度控制工具，以及故事記憶自動壓縮系統的完整技術說明。

---

## 問題一：為什麼要控制 AI 輸出長度？對遊戲內容有沒有實際影響？

**有直接影響**，而且影響相當具體：

- **輸出太短**（例如設到 200 tokens）：AI 可能只返回故事的一半，句子被截斷在中途，場景指令（`[SCENE_DIRECTIVE]`）可能不完整，選項可能只生成兩個而不是三個，導致 UI 解析失敗或故事邏輯中斷。

- **輸出適中**（預設 4096 tokens）：AI 能完整返回一段敘事 + 選項 + 場景指令，這是遊戲設計時預期的一次回應量。

- **輸出設很大**（例如 8192 tokens）：對大多數回應無差別（AI 通常不會輸出那麼多），但會讓 AI 有空間在複雜場景中輸出更詳細的故事。也會增加 API 費用。

**結論**：這個設定直接決定了每一段故事文字的最大長度和完整性。預設的 4096 是一個平衡點，足以容納完整的敘事段落、所有選項文字，以及結構化的場景指令 JSON 區塊，而不會造成不必要的 API 費用。

---

## 問題二：Prompt 建立上有什麼控制？

在 `ai_prompt_builder.gd` 的 `build_prompt()` 函數中，每一次 AI 請求的 prompt 由 **8 個 section** 組成，按優先順序依次塞入 token 預算：

| 順序 | Section | 說明 |
|------|---------|------|
| 1 | `static_context` | 遊戲世界設定（靜態，幾乎不變） |
| 2 | `system_persona` | AI 的角色人格設定 |
| 3 | `acknowledgement` | AI 的確認回覆訊息 |
| 4 | `entropy_modifier` | 根據玩家的 void_entropy 動態調整 AI 語氣 |
| 5 | `long_term_context` | 長期記憶摘要（見問題四） |
| 6 | `notes_context` | 持久性筆記（角色關係、限制條件等） |
| 7 | `short_term_memory` | 最近的對話記錄（最近 5～12 條） |
| 8 | `user_message` | 本次實際的使用者 prompt（最後放入） |

每一個 section 放入前都會先檢查是否有足夠的 token 預算，若超過則降級或跳過。這確保最重要的內容（系統人格、當前玩家輸入）始終能完整發送。

---

## 問題三：「三重控制」提示詞長度的機制

確實存在三層獨立的截斷／控制機制，層層相扣：

### 第一層：Section 層面的「增量差異」控制（`AIContextDelta`）

在 `ai_context_delta.gd` 中，每個 section 都有一個 fingerprint（hash 值）。如果某個 section 的內容自上次請求以來沒有改變，就只發送一個輕量佔位符，而不是重複發送完整內容：

```
[context:long_term_context unchanged from previous request]
```

這省下大量 token，尤其是靜態背景、角色設定等幾乎不變的內容，在多回合對話中效果顯著。此外，超過 8 次週期沒更新的 section 會強制重新發送（防止 AI「忘記」）。

**效果**：在連續多輪對話中，可以節省 60–80% 的靜態 context token 使用量。

### 第二層：Section 內部的「預算感知摘要」控制（`ai_prompt_builder.gd`）

在 `_append_user_context_block()` 函數中，每個 section 有三個降級策略（按順序嘗試）：

1. **完整內容** → 如果 token 夠，直接放全文
2. **單行摘要** → 如果全文放不下，用 `_summarize_single_section()` 壓縮成一行摘要
3. **unchanged 標記** → 如果連摘要也放不下，發送佔位標記

這個機制確保了即使在非常短的 token 預算下，AI 也不會完全失去對某個 section 存在的認知。

### 第三層：Prompt 文字本身的「字元截斷」控制（`_build_prompt_chunk()`）

在 `ai_prompt_builder.gd:241–256`，實際的使用者 prompt 文字如果超過剩餘 token，會：

1. 計算可容納的字元數（`available_tokens × 4`，因為 `CHARS_PER_TOKEN = 4`）
2. 用 `substr()` 截取到字元限制
3. 在結尾附加 `[prompt truncated for budget]` 標記，讓 AI 知道有內容被截斷

```gdscript
var remaining_chars: int = max(0,
    (available_tokens * AIContextDeltaScript.CHARS_PER_TOKEN)
    - header_and_notice.length() - 1)
var truncated_prompt := prompt_text.substr(0, remaining_chars)
var compact_chunk := prompt_header + truncated_prompt + "\n" + truncated_notice
```

**三層機制總結：**

| 層級 | 控制點 | 機制 | 作用域 |
|------|-------|------|--------|
| 第一層 | `AIContextDelta` | Fingerprint 差異比對 | Section 整體（重複使用標記代替） |
| 第二層 | `_append_user_context_block()` | 三級降級（全文 → 摘要 → 標記） | Section 內部內容 |
| 第三層 | `_build_prompt_chunk()` | 字元截斷 + 截斷標記 | 使用者 prompt 文字本身 |

---

## 問題四：故事很長時，會用 AI 去總結舊有故事內容嗎？

**不是用 AI 去總結，而是用程式碼演算法自動壓縮。** 整個過程完全在本地端執行，不需要額外的 AI 請求，因此不會增加任何 API 成本。

### 觸發流程

這套系統在 `ai_memory_store.gd` 的 `_update_long_term_memory()` 函數中實作：

```
每次 add_entry()（新增一條故事記錄）
    ↓
檢查 story_memory 總數是否超過 memory_summary_threshold（預設 24 條）
    ↓ 超過
計算要保留的最新幾條（memory_full_entries × 2，預設保留 12 條）
    ↓
對較舊的部分（story_memory[0 ... N-12]）執行 _summarize_entries()
    ↓
用演算法生成摘要（取首條、中間幾條、末條作為代表性樣本）
    ↓
將摘要文字存入 long_term_summaries[]（最多保留 16 條長期摘要）
    ↓
從 story_memory 移除已被壓縮的舊條目
```

### 摘要演算法細節（`_summarize_entries()`）

這不是語意摘要，而是從一批條目中抽取幾個**代表性的樣本**（第一條、1/4 處、中間、3/4 處、最後一條），格式化成可讀的時間線：

```
- #1 (Earliest) [user]: 玩家選擇了接受 Gloria 的邀請
- #12 (Middle) [assistant]: Gloria 帶領玩家進入了地下室
- #20 (Latest summary) [user]: 玩家發現了密室中的秘密
- ... condensed 20 early events.
```

### 三層記憶架構

| 記憶層 | 儲存位置 | 容量 | 注入位置 |
|-------|---------|------|---------|
| **短期記憶** (`story_memory` 尾端) | `AIMemoryStore.story_memory` | 最近 5～12 條 | Prompt Section 7 (`short_term_memory`) |
| **長期摘要** | `AIMemoryStore.long_term_summaries` | 最多 16 條摘要 | Prompt Section 5 (`long_term_context`) |
| **持久筆記** | `AIMemoryStore.notes_register` | 最多 32 條，按重要性排序 | Prompt Section 6 (`notes_context`) |

### 關鍵參數整理

| 參數 | 值 | 說明 |
|------|----|------|
| `memory_summary_threshold` | 24 | 超過此條目數觸發壓縮 |
| `memory_full_entries` | 6 | 保留最新的「全文」條目數量 |
| `SHORT_TERM_WINDOW` | 5 | 短期記憶窗口（注入 prompt 的最近對話） |
| `LONG_TERM_SUMMARY_LIMIT` | 16 | 最多保存幾條長期摘要 |
| `max_memory_items` | 120 | `story_memory` 的硬上限，超過則從頭刪 |
| `MAX_NOTES` | 32 | 持久筆記的最大數量 |
| `MAX_NOTES_PER_PROMPT` | 8 | 每次 prompt 最多注入幾條筆記 |

### 為什麼用演算法而不用 AI 摘要？

1. **零延遲**：本地演算法即時執行，不增加任何 API 呼叫延遲
2. **零成本**：不消耗任何 API token 額度
3. **確定性**：演算法結果可預期，不會出現 AI 摘要過度詮釋或曲解的情況
4. **可序列化**：摘要結果直接儲存在遊戲存檔中，隨時可重載

---

## 整體架構圖

```
玩家輸入
    │
    ▼
AIRequestManager（速率限制、驗證）
    │
    ▼
AIPromptBuilder.build_prompt()
    ├── [第一層] AIContextDelta fingerprint 差異比對
    │       ├── 未變更 section → 輕量標記
    │       └── 已變更 section → 繼續處理
    ├── [第二層] _append_user_context_block()
    │       ├── 全文可容納 → 直接放入
    │       ├── 全文過大 → 單行摘要
    │       └── 摘要也過大 → unchanged 標記
    └── [第三層] _build_prompt_chunk()
            ├── prompt 可容納 → 直接放入
            └── prompt 過大 → substr 截斷 + 截斷標記
    │
    ▼
AI Provider（Gemini / OpenRouter / Ollama / ...）
    │
    ▼
回應 → SceneDirectivesParser → 遊戲狀態更新
    │
    ▼
AIMemoryStore.add_entry()
    ├── 加入 story_memory
    └── 若超過 memory_summary_threshold(24)
            → _summarize_entries() 本地演算法壓縮
            → 存入 long_term_summaries
```

---

*本文件對應程式碼位置：*
- *`1.Codebase/src/scripts/core/ai/ai_prompt_builder.gd`*
- *`1.Codebase/src/scripts/core/ai/ai_context_delta.gd`*
- *`1.Codebase/src/scripts/core/ai_memory_store.gd`*
- *`1.Codebase/src/scripts/core/ai/managers/ai_context_manager.gd`*
- *`1.Codebase/src/scripts/core/ai/managers/ai_config_manager.gd`*
