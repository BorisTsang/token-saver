#!/usr/bin/env python3
"""SessionStart hook: stdout from this hook IS injected into Claude's context.
Re-loads project memory after every startup/resume/compaction so goals survive."""
import os
import sys

p = "NOTES.md"
if os.path.exists(p):
    head = open(p, encoding="utf-8", errors="replace").read().splitlines()[:25]
    print("token-saver — project memory (NOTES.md, head):")
    print("\n".join(head))
    print("(facts/decisions go to NOTES.md, rules to CLAUDE.md; checkpoint goal/done/in-flight/next at milestones)")
sys.exit(0)
