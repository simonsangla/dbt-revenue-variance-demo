#!/usr/bin/env bash
# Proof: dbt writes target/osi_document.json at parse time, but its datasets list is empty until revenue
# is modelled as a semantic model. Parses two clean git archives of this repo and compares them.
#   BEFORE = e039c63 (logic only in SQL models)   AFTER = f5ba575 (PR #7: semantic model + metric)
# Exit 0 only if BEFORE has no datasets and AFTER carries monthly_revenue and the revenue metric.
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel)"; DBT="${DBT:-dbt}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
osi(){ # osi <ref> <dir>: archive the ref, parse it, print "datasets=<names> metrics=<names>"
  mkdir -p "$W/$2"; git -C "$ROOT" archive "$1" | tar -x -C "$W/$2"
  (cd "$W/$2" && DBT_PROFILES_DIR=. $DBT parse --target-path "$W/$2/t" --no-partial-parse >/dev/null) || { echo "parse failed for $1"; exit 1; }
  python3 -c "import json,sys;s=json.load(open(sys.argv[1]))['semantic_model'][0];print('datasets=%s metrics=%s'%(','.join(d['name'] for d in s['datasets']),','.join(m['name'] for m in s.get('metrics',[]))))" "$W/$2/t/osi_document.json"
}
before=$(osi e039c63 before); after=$(osi f5ba575 after)
echo "BEFORE e039c63: $before"; echo "AFTER  f5ba575: $after"
[ "$before" = "datasets= metrics=" ] || { echo "FAIL: before is not empty"; exit 1; }
[ "$after" = "datasets=monthly_revenue metrics=revenue" ] || { echo "FAIL: after does not carry the semantic model and metric"; exit 1; }
echo "PASS: the OSI export only carries what is modelled"
