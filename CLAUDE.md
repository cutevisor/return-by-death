# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 語言規範

一律使用繁體中文回覆。

## 專案概覽

輕量級 AI Telegram 秘書的**啟動器與服務設定**，不是獨立應用程式。核心邏輯：

- 將 Markdown 記憶與行為規範合併成 system prompt，注入 Claude Code
- 透過 `plugin:telegram@claude-plugins-official` MCP plugin 收發 Telegram 訊息
- systemd + tmux 確保服務常駐與自動重啟

## 檔案結構

| 檔案 | 用途 |
|------|------|
| `config.sh` | **個人設定**：chat_id、AI 名稱、路徑（使用前必須填寫） |
| `claude-telegram-wrapper.sh` | 啟動腳本：讀取 config → 合併 prompt → 啟動 Claude Code → 觸發上線招呼 |
| `claude-telegram-cmd` | 向 tmux session 發送指令的工具腳本 |
| `claude-telegram.service` | systemd user service 定義（路徑需替換） |
| `past_life_memory.md` | 轉生記憶**範本**，正式使用請放到 `$MEMORY_DIR/` |
| `claude_telegram_prompt.md` | 行為規範**範本**，正式使用請放到 `$MEMORY_DIR/` |

## 初次設定

1. 填寫 `config.sh` 中的個人設定（`OWNER_CHAT_ID`、`HOME_DIR` 等）
2. 將 `past_life_memory.md` 與 `claude_telegram_prompt.md` 複製到 `$MEMORY_DIR/`
3. 將 `claude-telegram-wrapper.sh` 複製（或 symlink）到 `$HOME_DIR/.local/bin/`
4. 編輯 `claude-telegram.service`，將 `YOUR_USERNAME` 替換為你的 Linux 使用者名稱
5. 安裝 systemd service：
   ```bash
   cp claude-telegram.service ~/.config/systemd/user/
   systemctl --user daemon-reload
   systemctl --user enable --now claude-telegram.service
   ```

## 服務管理指令

```bash
systemctl --user start claude-telegram.service
systemctl --user stop claude-telegram.service
systemctl --user restart claude-telegram.service       # 等同觸發轉生
systemctl --user status claude-telegram.service
journalctl --user-unit claude-telegram.service -f      # 即時日誌
tmux attach-session -t claude-telegram                 # 進入 Claude Code 會話
```

## 啟動流程

```
wrapper.sh
  ├─ source config.sh
  ├─ 合併 環境設定區塊 + past_life_memory.md + claude_telegram_prompt.md → 暫存檔
  ├─ exec claude --append-system-prompt-file <暫存檔>
  └─ 背景：sleep 20 → 刪暫存檔 → 向 tmux 發送上線招呼指令
```

暫存檔在 Claude 啟動 20 秒後即刪除，防止 `ps aux` 洩漏 prompt 內容。

## 架構要點

### System Prompt 注入
行為規範不在程式碼中，由 wrapper 合併三個來源後注入：
1. **環境設定**（由 config.sh 動態產生）：AI 名稱、chat_id
2. **`past_life_memory.md`**：上次會話摘要，跨重啟持久化
3. **`claude_telegram_prompt.md`**：行為規範與回應準則

修改 AI 行為 → 編輯 `$MEMORY_DIR/claude_telegram_prompt.md`

### 轉生機制
主人指示「轉生/投胎」時，Claude 自行：
1. 將對話摘要寫入 `$MEMORY_DIR/past_life_memory.md`（頂部寫 `轉生次數: N`）
2. 執行 `systemctl --user restart claude-telegram.service`

新實例啟動後讀取更新後的記憶，實現跨會話持久化。

### 進度回報機制
長任務（需讀檔、執行指令、多步驟）的強制流程：
1. 先 `reply` 簡短進度訊息（記下 message_id）
2. 每 2-3 個工具呼叫後 `edit_message` 更新進度
3. 最終用 `edit_message` 替換為結果（禁止再發新 reply）

### Telegram 工具
- `react` — 收到訊息立刻加 emoji 確認
- `reply` — 發送新訊息（format: "markdownv2"）
- `edit_message` — 更新既有訊息（進度反饋）
- `claude-telegram-cmd <cmd>` — 向 tmux session 發送指令（如 `/compact`）；session 不存在時報錯退出

## 修改指引

| 要改的東西 | 修改哪個檔案 |
|------|------|
| AI 行為規範 | `$MEMORY_DIR/claude_telegram_prompt.md` |
| 上次會話記憶 | `$MEMORY_DIR/past_life_memory.md` |
| chat_id / AI 名稱 / 路徑 | `config.sh` |
| 服務啟動參數或 Claude 指令列 | `claude-telegram-wrapper.sh`，改後需 `systemctl --user daemon-reload` |
| systemd 服務設定 | `claude-telegram.service`，改後需 `systemctl --user daemon-reload` |
