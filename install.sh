#!/usr/bin/env bash
# token-saver installer — copies skill, agents, global rules, and hooks into ~/.claude
set -e
cd "$(dirname "$0")"
C="$HOME/.claude"
mkdir -p "$C/skills" "$C/agents" "$C/tc-cache"

# 1. skill
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

# 4. hooks (merge into settings.json without clobbering)
python3 - <<'EOF'
import json, os
p = os.path.expanduser("~/.claude/settings.json")
s = json.load(open(p)) if os.path.exists(p) else {}
h = s.setdefault("hooks", {})
def add(event, matcher, cmd):
    arr = h.setdefault(event, [])
    if any(cmd in str(e) for e in arr):
        return
    arr.append({"matcher": matcher, "hooks": [{"type": "command", "command": cmd}]})
add("PostToolUse", "Bash", "python3 ~/.claude/skills/token-saver/scripts/big-output-check.py")
add("PreCompact", "", "echo 'Preserve in the summary: current goal, work in flight, next steps, key file:line references, and user preferences stated this session.'")
json.dump(s, open(p, "w"), indent=2)
print("✓ hooks merged into settings.json")
EOF

echo
echo "Done. Restart Claude Code, then run /token-saver init inside any project."
