# 💰 token-saver — make Claude Code cheaper AND smarter

A skill pack for Claude Code. It cuts token spend 40–70% by removing waste (not by making Claude dumber), gives Claude permanent memory of your projects, and installs a team of expert AI agents that review each other's work.

## Install

```bash
git clone https://github.com/BorisTsang/token-saver.git
cd token-saver && bash install.sh
```

(Or download the zip from GitHub → unzip → `bash install.sh`.)

Restart Claude Code. Done — it works in **every** project automatically.
To update later: `git pull && bash install.sh`.

## What it does automatically (no action needed)

| Feature | What it means for you |
|---|---|
| 🤐 **Caveman mode** | Claude stops writing fluff ("Let me…", long explanations). Does work, reports result in 1–3 sentences. |
| 📖 **Reads less** | Searches before reading, reads only the needed part of files instead of whole files. |
| 🗜 **Shrinks big outputs** | Huge logs/JSON/code get compressed 60–95% before entering chat. Original is kept on disk — nothing is lost. |
| 🧠 **Memory** | Claude saves project facts & decisions to a `NOTES.md` file. Next session it already knows your project — no expensive re-discovery. |
| 📈 **Self-improving** | Every time you correct Claude ("don't do X", "always Y"), it saves that as a permanent rule. Fewer repeated mistakes forever. |
| 💾 **Crash insurance** | Before Claude compresses a long conversation, a hook makes sure your goal + progress survive. |

## Commands (type these in Claude Code when you want)

| Command | What it does |
|---|---|
| `/token-saver init` | Run once per project. Sets up a lean project config + memory file, and flags token-wasting MCP servers. |
| `/token-saver team <task>` | Full expert-team build: architect designs → dev builds → QA + security (+ designer) review → fixes → final verdict. |
| `/token-saver audit` | Report of what's eating your tokens + fixes. |
| `/token-saver remember <fact>` | Force-save something to project memory. |
| `/token-saver judge` | Brutal investor + product-manager verdict on current work. |

## The agent team (auto-included)

5 real agents: 🏗 architect · 🛠 dev · 🧪 qa-reviewer (runs on cheap Haiku) · 🔒 security-expert · 🎨 uiux-designer.
5 free "lenses": 💰 investor · 📋 product-manager · 🚀 devops · ⚡ performance · 📝 docs-writer.
Token-smart: only relevant roles activate, and reviewers only see the changed code, never the whole repo.

## Tips for maximum savings

1. After finishing a task, let Claude checkpoint, then type `/clear` — a fresh chat is cheaper and smarter than a bloated one.
2. Run `/token-saver audit` once a month.
3. Disconnect MCP servers you don't use — each one costs tokens on every single message.

## What's inside

```
skills/token-saver/   the skill: rules, scripts (compress.py, toon.py), templates
agents/               5 expert agent definitions
CLAUDE-global.md      the always-on rules (installer puts it at ~/.claude/CLAUDE.md)
install.sh            installer (also merges 2 hooks into your settings)
```

No external tools, no servers, no accounts. Python 3 only (already on Mac/Linux).
