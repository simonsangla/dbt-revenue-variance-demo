#!/usr/bin/env bash
# Test: proofs/run_all.sh treats a PENDING proof as not-evidence.
#   1. a PENDING CLAIM.md that contains any digit fails the run (no number may be
#      published before it is proven);
#   2. a digit-free PENDING proof is reported with an explicit PENDING status and
#      does not fail the run;
#   3. asking run_all.sh to judge a PENDING proof by name is refused (exit 2),
#      even when its check.sh passes;
#   4. --strict refuses the whole run while any PENDING proof exists (exit 2).
# Runs against a scratch copy of proofs/run_all.sh with fake proofs (no dbt needed),
# then lints the real proofs/ tree. Exit 0 only if every case behaves.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
fail=0
mk(){ # mk NAME CHECK_EXIT CLAIM_TEXT [pending]
  mkdir -p "$W/p/$1"
  printf '#!/usr/bin/env bash\nexit %s\n' "$2" > "$W/p/$1/check.sh"
  printf '%s\n' "$3" > "$W/p/$1/CLAIM.md"
  [ "${4:-}" = pending ] && echo stub > "$W/p/$1/PENDING"
  return 0
}
expect(){ # expect LABEL WANT_EXIT GOT_EXIT
  if [ "$2" = "$3" ]; then echo "ok   $1 (exit $3)"; else echo "FAIL $1: want exit $2, got $3"; fail=1; fi
}
reset(){ rm -rf "$W/p"; mkdir -p "$W/p"; cp "$ROOT/proofs/run_all.sh" "$W/p/run_all.sh"; mk bound 0 "Binding claim: 42 rows"; }

reset; mk pend 1 "Claim with a number: 15% off" pending
bash "$W/p/run_all.sh" >"$W/out" 2>&1; expect "PENDING claim with digits fails the run" 1 $?

reset; mk pend 1 "Claim without numbers" pending
bash "$W/p/run_all.sh" >"$W/out" 2>&1; rc=$?
expect "digit-free PENDING proof does not fail the run" 0 $rc
grep -q '^PENDING pend' "$W/out" || { echo "FAIL explicit PENDING status line missing"; fail=1; }

reset; mk pend 0 "Claim without numbers" pending
bash "$W/p/run_all.sh" pend >"$W/out" 2>&1; expect "judging a PENDING proof by name is refused" 2 $?
bash "$W/p/run_all.sh" bound >"$W/out" 2>&1; expect "judging a binding proof by name still works" 0 $?
bash "$W/p/run_all.sh" --strict >"$W/out" 2>&1; expect "--strict refuses while a PENDING proof exists" 2 $?

reset
bash "$W/p/run_all.sh" --strict >"$W/out" 2>&1; expect "--strict passes with no PENDING proof" 0 $?

# The real tree: every PENDING CLAIM.md is digit-free.
for p in "$ROOT"/proofs/*/PENDING; do
  [ -e "$p" ] || continue
  c="$(dirname "$p")/CLAIM.md"
  if grep -n '[0-9]' "$c"; then echo "FAIL ${c#$ROOT/} is PENDING but contains digits (above)"; fail=1
  else echo "ok   ${c#$ROOT/} is PENDING and digit-free"; fi
done
[ "$fail" = 0 ] && echo "PASS: PENDING proofs are never counted as evidence" || echo "FAIL: see above"
exit "$fail"
