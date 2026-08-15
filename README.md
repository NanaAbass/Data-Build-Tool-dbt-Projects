# PulseCare Analytics — dbt Project

## Business Scenario
**PulseCare Health Network** operates outpatient primary care, urgent care, and
specialty clinics across 10 U.S. regions. This project consolidates raw
**patient visit**, **insurance claims**, and **provider** data into a tested,
medallion-architected dbt warehouse that powers revenue and provider
performance reporting for finance and operations leadership.

## Phases
| Phase | Focus |
|---|---|
| **1 — Environment Setup & Seed Ingestion** | ✅ this phase |
| 2 — Medallion Pipeline (Bronze → Gold) | upcoming |
| 3 — Jinja Templating & Macros | upcoming |
| 4 — Testing & Data Quality | upcoming |
| 5 — Snapshots (SCD Type 2) & CI/CD | upcoming |

## Phase 1 — Environment Setup & Seed Ingestion

**Objective:** install dbt Core via `uv`, establish dev/prod connection
profiles, and ingest static reference data.

### Stack
- **Package manager:** [`uv`](https://docs.astral.sh/uv/) — fast, modern
  Python dependency management
- **dbt:** `dbt-core` 1.12 + `dbt-duckdb` 1.11
- **Warehouse:** DuckDB — file-based, zero external infra, real SQL engine.
  Swap `profiles.yml` for Snowflake/BigQuery/Postgres in a real deployment
  without touching any model code.

### What was done
1. `uv init` — scaffolded the Python project (`pyproject.toml`, `uv.lock`)
2. `uv add dbt-core dbt-duckdb` — added dbt and the DuckDB adapter as
   locked, reproducible dependencies
3. `profiles.yml` — defines **two targets**:
   - `dev` → `data/dev/pulsecare_dev.duckdb`, schema `dev_analytics`
   - `prod` → `data/prod/pulsecare_prod.duckdb`, schema `prod_analytics`

   Physically separate DuckDB files, so a local `dbt run` can never
   touch production data.
4. `seeds/region_lookup.csv` — static clinic-region reference data
   (region → state, timezone, network tier) loaded with `dbt seed`.
   This is reference data maintained by hand (not pulled from a source
   system), which is exactly what seeds are for. Downstream gold models
   (Phase 2) will join visits/claims to this table on `region_id`.

### Project structure
```
pulsecare_analytics/
├── dbt_project.yml
├── profiles.yml              # dev + prod targets (DuckDB)
├── pyproject.toml            # uv-managed deps
├── uv.lock
├── seeds/
│   └── region_lookup.csv     # static regional lookup (Phase 1)
├── models/
│   ├── bronze/                # Phase 2
│   ├── silver/                # Phase 2
│   └── gold/                  # Phase 2
├── macros/                    # Phase 3
├── snapshots/                  # Phase 5
├── tests/                      # Phase 4
├── analyses/
└── data/
    ├── dev/pulsecare_dev.duckdb
    └── prod/pulsecare_prod.duckdb
```

### Running it yourself
```bash
# install deps
uv sync

# verify both connection profiles
uv run dbt debug --profiles-dir . --target dev
uv run dbt debug --profiles-dir . --target prod

# load the seed into dev
uv run dbt seed --profiles-dir . --target dev

# load the seed into prod (done explicitly in CI/CD in Phase 5)
uv run dbt seed --profiles-dir . --target prod
```

### Verified in this session
- dbt debug passes on both dev and prod targets
- dbt seed loads all 10 rows of region_lookup into dev_analytics_seed_data.region_lookup
- dev and prod DuckDB files confirmed physically isolated — prod stays empty until deliberately seeded
