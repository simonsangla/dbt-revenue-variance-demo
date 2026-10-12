# Two one-line breaks, two different detectors (2026-10-12)

**Claim discussed (paraphrased):** a one-line change to the revenue definition in a model is caught by the
build, but a one-word change to the metric in the semantic layer passes a green build and is caught only by a
known-answer check on the metric itself.

**What I tested:** two copies of HEAD (`git archive`), each with one change, each run through `dbt build`.

| | Change | Revenue | `dbt build` | Metric check |
|---|---|---|---|---|
| Clean (HEAD) | none | 53,546.30 EUR | PASS=29, ERROR=0 | MetricFlow 53,546.30 = seed |
| Break 1 | `stg_orders`: `status = 'completed'` -> `status in ('completed', 'refunded')` | 61,606.60 EUR (+15%) | PASS=27, **ERROR=2** | not needed |
| Break 2 | `actual_revenue` measure `agg: sum` -> `agg: max` | 9,550.90 EUR via MetricFlow | **PASS=29, ERROR=0** | 9,550.90 vs 53,546.30, **FAIL** |

Break 1 fails on `assert_variance_bridge_reconciles` and `assert_bridge_covers_all_revenue`, the two tests that
recompute revenue from the raw orders seed. Break 2 is invisible to every table test.

**Result:** holds. Real counts on HEAD: break 1 = 2 errors, break 2 = 29 passed, 0 errors.

**Run it:** `bash proofs/2026-10-12-two-breaks/check.sh` (needs `uv`; override with `MF=mf`). Last line:
`NUMBERS: 53,546.30 61,606.60 15% 2 29 0 9,550.90`.
