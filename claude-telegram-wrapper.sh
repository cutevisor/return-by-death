#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"

export HOME="$HOME_DIR"
export PATH="${HOME_DIR}/.local/bin:${HOME_DIR}/.bun/bin:${HOME_DIR}/.npm-global/bin:/usr/local/bin:/usr/bin:/bin"
cd "$WORK_DIR"

PAST_LIFE="$MEMORY_DIR/past_life_memory.md"
PROMPT_FILE="$MEMORY_DIR/claude_telegram_prompt.md"
COMBINED_FILE=$(mktemp /tmp/claude-telegram-prompt.XXXXXX)

# 組合 prompt 寫入暫存檔，避免 ps aux 暴露內容
{
  # 注入個人設定供 AI 參考
  echo "# 環境設定"
  echo "- AI 名稱：${AI_NAME}"
  echo "- 主人 Telegram chat_id：${OWNER_CHAT_ID}"
  echo ""

  if [ -f "$PAST_LIFE" ]; then
    echo "# 上輩子記憶"
    cat "$PAST_LIFE"
    echo ""
  fi
  if [ -f "$PROMPT_FILE" ]; then
    cat "$PROMPT_FILE"
  fi
} > "$COMBINED_FILE"

# 背景等 Claude 就緒後送觸發 prompt，並刪除暫存檔
(
  sleep 20
  rm -f "$COMBINED_FILE"
  tmux send-keys -t claude-telegram "根據 system prompt 中的上輩子記憶，用 telegram reply tool 向 chat_id ${OWNER_CHAT_ID} 發送上線招呼" Enter
) &

exec "$CLAUDE_BIN" --dangerously-skip-permissions --permission-mode bypassPermissions \
  --add-dir ~/.claude/channels/telegram \
  --channels plugin:telegram@claude-plugins-official \
  --append-system-prompt-file "$COMBINED_FILE"
