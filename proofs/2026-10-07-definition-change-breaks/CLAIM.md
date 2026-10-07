# A definition change must break the build (2026-10-07)

**Claim discussed (paraphrased):** a metric defined once but never checked is a nicer place to keep a mistake;
a legitimate definition change should create a visible break that the metric's owner approves, rather than
quietly changing the answers downstream.

**What I tested:** one line in `stg_orders` changed so refunded orders count as revenue, then `dbt build`.

| | Revenue | `dbt build` |
|---|---|---|
| Clean (`f5ba575`) | 53,546.30 EUR | PASS=27, ERROR=0 |
| Refunds counted | 61,606.60 EUR (+8,060.30, +15%) | ERROR=2: `assert_variance_bridge_reconciles` (12 month x product rows), `assert_bridge_covers_all_revenue` |

**Result:** holds. The known-answer tests recompute revenue from the raw orders, so the changed definition
cannot reach the variance bridge silently: the build goes red and someone has to decide.

**Run it:** `bash proofs/2026-10-07-definition-change-breaks/check.sh`
