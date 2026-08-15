"""
Simulates an upstream EL (Extract & Load) process that lands raw operational
data into the warehouse's `raw` schema, BEFORE dbt ever touches it.
In a real stack this would be Fivetran/Airbyte/custom ingestion.
dbt's bronze layer then reads these tables via source().

Usage:
    uv run python scripts/load_raw_data.py --target dev
    uv run python scripts/load_raw_data.py --target prod
"""
import argparse
import random
import duckdb
from datetime import datetime, timedelta

random.seed(42)

REGIONS = [f"R{str(i).zfill(2)}" for i in range(1, 11)]
SPECIALTIES = ["Family Medicine", "Cardiology", "Orthopedics", "Pediatrics",
               "Dermatology", "Internal Medicine", "OB/GYN", "Psychiatry"]
VISIT_TYPES = ["New Patient", "Follow-Up", "Annual Physical", "Urgent Care", "Telehealth"]
DIAGNOSIS_CODES = ["J06.9", "I10", "E11.9", "M54.5", "F41.1", "K21.9", "Z00.00", "R51"]
PAYERS = ["Aetna", "BlueCross BlueShield", "UnitedHealthcare", "Cigna", "Medicare", "Medicaid"]
CLAIM_STATUSES = ["Paid", "Pending", "Denied", "Partially Paid"]
VISIT_STATUSES = ["Completed", "No-Show", "Cancelled"]

START_DATE = datetime(2025, 1, 1)


def random_date(start, days_range):
    return start + timedelta(days=random.randint(0, days_range))


def build_providers(n=15):
    rows = []
    for i in range(1, n + 1):
        provider_id = f"P{str(i).zfill(4)}"
        rows.append((
            provider_id,
            f"Dr. Provider {i}",
            random.choice(SPECIALTIES),
            f"{random.randint(1000000000, 9999999999)}",  # npi_number
            random.choice(REGIONS),
            random_date(datetime(2015, 1, 1), 3000).date().isoformat(),
            random.choice([True, True, True, False]),  # active_flag, mostly active
        ))
    return rows


def build_visits(providers, n=250):
    rows = []
    for i in range(1, n + 1):
        visit_id = f"V{str(i).zfill(5)}"
        patient_id = f"PT{str(random.randint(1, 120)).zfill(5)}"
        provider = random.choice(providers)
        provider_id = provider[0]
        region_id = provider[4]
        visit_date = random_date(START_DATE, 400)
        status = random.choices(VISIT_STATUSES, weights=[85, 10, 5])[0]
        rows.append((
            visit_id,
            patient_id,
            provider_id,
            region_id,
            visit_date.date().isoformat(),
            random.choice(VISIT_TYPES),
            random.choice(DIAGNOSIS_CODES),
            status,
            (visit_date - timedelta(days=random.randint(0, 3))).isoformat(),  # created_at
        ))
    return rows


def build_claims(visits):
    rows = []
    claim_seq = 1
    for v in visits:
        visit_id, _, _, _, visit_date, _, _, visit_status, _ = v
        if visit_status != "Completed":
            continue
        # occasionally a visit generates 2 claims (e.g. resubmission)
        n_claims = 1 if random.random() > 0.08 else 2
        for _ in range(n_claims):
            claim_id = f"C{str(claim_seq).zfill(6)}"
            claim_seq += 1
            billed = round(random.uniform(85, 2400), 2)
            discount = round(billed * random.uniform(0, 0.15), 2)
            allowed = round(billed - discount, 2)
            status = random.choices(CLAIM_STATUSES, weights=[70, 12, 8, 10])[0]
            if status == "Paid":
                paid = allowed
            elif status == "Partially Paid":
                paid = round(allowed * random.uniform(0.4, 0.9), 2)
            elif status == "Denied":
                paid = 0.0
            else:  # Pending
                paid = 0.0
            claim_date = (datetime.fromisoformat(visit_date) + timedelta(days=random.randint(1, 21))).date().isoformat()
            rows.append((
                claim_id,
                visit_id,
                random.choice(PAYERS),
                billed,
                allowed,
                paid,
                discount,
                status,
                claim_date,
            ))
    return rows


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", choices=["dev", "prod"], required=True)
    args = parser.parse_args()

    db_path = f"{args.target}.duckdb"
    con = duckdb.connect(db_path)
    con.execute("CREATE SCHEMA IF NOT EXISTS raw")

    providers = build_providers()
    visits = build_visits(providers)
    claims = build_claims(visits)

    con.execute("DROP TABLE IF EXISTS raw.providers")
    con.execute("""
        CREATE TABLE raw.providers (
            provider_id VARCHAR, provider_name VARCHAR, specialty VARCHAR,
            npi_number VARCHAR, region_id VARCHAR, hire_date VARCHAR, active_flag BOOLEAN
        )
    """)
    con.executemany("INSERT INTO raw.providers VALUES (?,?,?,?,?,?,?)", providers)

    con.execute("DROP TABLE IF EXISTS raw.patient_visits")
    con.execute("""
        CREATE TABLE raw.patient_visits (
            visit_id VARCHAR, patient_id VARCHAR, provider_id VARCHAR, region_id VARCHAR,
            visit_date VARCHAR, visit_type VARCHAR, diagnosis_code VARCHAR,
            visit_status VARCHAR, created_at VARCHAR
        )
    """)
    con.executemany("INSERT INTO raw.patient_visits VALUES (?,?,?,?,?,?,?,?,?)", visits)

    con.execute("DROP TABLE IF EXISTS raw.insurance_claims")
    con.execute("""
        CREATE TABLE raw.insurance_claims (
            claim_id VARCHAR, visit_id VARCHAR, payer_name VARCHAR,
            billed_amount DOUBLE, allowed_amount DOUBLE, paid_amount DOUBLE,
            discount_amount DOUBLE, claim_status VARCHAR, claim_date VARCHAR
        )
    """)
    con.executemany("INSERT INTO raw.insurance_claims VALUES (?,?,?,?,?,?,?,?,?)", claims)

    print(f"[{args.target}] Loaded raw schema:")
    for tbl in ["providers", "patient_visits", "insurance_claims"]:
        count = con.execute(f"SELECT COUNT(*) FROM raw.{tbl}").fetchone()[0]
        print(f"  raw.{tbl}: {count} rows")

    con.close()


if __name__ == "__main__":
    main()
