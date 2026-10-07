#!/usr/bin/env bash
# Proof: a dashboard-style SQL query over the models (what dbt Charts runs: ref(), not the Semantic Layer)
# and the `revenue` metric (mf query) are two independent definitions; this check asserts they agree.
# Builds HEAD three times: clean, mutation A (chart SQL reads raw orders, status filter dropped) and
# mutation B (actual_revenue measure agg sum -> max). Clean must match; A and B must be detected.
# Records the plain `dbt build` PASS/ERROR line of each tree: build stays green under both mutations.
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel)"; DBT="${DBT:-dbt}"
MF="${MF:-uvx --from dbt-metricflow[dbt-duckdb] mf}"
P=proofs/2026-10-07-chart-vs-metric
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
plain(){ sed 's/\x1b\[[0-9;]*m//g'; }
num(){ grep -Eo '^ *-?[0-9][0-9]*\.?[0-9]*' | tr -d ' ' | tail -1; }
build(){ (cd "$W/$1" && DBT_PROFILES_DIR=. $DBT build 2>&1 | plain | grep -Eo 'PASS=[0-9]+ WARN=[0-9]+ ERROR=[0-9]+' | tail -1); }
metric(){ (cd "$W/$1" && DBT_PROFILES_DIR=. $MF query --metrics revenue 2>&1 | plain | num); }
chart(){ (cd "$W/$1" && DBT_PROFILES_DIR=. $DBT show --inline "$(grep -v '^ *--' "$P/chart.sql")" 2>&1 | plain | grep -E '^\| *[0-9]' | grep -Eo '[0-9][0-9,]*\.?[0-9]*' | head -1 | tr -d ,); }
for d in clean chartA metricB; do mkdir -p "$W/$d"; git -C "$ROOT" archive "${REF:-HEAD}" | tar -x -C "$W/$d"; done
sed "s/ref('fct_monthly_revenue')/ref('orders')/; s/sum(actual_revenue)/sum(quantity * unit_price)/" "$W/clean/$P/chart.sql" > "$W/chartA/$P/chart.sql"
grep -q "ref('orders')" "$W/chartA/$P/chart.sql" || { echo "FAIL: mutation A not applied"; exit 1; }
F=models/marts/_semantic_models.yml
awk '/- name: actual_revenue/{print; getline; sub(/agg: sum/,"agg: max")} {print}' "$W/clean/$F" > "$W/metricB/$F"
grep -A1 'name: actual_revenue' "$W/metricB/$F" | grep -q 'agg: max' || { echo "FAIL: mutation B not applied"; exit 1; }
eq(){ awk -v a="$1" -v b="$2" 'BEGIN{d=a-b; if(d<0)d=-d; exit !(a!="" && b!="" && d<0.005)}'; }
fail=0
for d in clean chartA metricB; do
  b=$(build "$d"); c=$(chart "$d"); m=$(metric "$d")
  echo "$d: dbt build [$b] | chart query: $c | mf query revenue: $m"
  [ -n "$c" ] && [ -n "$m" ] || { echo "FAIL: $d returned no number"; exit 1; }
  case "$b" in *ERROR=0) ;; *) echo "FAIL: plain dbt build not green on $d"; fail=1;; esac
  if [ "$d" = clean ]; then eq "$c" "$m" || { echo "FAIL: chart and metric disagree on the clean tree"; fail=1; }
  else eq "$c" "$m" && { echo "FAIL: $d drift went through silently"; fail=1; }; fi
done
[ "$fail" = 0 ] || exit 1
echo "PASS: chart query and revenue metric agree; drift on either side (A chart SQL, B metric agg) is caught while dbt build stays green"
