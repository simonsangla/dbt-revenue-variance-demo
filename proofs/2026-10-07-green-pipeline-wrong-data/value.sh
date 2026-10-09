#!/usr/bin/env bash
# Read-only value check: each cited number (args) must be a line of the stored check.sh output ($PROOF_OUT).
set -uo pipefail
[ -n "${PROOF_OUT:-}" ] && [ -f "$PROOF_OUT" ] || { echo "FAIL: PROOF_OUT missing"; exit 1; }
[ "$#" -gt 0 ] || { echo "FAIL: no numbers given"; exit 1; }
rc=0
for n in "$@"; do
  line=$(grep -F -- "$n" "$PROOF_OUT" | grep -v '^\$' | head -1)
  if [ -n "$line" ]; then echo "$n: $line"; else echo "FAIL: $n not in proof output"; rc=1; fi
done
exit "$rc"
