# A dashboard query and the revenue metric must agree (2026-10-07)

**Claim discussed (paraphrased):** dbt Charts query models directly (`ref()` / SQL), not the Semantic Layer
([docs.getdbt.com/guides/dbt-charts](https://docs.getdbt.com/guides/dbt-charts)). So a dashboard query and the
`revenue` metric are two independent definitions of the same number, and `dbt build` checks neither one against
the other.

**What I tested:** [`chart.sql`](chart.sql), a dashboard-style query (what dbt Charts would run: models, not the
Semantic Layer), `sum(actual_revenue)` over `ref('fct_monthly_revenue')`, run with `dbt show`, against
`mf query --metrics revenue` (MetricFlow on DuckDB), at total grain. No dbt Charts install: the chart is a
plain SQL query. Then one mutation on each side.

| | Chart query | `revenue` via MetricFlow | plain `dbt build` | Result |
|---|---|---|---|---|
| Clean (HEAD) | 53,546.30 EUR | 53,546.30 EUR | PASS=27 WARN=0 ERROR=0 | match |
| A: chart reads `ref('orders')`, status filter dropped | 61,606.60 EUR | 53,546.30 EUR | PASS=27 WARN=0 ERROR=0 | mismatch, proof FAILS |
| B: `actual_revenue` `agg: sum` -> `agg: max` | 53,546.30 EUR | 9,550.90 EUR | PASS=27 WARN=0 ERROR=0 | mismatch, proof FAILS |

**Result:** holds. `dbt build` stays green under both mutations; only this check, which runs both definitions
side by side, sees the drift. Total grain only (per-month not compared).

**Run it:** `bash proofs/2026-10-07-chart-vs-metric/check.sh` (needs `uv`; override with `MF=mf` if MetricFlow
is installed; `REF=<rev>` checks another commit than HEAD)
