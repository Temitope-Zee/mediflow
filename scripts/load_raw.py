"""Load landing CSVs into the raw schema as text, unchanged."""
import argparse
import io
import os
from pathlib import Path

import pandas as pd
import psycopg2

DSN = os.getenv("WAREHOUSE_DSN",
                "host=warehouse port=5432 dbname=mediflow user=mediflow password=mediflow")


def load_file(cur, path, run_date):
    table = path.stem
    df = pd.read_csv(path, dtype=str, keep_default_na=False)
    df["_source_file"] = path.name
    df["_run_date"] = run_date
    columns = ", ".join(f'"{c}" text' for c in df.columns)
    cur.execute(f"drop table if exists raw.{table}")
    cur.execute(f"create table raw.{table} ({columns})")
    buffer = io.StringIO()
    df.to_csv(buffer, index=False, header=False)
    buffer.seek(0)
    cur.copy_expert(f"copy raw.{table} from stdin with (format csv)", buffer)
    return len(df)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-date", required=True)
    parser.add_argument("--landing-dir", default="/opt/airflow/data/landing")
    args = parser.parse_args()

    folder = Path(args.landing_dir) / args.run_date
    files = sorted(folder.glob("*.csv"))
    if not files:
        raise FileNotFoundError(f"No CSV files in {folder}")
    with psycopg2.connect(DSN) as conn, conn.cursor() as cur:
        cur.execute("create schema if not exists raw")
        for path in files:
            print(f"raw.{path.stem}: {load_file(cur, path, args.run_date)} rows")
