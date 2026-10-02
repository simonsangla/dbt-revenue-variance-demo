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
- The two sum exactly to `actual_revenue - budget_revenue`; the singular test
  `assert_variance_bridge_reconciles` fails if they do not.

## Run it (no credentials)

```
cd dbt-revenue-variance-demo && DBT_PROFILES_DIR=. uvx --with dbt-duckdb --from dbt-core dbt build
```

25 nodes: 3 seeds, 5 models, 17 tests. `dbt docs generate --static` produces `site/index.html`,
the docs site deployed on Vercel.

## Snowflake

The SQL is portable. `profiles.snowflake.example.yml` is a template that reads credentials
from environment variables; the published build runs on DuckDB.
