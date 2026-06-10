#!/usr/bin/env bash
# token-saver installer — copies skill, agents, global rules, and hooks into ~/.claude
set -e
cd "$(dirname "$0")"
C="$HOME/.claude"
mkdir -p "$C/skills" "$C/agents" "$C/tc-cache"

# 0. settings.json must be valid JSON before we touch anything
if [ -e "$C/settings.json" ] && ! python3 -m json.tool "$C/settings.json" >/dev/null 2>&1; then
  echo "✗ ~/.claude/settings.json is not valid JSON (comments?). Fix it, then re-run." >&2
  exit 1
fi

# 1. skill (note: replaces any previous version, including local edits to it)
[ -d "$C/skills/token-saver" ] && echo "  note: replacing existing token-saver skill"
cp -r skills/token-saver "$C/skills/"
chmod +x "$C/skills/token-saver/scripts/"*.py
echo "✓ skill installed"

# 2. agents (don't overwrite customized ones)
for f in agents/*.md; do
  t="$C/agents/$(basename "$f")"
  [ -e "$t" ] && echo "  skip $(basename "$f") (exists)" || { cp "$f" "$t"; echo "✓ agent $(basename "$f")"; }
done

# 3. global rules
if [ -e "$C/CLAUDE.md" ]; then
  if grep -q "Token-saver core rules" "$C/CLAUDE.md"; then
    echo "  skip CLAUDE.md (already has rules)"
  else
    printf "\n\n" >> "$C/CLAUDE.md"; cat CLAUDE-global.md >> "$C/CLAUDE.md"
    echo "✓ rules appended to existing CLAUDE.md"
  fi
else
  cp CLAUDE-global.md "$C/CLAUDE.md"; echo "✓ global CLAUDE.md created"
fi

# 4. hooks (merge into settings.json without clobbering; drops the old no-op PreCompact hook)
python3 - <<'EOF'
import json, os
p = os.path.expanduser("~/.claude/settings.json")
s = json.load(open(p)) if os.path.exists(p) else {}
h = s.setdefault("hooks", {})
# remove the v1.0 PreCompact echo (stdout never reached the model — dead feature)
if "PreCompact" in h:
    h["PreCompact"] = [e for e in h["PreCompact"] if "Preserve in the summary" not in str(e)]
    if not h["PreCompact"]:
        del h["PreCompact"]
def add(event, matcher, cmd):
    arr = h.setdefault(event, [])
    if any(cmd in str(e) for e in arr):
        return
    arr.append({"matcher": matcher, "hooks": [{"type": "command", "command": cmd}]})
add("PostToolUse", "Bash", "python3 ~/.claude/skills/token-saver/scripts/big-output-check.py")
add("SessionStart", "", "python3 ~/.claude/skills/token-saver/scripts/session-start.py")
json.dump(s, open(p, "w"), indent=2)
print("✓ hooks merged into settings.json")
EOF

echo
echo "Done. Restart Claude Code, then run /token-saver init inside any project."
echo "Uninstall anytime: bash uninstall.sh"
