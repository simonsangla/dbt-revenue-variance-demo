# No time spine, no semantic layer (2026-10-07)

**Learning (from adding the semantic model in PR #7):** dbt's semantic layer needs a day-grain time spine
model before it will parse a project that defines metrics.

**What I tested:** `f5ba575` with and without `metricflow_time_spine`.

| | `dbt parse` |
|---|---|
| With the time spine | OK |
| Without it | exit 2: "The semantic layer requires a time spine model with granularity DAY or smaller in the project, but none was found" |

**Result:** holds. Moving a metric into the semantic layer is two models, not one.
Docs: [MetricFlow time spine](https://docs.getdbt.com/docs/build/metricflow-time-spine).

**Run it:** `bash proofs/2026-10-07-time-spine-required/check.sh`
