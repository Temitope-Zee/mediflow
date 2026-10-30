"""Generate synthetic Riverside General Hospital data with planted quality problems."""
import argparse
import random
from datetime import date, datetime, timedelta
from pathlib import Path

import pandas as pd
from faker import Faker

fake = Faker("en_GB")
CLINICS = ["CARD-OP", "DERM-OP", "ORTH-OP", "DIAB-OP", "RESP-OP"]
WARDS = ["WARD-A1", "WARD-B2", "WARD-C3", "ICU-01"]


def make_patients(n):
    df = pd.DataFrame([{
        "patient_id": i,
        "mrn": f"RGH{100000 + i}",
        "first_name": fake.first_name(),
        "last_name": fake.last_name(),
        "date_of_birth": fake.date_of_birth(minimum_age=0, maximum_age=95),
        "sex": random.choice(["F", "M"]),
        "postcode": fake.postcode(),
        "registered_at": fake.date_time_between("-3y", "now"),
    } for i in range(1, n + 1)])
    dupes = df.sample(frac=0.02, random_state=1).copy()             # Planted: duplicate MRNs
    dupes["patient_id"] = range(n + 1, n + 1 + len(dupes))
    df = pd.concat([df, dupes], ignore_index=True)
    df.loc[df.sample(frac=0.01, random_state=2).index, "date_of_birth"] = None        # Planted
    df.loc[df.sample(frac=0.005, random_state=3).index, "date_of_birth"] = date(2030, 1, 1)  # Planted
    lower = df.sample(frac=0.2, random_state=4).index
    df.loc[lower, "postcode"] = df.loc[lower, "postcode"].str.lower()            # Planted
    return df


def make_appointments(n, patient_ids):
    df = pd.DataFrame([{
        "appointment_id": i,
        "patient_id": random.choice(patient_ids),
        "clinic_code": random.choice(CLINICS),
        "clinician_id": f"C{random.randint(1, 40):03d}",
        "scheduled_at": (s := fake.date_time_between("-2y", "now")),
        "booked_at": s - timedelta(days=random.randint(1, 90)),
        "status": random.choices(["Attended", "DNA", "Cancelled", "Rescheduled"],
                                 weights=[75, 10, 10, 5])[0],
    } for i in range(1, n + 1)])
    messy = df.sample(frac=0.15, random_state=5).index
    df.loc[messy, "status"] = df.loc[messy, "status"].str.upper()                # Planted
    df.loc[df.sample(frac=0.01, random_state=6).index, "patient_id"] = 999999    # Planted: orphans
    return df


def make_admissions(n, patient_ids):
    pool = random.sample(patient_ids, k=len(patient_ids) // 3)  # repeat patients create readmissions
    rows = []
    for i in range(1, n + 1):
        admitted = fake.date_time_between("-2y", "now")
        los = random.choices([0, 1, 2, 3, 5, 8, 14, 30], weights=[10, 20, 20, 15, 15, 10, 7, 3])[0]
        discharged = admitted + timedelta(days=los, hours=random.randint(1, 20))
        rows.append({
            "admission_id": i,
            "patient_id": random.choice(pool),
            "ward_code": random.choice(WARDS),
            "admission_type": random.choices(["Emergency", "Elective"], weights=[60, 40])[0],
            "admitted_at": admitted,
            "discharged_at": discharged if discharged < datetime.now() else None,
            "discharge_destination": random.choice(["Home", "Care home", "Other hospital"]),
        })
    df = pd.DataFrame(rows)
    bad = df.sample(frac=0.01, random_state=7).index                              # Planted
    df.loc[bad, "discharged_at"] = df.loc[bad, "admitted_at"] - timedelta(days=1)
    return df


def make_invoices(admissions):
    rows = []
    for a in admissions.dropna(subset=["discharged_at"]).itertuples():
        invoice_date = a.discharged_at.date() + timedelta(days=random.randint(1, 10))
        paid = invoice_date + timedelta(days=random.randint(5, 90))
        rows.append({
            "invoice_id": f"INV{a.admission_id:06d}",
            "patient_id": a.patient_id,
            "admission_id": a.admission_id,
            "payer_type": random.choices(["NHS", "Insurer", "Self-pay"], weights=[70, 20, 10])[0],
            "amount_gbp": round(random.uniform(400, 12000), 2),
            "invoice_date": invoice_date,
            "due_date": invoice_date + timedelta(days=30),
            "paid_date": paid if random.random() < 0.8 and paid <= date.today() else None,
        })
    df = pd.DataFrame(rows)
    neg = df.sample(frac=0.01, random_state=8).index
    df.loc[neg, "amount_gbp"] = -df.loc[neg, "amount_gbp"]                        # Planted
    early = df.sample(frac=0.01, random_state=9).index                            # Planted
    df.loc[early, "paid_date"] = df.loc[early, "invoice_date"] - timedelta(days=3)
    return df


def make_units():
    clinics = [{"unit_code": c, "unit_name": f"{c[:4].title()} Outpatients", "unit_type": "Clinic",
                "specialty": c[:4], "bed_count": None} for c in CLINICS]
    wards = [{"unit_code": w, "unit_name": f"Ward {w[-2:]}", "unit_type": "Ward",
              "specialty": "General", "bed_count": 12 if w.startswith("ICU") else 28} for w in WARDS]
    return pd.DataFrame(clinics + wards)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-date", required=True)
    parser.add_argument("--out-dir", default="/opt/airflow/data/landing")
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()
    random.seed(args.seed)
    Faker.seed(args.seed)

    out = Path(args.out_dir) / args.run_date
    out.mkdir(parents=True, exist_ok=True)
    patients = make_patients(2000)
    ids = patients["patient_id"].tolist()
    admissions = make_admissions(1500, ids)
    files = {
        "patients": patients,
        "appointments": make_appointments(8000, ids),
        "admissions": admissions,
        "invoices": make_invoices(admissions),
        "reference_units": make_units(),
    }
    for name, df in files.items():
        df.to_csv(out / f"{name}.csv", index=False)
        print(f"{name}: {len(df)} rows")
