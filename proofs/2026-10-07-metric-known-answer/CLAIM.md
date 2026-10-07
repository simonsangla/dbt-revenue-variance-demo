# The revenue metric must match the raw orders (2026-10-07)

**Claim discussed (paraphrased):** tests that read tables cannot see a change made inside the semantic layer;
a metric defined in YAML needs its own known-answer test, queried through the semantic layer itself.

**What I tested:** `mf query --metrics revenue` (MetricFlow on DuckDB) against `sum(quantity * unit_price)` of
completed orders in `seeds/orders.csv`, then the same with one word changed in the `actual_revenue` measure
(`agg: sum` -> `agg: max`).

| | `revenue` via MetricFlow | Raw seed | Result |
|---|---|---|---|
| Clean (HEAD) | 53,546.30 EUR | 53,546.30 EUR | match |
| `agg: sum` -> `agg: max` | 9,550.90 EUR | 53,546.30 EUR | mismatch, proof FAILS |

Note: `dbt build` stays green on the mutated measure (no table test reads the semantic layer); only this check catches it.

**Result:** holds. A change to the metric definition no longer passes silently.

**Run it:** `bash proofs/2026-10-07-metric-known-answer/check.sh` (needs `uv`; override with `MF=mf` if MetricFlow is installed)
