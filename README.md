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

29 nodes: 3 seeds, 6 models (incl. the `metricflow_time_spine`), 20 tests, plus 1 semantic model and 1 metric (`revenue`). `dbt docs generate --static && python3 scripts/sanitize_docs.py` produces `site/index.html`
(neutral build path, share tags, favicon, link-back), the docs site deployed on Vercel.

## Snowflake

The SQL is plain and was only run on DuckDB. `profiles.snowflake.example.yml` is a template that reads credentials
from environment variables; the published build runs on DuckDB.

## Semantic layer and the OSI export

`models/marts/_semantic_models.yml` defines revenue once as a semantic model (`monthly_revenue`) with a simple
`revenue` metric. dbt 1.12 then writes it to `target/osi_document.json` (Apache Ossie / Open Semantic Interchange)
at parse time, so other tools can read the same definition. Before it, that file was written but empty.

## Proofs

[`proofs/`](proofs/) holds one re-runnable check per claim tested against this demo (claim, test, result).
`bash proofs/run_all.sh` runs them; CI runs them on every push. Browse them on the site at `/proofs.html`.

## Demo video

60-second silent walkthrough with captions (fictional data):
lineage graph -> `fct_revenue_variance` -> Pro Plan, January 2026
(total -29.80 = volume +596.00 + price -625.80) -> the reconciliation tests -> `dbt build` PASS=26.

- [`demo/dbt-revenue-variance-16x9.mp4`](demo/dbt-revenue-variance-16x9.mp4) (1920x1080)
- [`demo/dbt-revenue-variance-1x1.mp4`](demo/dbt-revenue-variance-1x1.mp4) (1080x1080, social cut)
- [`demo/hero.png`](demo/hero.png), how it was made: [`demo/recording-notes.md`](demo/recording-notes.md)
