#!/usr/bin/env bash
# Proof: a changed revenue definition must break the build visibly, not quietly change the answer downstream.
# Takes f5ba575, counts refunded orders as revenue (one line in stg_orders), runs dbt build, and expects the
# known-answer test assert_variance_bridge_reconciles to FAIL. Exit 0 only if the clean build passes and the
# mutated build fails on that test.
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel)"; DBT="${DBT:-dbt}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
plain(){ sed 's/\x1b\[[0-9;]*m//g'; }
build(){ (cd "$W/$1" && DBT_PROFILES_DIR=. $DBT build --target-path "$W/$1/t" 2>&1 | plain); }
total(){ (cd "$W/$1" && DBT_PROFILES_DIR=. $DBT show --target-path "$W/$1/t" --inline "select sum(revenue) as r from {{ ref('stg_orders') }}" 2>&1 | plain | grep -E '^\| *[0-9]' | grep -Eo '[0-9][0-9,]*\.?[0-9]*' | head -1); }
for d in clean mutated; do mkdir -p "$W/$d"; git -C "$ROOT" archive f5ba575 | tar -x -C "$W/$d"; done
sed -i.bak "s/where status = 'completed'/where status in ('completed', 'refunded')/" "$W/mutated/models/staging/stg_orders.sql"
grep -q "status in ('completed', 'refunded')" "$W/mutated/models/staging/stg_orders.sql" || { echo "FAIL: mutation not applied"; exit 1; }
clean=$(build clean); mut=$(build mutated)
echo "Change: one line in stg_orders, refunded orders now count as revenue"
echo "Revenue: $(total clean) -> $(total mutated) EUR"
echo "CLEAN:   $(printf '%s\n' "$clean" | grep -o 'Done\..*' | tail -1)"
echo "MUTATED: $(printf '%s\n' "$mut" | grep -o 'Done\..*' | tail -1)"
printf '%s\n' "$mut" | grep -Eo 'FAIL [0-9]+ assert_[a-z_]+' | sed 's/^/  /'
printf '%s\n' "$clean" | grep -q 'ERROR=0' || { echo "FAIL: clean build is not green"; exit 1; }
printf '%s\n' "$mut" | grep -Eq 'FAIL [0-9]+ assert_variance_bridge_reconciles' || { echo "FAIL: the definition change went through silently"; exit 1; }
echo "PASS: counting refunds as revenue turns the build red on the known-answer tests"
