# Proofs

Each folder tests one claim from the public dbt / Snowflake conversation against this demo, with a
re-runnable `check.sh` and a `CLAIM.md` (claim paraphrased, what was tested, result). Fictional data only;
the poster is never named. `bash proofs/run_all.sh` runs them all; CI runs them on every push.

| Date | Topic | Result | Proof |
|---|---|---|---|
| 2026-10-07 | dbt `osi_document.json` (Apache Ossie) | Written at parse time, but empty until revenue is a semantic model | [CLAIM](2026-10-07-osi-export/CLAIM.md) · [check.sh](2026-10-07-osi-export/check.sh) |
