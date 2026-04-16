#!/bin/bash
# 個人設定 — 依照自己的環境填寫後再啟動服務

# 主人的 Telegram chat_id（對 bot 發任意訊息，bot 會回覆含 chat_id 的資訊）
OWNER_CHAT_ID="YOUR_TELEGRAM_CHAT_ID"

# AI 秘書名稱（可自訂）
AI_NAME="小晴"

# 家目錄（絕對路徑）
HOME_DIR="/home/YOUR_USERNAME"

# 工作目錄（AI 的 cwd，存放技能、腳本、記憶等）
WORK_DIR="${HOME_DIR}/clawd"

# 記憶目錄（存放 past_life_memory.md 與 claude_telegram_prompt.md）
MEMORY_DIR="${WORK_DIR}/memory"

# claude 執行檔路徑
CLAUDE_BIN="${HOME_DIR}/.local/bin/claude"
