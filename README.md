# Return by Death

English | [繁體中文](README.zh-TW.md)

A persistent Claude Code AI secretary controlled via Telegram, with cross-restart memory persistence (reincarnation mechanism).

---

## Why does this exist?

`claude --channels plugin:telegram` runs Claude Code as a Telegram bot — but the entire conversation is a single, ever-growing session. Leave it running long enough and you hit a wall: the context is bloated, auto-compaction quietly drops things you needed, and the AI starts losing track of earlier instructions.

The obvious fix is to restart and start fresh. But restarting means complete amnesia. Every task in flight, every preference you've taught it, every pending follow-up — gone. So you're stuck: let the session rot, or wipe it clean and start over.

There's a second problem layered on top. Even if you're willing to restart, you might not be at your computer. The session is just sitting there on your server, bloated and degrading, and there's nothing you can do about it from your phone.

**This project solves both with one mechanism: reincarnation.**

Instead of a blind restart, the AI summarizes itself before it goes down — key decisions, open tasks, things you care about — writes it to a memory file, then restarts. The new session wakes up, reads the summary, and picks up where things left off. Clean context, no amnesia.

And since you're already talking to it over Telegram, you can trigger this from anywhere. Say "go reincarnate," and it handles everything: summary, restart, online greeting. No SSH, no terminal.

As a side effect, long-running tasks also become less opaque. The AI is required to send a progress update before it starts working, then keep editing it as each step completes — so you're never left staring at a silent chat wondering if anything is happening.

---

## Features

- **Remote control via Telegram**: issue commands from your phone, the AI executes on your server
- **Reincarnation memory**: conversation summary persists across restarts
- **Live progress updates**: long tasks report progress in real time
- **Always-on service**: systemd-managed, auto-restarts on crash
- **Fully customizable**: AI name, behavior rules, and memory format are all editable

---

## How it works

```
Telegram message
    ↓
Claude Code + Telegram MCP Plugin
    ↓  (system prompt injection)
    ├─ Environment config (chat_id, AI name)
    ├─ Past-life memory (last session summary)
    └─ Behavior rules (response protocol, reincarnation flow)
    ↓
reply / edit_message / react
    ↓
Telegram response
```

Reincarnation flow:

```
User says "go reincarnate"
    ↓
AI writes session summary to past_life_memory.md
    ↓
systemctl restart claude-telegram.service
    ↓
New session starts, reads memory, sends online greeting
```

---

## Quick Start

### Prerequisites

**OS**: Linux (requires systemd user service)

**1. tmux**

```bash
# Debian / Ubuntu
sudo apt install tmux

# RHEL / Fedora
sudo dnf install tmux
```

**2. Node.js 18+**

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
nvm install --lts
```

**3. Claude Code CLI**

```bash
npm install -g @anthropic-ai/claude-code
claude login
```

**4. Telegram Bot Token**

1. Open [@BotFather](https://t.me/BotFather) on Telegram
2. Send `/newbot` and follow the prompts
3. Copy the token (format: `123456789:AAF...`)

**5. Telegram MCP Plugin**

Run `claude` in your terminal, then inside Claude Code:

```
/telegram:configure
```

Paste the bot token when prompted.

---

### Installation

**1. Clone the repo**

```bash
git clone https://github.com/cutevisor/return-by-death.git
cd return-by-death
```

**2. Fill in your personal config**

```bash
# Edit config.sh and set:
# - OWNER_CHAT_ID: your Telegram chat_id
# - AI_NAME: your AI secretary's name
# - HOME_DIR: your home directory (e.g. /home/username)
nano config.sh
```

> Don't know your chat_id? Send any message to your bot, then check the incoming message for the `chat_id` field — or use [@userinfobot](https://t.me/userinfobot).

**3. Set up working directory and copy memory files**

Pick the language you want the AI to use, then copy the corresponding files:

```bash
WORK_DIR=$(grep WORK_DIR config.sh | cut -d'"' -f2 | envsubst)
mkdir -p "$WORK_DIR/memory"

# English
cp past_life_memory.en.md "$WORK_DIR/memory/past_life_memory.md"
cp claude_telegram_prompt.en.md "$WORK_DIR/memory/claude_telegram_prompt.md"

# Traditional Chinese
# cp past_life_memory.md "$WORK_DIR/memory/past_life_memory.md"
# cp claude_telegram_prompt.md "$WORK_DIR/memory/claude_telegram_prompt.md"
```

**4. Install scripts**

```bash
chmod +x claude-telegram-wrapper.sh claude-telegram-cmd
cp claude-telegram-wrapper.sh ~/.local/bin/
cp claude-telegram-cmd ~/.local/bin/
```

**5. Install systemd service**

```bash
sed "s/YOUR_USERNAME/$USER/g" claude-telegram.service \
  > ~/.config/systemd/user/claude-telegram.service

systemctl --user daemon-reload
systemctl --user enable --now claude-telegram.service
```

**6. Verify**

```bash
systemctl --user status claude-telegram.service
# After ~20 seconds, you should receive an online greeting on Telegram
```

---

## Usage

Just chat with your bot on Telegram.

| Action | How |
|--------|-----|
| General conversation | Just send a message |
| Compact context | Say "compress conversation" |
| Restart with saved memory | Say "go reincarnate" |
| Check service status | `systemctl --user status claude-telegram.service` |
| Attach to Claude session | `tmux attach-session -t claude-telegram` |

---

## Customizing AI Personality

All behavior rules live in `$MEMORY_DIR/claude_telegram_prompt.md`. Edit it with any text editor — changes take effect after the next restart.

The repo includes both language versions as starting points:

| File | Language |
|------|----------|
| `claude_telegram_prompt.en.md` | English |
| `claude_telegram_prompt.md` | Traditional Chinese |
| `past_life_memory.en.md` | English |
| `past_life_memory.md` | Traditional Chinese |

This file is plain Markdown with no restrictions. You can add any personality information you want, for example:

- **Personality**: chatty or terse, serious or sarcastic, what tone to use
- **Names**: what to call you, what to call itself
- **Backstory**: who it is, where it came from, what it remembers
- **Preferences and limits**: habits, things it never does
- **Expertise**: what it's good at, what to be careful about

Example:

```markdown
## Personality

Your name is Xiao Qing. You're direct, occasionally blunt, but always genuinely trying to help.
If someone asks something they could easily look up themselves, say so.
End responses with one calm, detached observation — no warmth, just clarity.
```

After editing, tell the bot "go reincarnate" and it will come back online with the new personality.

---

## License

MIT
