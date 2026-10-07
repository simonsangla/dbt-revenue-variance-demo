#!/usr/bin/env bash
# Proof: dbt's semantic layer refuses to parse without a day-grain time spine model.
# Takes f5ba575 (semantic model + metric + metricflow_time_spine), deletes the time spine, and expects parse to
# fail with the time-spine error. Exit 0 only if the clean parse passes and the mutated parse fails that way.
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel)"; DBT="${DBT:-dbt}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
for d in clean mutated; do mkdir -p "$W/$d"; git -C "$ROOT" archive f5ba575 | tar -x -C "$W/$d"; done
mv "$W/mutated/models/marts/metricflow_time_spine.sql" "$W/spine.sql.removed"
python3 - "$W/mutated/models/marts/_semantic_models.yml" <<'PY'
import sys; p = sys.argv[1]; t = open(p).read(); i = t.find("\nmodels:")
open(p, "w").write(t[:i] + "\n" if i >= 0 else t)
PY
(cd "$W/clean" && DBT_PROFILES_DIR=. $DBT parse --target-path "$W/clean/t" --no-partial-parse >/dev/null 2>&1) || { echo "FAIL: clean parse failed"; exit 1; }
echo "CLEAN:   parse OK"
out=$(cd "$W/mutated" && DBT_PROFILES_DIR=. $DBT parse --target-path "$W/mutated/t" --no-partial-parse 2>&1); rc=$?
echo "MUTATED: parse exit $rc: $(printf '%s\n' "$out" | grep -o 'The semantic layer requires a time spine[^.]*' | head -1)"
[ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'requires a time spine' || { echo "FAIL: parse did not refuse"; exit 1; }
echo "PASS: no time spine, no semantic layer"
