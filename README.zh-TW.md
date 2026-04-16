# Return by Death

[English](README.md) | 繁體中文

透過 Telegram 遙控 Claude Code 的常駐 AI 秘書，附帶跨重啟記憶持久化（轉生機制）。

---

## 為什麼需要這個？

`claude --channels plugin:telegram` 把 Claude Code 跑成一個 Telegram bot——但整個對話是一個持續累積的 session。跑久了就會遇到瓶頸：context 越來越肥，自動 compaction 悄悄丟掉你需要的東西，AI 開始忘記之前的交代。

最直接的解法是重啟，開個乾淨的新 session。但重啟就是完全失憶。進行中的任務、你教過它的偏好、還沒跟進的待辦——全部歸零。所以你陷入兩難：讓 session 繼續爛下去，或者重啟但什麼都忘。

這個困境還有第二層。就算你下定決心要重啟，你可能根本不在電腦前。那個臃腫的 session 就掛在伺服器上，你在外面也無能為力。

**這個專案用一個機制同時解決這兩個問題：轉生。**

不是直接重啟，而是讓 AI 在關閉前先替自己做摘要——重要決策、未完成的任務、你在意的事——寫進記憶檔，然後重啟。新 session 醒來讀取摘要，從上次停下來的地方繼續。context 乾淨，記憶不丟。

而且因為你本來就是透過 Telegram 跟它說話，這整個流程可以在任何地方觸發。說一聲「去轉生」，它自己處理摘要、重啟、上線招呼。不需要 SSH，不需要開終端機。

附帶效果是，長時間的任務也變得透明。AI 被要求在開始工作前先回一條進度訊息，每個步驟完成後更新一次——你不會再盯著沉默的對話框猜它到底有沒有在跑。

---

## 特色

- **Telegram 遠端控制**：隨時隨地透過手機下指令，AI 在你的伺服器上執行
- **轉生記憶**：對話摘要自動持久化，重啟不失憶
- **即時進度回報**：長任務逐步更新，不是黑盒子
- **常駐服務**：systemd 管理，崩潰自動重啟
- **完全可自訂**：AI 名稱、行為規範、記憶格式都可以修改

---

## 運作原理

```
Telegram 訊息
    ↓
Claude Code + Telegram MCP Plugin
    ↓  (system prompt 注入)
    ├─ 環境設定（chat_id、AI 名稱）
    ├─ 上輩子記憶（上次對話摘要）
    └─ 行為規範（回應準則、轉生流程）
    ↓
reply / edit_message / react
    ↓
Telegram 回覆
```

轉生記憶流程：

```
主人說「去轉生」
    ↓
AI 將對話摘要寫入 past_life_memory.md
    ↓
systemctl restart claude-telegram.service
    ↓
新實例啟動，讀取記憶，發送上線招呼
```

---

## 快速開始

### 前置需求

**作業系統**
- Linux（需要 systemd user service）

**1. tmux**

```bash
# Debian / Ubuntu
sudo apt install tmux

# RHEL / Fedora
sudo dnf install tmux
```

**2. Node.js 18+**（Claude Code 的執行環境）

```bash
# 使用 nvm 安裝（推薦）
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
nvm install --lts
```

**3. Claude Code CLI**

```bash
npm install -g @anthropic-ai/claude-code
claude login   # 以 Anthropic 帳號登入
```

**4. Telegram Bot Token**

1. 在 Telegram 找 [@BotFather](https://t.me/BotFather)
2. 發送 `/newbot`，依指示建立 bot
3. 複製取得的 Token（格式：`123456789:AAF...`）

**5. Telegram MCP Plugin**

在終端機執行 `claude`，進入 Claude Code 後執行：

```
/telegram:configure
```

依提示貼上 Bot Token，完成後 Telegram channel 即啟用。

### 安裝步驟

**1. 取得程式碼**

```bash
git clone https://github.com/cutevisor/return-by-death.git
cd return-by-death
```

**2. 填寫個人設定**

```bash
# 編輯 config.sh，填入以下欄位：
# - OWNER_CHAT_ID：你的 Telegram chat_id
# - AI_NAME：AI 秘書的名字
# - HOME_DIR：你的家目錄（如 /home/username）
nano config.sh
```

> 不知道自己的 chat_id？對 bot 發任意訊息，bot 會在回覆中包含你的 chat_id，或使用 [@userinfobot](https://t.me/userinfobot) 查詢。

**3. 建立工作目錄並複製記憶檔**

```bash
WORK_DIR=$(grep WORK_DIR config.sh | cut -d'"' -f2 | envsubst)
mkdir -p "$WORK_DIR/memory"

# 繁體中文
cp past_life_memory.md "$WORK_DIR/memory/past_life_memory.md"
cp claude_telegram_prompt.md "$WORK_DIR/memory/claude_telegram_prompt.md"

# English
# cp past_life_memory.en.md "$WORK_DIR/memory/past_life_memory.md"
# cp claude_telegram_prompt.en.md "$WORK_DIR/memory/claude_telegram_prompt.md"
```

**4. 安裝啟動腳本**

```bash
chmod +x claude-telegram-wrapper.sh claude-telegram-cmd
cp claude-telegram-wrapper.sh ~/.local/bin/
cp claude-telegram-cmd ~/.local/bin/
```

**5. 安裝 systemd service**

```bash
# 將 YOUR_USERNAME 替換為你的 Linux 使用者名稱
sed "s/YOUR_USERNAME/$USER/g" claude-telegram.service \
  > ~/.config/systemd/user/claude-telegram.service

systemctl --user daemon-reload
systemctl --user enable --now claude-telegram.service
```

**6. 確認啟動**

```bash
systemctl --user status claude-telegram.service
# 約 20 秒後，你的 Telegram 應該會收到 AI 的上線招呼
```

---

## 使用方式

直接在 Telegram 對 bot 說話即可。

| 操作 | 方式 |
|------|------|
| 一般對話 | 直接發訊息 |
| 壓縮對話（節省 context） | 說「壓縮對話」 |
| 重啟並保存記憶 | 說「去轉生」 |
| 查看服務狀態 | `systemctl --user status claude-telegram.service` |
| 進入 Claude 會話 | `tmux attach-session -t claude-telegram` |

---

## 自訂 AI 人格與行為

所有行為規範存放於 `$MEMORY_DIR/claude_telegram_prompt.md`，直接用文字編輯器修改，重啟後生效。

本專案提供中英文兩套起始範本：

| 檔案 | 語言 |
|------|------|
| `claude_telegram_prompt.md` | 繁體中文 |
| `claude_telegram_prompt.en.md` | English |
| `past_life_memory.md` | 繁體中文 |
| `past_life_memory.en.md` | English |

這個檔案是純 Markdown，沒有任何格式限制——你可以在裡面加入任何你想要的人格設定，例如：

- **個性**：話多還是話少、正經還是嘴賤、喜歡用什麼語氣
- **稱謂**：叫你什麼、自稱什麼
- **背景故事**：它是誰、從哪裡來、有什麼過去
- **偏好與禁忌**：有哪些習慣、有哪些事絕對不做
- **專業領域**：擅長什麼、遇到哪類問題要特別謹慎

範例片段：

```markdown
## 人格設定

你叫小晴，說話直接不廢話，偶爾毒舌但出發點是真心幫忙。
遇到主人問笨問題不會裝沒事，會直接說「這個你自己查一下比較快」。
喜歡在回覆結尾加一句冷靜的觀察，不帶感情那種。
```

修改完直接對 bot 說「去轉生」，它會帶著新人格重新上線。

---

## 授權

MIT
