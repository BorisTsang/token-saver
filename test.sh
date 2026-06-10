#!/usr/bin/env bash
# token-saver test suite — run from repo root: bash test.sh
set -u
S="skills/token-saver/scripts"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
pass=0; fail=0
ok()  { echo "PASS $1"; pass=$((pass+1)); }
bad() { echo "FAIL $1"; fail=$((fail+1)); }

# --- compress.py ---
{ for i in $(seq 1 80); do echo "INFO same"; done; echo "ERROR boom"; } > "$T/a.log"
python3 $S/compress.py "$T/a.log" | grep -q "ERROR boom" && ok "log keeps errors" || bad "log keeps errors"

H=$(python3 $S/compress.py "$T/a.log" | grep -oP 'restore \K\w+')
python3 $S/compress.py --restore "$H" | cmp -s - "$T/a.log" && ok "restore byte-identical" || bad "restore byte-identical"

python3 $S/compress.py --restore 2>/dev/null && bad "restore no-arg exits cleanly" || ok "restore no-arg exits cleanly"

python3 -c 'import json;print(json.dumps([{"i":i,"s":"x"*300} for i in range(40)]))' > "$T/b.json"
python3 $S/compress.py "$T/b.json" | grep -q "compressed json" && ok "json compresses" || bad "json compresses"

printf 'class A:\n    def f(self):\n        return 1\n' | python3 $S/compress.py | grep -q "compressed code" \
  && ok "stdin python detected as code" || bad "stdin python detected as code"

echo -n "" | python3 $S/compress.py && ok "empty input no crash" || bad "empty input no crash"

echo "short" | python3 $S/compress.py | grep -qx "short" && ok "uncompressible passes through" || bad "uncompressible passes through"

# --- toon.py ---
python3 - <<'EOF' > "$T/nasty.json"
import json
print(json.dumps([
 {"id":"007","msg":'say "hi"',"n":9.5,"flag":True,"note":None},
 {"id":"12.0","msg":"a,b,c","n":-3,"flag":False,"note":"true"},
 {"msg":"reordered keys","id":"x","note":" sp ","n":0,"flag":True},
], ensure_ascii=False))
EOF
python3 $S/toon.py encode "$T/nasty.json" > "$T/n.toon" \
  && python3 $S/toon.py decode "$T/n.toon" | python3 -c "
import json,sys
a=json.load(sys.stdin); b=json.load(open('$T/nasty.json'))
assert all(dict(x)==dict(y) for x,y in zip(a,b)), (a,b)" \
  && ok "toon torture round-trip (incl. reordered keys)" || bad "toon torture round-trip"

echo '[{"a":{"n":1}}]' | python3 $S/toon.py encode 2>/dev/null && bad "toon refuses nested" || ok "toon refuses nested"
echo '[{"a":1},{"b":2}]' | python3 $S/toon.py encode 2>/dev/null && bad "toon refuses different keys" || ok "toon refuses different keys"

# --- hooks ---
python3 -c 'import json;print(json.dumps({"tool_name":"Bash","tool_input":{"command":"ls"},"tool_response":{"stdout":"y"*7000}}))' \
  | python3 $S/big-output-check.py 2>/dev/null
[ $? -eq 2 ] && ok "big-output hook triggers" || bad "big-output hook triggers"

echo '{"tool_name":"Bash","tool_input":{"command":"ls"},"tool_response":{"stdout":"hi"}}' \
  | python3 $S/big-output-check.py && ok "big-output hook quiet on small" || bad "big-output hook quiet on small"

cd "$T" && printf '# NOTES\n- goal: test\n' > NOTES.md
python3 "$OLDPWD/$S/session-start.py" | grep -q "goal: test" && ok "session-start injects NOTES.md" || bad "session-start injects NOTES.md"
rm NOTES.md
python3 "$OLDPWD/$S/session-start.py" | grep -q . && bad "session-start silent without NOTES.md" || ok "session-start silent without NOTES.md"
cd "$OLDPWD"

# --- installer (sandboxed HOME, twice for idempotency) ---
FH=$(mktemp -d)
HOME="$FH" bash install.sh >/dev/null 2>&1 && HOME="$FH" bash install.sh >/dev/null 2>&1 \
  && python3 -m json.tool "$FH/.claude/settings.json" >/dev/null \
  && [ "$(ls "$FH/.claude/agents" | wc -l)" -eq 5 ] \
  && ok "installer idempotent + valid settings" || bad "installer idempotent + valid settings"
HOME="$FH" bash uninstall.sh >/dev/null 2>&1 \
  && [ ! -d "$FH/.claude/skills/token-saver" ] && [ "$(ls "$FH/.claude/agents" 2>/dev/null | wc -l)" -eq 0 ] \
  && ok "uninstaller cleans up" || bad "uninstaller cleans up"
rm -rf "$FH"

echo; echo "passed=$pass failed=$fail"
[ $fail -eq 0 ]
