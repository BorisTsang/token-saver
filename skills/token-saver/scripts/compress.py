#!/usr/bin/env python3
"""compress.py — shrink logs/JSON/code before they enter Claude's context.
Usage:
  cmd | compress.py                    auto-detect mode from content
  compress.py FILE [--mode log|json|code]
  compress.py --restore HASH           print stored original
Original is always saved to ~/.claude/tc-cache/<hash>.orig (recoverable).
"""
import ast
import hashlib
import json
import re
import sys
import time
from pathlib import Path

CACHE = Path.home() / ".claude" / "tc-cache"
HEAD, TAIL, MAX_STR, MAX_ARR = 25, 15, 200, 10
KEEP_RE = re.compile(r"error|warn|fatal|fail|exception|traceback|panic", re.I)


def est(s):
    return len(s) // 4


def save_original(text):
    h = hashlib.sha256(text.encode()).hexdigest()[:12]
    try:
        CACHE.mkdir(parents=True, exist_ok=True)
        CACHE.chmod(0o700)
        cutoff = time.time() - 7 * 86400  # originals may hold secrets — auto-prune after 7 days
        for old in CACHE.glob("*.orig"):
            if old.stat().st_mtime < cutoff:
                old.unlink(missing_ok=True)
        p = CACHE / f"{h}.orig"
        if not p.exists():
            p.write_text(text)
            p.chmod(0o600)
    except OSError:
        return None  # cache unavailable — still compress, just not restorable
    return h


def compress_log(text):
    lines = text.splitlines()
    out, prev, count = [], None, 0

    def flush():
        nonlocal prev, count
        if prev is not None:
            out.append(prev if count == 1 else f"{prev}  [x{count}]")
        prev, count = None, 0

    for ln in lines:
        if ln == prev:
            count += 1
        else:
            flush()
            prev, count = ln, 1
    flush()

    if len(out) <= HEAD + TAIL:
        return "\n".join(out)
    keep = set(range(HEAD)) | set(range(len(out) - TAIL, len(out)))
    keep |= {i for i, ln in enumerate(out) if KEEP_RE.search(ln)}
    res, last = [], -1
    for i in sorted(keep):
        if i > last + 1:
            res.append(f"  ... [{i - last - 1} lines omitted] ...")
        res.append(out[i])
        last = i
    return "\n".join(res)


def shrink_json(v):
    if isinstance(v, dict):
        return {k: shrink_json(x) for k, x in v.items()
                if x not in (None, "", [], {})}
    if isinstance(v, list):
        if len(v) > MAX_ARR:
            return ([shrink_json(x) for x in v[:5]]
                    + [f"... {len(v) - 8} items omitted ..."]
                    + [shrink_json(x) for x in v[-3:]])
        return [shrink_json(x) for x in v]
    if isinstance(v, str) and len(v) > MAX_STR:
        return v[:MAX_STR] + f"...[{len(v) - MAX_STR} chars cut]"
    return v


def compress_json(text):
    return json.dumps(shrink_json(json.loads(text)), separators=(",", ":"), ensure_ascii=False)


def compress_code(text):
    # Python: AST skeleton (signatures + docstrings, bodies elided)
    try:
        tree = ast.parse(text)
    except SyntaxError:
        # JS/TS/Go/other: keep signature-ish lines
        sig = re.compile(r"^\s*(import |export |from |func |fn |class |interface |type |def |const \w+ = |function |public |private )")
        return "\n".join(ln for ln in text.splitlines() if sig.match(ln)) or compress_log(text)
    out = []
    for node in tree.body:
        if isinstance(node, (ast.Import, ast.ImportFrom)):
            out.append(ast.get_source_segment(text, node) or "")
        elif isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            out.extend(skeleton(node, text, 0))
        elif isinstance(node, ast.Assign):
            out.append((ast.get_source_segment(text, node) or "")[:120])
    return "\n".join(out)


def skeleton(node, src, depth):
    ind = "    " * depth
    head = (ast.get_source_segment(src, node) or "").splitlines()[0]
    lines = [ind + head]
    doc = ast.get_docstring(node)
    if doc:
        lines.append(f'{ind}    """{doc.splitlines()[0]}"""')
    if isinstance(node, ast.ClassDef):
        for sub in node.body:
            if isinstance(sub, (ast.FunctionDef, ast.AsyncFunctionDef)):
                lines.extend(skeleton(sub, src, depth + 1))
    else:
        lines.append(ind + "    ...")
    return lines


def detect(text, name=""):
    if name.endswith((".py", ".js", ".ts", ".tsx", ".go", ".rs")):
        return "code"
    s = text.lstrip()
    if s.startswith(("{", "[")):
        try:
            json.loads(text)
            return "json"
        except Exception:
            pass
    # piped Python source (no filename) should still skeletonize, not log-compress
    if re.search(r"^(def |class |import |from \w+ import )", text, re.M):
        try:
            ast.parse(text)
            return "code"
        except SyntaxError:
            pass
    return "log"


def main():
    args = sys.argv[1:]
    if args and args[0] == "--restore":
        if len(args) < 2:
            sys.exit("usage: compress.py --restore HASH")
        p = CACHE / f"{args[1]}.orig"
        sys.stdout.write(p.read_text() if p.exists() else f"no cached original {args[1]}\n")
        return
    mode = None
    if "--mode" in args:
        i = args.index("--mode")
        mode = args[i + 1]
        del args[i:i + 2]
    if args:
        text = Path(args[0]).read_text(errors="replace")
        mode = mode or detect(text, args[0])
    else:
        text = sys.stdin.read()
        mode = mode or detect(text)
    if not text.strip():
        return
    out = {"log": compress_log, "json": compress_json, "code": compress_code}[mode](text)
    if est(out) >= est(text):
        print(text)  # compression didn't help; pass through without caching
        return
    h = save_original(text)  # only cache when we actually compressed
    print(out)
    tail = f"full: compress.py --restore {h}" if h else "original not cached"
    note = {"json": " | nulls/empties dropped, long strings truncated, big arrays sampled",
            "code": " | bodies elided, signatures kept", "log": ""}[mode]
    print(f"\n[compressed {mode}: ~{est(text)}→~{est(out)} tok{note} | {tail}]")


if __name__ == "__main__":
    main()
