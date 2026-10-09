# A green pipeline can still carry wrong data (2026-10-07)

**Claim discussed (paraphrased):** "The pipeline is green. But is the data ready?" A run that succeeds says the
code executed, not that the numbers are right; duplicates, lost returns and missing periods pass straight through.

**What I tested:** three failures injected into the orders seed of a copy of the repo (`git archive`), then
`dbt build` on each. First against the tests that existed (`29349b7`), then with two new singular tests.

| Mutation | Revenue (clean 53,546.30 EUR) | Before new tests (`29349b7`) | After new tests (HEAD) |
|---|---|---|---|
| 1. Five completed order lines loaded twice | 53,776.60 EUR (+230.30) | **caught**: `unique_stg_orders_order_id` (ERROR=1) | caught, same test |
| 2. Refunded lines relabelled `completed` (returns no longer excluded) | 61,606.60 EUR (+8,060.30, +15%) | **not caught**: PASS=27 ERROR=0 | caught: `assert_refunds_present_each_month` |
| 3. March 2026 orders missing | 35,950.20 EUR (-17,596.10, -33%) | **not caught**: PASS=27 ERROR=0 | caught: `assert_orders_cover_budget_months` (and `assert_refunds_present_each_month`, March refunds gone too) |

**Result:** before this proof, 2 of 3 failures went through a fully green build. The known-answer tests did not
help: they recompute revenue from the same seed, so when the seed itself is wrong both sides agree. The missing
month showed up only as a 100% budget miss in the bridge, which reads like a business result, not a data fault.

**Added:** `tests/assert_orders_cover_budget_months.sql` (every budget month has completed orders) and
`tests/assert_refunds_present_each_month.sql` (every budget month still carries refunded lines in the source).
Clean build: PASS=29 ERROR=0; mutated builds ERROR=1, 1, 2.

**Limits:** the refunds test detects a lost status, not a wrong refund rate; a duplicate re-keyed with a new
`order_id` is not caught by any test here.

**Plain figures** (comma-free, printed by `check.sh`): clean revenue 53546.3 EUR, refunds relabelled 61606.6 EUR, +15%.

**Run it:** `bash proofs/2026-10-07-green-pipeline-wrong-data/check.sh` (`REF=29349b7` replays the before state;
it exits 1 because mutations 2 and 3 pass a green build)
