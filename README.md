# Revenue variance — a dbt demo

Budget vs actual revenue, decomposed into **volume** and **price** effects, built with dbt.
All data is fictional (generated seeds, seed 42). No client data, no client identity.

```
seeds (orders, budget, products)
  -> staging: stg_orders, stg_budget, stg_products   (views)
  -> marts:   fct_monthly_revenue, fct_revenue_variance (tables)
```

- `volume_effect = (actual_units - budget_units) * budget_price`
- `price_effect  = actual_revenue - actual_units * budget_price`
- The two sum to `actual_revenue - budget_revenue` by construction, so that identity is not what is tested. The singular tests
  `assert_variance_bridge_reconciles` and `assert_bridge_covers_all_revenue` tie `budget + volume + price` to the completed revenue
  recomputed straight from the orders seed, so a changed refund filter, a revenue formula change or a dropped join fails the build.

## Run it (no credentials)

```
cd dbt-revenue-variance-demo && DBT_PROFILES_DIR=. uvx --with dbt-duckdb --from dbt-core dbt build
```

25 nodes: 3 seeds, 5 models, 17 tests. `dbt docs generate --static && python3 scripts/sanitize_docs.py` produces `site/index.html`
(neutral build path, share tags, favicon, link-back), the docs site deployed on Vercel.

## Snowflake

The SQL is plain and was only run on DuckDB. `profiles.snowflake.example.yml` is a template that reads credentials
from environment variables; the published build runs on DuckDB.

## Demo video

60-second silent walkthrough with captions (fictional data):
lineage graph -> `fct_revenue_variance` -> Pro Plan, January 2026
(total -29.80 = volume +596.00 + price -625.80) -> the reconciliation tests -> `dbt build` PASS=26.

- [`demo/dbt-revenue-variance-16x9.mp4`](demo/dbt-revenue-variance-16x9.mp4) (1920x1080)
- [`demo/dbt-revenue-variance-1x1.mp4`](demo/dbt-revenue-variance-1x1.mp4) (1080x1080, social cut)
- [`demo/hero.png`](demo/hero.png), how it was made: [`demo/recording-notes.md`](demo/recording-notes.md)
