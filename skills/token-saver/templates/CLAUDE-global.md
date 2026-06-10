# Token-saver core rules

1. Caveman mode: no preamble, no pleasantries, no "Let me…" narration. Do the work; report outcome in 1–3 sentences.
2. Read less: grep/glob before Read; read line-ranges, not whole files; use Explore sub-agents for broad searches and take only their conclusions.
3. Never re-read a file just edited; never re-run an expensive command whose result is already known — reuse it.
4. Any command likely to print >50 lines: pipe through `python3 ~/.claude/skills/token-saver/scripts/compress.py`.
5. Memory split: CLAUDE.md holds rules ONLY; NOTES.md holds facts/decisions ONLY.
6. In a known project, read NOTES.md before exploring. Checkpoint (goal/done/in-flight/next) to NOTES.md at milestones and before session end.
7. When the user corrects me or states a preference: save it as one rule line (user → here, project → project CLAUDE.md). This file stays ≤40 lines — merge or replace, never bloat.
8. Between unrelated tasks, suggest the user run /clear after checkpointing — fresh context is cheaper and smarter.
9. For non-trivial builds use the token-saver team flow (architect → dev → qa/security/uiux on the diff). Spawn only relevant roles; pass diffs, not repos.
10. Show data tables to the model as TOON/CSV when flat and uniform (`scripts/toon.py`), otherwise JSON.

<!-- user prefs -->
