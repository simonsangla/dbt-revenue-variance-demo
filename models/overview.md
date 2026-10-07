{% docs __overview__ %}

# Why did revenue miss budget?

Revenue came in under budget. This demo shows why, in one table.

## The answer, for Pro Plan in January 2026

| | EUR |
|---|---|
| **Total variance vs budget** | **-29.80** |
| Volume effect (sold more units) | +596.00 |
| Price effect (sold at lower prices) | -625.80 |

**Growth hid a discounting problem.** Sales volume beat the plan, but discounting ate the gain.

## What the model does

It splits the budget gap into a volume part and a price part, for every product and every month. Two dbt tests tie the bridge back to the raw order lines: budget + volume + price must equal the completed revenue recomputed from the orders seed, per month and product and in total.

## Tested in public

Claims from the dbt and Snowflake conversation, re-run against this demo. Each one is a script in `proofs/` that CI re-runs on every push, and each appears in the lineage graph as an exposure.

| Date | Claim tested | Result |
|---|---|---|
| 2026-10-07 | dbt 1.12 writes `osi_document.json` (Apache Ossie) at parse time | **Holds**, but it is empty until revenue is a semantic model. [Proof](#!/exposure/exposure.revenue_variance.proof_2026_10_07_osi_export) |

## Start here

Open the [fct_revenue_variance model](#!/model/model.revenue_variance.fct_revenue_variance).

Fictional data. Built on DuckDB in plain SQL.

Built by Simon Sangla — [simonsangla.com](https://simonsangla.com)

{% enddocs %}
