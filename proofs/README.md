# Proofs

Each folder tests one claim from the public dbt / Snowflake conversation against this demo, with a
re-runnable `check.sh` and a `CLAIM.md` (claim paraphrased, what was tested, result). Fictional data only;
the poster is never named. `bash proofs/run_all.sh` runs them all; CI runs them on every push.

| Date | Topic | Result | Proof |
|---|---|---|---|
| 2026-10-07 | dbt `osi_document.json` (Apache Ossie) | Written at parse time, but empty until revenue is a semantic model | [CLAIM](2026-10-07-osi-export/CLAIM.md) · [check.sh](2026-10-07-osi-export/check.sh) |
| 2026-10-07 | A changed revenue definition | Counting refunds adds 8,060.30 EUR (+15%) and turns the build red on 2 known-answer tests | [CLAIM](2026-10-07-definition-change-breaks/CLAIM.md) · [check.sh](2026-10-07-definition-change-breaks/check.sh) |
| 2026-10-07 | Semantic layer prerequisites | No day-grain time spine, no parse | [CLAIM](2026-10-07-time-spine-required/CLAIM.md) · [check.sh](2026-10-07-time-spine-required/check.sh) |
| 2026-10-07 | Dashboard query vs `revenue` metric | Agree at 53,546.30 EUR; a chart-SQL or metric change is caught while `dbt build` stays green | [CLAIM](2026-10-07-chart-vs-metric/CLAIM.md) · [check.sh](2026-10-07-chart-vs-metric/check.sh) |
| 2026-10-07 | Green pipeline, wrong data | Duplicates were caught; refunds counted as revenue (+15%) and a missing month (-33%) passed a green build until two tests were added | [CLAIM](2026-10-07-green-pipeline-wrong-data/CLAIM.md) · [check.sh](2026-10-07-green-pipeline-wrong-data/check.sh) |
