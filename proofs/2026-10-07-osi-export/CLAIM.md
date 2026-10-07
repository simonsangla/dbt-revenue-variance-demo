# OSI export from dbt parse (2026-10-07)

**Claim discussed (paraphrased):** dbt 1.12 natively supports Apache Ossie (Open Semantic Interchange):
every project writes `target/osi_document.json` at parse time, so "revenue" defined once can travel to every tool.

**What I tested:** parse this repo before and after modelling revenue as a semantic model.

| | `osi_document.json` |
|---|---|
| Before (`e039c63`, variance logic only in SQL models) | written, `datasets: []` |
| After (`f5ba575`, PR #7: semantic model `monthly_revenue` + metric `revenue` + time spine) | datasets `monthly_revenue`, metrics `revenue` |

**Result:** the claim holds (the file is written at parse time), and it only carries what you have modelled.
Logic that lives only in SQL models does not travel. Adding the semantic layer also required a day-grain
time spine model (`metricflow_time_spine`): without it dbt refuses to parse.

**Run it:** `bash proofs/2026-10-07-osi-export/check.sh` (needs git history; `DBT=` overrides the dbt command).
Docs: [sl-manifest / osi_document.json](https://docs.getdbt.com/reference/artifacts/sl-manifest),
[Ossie semantic models](https://docs.getdbt.com/docs/build/ossie-semantic-models).
