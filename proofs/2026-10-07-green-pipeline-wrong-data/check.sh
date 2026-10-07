#!/usr/bin/env bash
# Proof: a green pipeline can still carry wrong data. Three seed-level failures replayed on copies of HEAD
# (git archive): 1 duplicated order lines, 2 refunded lines relabelled completed (returns no longer excluded),
# 3 a whole month of orders missing. Each tree gets `dbt build`; records build summary, failing tests and
# completed revenue. Exit 0 only if the clean build is green and every mutation turns the build red.
# REF=<rev> checks another commit than HEAD (e.g. REF=29349b7 shows what the tests caught before this proof).
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel)"; DBT="${DBT:-dbt}"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
plain(){ sed 's/\x1b\[[0-9;]*m//g'; }
build(){ (cd "$W/$1" && DBT_PROFILES_DIR=. $DBT build --target-path "$W/$1/t" 2>&1 | plain); }
total(){ (cd "$W/$1" && DBT_PROFILES_DIR=. $DBT show --target-path "$W/$1/t" --inline "select sum(revenue) as r from {{ ref('stg_orders') }}" 2>&1 | plain | grep -E '^\| *[0-9]' | grep -Eo '[0-9][0-9,]*\.?[0-9]*' | head -1); }
for d in clean dup refunds month; do mkdir -p "$W/$d"; git -C "$ROOT" archive "${REF:-HEAD}" | tar -x -C "$W/$d"; done
S=seeds/orders.csv
{ cat "$W/clean/$S"; grep ',completed$' "$W/clean/$S" | head -5; } > "$W/dup/$S"
sed 's/,refunded$/,completed/' "$W/clean/$S" > "$W/refunds/$S"
grep -v ',2026-03-' "$W/clean/$S" > "$W/month/$S"
[ "$(wc -l < "$W/dup/$S")" -gt "$(wc -l < "$W/clean/$S")" ] || { echo "FAIL: mutation 1 not applied"; exit 1; }
grep -q ',refunded$' "$W/refunds/$S" && { echo "FAIL: mutation 2 not applied"; exit 1; }
grep -q ',2026-03-' "$W/month/$S" && { echo "FAIL: mutation 3 not applied"; exit 1; }
fail=0
for d in clean dup refunds month; do
  out=$(build "$d")
  echo "$d: revenue $(total "$d") EUR | $(printf '%s\n' "$out" | grep -Eo 'PASS=[0-9]+ WARN=[0-9]+ ERROR=[0-9]+' | tail -1)"
  printf '%s\n' "$out" | grep -Eo 'FAIL [0-9]+ [a-z_0-9]{3,}' | sort -u | sed 's/^/  /'
  if [ "$d" = clean ]; then printf '%s\n' "$out" | grep -q 'ERROR=0' || { echo "FAIL: clean build is not green"; fail=1; }
  else printf '%s\n' "$out" | grep -q 'ERROR=0' && { echo "FAIL: $d went through a green build"; fail=1; }; fi
done
[ "$fail" = 0 ] || exit 1
echo "PASS: duplicated lines, returns counted as revenue and a missing month each turn the build red"
