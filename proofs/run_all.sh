#!/usr/bin/env bash
# Run every proofs/*/check.sh. Exit 1 if any proof no longer holds (a dbt upgrade can change a past result).
# A folder with a PENDING file is a promoted claim not yet proven (mission-os#1635). It is never evidence:
#   - its check runs and is reported with an explicit "PENDING" status, but does not decide the run;
#   - its CLAIM.md must contain no digits (no number is published before it is proven), else the run fails;
#   - `run_all.sh <proof-dir>` judges one proof and REFUSES a PENDING one (exit 2), even if its check passes;
#   - `run_all.sh --strict` refuses the whole run (exit 2) while any PENDING proof exists.
# Delete PENDING once check.sh is real; from then on the proof is binding.
# Tested by scripts/test_pending_claims.sh.
set -uo pipefail
cd "$(dirname "$0")"
strict=0; only=""
for a in "$@"; do
  case "$a" in
    --strict) strict=1 ;;
    -*) echo "usage: run_all.sh [--strict] [PROOF_DIR]" >&2; exit 64 ;;
    *) only="${a%/}"; only="${only#proofs/}" ;;
  esac
done
if [ -n "$only" ]; then
  [ -f "$only/check.sh" ] || { echo "no such proof: $only" >&2; exit 64; }
  if [ -f "$only/PENDING" ]; then echo "PENDING $only: refused, not a proof until PENDING is removed"; exit 2; fi
  echo "== $only"; bash "$only/check.sh"; exit $?
fi
fail=0; pending=""
for c in */check.sh; do
  d="${c%/check.sh}"; echo "== $d"
  if [ -f "$d/PENDING" ]; then
    pending="$pending $d"
    if grep -q '[0-9]' "$d/CLAIM.md" 2>/dev/null; then
      echo "FAIL $d: PENDING CLAIM.md contains digits; no number before the proof exists"; fail=1
    fi
    if bash "$c"; then echo "PENDING $d: check passes, still not counted; delete PENDING to make it binding"
    else echo "PENDING $d: not yet proven, not counted"; fi
  else
    bash "$c" || fail=1
  fi
done
[ -n "$pending" ] && echo "STATUS: PENDING (not evidence):$pending"
[ "$fail" = 0 ] || exit 1
[ "$strict" = 1 ] && [ -n "$pending" ] && { echo "STRICT: refused, PENDING proofs present"; exit 2; }
exit 0
