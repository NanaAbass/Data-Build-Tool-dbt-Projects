# PulseCare Analytics

A multi-phase **dbt** analytics pipeline built for a fictional multi-region outpatient clinic operator. The project consolidates patient visits, insurance claims, and provider data into a medallion-architected warehouse to power revenue and provider-performance reporting.

Built as a hands-on walkthrough of modular SQL, custom macros, data quality testing, and multi-environment deployment with dbt.

## Business Scenario

PulseCare operates outpatient clinics across multiple regions. Each clinic visit generates a patient record, is tied to a provider, and (when completed) produces one or more insurance claims. Finance and operations need a single source of truth to answer questions like:

- What's our net revenue by region, after discounts?
- How is each provider performing — visit volume, no-show rate, denial rate?
- Which claims are stuck, denied, or under-collected?

This repo builds that warehouse from raw operational exports through to reporting-ready gold tables.

## Tech Stack

| Component | Tool |
|---|---|
| Transformation | [dbt-core](https://github.com/dbt-labs/dbt-core) |
| Warehouse | [DuckDB](https://duckdb.org/) (via `dbt-duckdb`) |
| Python/dependency management | [uv](https://github.com/astral-sh/uv) |
| Raw data ingestion (simulated EL) | `scripts/load_raw_data.py` |

## Architecture: Medallion Layers

```
raw (simulated upstream EL)
  └─ bronze/   1:1 landing of source tables, light casting only
       └─ silver/   joined, enriched, business-readable entities
            └─ gold/   aggregated, reporting-ready marts
```

| Layer | Materialization | Purpose |
|---|---|---|
| `bronze` | table | Raw ingestion from `source()`, minimal transformation |
| `silver` | view | Joined/enriched entities (providers, visits, claims) |
| `gold` | table | Aggregated marts for reporting (revenue, provider performance) |

Schemas are physically separated in DuckDB (`bronze`, `silver`, `gold`), with isolated `dev.duckdb` and `prod.duckdb` files per environment.

## Project Structure

```
pulsecare/
├── seeds/
│   ├── region_lookup.csv
│   ├── raw_patient_visits.csv
│   ├── raw_insurance_claims.csv
│   └── raw_providers.csv
├── models/
│   ├── bronze/
│   │   ├── bronze_patient_visits.sql
│   │   ├── bronze_insurance_claims.sql
│   │   ├── bronze_providers.sql
│   │   └── bronze_region_lookup.sql
│   ├── silver/
│   │   ├── silver_patient_visits.sql
│   │   ├── silver_claims.sql
│   │   ├── silver_providers.sql
│   │   ├── silver_provider_roster.sql
│   │   └── silver_visit_claims.sql
│   ├── gold/
│   │   ├── gold_provider_rev_summary.sql
│   │   ├── gold_reg_rev_summary.sql
│   │   ├── gold_reg_rev.sql
│   │   └── gold_provider_per.sql
│   └── source.yml
├── macros/
│   ├── generate_schema.sql
│   ├── network_tier.sql
│   ├── net_revenue.sql
│   └── generic_tests/            # custom generic test macros (Phase 4)
├── tests/                        # singular tests (Phase 4)
├── scripts/
│   └── load_raw_data.py          # simulates upstream EL into raw schema
├── snapshots/                    # SCD Type 2 (Phase 5)
├── dbt_project.yml
└── profiles.yml
```

## Getting Started

### Prerequisites

- Python 3.9+
- [`uv`](https://github.com/astral-sh/uv) installed

### Setup

```bash
# 1. Install dependencies
uv init
uv add dbt-core dbt-duckdb duckdb

# 2. Simulate the upstream EL load into DuckDB's raw schema
uv run python scripts/load_raw_data.py --target dev

# 3. Seed static lookup data (region metadata, raw CSV fallbacks)
uv run dbt seed --target dev

# 4. Build all models
uv run dbt run --target dev

# 5. Run the test suite
uv run dbt test --target dev
```

> **Note:** Because bronze models reference `source()` rather than `ref()`, dbt does not draw a DAG dependency edge between the seed step and the bronze source nodes. Always run `dbt seed → dbt run → dbt test` as separate, ordered steps rather than `dbt build`, to avoid a race condition where models run before seeds are loaded.

### Environments

`profiles.yml` defines two isolated DuckDB targets:

| Target | File |
|---|---|
| `dev` | `dev.duckdb` |
| `prod` | `prod.duckdb` |

Switch targets with `--target prod` on any dbt command; run `scripts/load_raw_data.py --target prod` first to populate the corresponding raw schema.

## Roadmap & Phases

| Phase | Focus | Status |
|---|---|---|
| 1 | Project scaffolding, seeds, dev/prod profiles | ✅ Complete |
| 2 | Bronze → Silver → Gold medallion models | ✅ Complete |
| 3 | Jinja macros and control flow | ✅ Complete |
| 4 | Testing and data quality | ✅ Complete |
| 5 | SCD Type 2 snapshots and CI/CD | ✅ Complete |

### Phase 1 — Environment Setup & Seed Ingestion
Project scaffolded with `uv`, dbt connection profiles established for `dev`/`prod`, and static regional metadata loaded via `dbt seed`.

### Phase 2 — Medallion Pipeline (Bronze → Gold)
Models organized into `bronze`, `silver`, and `gold` folders with folder-level materialization config (bronze/gold as tables, silver as views). Bronze reads raw tables via `source()`; every downstream layer chains through `ref()`.

### Phase 3 — Jinja Templating & Reusable Macros
Repetitive SQL replaced with parameterized macros:

| Macro | Purpose |
|---|---|
| `net_revenue(paid_column, discount_column, currency_vars)` | Currency-adjusted net revenue calculation |
| `network_tier(tier_column)` | Maps tier labels (`Tier 1`/`2`/`3`) to numeric priority via Jinja `for` loop |
| `generate_schema_name` | Overridden to keep custom schema names clean across environments |
| `calculate_net_revenue`, `pivot_visit_type_charges`, `get_column_values` | Additional reusable calculation and pivoting macros |

### Phase 4 — Testing & Data Quality *(current focus)*
- **Custom generic tests:** `not_future_date`, `value_within_range` (parameterized `min_value`/`max_value`), `non_negative`
- **Singular test:** `assert_revenue_not_less_than_discount.sql` — asserts realized revenue never dips below the discount applied
- **Schema tests:** standard (`unique`, `not_null`, `accepted_values`) plus custom generic tests across bronze/silver/gold, with severity tuned per check (`error` for invalid dates, `warn` for out-of-range coverage metrics) using dbt's nested `config: severity:` syntax

> **Known issue:** `gold_provider_per.sql` currently joins its final `SELECT` from an ungrouped visits CTE rather than a deduplicated provider list, which can produce duplicate `provider_id` rows. This is a pre-existing Phase 1–3 artifact and is intentionally left unmodified during Phase 4 testing work; it is flagged here for future remediation.

### Phase 5 — Snapshots (SCD Type 2) & CI/CD
- `dbt snapshot` using the timestamp strategy to track history on changing provider/patient attributes
- Parameterization via `target.catalog` / `target.schema`
- CI/CD pipeline enforcing explicit `dbt seed → dbt run → dbt test` sequencing to avoid the source/seed race condition described above

## Data Sources (Seeds)

| Seed | Description |
|---|---|
| `region_lookup` | Static region metadata: name, state, timezone, network tier |
| `raw_patient_visits` | Patient visit records |
| `raw_insurance_claims` | Insurance claim records |
| `raw_providers` | Provider roster |

Operational data (`patient_visits`, `insurance_claims`, `providers`) is additionally simulated via `scripts/load_raw_data.py`, standing in for a real Fivetran/Airbyte-style EL process landing data into the `raw` schema before dbt runs.

## License

For educational/demonstration purposes.
