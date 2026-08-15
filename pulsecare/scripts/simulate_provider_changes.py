"""
Phase 5 helper: simulate provider-roster change events.

raw.providers (loaded by scripts/load_raw_data.py) has no updated_at
column, but the snapshot_provider_roster snapshot uses the `timestamp`
strategy and needs one to detect changes between snapshot runs.

This script is additive only — it never touches load_raw_data.py or
any Phase 1-3 model. Run modes:

    --init     add updated_at (defaults to hire_date) if missing
    --mutate   apply a handful of realistic roster changes (specialty
               reassignment, region transfer, active_flag toggle) and
               bump updated_at on just those rows, so a second
               `dbt snapshot` run produces new SCD2 versions

Usage:
    uv run python scripts/simulate_provider_changes.py --target dev --init
    uv run python scripts/simulate_provider_changes.py --target dev --mutate
"""
import argparse
import duckdb
from datetime import datetime, timedelta


def init_updated_at(con):
    cols = [r[0] for r in con.execute("PRAGMA table_info('raw.providers')").fetchall()]
    if "updated_at" not in cols:
        con.execute("ALTER TABLE raw.providers ADD COLUMN updated_at TIMESTAMP")
        con.execute("UPDATE raw.providers SET updated_at = CAST(hire_date AS TIMESTAMP)")
        print("Added updated_at column, initialized to hire_date.")
    else:
        print("updated_at already present, nothing to do.")


def mutate_roster(con):
    now = datetime.utcnow()

    # 1. Specialty reassignment for one provider
    con.execute(f"""
        UPDATE raw.providers
        SET specialty = 'Dermatology', updated_at = TIMESTAMP '{now.isoformat()}'
        WHERE provider_id = 'P0001'
    """)

    # 2. Region transfer for another provider
    con.execute(f"""
        UPDATE raw.providers
        SET region_id = 'R05', updated_at = TIMESTAMP '{(now + timedelta(seconds=1)).isoformat()}'
        WHERE provider_id = 'P0002'
    """)

    # 3. Active flag toggled off (e.g. provider left the network)
    con.execute(f"""
        UPDATE raw.providers
        SET active_flag = false, updated_at = TIMESTAMP '{(now + timedelta(seconds=2)).isoformat()}'
        WHERE provider_id = 'P0003'
    """)

    print("Mutated P0001 (specialty), P0002 (region_id), P0003 (active_flag).")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", choices=["dev", "prod"], required=True)
    parser.add_argument("--init", action="store_true")
    parser.add_argument("--mutate", action="store_true")
    args = parser.parse_args()

    con = duckdb.connect(f"{args.target}.duckdb")
    if args.init:
        init_updated_at(con)
    if args.mutate:
        mutate_roster(con)
    con.close()


if __name__ == "__main__":
    main()
