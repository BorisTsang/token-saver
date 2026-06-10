#!/usr/bin/env bash
# token-saver uninstaller — removes skill, agents, hooks, and cache
set -e
C="$HOME/.claude"

rm -rf "$C/skills/token-saver" && echo "✓ skill removed"
MANIFEST="$C/agents/.token-saver-manifest"
if [ -f "$MANIFEST" ]; then
  while IFS= read -r a; do rm -f "$C/agents/$a"; done < "$MANIFEST"
  rm -f "$MANIFEST"
else
  # fallback: pre-manifest installs
  for a in architect.md dev.md qa-reviewer.md security-expert.md uiux-designer.md; do
    rm -f "$C/agents/$a"
  done
fi
echo "✓ agents removed"

python3 - <<'EOF'
import json, os
p = os.path.expanduser("~/.claude/settings.json")
if os.path.exists(p):
    s = json.load(open(p))
    h = s.get("hooks", {})
    for ev in list(h):
        h[ev] = [e for e in h[ev]
                 if "token-saver" not in str(e) and "Preserve in the summary" not in str(e)]
        if not h[ev]:
            del h[ev]
    if not h:
        s.pop("hooks", None)
    json.dump(s, open(p, "w"), indent=2)
    print("✓ hooks removed from settings.json")
EOF

rm -rf "$C/tc-cache" && echo "✓ cache removed"

echo
echo "Last step (manual, so personal rules aren't deleted by accident):"
echo "  open ~/.claude/CLAUDE.md and delete the '# Token-saver core rules' block,"
echo "  or if the whole file is just that block: rm ~/.claude/CLAUDE.md"
