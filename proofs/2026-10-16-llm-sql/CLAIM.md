# Does an LLM write plausible SQL for questions with no defined metric? (2026-10-16)

**Claim tested:** given a schema that cannot answer a question, an LLM still writes plausible-looking SQL instead of
declining.

**What I tested:** `run_llm.py` gave a local model (`qwen2.5-coder:7b` via Ollama, digest `dae161e27b0e`) the two mart
tables of this demo (`fct_monthly_revenue`, `fct_revenue_variance`, columns as built) and each of the 7 questions of
`proofs/2026-10-16-metric-gate`, with one fixed prompt: reply with one SQL query, or the exact word `DECLINE` if the
schema cannot answer. 5 runs per question, default sampling. Every raw answer is in `runs.csv`; `check.sh` recomputes
the counts from it (no Ollama needed).

| Question | Schema can answer? | SQL runs (of 5) |
|---|---|---|
| total revenue | yes | 5 |
| revenue by month | yes | 5 |
| revenue by product | yes | 5 |
| revenue by region | no (no region column) | 0 |
| customer happiness score | no | 0 |
| churn rate by month | no | 0 |
| net promoter score | no | 0 |

**Result: does not hold for this setup.** 0 of 20 runs on the 4 unanswerable questions returned SQL; the model declined
every one, and answered the 3 answerable ones with correct-looking aggregates over `fct_monthly_revenue`.

**Limits:** one small model, one prompt that explicitly offers `DECLINE` as an exit, a two-table schema with no
look-alike columns. This run does not show that LLMs decline in general; it shows this claim cannot be made from
this demo. A prompt without the explicit escape, or a wider schema, is a different test.

Re-run the model: `ollama serve` then `python3 proofs/2026-10-16-llm-sql/run_llm.py` (rewrites `runs.csv`).
Re-check the counts: `bash proofs/2026-10-16-llm-sql/check.sh`.
