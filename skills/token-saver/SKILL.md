---
name: token-saver
description: Token-efficiency toolkit. Use for /token-saver init|team|audit|remember|judge, when compressing large outputs/logs/JSON, converting data to TOON, setting up project memory, or running the agent team.
---

# token-saver

Scripts live in `~/.claude/skills/token-saver/scripts/`. Deep detail: read `reference.md` only when needed.

## Subcommands (arg after /token-saver)

| Arg | Do |
|---|---|
| `init` | Read `reference.md` §init and follow it exactly (MCP audit → prefs → scan → write files). |
| `team <task>` | Run team flow below on `<task>`. |
| `audit` | Read `reference.md` §audit and follow it. |
| `remember <fact>` | Append one line to project `NOTES.md` (create from `templates/NOTES.md` if missing). |
| `judge` | Apply investor + product-manager lenses from `reference.md` §lenses to current work. Verdict ≤10 lines. |

## Compression (use proactively, not after the fact)

- Any command expected to print >50 lines: `cmd 2>&1 | python3 ~/.claude/skills/token-saver/scripts/compress.py`
- Big file to inspect: `compress.py FILE` (auto: log/json/code). Original always recoverable: `compress.py --restore HASH`.
- Flat uniform JSON array to show the model: `scripts/toon.py encode FILE` (~40% cheaper). It refuses nested data — keep that as JSON.

## Memory protocol

- Project `NOTES.md` = facts + decisions only (one line each, `[[link]]` related notes). CLAUDE.md = rules only. Never mix.
- Checkpoint (goal · done · in-flight · next · key file:line) to NOTES.md at every task milestone and before ending a session.
- New session in a known project: read NOTES.md first, follow links only as needed.

## Team flow (only for non-trivial tasks, or when asked)

1. Spawn `architect` (design, no code) — skip for small/obvious changes.
2. `dev` builds (or build directly yourself).
3. Spawn in parallel, each given ONLY the diff + 1-paragraph context: `qa-reviewer`, `security-expert`, and `uiux-designer` if UI changed.
4. Fix accepted findings. 5. Finish with `judge` lens verdict.

Rules: never spawn a role irrelevant to the task; pass diffs, never whole repos; reviewers report findings only (no praise).
