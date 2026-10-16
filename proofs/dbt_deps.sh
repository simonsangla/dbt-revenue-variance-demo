#!/usr/bin/env bash
# dbt wrapper for proofs: an exported tree (git archive) carries packages.yml but never
# dbt_packages/, so run `dbt deps` once in it before the real command. Set by run_all.sh.
set -uo pipefail
real="${DBT_REAL:-dbt}"
if [ -f packages.yml ] && [ ! -d dbt_packages ]; then
  $real deps >/dev/null 2>&1 || { echo "dbt deps failed in $PWD" >&2; exit 1; }
fi
exec $real "$@"
