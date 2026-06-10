#!/usr/bin/env python3
"""toon.py — JSON <-> TOON (Token-Oriented Object Notation), tabular subset.
Saves ~40% tokens, but ONLY for flat uniform arrays of objects. Refuses anything else.
Usage:
  toon.py encode FILE.json   (or stdin)
  toon.py decode FILE.toon   (or stdin)
"""
import json
import sys
from pathlib import Path


def is_scalar(v):
    return v is None or isinstance(v, (str, int, float, bool))


def looks_typed(s):
    """String that would decode as something else (number/bool/null) must be quoted."""
    if s in ("", "true", "false"):
        return True
    for t in (int, float):
        try:
            t(s)
            return True
        except ValueError:
            pass
    return False


def fmt(v):
    if v is None:
        return ""
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return str(v)
    s = str(v)
    if any(c in s for c in ',"\n') or s != s.strip() or looks_typed(s):
        return json.dumps(s, ensure_ascii=False)
    return s


def encode_array(name, arr):
    if not arr or not all(isinstance(x, dict) for x in arr):
        sys.exit("refused: not an array of objects — keep this as JSON")
    keys = list(arr[0].keys())
    for x in arr:
        if list(x.keys()) != keys:
            sys.exit("refused: non-uniform objects (different keys) — keep this as JSON")
        if not all(is_scalar(v) for v in x.values()):
            sys.exit("refused: nested values — TOON only helps flat tabular data, keep JSON")
    lines = [f"{name}[{len(arr)}]{{{','.join(keys)}}}:"]
    lines += ["  " + ",".join(fmt(x[k]) for k in keys) for x in arr]
    return "\n".join(lines)


def encode(text):
    data = json.loads(text)
    if isinstance(data, list):
        return encode_array("items", data)
    if isinstance(data, dict) and len(data) == 1 and isinstance(next(iter(data.values())), list):
        k = next(iter(data))
        return encode_array(k, data[k])
    sys.exit("refused: input must be an array (or {key: array}) of flat uniform objects")


def parse_val(s):
    s = s.strip()
    if s == "":
        return None
    if s.startswith('"'):
        return json.loads(s)
    if s in ("true", "false"):
        return s == "true"
    for t in (int, float):
        try:
            return t(s)
        except ValueError:
            pass
    return s


def split_row(row):
    out, cur, q = [], "", False
    i = 0
    while i < len(row):
        c = row[i]
        if q and c == "\\" and i + 1 < len(row):
            cur += c + row[i + 1]  # escaped char inside quotes (e.g. \")
            i += 2
            continue
        if c == '"':
            q = not q
            cur += c
        elif c == "," and not q:
            out.append(cur)
            cur = ""
        else:
            cur += c
        i += 1
    out.append(cur)
    return out


def decode(text):
    lines = [ln for ln in text.splitlines() if ln.strip()]
    head = lines[0]
    name = head.split("[")[0]
    keys = head[head.index("{") + 1:head.index("}")].split(",")
    rows = [dict(zip(keys, map(parse_val, split_row(ln.strip())))) for ln in lines[1:]]
    return json.dumps(rows if name == "items" else {name: rows}, ensure_ascii=False, indent=1)


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in ("encode", "decode"):
        sys.exit(__doc__)
    text = Path(sys.argv[2]).read_text() if len(sys.argv) > 2 else sys.stdin.read()
    print(encode(text) if sys.argv[1] == "encode" else decode(text))


if __name__ == "__main__":
    main()
