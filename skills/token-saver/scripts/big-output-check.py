#!/usr/bin/env python3
"""PostToolUse hook: if a Bash tool output was huge, remind Claude to pipe through compress.py next time."""
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if data.get("tool_name") != "Bash":
    sys.exit(0)
out = data.get("tool_response") or {}
text = (out.get("stdout") or "") + (out.get("stderr") or "") if isinstance(out, dict) else str(out)
if len(text) > 6000 and "compress.py" not in str(data.get("tool_input", {}).get("command", "")):
    print("token-saver: that output was huge — pipe noisy commands through "
          "`python3 ~/.claude/skills/token-saver/scripts/compress.py` next time.", file=sys.stderr)
    sys.exit(2)  # stderr is shown to Claude
sys.exit(0)
