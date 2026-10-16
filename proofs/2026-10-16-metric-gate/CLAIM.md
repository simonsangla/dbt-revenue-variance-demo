# An agent checks for a defined metric before answering (2026-10-16)

**Claim discussed (paraphrased):** an agent should first check whether a question maps to a defined, tested metric;
if it does not, the agent declines instead of sampling an answer.

**What I tested:** `dbt parse` writes `semantic_manifest.json`; `check.sh` reads every defined metric and the
dimensions/entities of its semantic model, then maps a fixed question set onto them deterministically. A question is
ANSWERABLE only if it names a defined metric and every "by X" grouping is a dimension of that metric; otherwise DECLINE.
The one defined metric, `revenue`, is the one with a known-answer test (`proofs/2026-10-07-metric-known-answer`).

| Question | Verdict | Why |
|---|---|---|
| total revenue / revenue by month / revenue by product | ANSWERABLE | maps to metric `revenue` |
| revenue by region | DECLINE | `revenue` has no `region` dimension |
| customer happiness score / churn rate by month / net promoter score | DECLINE | no defined metric |

**Result:** holds. 3 of 7 questions answerable, 4 declined; nothing is answered outside the semantic layer.

Re-run: `bash proofs/2026-10-16-metric-gate/check.sh` (needs `uv`).
