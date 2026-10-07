#!/usr/bin/env bash
# Proof: the `revenue` metric, queried through MetricFlow, must equal raw completed-order revenue from the seed.
# Tables-only tests cannot see a change inside the semantic layer YAML, so this one queries the metric itself.
# Builds HEAD twice (clean, and with the actual_revenue measure mutated from sum to max), runs `mf query
# --metrics revenue` on each, and compares to sum(quantity*unit_price) of completed orders read from
# seeds/orders.csv. Exit 0 only if clean matches and the mutation is detected as a mismatch.
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel)"; DBT="${DBT:-dbt}"
MF="${MF:-uvx --from dbt-metricflow[dbt-duckdb] mf}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
plain(){ sed 's/\x1b\[[0-9;]*m//g'; }
num(){ grep -Eo '^ *-?[0-9][0-9]*\.?[0-9]*' | tr -d ' ' | tail -1; }
metric(){ (cd "$W/$1" && export DBT_PROFILES_DIR=. && $DBT build >/dev/null 2>&1; $MF query --metrics revenue 2>&1 | plain | num); }
raw(){ (cd "$W/clean" && DBT_PROFILES_DIR=. $DBT show --inline "select round(sum(quantity*unit_price),2) as r from {{ ref('orders') }} where status = 'completed'" 2>&1 | plain | grep -E '^\| *[0-9]' | grep -Eo '[0-9][0-9,]*\.?[0-9]*' | head -1 | tr -d ,); }
for d in clean mutated; do mkdir -p "$W/$d"; git -C "$ROOT" archive HEAD | tar -x -C "$W/$d"; done
F=models/marts/_semantic_models.yml
awk '/- name: actual_revenue/{print; getline; sub(/agg: sum/,"agg: max")} {print}' "$W/clean/$F" > "$W/mutated/$F"
grep -A1 'name: actual_revenue' "$W/mutated/$F" | grep -q 'agg: max' || { echo "FAIL: mutation not applied"; exit 1; }
c=$(metric clean); m=$(metric mutated); r=$(raw)
echo "Raw completed-order revenue (seed): $r EUR"
echo "CLEAN   mf query revenue: $c"
echo "MUTATED mf query revenue (actual_revenue agg sum -> max): $m"
eq(){ awk -v a="$1" -v b="$2" 'BEGIN{d=a-b; if(d<0)d=-d; exit !(a!="" && b!="" && d<0.005)}'; }
eq "$c" "$r" || { echo "FAIL: clean metric does not match the raw orders (or MetricFlow did not run)"; exit 1; }
[ -n "$m" ] || { echo "FAIL: mutated metric returned nothing"; exit 1; }
eq "$m" "$r" && { echo "FAIL: the metric definition change went through silently"; exit 1; }
echo "PASS: the revenue metric matches the seed, and a one-word change in its measure is caught"
