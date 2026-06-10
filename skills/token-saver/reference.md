# token-saver reference (load on demand only)

## §init — /token-saver init

Run steps in order. Idempotent: skip anything that already exists and is healthy.

1. **MCP audit first.** Run `claude mcp list` (or check `.mcp.json` / settings). Every connected MCP server costs tokens on EVERY request even if unused. Tell the user which servers exist and ask which they actually use; suggest removing the rest (`claude mcp remove <name>`).
2. **Global prefs (once).** If `~/.claude/CLAUDE.md` lacks the `# Token-saver core rules` block, ask the user 3 quick questions (answer language? terse or explained answers? any standing rules?) and write the block from `templates/CLAUDE-global.md`, filling in their answers. Hard cap 40 lines.
3. **Scan the project.** Detect language/framework (manifest files), build/test/run commands, top-level layout (one `ls` + manifest reads — do NOT read source files).
4. **Write project `CLAUDE.md`** from `templates/CLAUDE-project.md`, filled with real scanned values. ≤40 lines. If one exists: trim it instead — keep rules, move facts to NOTES.md, delete anything derivable from code.
5. **Create `NOTES.md`** in project root from `templates/NOTES.md` if missing. Add `NOTES.md` pointer line to project CLAUDE.md.
6. Report in ≤5 lines what was created/skipped.

## §audit — /token-saver audit

Produce a ranked token-cost report, then offer fixes:

1. Global + project CLAUDE.md: `wc -c` ÷ 4 = tokens paid EVERY session. Flag if >1500 tok. Prune: duplicate rules, contradictions, facts that belong in NOTES.md, anything stale. Enforce 40-line cap.
2. MCP servers: list them; each ≈ hundreds–thousands of tokens per request. Flag unused.
3. `~/.claude/skills/`: count skills; flag any SKILL.md description >2 lines.
4. NOTES.md: flag if >150 lines → archive old entries to `NOTES-archive.md`.
5. Repo: find large JSON/fixture files read often → suggest toon.py or compress.py.
6. Output: table (source | est. tokens/session | fix), top offender first. Apply fixes only with user OK.

## §lenses (zero-cost role prompts — apply yourself, no agent spawn)

- **investor 💰** — Would I fund this? Is it worth building, who pays, what's the moat, what kills it? Name the 3 weakest points bluntly.
- **product-manager 📋** — Does this solve the user's actual problem? What's missing, what's overbuilt, what ships first?
- **devops 🚀** — Will this deploy/run reliably? Config, secrets handling, CI, rollback.
- **performance ⚡** — Slow paths, N+1 queries, memory hogs, bundle size, unnecessary work.
- **docs-writer 📝** — Write/refresh README + key comments. Terse, example-first.

`judge` = investor + product-manager combined, ≤10-line verdict with a build/fix/kill call.

## Self-improve rule detail

When the user corrects you or states a preference: distill to ONE line. About the user → global CLAUDE.md; about the project → project CLAUDE.md; a fact/decision → NOTES.md. Before adding, check for duplicates/contradictions; replace rather than append when overlapping. Respect the 40-line cap — if full, merge or drop the least useful rule.

## Compression notes

- compress.py caches originals at `~/.claude/tc-cache/<hash>.orig` (plain text — may hold secrets; auto-pruned after 7 days, safe to clear anytime).
- If compression wouldn't save tokens, it prints the original unchanged.
- Modes: `--mode log|json|code` to override detection.
