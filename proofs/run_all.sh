#!/usr/bin/env bash
# Run every proofs/*/check.sh. Exit 1 if any proof no longer holds (a dbt upgrade can change a past result).
set -uo pipefail
cd "$(dirname "$0")"; fail=0
for c in */check.sh; do echo "== ${c%/check.sh}"; bash "$c" || fail=1; done
exit "$fail"
