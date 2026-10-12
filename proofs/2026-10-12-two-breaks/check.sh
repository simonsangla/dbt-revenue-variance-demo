#!/usr/bin/env bash
# Proof: two one-line breaks, two different detectors. On copies of HEAD (git archive):
# Break 1 counts refunded orders as revenue in stg_orders -> dbt build must go red (table tests see it).
# Break 2 changes the actual_revenue measure from sum to max -> dbt build stays green, but the MetricFlow
# revenue metric no longer matches the seed. Prints every number and a final NUMBERS line.
# Exit 0 only if break 1 is red, break 2 is green on build and red on the metric check.
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel)"; DBT="${DBT:-dbt}"
MF="${MF:-uvx --from dbt-metricflow[dbt-duckdb] mf}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
plain(){ sed 's/\x1b\[[0-9;]*m//g'; }
build(){ (cd "$W/$1" && DBT_PROFILES_DIR=. $DBT build 2>&1 | plain); }
total(){ (cd "$W/$1" && DBT_PROFILES_DIR=. $DBT show --inline "select sum(revenue) as r from {{ ref('stg_orders') }}" 2>&1 | plain | grep -E '^\| *[0-9]' | grep -Eo '[0-9][0-9,]*\.?[0-9]*' | head -1 | tr -d ,); }
metric(){ (cd "$W/$1" && DBT_PROFILES_DIR=. $MF query --metrics revenue 2>&1 | plain | grep -Eo '^ *-?[0-9][0-9]*\.?[0-9]*' | tr -d ' ' | tail -1); }
cnt(){ printf '%s\n' "$1" | grep -Eo "$2=[0-9]+" | tail -1 | cut -d= -f2; }
fmt(){ awk -v n="$1" 'BEGIN{s=sprintf("%.2f",n); i=substr(s,1,length(s)-3); d=substr(s,length(s)-2); o=""; while(length(i)>3){o=","substr(i,length(i)-2)o; i=substr(i,1,length(i)-3)} print i o d}'; }
same(){ awk -v a="$1" -v b="$2" 'BEGIN{d=a-b; if(d<0)d=-d; exit !(a!="" && b!="" && d<0.005)}'; }
for d in clean b1 b2; do mkdir -p "$W/$d"; git -C "$ROOT" archive HEAD | tar -x -C "$W/$d"; done
S=models/staging/stg_orders.sql
sed "s/where status = 'completed'/where status in ('completed', 'refunded')/" "$W/clean/$S" > "$W/b1/$S"
grep -q "status in ('completed', 'refunded')" "$W/b1/$S" || { echo "FAIL: break 1 not applied"; exit 1; }
F=models/marts/_semantic_models.yml
awk '/- name: actual_revenue/{print; getline; sub(/agg: sum/,"agg: max")} {print}' "$W/clean/$F" > "$W/b2/$F"
grep -A1 'name: actual_revenue' "$W/b2/$F" | grep -q 'agg: max' || { echo "FAIL: break 2 not applied"; exit 1; }
oc=$(build clean); o1=$(build b1); o2=$(build b2)
rc=$(total clean); r1=$(total b1); mc=$(metric clean); m2=$(metric b2)
pct=$(awk -v a="$rc" -v b="$r1" 'BEGIN{printf "%.0f", (b-a)/a*100}')
e1=$(cnt "$o1" ERROR); p2=$(cnt "$o2" PASS); e2=$(cnt "$o2" ERROR)
echo "CLEAN build: $(printf '%s\n' "$oc" | grep -o 'Done\..*' | tail -1)"
echo "CLEAN metric check: MetricFlow revenue $mc vs seed $rc"
echo "BREAK 1 (stg_orders counts refunded orders): revenue $rc -> $r1 EUR (+${pct}%)"
echo "  build: $(printf '%s\n' "$o1" | grep -o 'Done\..*' | tail -1)"
printf '%s\n' "$o1" | grep -Eo 'FAIL [0-9]+ [a-z_0-9]{3,}' | sort -u | sed 's/^/  /'
echo "BREAK 2 (actual_revenue agg sum -> max):"
echo "  build: $(printf '%s\n' "$o2" | grep -o 'Done\..*' | tail -1)"
if same "$m2" "$rc"; then v=PASS; else v=FAIL; fi
echo "  metric check: MetricFlow revenue $m2 vs seed $rc -> $v"
fail=0
printf '%s\n' "$oc" | grep -q 'ERROR=0' || { echo "FAIL: clean build is not green"; fail=1; }
same "$mc" "$rc" || { echo "FAIL: clean metric does not match the seed (or MetricFlow did not run)"; fail=1; }
[ "${e1:-0}" -gt 0 ] || { echo "FAIL: break 1 went through a green build"; fail=1; }
[ "${e2:-x}" = 0 ] || { echo "FAIL: break 2 build is not green"; fail=1; }
{ [ -n "$m2" ] && ! same "$m2" "$rc"; } || { echo "FAIL: break 2 not caught by the metric check"; fail=1; }
[ "$fail" = 0 ] || exit 1
echo "NUMBERS: $(fmt "$rc") $(fmt "$r1") ${pct}% $e1 $p2 $e2 $(fmt "$m2")"
echo "PASS: break 1 turns the build red; break 2 passes the build and is caught only by the metric check"
