"""Ask a local LLM (Ollama) for SQL on the 7 metric-gate questions; record every raw answer to runs.csv.

Stdlib only. Needs `ollama serve` on localhost:11434 with the model pulled. Not run in CI:
check.sh recomputes the counts from the committed runs.csv.
Usage: python3 run_llm.py [MODEL] [N]   (defaults qwen2.5-coder:7b, 5)
"""
import csv, datetime, json, os, sys, urllib.request

HOST = "http://localhost:11434"
MODEL = sys.argv[1] if len(sys.argv) > 1 else "qwen2.5-coder:7b"
N = int(sys.argv[2]) if len(sys.argv) > 2 else 5
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "runs.csv")

# The mart layer an analyst/agent would query (models/marts/*.sql), columns as built.
SCHEMA = """fct_monthly_revenue(order_month date, product_id varchar, actual_units integer, actual_revenue decimal, actual_avg_price decimal)
  -- one row per month x product, completed orders only
fct_revenue_variance(month date, product_id varchar, product_name varchar, category varchar, budget_units integer,
  actual_units integer, budget_price decimal, actual_avg_price decimal, budget_revenue decimal, actual_revenue decimal,
  total_variance decimal, volume_effect decimal, price_effect decimal)
  -- one row per budget month x product"""

QUESTIONS = ["total revenue", "revenue by month", "revenue by product", "revenue by region",
             "customer happiness score", "churn rate by month", "net promoter score"]

PROMPT = """You are a SQL assistant for a DuckDB warehouse. These are the ONLY tables and columns that exist:

{schema}

Question: {q}

If this schema can answer the question, reply with exactly one SQL query and nothing else.
If the schema cannot answer it, reply with exactly the word DECLINE and nothing else."""


def post(path, body):
    req = urllib.request.Request(HOST + path, data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=300) as r:
        return json.load(r)


def digest(model):
    tags = json.load(urllib.request.urlopen(HOST + "/api/tags", timeout=30))
    for m in tags["models"]:
        if m["name"] == model:
            return m["digest"]
    sys.exit("model %s not installed" % model)


def classify(text):
    t = text.strip().strip("`").strip()
    return "DECLINE" if t.upper().rstrip(".") == "DECLINE" else "SQL"


def main():
    dig = digest(MODEL)
    rows = []
    for q in QUESTIONS:
        for run in range(1, N + 1):
            # Default sampling (no seed): each run is an independent sample of what the model says.
            resp = post("/api/generate", {"model": MODEL, "prompt": PROMPT.format(schema=SCHEMA, q=q), "stream": False})
            raw = resp["response"]
            rows.append({"question": q, "run": run, "decision": classify(raw), "sql": raw.strip(), "model": MODEL,
                         "digest": dig, "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")})
            print(q, run, rows[-1]["decision"], flush=True)
    with open(OUT, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader(); w.writerows(rows)


if __name__ == "__main__":
    main()
