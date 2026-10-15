#!/usr/bin/env bash
# Run every proofs/*/check.sh. Exit 1 if any proof no longer holds (a dbt upgrade can change a past result).
# A folder with a PENDING file is a promoted claim not yet proven (mission-os#1635): its check runs and is
# reported, but does not fail the run. Delete PENDING once check.sh is real; from then on it is binding.
set -uo pipefail
cd "$(dirname "$0")"; fail=0
for c in */check.sh; do
  d="${c%/check.sh}"; echo "== $d"
  if [ -f "$d/PENDING" ]; then
    bash "$c" && echo "PENDING $d: check passes; delete PENDING to make it binding" || echo "PENDING $d: not yet proven (not counted)"
  else
    bash "$c" || fail=1
  fi
done
exit "$fail"
