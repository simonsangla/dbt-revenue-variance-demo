# Claude now writes the SQL behind every dashboard chart (2026-10-15)

Status: **not yet proven** (stub; `check.sh` exits 1 until a real check replaces it).

**Claim discussed:** Claude now writes the SQL behind every dashboard chart.

**Open question:** Who checks that query before the meeting?

**Context:** Claude Dashboards (beta) runs Claude-written SQL against your warehouse; primary-source quotes in the research note. Angle for AI builders: generated queries need the same review as generated code.

**Source candidate:** `asset-claude-dashboards` (mission-os `missions/linkedin-campaign/candidates.json`, evidence `docs/research/2026-10-13-claude-dashboards-positioning.md`)

**Run it:** `bash proofs/2026-10-15-claude-dashboards/check.sh`
