#!/usr/bin/env bash
# Proof: an agent can check whether a question maps to a defined, tested metric before answering, and decline otherwise.
# Parses the dbt project (dbt parse -> semantic_manifest.json), collects every defined metric with the dimensions and
# entities of its semantic model, then maps a fixed question set onto them deterministically:
#   ANSWERABLE  the question names a defined metric AND every "by <x>" grouping is a dimension/entity of that metric;
#   DECLINE     otherwise (no metric, or a grouping the metric cannot be cut by) - the agent declines instead of sampling.
# Exit 0 only if the mapping runs and the controls hold (a defined-metric question answers, an undefined one declines).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"; DBT="${DBT:-uvx --with dbt-duckdb --from dbt-core dbt}"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
(cd "$ROOT" && DBT_PROFILES_DIR=. $DBT parse --target-path "$T" >"$T/parse.log" 2>&1) || { echo "FAIL: dbt parse"; tail -5 "$T/parse.log"; exit 1; }
[ -f "$T/semantic_manifest.json" ] || { echo "FAIL: no semantic_manifest.json"; exit 1; }
python3 - "$T/semantic_manifest.json" <<'PY'
import json, re, sys
sm = json.load(open(sys.argv[1]))
measure_model = {m["name"]: s for s in sm["semantic_models"] for m in s.get("measures", [])}
metrics = {}
for met in sm["metrics"]:
    meas = (met.get("type_params") or {}).get("measure") or {}
    s = measure_model.get(meas.get("name") if isinstance(meas, dict) else meas)
    cuts = set()
    if s:
        for d in s.get("dimensions", []) + s.get("entities", []):
            cuts.add(d["name"]); cuts.add(d["name"].split("_")[-1])
    words = {met["name"].lower()} | set(re.findall(r"[a-z]+", (met.get("label") or "").lower()))
    metrics[met["name"]] = (words, cuts)
print("Defined metrics: %d (%s)" % (len(metrics), ", ".join("%s cut by %s" % (k, "/".join(sorted(v[1]))) for k, v in sorted(metrics.items()))))
questions = ["total revenue", "revenue by month", "revenue by product", "revenue by region",
             "customer happiness score", "churn rate by month", "net promoter score"]
res = {}
for q in questions:
    toks = set(re.findall(r"[a-z]+", q.lower()))
    hit = [k for k, (w, _) in metrics.items() if w & toks]
    groups = re.findall(r"\bby ([a-z_]+)", q.lower())
    if not hit:
        v, why = "DECLINE", "no defined metric matches"
    else:
        bad = [g for g in groups if g not in metrics[hit[0]][1]]
        v, why = ("DECLINE", "%s has no dimension '%s'" % (hit[0], bad[0])) if bad else ("ANSWERABLE", "maps to metric %s" % hit[0])
    res[q] = v
    print("%-10s | %-26s | %s" % (v, q, why))
a = sum(v == "ANSWERABLE" for v in res.values()); d = len(res) - a
print("Questions: %d, answerable: %d, declined: %d" % (len(res), a, d))
if res["total revenue"] != "ANSWERABLE" or res["customer happiness score"] != "DECLINE" or not a or not d:
    print("FAIL: controls did not hold"); sys.exit(1)
print("PASS: every question is answered only through a defined metric; the rest are declined, none sampled")
PY
