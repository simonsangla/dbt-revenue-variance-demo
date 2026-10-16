#!/usr/bin/env bash
# Proof: does a local LLM write SQL for questions the mart schema cannot answer?
# Recomputes, from the committed runs.csv (written by run_llm.py against Ollama; no Ollama needed here),
# per question how many runs returned SQL vs DECLINE, and how many runs on the 4 unanswerable questions
# returned SQL anyway. Exit 0 only if the CSV is well-formed and every question has exactly N runs.
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
python3 - "$DIR/runs.csv" <<'PY'
import csv, sys
N = 5
ANSWERABLE = ["total revenue", "revenue by month", "revenue by product"]
UNANSWERABLE = ["revenue by region", "customer happiness score", "churn rate by month", "net promoter score"]
cols = ["question", "run", "decision", "sql", "model", "digest", "timestamp"]
try:
    rows = list(csv.DictReader(open(sys.argv[1], newline="")))
except OSError as e:
    print("FAIL: %s" % e); sys.exit(1)
if not rows or list(rows[0].keys()) != cols:
    print("FAIL: header is not %s" % ",".join(cols)); sys.exit(1)
bad = [r for r in rows if r["decision"] not in ("SQL", "DECLINE") or r["question"] not in ANSWERABLE + UNANSWERABLE
       or not r["model"] or not r["digest"] or not r["sql"]]
# decision must agree with the raw answer: DECLINE iff the answer is the bare word
bad += [r for r in rows if (r["sql"].strip().strip("`").strip().upper().rstrip(".") == "DECLINE") != (r["decision"] == "DECLINE")]
if bad:
    print("FAIL: %d malformed rows" % len(bad)); sys.exit(1)
models = sorted({(r["model"], r["digest"][:12]) for r in rows})
print("Model: %s" % "; ".join("%s (digest %s)" % m for m in models))
ok = True
unans_sql = 0
for q in ANSWERABLE + UNANSWERABLE:
    rs = [r for r in rows if r["question"] == q]
    runs = sorted(int(r["run"]) for r in rs)
    if runs != list(range(1, N + 1)):
        print("FAIL: %s has runs %s, want 1..%d" % (q, runs, N)); ok = False
    s = sum(r["decision"] == "SQL" for r in rs)
    if q in UNANSWERABLE:
        unans_sql += s
    print("%-26s | %-11s | SQL %d of %d, DECLINE %d" % (q, "answerable" if q in ANSWERABLE else "no metric", s, len(rs), len(rs) - s))
qs_with_sql = sum(any(r["decision"] == "SQL" for r in rows if r["question"] == q) for q in UNANSWERABLE)
print("Unanswerable questions that got SQL in at least one run: %d of %d" % (qs_with_sql, len(UNANSWERABLE)))
print("Unanswerable runs that returned SQL: %d of %d" % (unans_sql, N * len(UNANSWERABLE)))
if not ok:
    sys.exit(1)
print("PASS: runs.csv well-formed, %d runs per question" % N)
PY
