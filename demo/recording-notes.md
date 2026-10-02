# Recording notes

- Pipeline: playwright-core (local npx cache) + installed Chrome, headless, 1920x1080 stills of the
  static dbt docs site (`site/index.html`, served on 127.0.0.1) and three HTML cards; ffmpeg
  slow zoom per scene, 0.5 s crossfades, h264 yuv420p, no audio track (silent by decision).
- Captions are injected into the page at capture time; nothing in the repo was changed for the video.
- Scenes: title (5 s), lineage graph (10 s), `fct_revenue_variance` columns (10 s), Pro Plan
  Jan 2026 row (13 s), `assert_variance_bridge_reconciles` source (10 s), `dbt build` result (7 s),
  end card (7 s). Total 59 s.
- The row card is a rendered panel, not a screen of a query tool. Its figures were read from
  `fct_revenue_variance` in `revenue_variance.duckdb` on 2026-10-02: budget 60 x 149.00 = 8,940.00,
  actual 64 units = 8,910.20, total -29.80, volume +596.00, price -625.80.
- The `dbt build` card restates the real run of 2026-10-02: `Done. PASS=25 WARN=0 ERROR=0`.
- Redaction: none needed, all data is fictional and no account identifiers appear.
- Self-review: frames at 2/9/18/30/42/52/57 s checked for readability, caption overlap, and figures.

| Asset | Size | Duration |
|---|---|---|
| dbt-revenue-variance-16x9.mp4 | 1920x1080 | 59 s |
| dbt-revenue-variance-1x1.mp4 | 1080x1080 | 59 s |
| hero.png | 1920x1080 | still |
