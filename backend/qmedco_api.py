#!/usr/bin/env python3
"""
QmedCO backend API.

A small dependency-free REST service backed by SQLite. It is designed for local
development first, but the data model and endpoints are intentionally close to
what the Flutter app needs: auth, profiles, doctors, departments, appointments,
lab bookings, consultations, emergencies, messages, and health tips.
"""

from __future__ import annotations

import argparse
import base64
import datetime as dt
import hashlib
import hmac
import json
import os
import secrets
import sqlite3
import time
import traceback
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlparse


APP_DIR = Path(__file__).resolve().parent
DATA_DIR = APP_DIR / "data"
DB_PATH = DATA_DIR / "qmedco.sqlite3"
TOKEN_TTL_SECONDS = 60 * 60 * 24 * 30
SECRET = os.environ.get("QMEDCO_SECRET", "dev-qmedco-secret-change-me").encode()
STAFF_ROLES = {"admin", "super_admin", "doctor", "nurse", "lab_tech", "receptionist"}
ADMIN_ROLES = {"admin", "super_admin"}
CLINICAL_ROLES = {"admin", "super_admin", "doctor", "nurse"}
APPOINTMENT_STATUSES = {
    "requested",
    "approved",
    "confirmed",
    "checked_in",
    "in_progress",
    "completed",
    "cancelled",
    "no_show",
    "rescheduled",
    "pending",
    "upcoming",
}
LAB_STATUSES = {"scheduled", "sample_collected", "processing", "result_ready", "completed", "cancelled", "pending", "confirmed"}
PAYMENT_STATUSES = {"pending", "paid", "failed", "refunded"}
PASSWORD_RESET_TOKEN_TTL = 60 * 60 * 24


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat()


def json_dumps(data: Any) -> bytes:
    return json.dumps(data, ensure_ascii=False, separators=(",", ":")).encode()


def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), 120_000)
    return f"pbkdf2_sha256${salt}${base64.b64encode(digest).decode()}"


def verify_password(password: str, stored: str) -> bool:
    try:
        algorithm, salt, digest = stored.split("$", 2)
    except ValueError:
        return False
    if algorithm != "pbkdf2_sha256":
        return False
    candidate = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), 120_000)
    return hmac.compare_digest(base64.b64encode(candidate).decode(), digest)


def make_token(user_id: int) -> str:
    expires = int(time.time()) + TOKEN_TTL_SECONDS
    nonce = secrets.token_urlsafe(12)
    payload = f"{user_id}.{expires}.{nonce}"
    signature = hmac.new(SECRET, payload.encode(), hashlib.sha256).hexdigest()
    token = f"{payload}.{signature}".encode()
    return base64.urlsafe_b64encode(token).decode()


def parse_token(token: str) -> int | None:
    try:
        raw = base64.urlsafe_b64decode(token.encode()).decode()
        user_id, expires, nonce, signature = raw.rsplit(".", 3)
    except Exception:
        return None
    payload = f"{user_id}.{expires}.{nonce}"
    expected = hmac.new(SECRET, payload.encode(), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(signature, expected):
        return None
    if int(expires) < int(time.time()):
        return None
    return int(user_id)


def db() -> sqlite3.Connection:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def row_to_dict(row: sqlite3.Row | None) -> dict[str, Any] | None:
    return dict(row) if row is not None else None


def rows_to_list(rows: list[sqlite3.Row]) -> list[dict[str, Any]]:
    return [dict(row) for row in rows]


def normalize_time_string(value: str) -> str:
    text = str(value or "").strip()
    if not text:
        return ""
    formats = ["%H:%M", "%I:%M %p", "%I:%M%p", "%H:%M:%S"]
    for fmt in formats:
        try:
            return dt.datetime.strptime(text, fmt).strftime("%H:%M")
        except ValueError:
            continue
    return text


def get_weekday(date_text: str) -> int:
    try:
        date_obj = dt.datetime.fromisoformat(date_text).date()
        return date_obj.isoweekday()
    except ValueError:
        return 0


def ensure_column(conn: sqlite3.Connection, table: str, column: str, definition: str) -> None:
    columns = {row["name"] for row in conn.execute(f"PRAGMA table_info({table})")}
    if column not in columns:
        conn.execute(f"ALTER TABLE {table} ADD COLUMN {column} {definition}")


def init_db() -> None:
    with db() as conn:
        conn.executescript(
            """
            CREATE TABLE IF NOT EXISTS users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              full_name TEXT NOT NULL,
              email TEXT NOT NULL UNIQUE,
              password_hash TEXT NOT NULL,
              phone TEXT DEFAULT '',
              date_of_birth TEXT DEFAULT '',
              location TEXT DEFAULT '',
              blood_group TEXT DEFAULT '',
              role TEXT NOT NULL DEFAULT 'patient',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS departments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              description TEXT NOT NULL,
              image_path TEXT NOT NULL,
              services TEXT NOT NULL,
              created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS doctors (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              department_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              specialty TEXT NOT NULL,
              rating REAL NOT NULL DEFAULT 4.5,
              reviews INTEGER NOT NULL DEFAULT 0,
              image_path TEXT NOT NULL,
              available INTEGER NOT NULL DEFAULT 1,
              experience TEXT NOT NULL DEFAULT '',
              fee INTEGER NOT NULL DEFAULT 50000,
              location TEXT NOT NULL DEFAULT 'QmedCO Main Clinic',
              created_at TEXT NOT NULL,
              FOREIGN KEY (department_id) REFERENCES departments(id)
            );

            DELETE FROM doctors
            WHERE id NOT IN (SELECT MIN(id) FROM doctors GROUP BY name);

            CREATE UNIQUE INDEX IF NOT EXISTS idx_doctors_name ON doctors(name);

            CREATE TABLE IF NOT EXISTS appointments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              doctor_id INTEGER NOT NULL,
              department_id INTEGER NOT NULL,
              appointment_date TEXT NOT NULL,
              appointment_time TEXT NOT NULL,
              room TEXT DEFAULT '',
              reason TEXT DEFAULT '',
              notes TEXT DEFAULT '',
              status TEXT NOT NULL DEFAULT 'upcoming',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users(id),
              FOREIGN KEY (doctor_id) REFERENCES doctors(id),
              FOREIGN KEY (department_id) REFERENCES departments(id),
              UNIQUE (doctor_id, appointment_date, appointment_time)
            );

            CREATE TABLE IF NOT EXISTS lab_tests (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              description TEXT NOT NULL,
              price INTEGER NOT NULL,
              duration TEXT NOT NULL,
              preparation TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS lab_bookings (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              lab_test_id INTEGER NOT NULL,
              booking_date TEXT NOT NULL,
              booking_time TEXT NOT NULL,
              notes TEXT DEFAULT '',
              status TEXT NOT NULL DEFAULT 'scheduled',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users(id),
              FOREIGN KEY (lab_test_id) REFERENCES lab_tests(id)
            );

            CREATE TABLE IF NOT EXISTS consultations (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              doctor_id INTEGER NOT NULL,
              mode TEXT NOT NULL,
              symptoms TEXT DEFAULT '',
              status TEXT NOT NULL DEFAULT 'requested',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users(id),
              FOREIGN KEY (doctor_id) REFERENCES doctors(id)
            );

            CREATE TABLE IF NOT EXISTS emergency_requests (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER,
              patient_name TEXT NOT NULL,
              phone TEXT NOT NULL,
              location TEXT NOT NULL,
              emergency_type TEXT NOT NULL,
              notes TEXT DEFAULT '',
              status TEXT NOT NULL DEFAULT 'received',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users(id)
            );

            CREATE TABLE IF NOT EXISTS messages (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              doctor_id INTEGER,
              direction TEXT NOT NULL DEFAULT 'outbound',
              body TEXT NOT NULL,
              created_at TEXT NOT NULL,
              read_at TEXT,
              FOREIGN KEY (user_id) REFERENCES users(id),
              FOREIGN KEY (doctor_id) REFERENCES doctors(id)
            );

            CREATE TABLE IF NOT EXISTS chat_threads (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              specialty TEXT NOT NULL,
              last_message TEXT NOT NULL,
              display_time TEXT NOT NULL,
              unread_count INTEGER NOT NULL DEFAULT 0,
              avatar_icon TEXT NOT NULL,
              avatar_color TEXT NOT NULL,
              category TEXT NOT NULL,
              is_online INTEGER NOT NULL DEFAULT 0,
              is_emergency INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS health_tips (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              body TEXT NOT NULL,
              category TEXT NOT NULL,
              image_path TEXT DEFAULT '',
              created_at TEXT NOT NULL
            );

            DELETE FROM health_tips
            WHERE id NOT IN (SELECT MIN(id) FROM health_tips GROUP BY title);

            CREATE UNIQUE INDEX IF NOT EXISTS idx_health_tips_title ON health_tips(title);

            CREATE TABLE IF NOT EXISTS lab_packages (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              tests INTEGER NOT NULL,
              turnaround TEXT NOT NULL,
              price INTEGER NOT NULL,
              badge TEXT NOT NULL,
              badge_color TEXT NOT NULL,
              icon TEXT NOT NULL,
              created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS lab_locations (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              address TEXT NOT NULL,
              rating REAL NOT NULL,
              distance TEXT NOT NULL,
              open INTEGER NOT NULL DEFAULT 1,
              hours TEXT NOT NULL,
              specialties TEXT NOT NULL,
              created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS lab_results (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER,
              test_name TEXT NOT NULL,
              lab_name TEXT NOT NULL,
              result_date TEXT NOT NULL,
              status TEXT NOT NULL,
              doctor_reviewed INTEGER NOT NULL DEFAULT 0,
              result_value TEXT DEFAULT '',
              notes TEXT DEFAULT '',
              created_at TEXT NOT NULL,
              UNIQUE (user_id, test_name, result_date),
              FOREIGN KEY (user_id) REFERENCES users(id)
            );

            CREATE TABLE IF NOT EXISTS password_reset_tokens (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              token TEXT NOT NULL UNIQUE,
              expires_at TEXT NOT NULL,
              used INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users(id)
            );

            CREATE TABLE IF NOT EXISTS invoices (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              appointment_id INTEGER,
              lab_booking_id INTEGER,
              description TEXT NOT NULL,
              amount INTEGER NOT NULL,
              currency TEXT NOT NULL DEFAULT 'TZS',
              status TEXT NOT NULL DEFAULT 'pending',
              due_date TEXT,
              paid_at TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users(id),
              FOREIGN KEY (appointment_id) REFERENCES appointments(id),
              FOREIGN KEY (lab_booking_id) REFERENCES lab_bookings(id)
            );

            CREATE TABLE IF NOT EXISTS payments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              invoice_id INTEGER NOT NULL,
              user_id INTEGER NOT NULL,
              amount INTEGER NOT NULL,
              currency TEXT NOT NULL DEFAULT 'TZS',
              method TEXT NOT NULL DEFAULT 'card',
              provider TEXT NOT NULL DEFAULT 'local',
              transaction_reference TEXT NOT NULL,
              status TEXT NOT NULL DEFAULT 'paid',
              created_at TEXT NOT NULL,
              FOREIGN KEY (invoice_id) REFERENCES invoices(id),
              FOREIGN KEY (user_id) REFERENCES users(id)
            );

            CREATE TABLE IF NOT EXISTS doctor_availability (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              doctor_id INTEGER NOT NULL,
              weekday INTEGER NOT NULL,
              start_time TEXT NOT NULL,
              end_time TEXT NOT NULL,
              slot_minutes INTEGER NOT NULL DEFAULT 30,
              max_patients INTEGER NOT NULL DEFAULT 1,
              active INTEGER NOT NULL DEFAULT 1,
              UNIQUE (doctor_id, weekday, start_time, end_time),
              FOREIGN KEY (doctor_id) REFERENCES doctors(id)
            );

            CREATE TABLE IF NOT EXISTS doctor_blocked_slots (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              doctor_id INTEGER NOT NULL,
              block_date TEXT NOT NULL,
              start_time TEXT NOT NULL,
              end_time TEXT NOT NULL,
              reason TEXT DEFAULT '',
              created_at TEXT NOT NULL,
              UNIQUE (doctor_id, block_date, start_time, end_time),
              FOREIGN KEY (doctor_id) REFERENCES doctors(id)
            );

            CREATE TABLE IF NOT EXISTS patient_vitals (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              recorded_by INTEGER,
              temperature TEXT DEFAULT '',
              blood_pressure TEXT DEFAULT '',
              pulse TEXT DEFAULT '',
              weight TEXT DEFAULT '',
              height TEXT DEFAULT '',
              notes TEXT DEFAULT '',
              created_at TEXT NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users(id),
              FOREIGN KEY (recorded_by) REFERENCES users(id)
            );

            CREATE TABLE IF NOT EXISTS medical_records (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              doctor_id INTEGER,
              appointment_id INTEGER,
              record_type TEXT NOT NULL DEFAULT 'visit_note',
              title TEXT NOT NULL,
              diagnosis TEXT DEFAULT '',
              notes TEXT DEFAULT '',
              allergies TEXT DEFAULT '',
              attachments TEXT DEFAULT '[]',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users(id),
              FOREIGN KEY (doctor_id) REFERENCES doctors(id),
              FOREIGN KEY (appointment_id) REFERENCES appointments(id)
            );

            CREATE TABLE IF NOT EXISTS prescriptions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              doctor_id INTEGER NOT NULL,
              appointment_id INTEGER,
              medication TEXT NOT NULL,
              dosage TEXT NOT NULL,
              frequency TEXT NOT NULL,
              duration TEXT NOT NULL,
              instructions TEXT DEFAULT '',
              status TEXT NOT NULL DEFAULT 'active',
              created_at TEXT NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users(id),
              FOREIGN KEY (doctor_id) REFERENCES doctors(id),
              FOREIGN KEY (appointment_id) REFERENCES appointments(id)
            );

            CREATE TABLE IF NOT EXISTS notifications (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              title TEXT NOT NULL,
              body TEXT NOT NULL,
              channel TEXT NOT NULL DEFAULT 'in_app',
              type TEXT NOT NULL DEFAULT 'general',
              read_at TEXT,
              created_at TEXT NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users(id)
            );

            CREATE TABLE IF NOT EXISTS audit_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              actor_user_id INTEGER,
              action TEXT NOT NULL,
              entity_type TEXT NOT NULL,
              entity_id INTEGER,
              metadata TEXT NOT NULL DEFAULT '{}',
              created_at TEXT NOT NULL,
              FOREIGN KEY (actor_user_id) REFERENCES users(id)
            );
            """
        )
        ensure_column(conn, "appointments", "room", "TEXT DEFAULT ''")
        ensure_column(conn, "doctors", "user_id", "INTEGER")
        ensure_column(conn, "lab_results", "result_value", "TEXT DEFAULT ''")
        ensure_column(conn, "lab_results", "notes", "TEXT DEFAULT ''")
        seed_data(conn)


def seed_data(conn: sqlite3.Connection) -> None:
    now = utc_now()
    departments = [
        ("Pediatrics", "Children & infant care", "lib/assets/Pediatrics.jpg", ["Initial Consultation", "Vaccination", "Growth Monitoring", "Follow-up Visits"]),
        ("Obstetrics & Gynecology", "Women's health & maternity", "lib/assets/Obstetrics_Gynecology.jpg", ["Antenatal Clinic", "Ultrasound", "Family Planning", "Follow-up Visits"]),
        ("Dentistry", "Dental & oral health care", "lib/assets/Dental.jpg", ["Dental Checkup", "Cleaning", "Fillings", "Tooth Extraction"]),
        ("Ophthalmology", "Eye & vision care", "lib/assets/Eye.jpg", ["Vision Test", "Eye Pressure Check", "Diagnosis & Testing", "Treatment Plans"]),
        ("General Medicine", "General outpatient consultation and primary care.", "lib/assets/Pediatrics.jpg", ["General Consultation", "Diagnosis", "Medication Review", "Follow-up Visits"]),
        ("Cardiology", "Heart screening, diagnosis, and cardiac care.", "lib/assets/Eye.jpg", ["Heart Screening", "ECG", "Blood Pressure Review", "Follow-up Visits"]),
    ]
    for name, description, image_path, services in departments:
        conn.execute(
            """
            INSERT INTO departments (name, description, image_path, services, created_at)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(name) DO UPDATE SET
              description = excluded.description,
              image_path = excluded.image_path,
              services = excluded.services
            """,
            (name, description, image_path, json.dumps(services), now),
        )

    department_ids = {row["name"]: row["id"] for row in conn.execute("SELECT id, name FROM departments")}
    doctors = [
        (department_ids["Pediatrics"], "Dr. Hyasinta Kessy", "Pediatrics", 4.9, 128, "lib/assets/pediatricsdoctot.png", 1, "11 yrs", 15000),
        (department_ids["Obstetrics & Gynecology"], "Dr. Anna Sikawa", "Obstetrics & Gynecology", 4.7, 95, "lib/assets/obstetrics_gynecologydoctor.jpg", 1, "9 yrs", 20000),
        (department_ids["Ophthalmology"], "Dr. Shaziri Mustapha", "Ophthalmology", 4.8, 112, "lib/assets/eyedoctor.png", 0, "7 yrs", 18000),
        (department_ids["Dentistry"], "Dr. Allan Michael", "Dentistry", 4.6, 80, "lib/assets/dentaldoctor.jpg", 1, "5 yrs", 12000),
        (department_ids["Pediatrics"], "Dr. Sophia Mollel", "Pediatrics", 4.8, 91, "lib/assets/Sophia Mollel.png", 1, "8 yrs", 15000),
        (department_ids["Ophthalmology"], "Dr. Nathani Temu", "Ophthalmology", 4.9, 102, "lib/assets/Nathani Temu.jpeg", 1, "12 yrs", 18000),
        (department_ids["Obstetrics & Gynecology"], "Dr. Jesca Tesha", "Obstetrics & Gynecology", 4.7, 88, "lib/assets/Jesca Tesha.jpg", 0, "10 yrs", 20000),
        (department_ids["Dentistry"], "Dr. Benjamin Mushi", "Dentistry", 4.6, 75, "lib/assets/Benjamin Mushi.jpeg", 1, "6 yrs", 12000),
        (department_ids["Ophthalmology"], "Dr. Sarah Kimani", "Eye Clinic", 4.7, 64, "lib/assets/eyedoctor.png", 1, "6 yrs", 18000),
        (department_ids["Pediatrics"], "Dr. James Otieno", "Pediatric Doctor", 4.6, 58, "lib/assets/pediatricsdoctot.png", 0, "8 yrs", 15000),
    ]
    for item in doctors:
        conn.execute(
            """
            INSERT INTO doctors
            (department_id, name, specialty, rating, reviews, image_path, available, experience, fee, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(name) DO UPDATE SET
              department_id = excluded.department_id,
              specialty = excluded.specialty,
              rating = excluded.rating,
              reviews = excluded.reviews,
              image_path = excluded.image_path,
              available = excluded.available,
              experience = excluded.experience,
              fee = excluded.fee
            """,
            (*item, now),
        )

    lab_tests = [
        ("Complete Blood Count", "Checks red cells, white cells, and platelets.", 15000, "20 min", "No special preparation required."),
        ("Pelvic Ultrasound", "Pelvic imaging for women's health review.", 35000, "30 min", "Drink water before the scan if instructed."),
        ("Vision Screening", "Basic vision and eye health screening.", 10000, "15 min", "Bring current glasses or contact lens prescription."),
        ("Malaria RDT", "Rapid malaria parasite screening.", 8000, "10 min", "No special preparation required."),
        ("Dental OPG X-Ray", "Panoramic dental X-ray for oral diagnosis.", 20000, "25 min", "Remove metal jewelry around the head and neck."),
        ("Hemoglobin Test", "Measures hemoglobin concentration in blood.", 12000, "20 min", "No special preparation required."),
        ("Blood Sugar", "Measures current blood glucose level.", 10000, "20 min", "Fasting may be requested for fasting glucose."),
        ("Pregnancy Test", "Urine or blood pregnancy screening.", 15000, "30 min", "No special preparation required."),
        ("Liver Function Test", "Assesses liver enzymes and proteins.", 35000, "4 hrs", "Avoid alcohol for 24 hours before testing."),
    ]
    for test in lab_tests:
        conn.execute(
            """
            INSERT INTO lab_tests (name, description, price, duration, preparation)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(name) DO UPDATE SET
              description = excluded.description,
              price = excluded.price,
              duration = excluded.duration,
              preparation = excluded.preparation
            """,
            test,
        )

    tips = [
        ("Stay hydrated", "Drink enough clean water throughout the day, especially in hot weather.", "Wellness", "lib/assets/healthtip1.jpg"),
        ("Do not skip medication", "Take prescribed medicine on schedule and ask a clinician before stopping.", "Medication", "lib/assets/healthtip2.jpg"),
        ("Book checkups early", "Routine checkups help detect health issues before they become serious.", "Prevention", "lib/assets/healthtip3.jpg"),
        ("Stay Well Hydrated", "Drink at least 8-10 glasses of water daily. Water helps transport nutrients to your baby and prevents dehydration during pregnancy.", "Pregnancy", ""),
        ("Eat a Nutritious Diet", "Eat a balanced diet rich in folic acid, iron, and calcium. Include green vegetables, legumes, eggs, and dairy products every day.", "Pregnancy", ""),
        ("Attend All Antenatal Visits", "Attend all antenatal clinic visits. Regular check-ups help detect any risks early and keep both mother and baby safe.", "Pregnancy", ""),
        ("Rest and Breathe Well", "Get 7-9 hours of sleep and rest when tired. Avoid heavy lifting and reduce stress through gentle walks or breathing exercises.", "Pregnancy", ""),
        ("Avoid Smoking and Alcohol", "Avoid alcohol and smoking completely. These can cause serious harm to your baby, including low birth weight and developmental problems.", "Pregnancy", ""),
        ("Take Prenatal Vitamins", "Take prenatal vitamins prescribed by your doctor, especially folic acid before and during pregnancy.", "Pregnancy", ""),
        ("Vaccinate on Schedule", "Follow the national immunisation schedule. Vaccines protect children from dangerous diseases like measles, polio, and tuberculosis.", "Children", ""),
        ("Drink Clean, Safe Water", "Give children clean, safe drinking water at all times. Dirty water causes diarrhoea, a leading cause of child illness.", "Children", ""),
        ("Good Nutrition for Growth", "Feed children a variety of foods: vegetables, fruits, proteins, and grains. Good nutrition supports brain development and strong bones.", "Children", ""),
        ("Wash Hands Regularly", "Teach children to wash hands with soap before eating and after using the toilet. This simple habit prevents many infections.", "Children", ""),
        ("Ensure Enough Sleep", "Children need 9-12 hours of sleep per night. Adequate sleep supports healthy growth, learning, and a strong immune system.", "Children", ""),
        ("Encourage Active Play", "Encourage at least 60 minutes of active play daily. Physical activity builds strength, coordination, and mental wellbeing.", "Children", ""),
        ("Protect Eyes from the Sun", "Wear sunglasses with UV protection when outdoors. Too much UV exposure can damage the eyes and increase cataract risk.", "Eye Care", ""),
        ("Rest Your Eyes - 20-20-20", "Every 20 minutes, look at something 20 feet away for 20 seconds to reduce eye strain and headaches from screen use.", "Eye Care", ""),
        ("Get an Annual Eye Exam", "Get a comprehensive eye exam at least once a year. Many eye conditions have no early symptoms and are caught through testing.", "Eye Care", ""),
        ("Eat Well for Eye Health", "Eat foods rich in vitamins A, C, and E such as carrots, spinach, and citrus fruits.", "Eye Care", ""),
        ("Do Not Touch Eyes with Dirty Hands", "Avoid touching or rubbing your eyes with unwashed hands. This can transfer bacteria and viruses that cause infections.", "Eye Care", ""),
        ("Read in Good Lighting", "Always read or work in well-lit areas. Poor lighting forces your eyes to work harder, causing fatigue and strain.", "Eye Care", ""),
        ("Brush Teeth Twice a Day", "Brush your teeth in the morning and before bed using fluoride toothpaste to remove plaque.", "Dental", ""),
        ("Choose Water Over Sugary Drinks", "Drink water instead of sugary drinks. Sugar feeds harmful bacteria that produce acids and damage tooth enamel.", "Dental", ""),
        ("Visit Your Dentist Regularly", "Visit your dentist every 6 months for a check-up and professional cleaning. Early detection saves teeth and reduces pain.", "Dental", ""),
        ("Limit Sugar in Your Diet", "Limit sweets, biscuits, and sticky foods. If you eat sugary snacks, rinse your mouth with water afterwards.", "Dental", ""),
        ("Children's Teeth - Start Early", "Start cleaning your baby's gums before teeth appear using a clean damp cloth. Begin brushing as soon as the first tooth comes in.", "Dental", ""),
        ("Quit Smoking for Better Oral Health", "Smoking stains teeth, causes bad breath, and increases the risk of gum disease and oral cancer.", "Dental", ""),
    ]
    for tip in tips:
        conn.execute(
            """
            INSERT INTO health_tips (title, body, category, image_path, created_at)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(title) DO UPDATE SET
              body = excluded.body,
              category = excluded.category,
              image_path = excluded.image_path
            """,
            (*tip, now),
        )

    seed_extra_mock_data(conn, now, department_ids)


def seed_extra_mock_data(conn: sqlite3.Connection, now: str, department_ids: dict[str, int]) -> None:
    staff_users = [
        ("QmedCO Admin", "admin@qmedco.test", "admin"),
        ("Dr. Hyasinta Kessy", "doctor@qmedco.test", "doctor"),
        ("QmedCO Nurse", "nurse@qmedco.test", "nurse"),
        ("QmedCO Lab Tech", "lab@qmedco.test", "lab_tech"),
        ("QmedCO Reception", "reception@qmedco.test", "receptionist"),
    ]
    for full_name, email, role in staff_users:
        conn.execute(
            """
            INSERT INTO users
            (full_name, email, password_hash, phone, date_of_birth, location, blood_group, role, created_at, updated_at)
            VALUES (?, ?, ?, '', '', 'QmedCO Main Clinic', '', ?, ?, ?)
            ON CONFLICT(email) DO UPDATE SET
              full_name = excluded.full_name,
              role = excluded.role,
              location = excluded.location,
              updated_at = excluded.updated_at
            """,
            (full_name, email, hash_password("secret123"), role, now, now),
        )

    demo_email = "patient@example.com"
    conn.execute(
        """
        INSERT INTO users
        (full_name, email, password_hash, phone, date_of_birth, location, blood_group, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(email) DO UPDATE SET
          full_name = excluded.full_name,
          phone = excluded.phone,
          location = excluded.location,
          blood_group = excluded.blood_group,
          updated_at = excluded.updated_at
        """,
        (
            "QmedCO Demo Patient",
            demo_email,
            hash_password("secret123"),
            "+255 712 345 678",
            "1998-04-12",
            "Dar es Salaam, Tanzania",
            "O+",
            now,
            now,
        ),
    )
    demo_user_id = conn.execute("SELECT id FROM users WHERE email = ?", (demo_email,)).fetchone()["id"]
    doctor_ids = {row["name"]: row["id"] for row in conn.execute("SELECT id, name FROM doctors")}
    doctor_user_id = conn.execute("SELECT id FROM users WHERE email = 'doctor@qmedco.test'").fetchone()["id"]
    conn.execute("UPDATE doctors SET user_id = ? WHERE name = ?", (doctor_user_id, "Dr. Hyasinta Kessy"))

    for doctor_id in doctor_ids.values():
        for weekday in range(1, 6):
            conn.execute(
                """
                INSERT OR IGNORE INTO doctor_availability
                (doctor_id, weekday, start_time, end_time, slot_minutes, max_patients, active)
                VALUES (?, ?, '09:00', '16:00', 30, 1, 1)
                """,
                (doctor_id, weekday),
            )

    appointments = [
        ("Dr. Hyasinta Kessy", department_ids["Pediatrics"], "2026-04-28", "10:00 AM", "Room 101", "confirmed", "Pediatric consultation"),
        ("Dr. Anna Sikawa", department_ids["Obstetrics & Gynecology"], "2026-04-30", "09:40 AM", "Room 205", "pending", "Antenatal review"),
        ("Dr. Shaziri Mustapha", department_ids["Ophthalmology"], "2026-04-10", "08:00 AM", "Room 303", "completed", "Vision follow-up"),
        ("Dr. Allan Michael", department_ids["Dentistry"], "2026-04-01", "11:50 AM", "Room 110", "completed", "Dental checkup"),
        ("Dr. Anna Sikawa", department_ids["Obstetrics & Gynecology"], "2026-04-05", "17:40", "Room 205", "cancelled", "Gynecology consultation"),
    ]
    for doctor_name, department_id, date, slot, room, status, reason in appointments:
        conn.execute(
            """
            INSERT OR IGNORE INTO appointments
            (user_id, doctor_id, department_id, appointment_date, appointment_time, room, reason, status, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (demo_user_id, doctor_ids[doctor_name], department_id, date, slot, room, reason, status, now, now),
        )

    chat_threads = [
        ("Dr. Sarah Kimani", "Eye Clinic", "Your prescription is ready for collection.", "10:24 AM", 3, "eye", "#1565C0", "doctors", 1, 0),
        ("Dental Care Centre", "Dental Clinic", "Reminder: Checkup tomorrow at 9:00 AM. Please arrive 10 mins early.", "Yesterday", 1, "tooth", "#00ACC1", "clinics", 0, 0),
        ("Mother & Child Clinic", "Maternity Clinic", "Your antenatal results are in. Please review at your convenience.", "Mon", 0, "heart", "#7B1FA2", "clinics", 1, 0),
        ("Dr. James Otieno", "Pediatric Doctor", "The vaccination schedule has been updated. Check your app.", "Sun", 2, "vaccine", "#388E3C", "doctors", 0, 0),
        ("Eye Clinic", "Ophthalmology", "New frames available in our optical shop. Visit us today!", "Sat", 0, "glasses", "#0288D1", "clinics", 0, 0),
        ("Appointment Reminder", "System", "Dental Checkup in 1 hour. Please confirm your attendance.", "Now", 1, "bell", "#F57C00", "reminders", 0, 0),
        ("Emergency Line", "Emergency  ·  Available 24/7", "Tap to call the emergency hotline.", "--", 0, "ambulance", "#EF5350", "emergency", 1, 1),
    ]
    for thread in chat_threads:
        conn.execute(
            """
            INSERT INTO chat_threads
            (name, specialty, last_message, display_time, unread_count, avatar_icon, avatar_color, category, is_online, is_emergency, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(name) DO UPDATE SET
              specialty = excluded.specialty,
              last_message = excluded.last_message,
              display_time = excluded.display_time,
              unread_count = excluded.unread_count,
              avatar_icon = excluded.avatar_icon,
              avatar_color = excluded.avatar_color,
              category = excluded.category,
              is_online = excluded.is_online,
              is_emergency = excluded.is_emergency
            """,
            (*thread, now),
        )

    for name, _, message, _, _, _, _, category, _, _ in chat_threads:
        doctor_id = doctor_ids.get(name)
        conn.execute(
            """
            INSERT INTO messages (user_id, doctor_id, direction, body, created_at)
            SELECT ?, ?, ?, ?, ?
            WHERE NOT EXISTS (
              SELECT 1 FROM messages
              WHERE user_id = ? AND COALESCE(doctor_id, 0) = COALESCE(?, 0) AND body = ?
            )
            """,
            (
                demo_user_id,
                doctor_id,
                "inbound" if category != "reminders" else "system",
                message,
                now,
                demo_user_id,
                doctor_id,
                message,
            ),
        )

    packages = [
        ("Full Body Checkup", 42, "24 hrs", 120000, "POPULAR", "#2B6CB0", "monitor_heart"),
        ("Diabetes Profile", 12, "4 hrs", 45000, "FAST", "#FF7043", "bloodtype"),
        ("Pregnancy Care", 18, "12 hrs", 80000, "NEW", "#7E57C2", "pregnant_woman"),
        ("Heart Screening", 15, "8 hrs", 95000, "VITAL", "#EF5350", "favorite"),
    ]
    for package in packages:
        conn.execute(
            """
            INSERT INTO lab_packages (name, tests, turnaround, price, badge, badge_color, icon, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(name) DO UPDATE SET
              tests = excluded.tests,
              turnaround = excluded.turnaround,
              price = excluded.price,
              badge = excluded.badge,
              badge_color = excluded.badge_color,
              icon = excluded.icon
            """,
            (*package, now),
        )

    labs = [
        ("Aga Khan Hospital Lab", "Ocean Road, Dar es Salaam", 4.9, "1.2 km", 1, "Open until 10:00 PM", ["Blood", "Imaging", "Pathology"]),
        ("Muhimbili Diagnostics", "Upanga, Dar es Salaam", 4.6, "2.8 km", 1, "Open until 8:00 PM", ["Ultrasound", "X-Ray", "ECG"]),
        ("Regency Medical Centre", "Masaki Peninsula", 4.7, "4.1 km", 0, "Opens at 8:00 AM", ["Full Body", "Cardiac", "Dental"]),
        ("ELCT Eye Center", "Azikiwe Street, Dar es Salaam", 4.8, "3.4 km", 1, "Open until 6:00 PM", ["Vision", "Eye Care", "Optical"]),
        ("TMJ Dental Clinic", "Mikocheni, Dar es Salaam", 4.5, "5.0 km", 1, "Open until 7:00 PM", ["Dental", "X-Ray", "Cleaning"]),
    ]
    for lab in labs:
        conn.execute(
            """
            INSERT INTO lab_locations (name, address, rating, distance, open, hours, specialties, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(name) DO UPDATE SET
              address = excluded.address,
              rating = excluded.rating,
              distance = excluded.distance,
              open = excluded.open,
              hours = excluded.hours,
              specialties = excluded.specialties
            """,
            (*lab[:-1], json.dumps(lab[-1]), now),
        )

    lab_test_ids = {row["name"]: row["id"] for row in conn.execute("SELECT id, name FROM lab_tests")}
    lab_bookings = [
        ("Pelvic Ultrasound", "2026-05-28", "10:30 AM", "confirmed"),
        ("Complete Blood Count", "2026-05-29", "8:00 AM", "pending"),
        ("Full Body Checkup", "2026-05-31", "9:00 AM", "pending"),
    ]
    for test_name, date, slot, status in lab_bookings:
        test_id = lab_test_ids.get(test_name) or lab_test_ids["Complete Blood Count"]
        conn.execute(
            """
            INSERT INTO lab_bookings
            (user_id, lab_test_id, booking_date, booking_time, status, created_at, updated_at)
            SELECT ?, ?, ?, ?, ?, ?, ?
            WHERE NOT EXISTS (
              SELECT 1 FROM lab_bookings
              WHERE user_id = ? AND lab_test_id = ? AND booking_date = ? AND booking_time = ?
            )
            """,
            (demo_user_id, test_id, date, slot, status, now, now, demo_user_id, test_id, date, slot),
        )

    results = [
        ("Vision Screening", "ELCT Eye Center", "2026-05-20", "normal", 1),
        ("Hemoglobin Test", "Aga Khan Lab", "2026-05-15", "borderline", 1),
        ("Dental OPG X-Ray", "TMJ Dental Clinic", "2026-05-10", "pending", 0),
    ]
    for result in results:
        conn.execute(
            """
            INSERT INTO lab_results (user_id, test_name, lab_name, result_date, status, doctor_reviewed, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(user_id, test_name, result_date) DO UPDATE SET
              lab_name = excluded.lab_name,
              status = excluded.status,
              doctor_reviewed = excluded.doctor_reviewed
            """,
            (demo_user_id, *result, now),
        )


class ApiError(Exception):
    def __init__(self, status: int, message: str, details: Any = None):
        super().__init__(message)
        self.status = status
        self.message = message
        self.details = details


class Handler(BaseHTTPRequestHandler):
    server_version = "QmedCOBackend/1.0"

    def do_OPTIONS(self) -> None:
        self.respond(204, None)

    def do_GET(self) -> None:
        self.dispatch("GET")

    def do_POST(self) -> None:
        self.dispatch("POST")

    def do_PATCH(self) -> None:
        self.dispatch("PATCH")

    def do_DELETE(self) -> None:
        self.dispatch("DELETE")

    def log_message(self, fmt: str, *args: Any) -> None:
        print(f"{self.log_date_time_string()} {self.address_string()} {fmt % args}")

    def dispatch(self, method: str) -> None:
        try:
            parsed = urlparse(self.path)
            path = parsed.path.rstrip("/") or "/"
            query = {k: v[-1] for k, v in parse_qs(parsed.query).items()}
            body = self.read_json() if method in {"POST", "PATCH"} else {}
            data = self.route(method, path, query, body)
            self.respond(200, data)
        except ApiError as exc:
            self.respond(exc.status, {"error": exc.message, "details": exc.details})
        except Exception as exc:
            traceback.print_exc()
            self.respond(500, {"error": "Internal server error", "details": str(exc)})

    def read_json(self) -> dict[str, Any]:
        length = int(self.headers.get("Content-Length", "0"))
        if length == 0:
            return {}
        raw = self.rfile.read(length)
        try:
            payload = json.loads(raw.decode())
        except json.JSONDecodeError:
            raise ApiError(400, "Invalid JSON body")
        if not isinstance(payload, dict):
            raise ApiError(400, "JSON body must be an object")
        return payload

    def respond(self, status: int, data: Any) -> None:
        self.send_response(status)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET,POST,PATCH,DELETE,OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type,Authorization")
        if data is None:
            self.end_headers()
            return
        payload = json_dumps(data)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def current_user_id(self, required: bool = True) -> int | None:
        auth = self.headers.get("Authorization", "")
        token = auth.removeprefix("Bearer ").strip() if auth.startswith("Bearer ") else ""
        user_id = parse_token(token) if token else None
        if required and user_id is None:
            raise ApiError(401, "Authentication required")
        return user_id

    def current_user(self) -> dict[str, Any]:
        return self.get_user(self.current_user_id())

    def require_role(self, roles: set[str]) -> dict[str, Any]:
        user = self.current_user()
        if user["role"] not in roles:
            raise ApiError(403, "You do not have permission for this action")
        return user

    def audit(self, actor_user_id: int | None, action: str, entity_type: str, entity_id: int | None = None, metadata: Any = None) -> None:
        with db() as conn:
            conn.execute(
                """
                INSERT INTO audit_logs (actor_user_id, action, entity_type, entity_id, metadata, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (actor_user_id, action, entity_type, entity_id, json.dumps(metadata or {}), utc_now()),
            )

    def notify(self, user_id: int, title: str, body: str, type_: str = "general", channel: str = "in_app") -> None:
        with db() as conn:
            conn.execute(
                """
                INSERT INTO notifications (user_id, title, body, type, channel, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (user_id, title, body, type_, channel, utc_now()),
            )
        if channel == "email":
            self.send_email(user_id, title, body)
        elif channel == "sms":
            self.send_sms(user_id, body)

    def send_email(self, user_id: int, subject: str, body: str) -> None:
        if os.environ.get("QMEDCO_EMAIL_ENABLED", "false").lower() != "true":
            print(f"[email stub] user={user_id} subject={subject}")
            return
        # Placeholder for actual email integration
        print(f"Sending email to {user_id}: {subject}")

    def send_sms(self, user_id: int, body: str) -> None:
        if os.environ.get("QMEDCO_SMS_ENABLED", "false").lower() != "true":
            print(f"[sms stub] user={user_id} body={body}")
            return
        # Placeholder for actual SMS integration
        print(f"Sending SMS to {user_id}: {body}")

    def doctor_id_for_user(self, user_id: int) -> int:
        with db() as conn:
            row = conn.execute("SELECT id FROM doctors WHERE user_id = ?", (user_id,)).fetchone()
        if row is None:
            raise ApiError(404, "No doctor profile is linked to this account")
        return row["id"]

    def route(self, method: str, path: str, query: dict[str, str], body: dict[str, Any]) -> Any:
        if method == "GET" and path == "/health":
            return {"ok": True, "service": "qmedco-backend", "time": utc_now()}
        if method == "POST" and path == "/api/auth/register":
            return self.register(body)
        if method == "POST" and path == "/api/auth/login":
            return self.login(body)
        if method == "GET" and path == "/api/me":
            return {"user": self.get_user(self.current_user_id())}
        if method == "PATCH" and path == "/api/me":
            return {"user": self.update_user(self.current_user_id(), body)}
        if method == "GET" and path == "/api/dashboard":
            return self.dashboard(self.current_user_id())
        if method == "GET" and path == "/api/admin/overview":
            return self.admin_overview()
        if method == "GET" and path == "/api/admin/users":
            return {"users": self.admin_users(query)}
        if method == "POST" and path == "/api/admin/users":
            return {"user": self.admin_create_user(body)}
        if method == "PATCH" and path.startswith("/api/admin/users/"):
            return {"user": self.admin_update_user(int(path.rsplit("/", 1)[-1]), body)}
        if method == "GET" and path == "/api/departments":
            return {"departments": self.departments(query)}
        if method == "GET" and path == "/api/specialties":
            return {"specialties": self.specialties(query)}
        if method == "POST" and path == "/api/departments":
            return {"department": self.create_department(body)}
        if method == "PATCH" and path.startswith("/api/departments/"):
            return {"department": self.update_department(int(path.rsplit("/", 1)[-1]), body)}
        if method == "GET" and path == "/api/doctors":
            return {"doctors": self.doctors(query)}
        if method == "POST" and path == "/api/doctors":
            return {"doctor": self.create_doctor(body)}
        if method == "PATCH" and path.startswith("/api/doctors/"):
            return {"doctor": self.update_doctor(int(path.rsplit("/", 1)[-1]), body)}
        if method == "GET" and path == "/api/doctor/portal":
            return self.doctor_portal()
        if method == "GET" and path == "/api/doctor/availability":
            return {"availability": self.doctor_availability(query)}
        if method == "POST" and path == "/api/doctor/availability":
            return {"availability": self.create_doctor_availability(body)}
        if method == "POST" and path == "/api/doctor/blocked-slots":
            return {"blockedSlot": self.create_blocked_slot(body)}
        if method == "GET" and path == "/api/time-slots":
            return {"slots": self.time_slots(query)}
        if method == "GET" and path == "/api/appointments":
            return {"appointments": self.appointments(self.current_user_id(), query)}
        if method == "GET" and path == "/api/staff/appointments":
            return {"appointments": self.staff_appointments(query)}
        if method == "POST" and path == "/api/appointments":
            return {"appointment": self.create_appointment(self.current_user_id(), body)}
        if method == "PATCH" and path.startswith("/api/appointments/"):
            appointment_id = int(path.rsplit("/", 1)[-1])
            return {"appointment": self.update_appointment(self.current_user_id(), appointment_id, body)}
        if method == "PATCH" and path.startswith("/api/staff/appointments/"):
            appointment_id = int(path.rsplit("/", 1)[-1])
            return {"appointment": self.staff_update_appointment(appointment_id, body)}
        if method == "GET" and path == "/api/lab-tests":
            return {"labTests": self.lab_tests()}
        if method == "GET" and path == "/api/lab-packages":
            return {"labPackages": self.lab_packages()}
        if method == "GET" and path == "/api/lab-locations":
            return {"labLocations": self.lab_locations()}
        if method == "GET" and path == "/api/lab-results":
            return {"labResults": self.lab_results(self.current_user_id())}
        if method == "POST" and path == "/api/lab-bookings":
            return {"labBooking": self.create_lab_booking(self.current_user_id(), body)}
        if method == "GET" and path == "/api/lab-bookings":
            return {"labBookings": self.lab_bookings(self.current_user_id())}
        if method == "GET" and path == "/api/lab/portal":
            return self.lab_portal(query)
        if method == "PATCH" and path.startswith("/api/lab/bookings/"):
            return {"labBooking": self.lab_update_booking(int(path.rsplit("/", 1)[-1]), body)}
        if method == "POST" and path == "/api/lab-results":
            return {"labResult": self.create_lab_result(body)}
        if method == "POST" and path == "/api/auth/password-reset-request":
            return {"message": self.password_reset_request(body)}
        if method == "POST" and path == "/api/auth/password-reset":
            return {"message": self.password_reset(body)}
        if method == "GET" and path == "/api/billing/invoices":
            return {"invoices": self.list_invoices(query)}
        if method == "POST" and path == "/api/billing/invoices":
            return {"invoice": self.create_invoice(body)}
        if method == "GET" and path == "/api/payments":
            return {"payments": self.list_payments(query)}
        if method == "POST" and path == "/api/payments":
            return {"payment": self.create_payment(body)}
        if method == "GET" and path == "/api/billing/summary":
            return self.billing_summary(query)
        if method == "POST" and path == "/api/consultations":
            return {"consultation": self.create_consultation(self.current_user_id(), body)}
        if method == "GET" and path == "/api/consultations":
            return {"consultations": self.consultations(self.current_user_id())}
        if method == "PATCH" and path.startswith("/api/staff/consultations/"):
            return {"consultation": self.staff_update_consultation(int(path.rsplit("/", 1)[-1]), body)}
        if method == "POST" and path == "/api/emergency-requests":
            return {"emergencyRequest": self.create_emergency(self.current_user_id(required=False), body)}
        if method == "GET" and path == "/api/emergency-requests":
            return {"emergencyRequests": self.emergencies(self.current_user_id())}
        if method == "GET" and path == "/api/staff/emergency-requests":
            return {"emergencyRequests": self.staff_emergencies(query)}
        if method == "PATCH" and path.startswith("/api/staff/emergency-requests/"):
            return {"emergencyRequest": self.staff_update_emergency(int(path.rsplit("/", 1)[-1]), body)}
        if method == "GET" and path == "/api/messages":
            return {"messages": self.messages(self.current_user_id(), query)}
        if method == "GET" and path == "/api/chat-threads":
            return {"chatThreads": self.chat_threads(query)}
        if method == "POST" and path == "/api/messages":
            return {"message": self.create_message(self.current_user_id(), body)}
        if method == "GET" and path == "/api/health-tips":
            return {"healthTips": self.health_tips(query)}
        if method == "GET" and path == "/api/medical-records":
            return {"medicalRecords": self.medical_records(query)}
        if method == "POST" and path == "/api/medical-records":
            return {"medicalRecord": self.create_medical_record(body)}
        if method == "GET" and path == "/api/vitals":
            return {"vitals": self.vitals(query)}
        if method == "POST" and path == "/api/vitals":
            return {"vital": self.create_vital(body)}
        if method == "GET" and path == "/api/prescriptions":
            return {"prescriptions": self.prescriptions(query)}
        if method == "POST" and path == "/api/prescriptions":
            return {"prescription": self.create_prescription(body)}
        if method == "GET" and path == "/api/notifications":
            return {"notifications": self.notifications()}
        if method == "PATCH" and path.startswith("/api/notifications/"):
            return {"notification": self.mark_notification_read(int(path.rsplit("/", 1)[-1]))}
        if method == "GET" and path == "/api/audit-logs":
            return {"auditLogs": self.audit_logs(query)}
        if method == "GET" and path == "/api/reports/summary":
            return self.reports_summary(query)
        raise ApiError(404, f"No route for {method} {path}")

    def register(self, body: dict[str, Any]) -> dict[str, Any]:
        full_name = str(body.get("fullName") or body.get("name") or "").strip()
        email = str(body.get("email") or "").strip().lower()
        password = str(body.get("password") or "")
        if not full_name:
            raise ApiError(400, "Full name is required")
        if "@" not in email:
            raise ApiError(400, "Valid email is required")
        if len(password) < 6:
            raise ApiError(400, "Password must be at least 6 characters")
        now = utc_now()
        try:
            with db() as conn:
                cur = conn.execute(
                    """
                    INSERT INTO users
                    (full_name, email, password_hash, phone, date_of_birth, location, blood_group, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        full_name,
                        email,
                        hash_password(password),
                        str(body.get("phone") or ""),
                        str(body.get("dateOfBirth") or ""),
                        str(body.get("location") or ""),
                        str(body.get("bloodGroup") or ""),
                        now,
                        now,
                    ),
                )
                user = self.get_user(cur.lastrowid, conn)
        except sqlite3.IntegrityError:
            raise ApiError(409, "Email is already registered")
        return {"token": make_token(user["id"]), "user": user}

    def login(self, body: dict[str, Any]) -> dict[str, Any]:
        email = str(body.get("email") or "").strip().lower()
        password = str(body.get("password") or "")
        with db() as conn:
            row = conn.execute("SELECT * FROM users WHERE email = ?", (email,)).fetchone()
        if row is None or not verify_password(password, row["password_hash"]):
            raise ApiError(401, "Invalid email or password")
        return {"token": make_token(row["id"]), "user": self.get_user(row["id"])}

    def get_user(self, user_id: int | None, conn: sqlite3.Connection | None = None) -> dict[str, Any]:
        if user_id is None:
            raise ApiError(401, "Authentication required")
        own_conn = conn is None
        conn = conn or db()
        try:
            row = conn.execute(
                """
                SELECT id, full_name AS fullName, email, phone, date_of_birth AS dateOfBirth,
                       location, blood_group AS bloodGroup, role, created_at AS createdAt,
                       updated_at AS updatedAt
                FROM users WHERE id = ?
                """,
                (user_id,),
            ).fetchone()
        finally:
            if own_conn:
                conn.close()
        if row is None:
            raise ApiError(404, "User not found")
        return dict(row)

    def update_user(self, user_id: int | None, body: dict[str, Any]) -> dict[str, Any]:
        allowed = {
            "fullName": "full_name",
            "phone": "phone",
            "dateOfBirth": "date_of_birth",
            "location": "location",
            "bloodGroup": "blood_group",
        }
        updates = []
        values = []
        for key, column in allowed.items():
            if key in body:
                updates.append(f"{column} = ?")
                values.append(str(body[key]))
        if not updates:
            return self.get_user(user_id)
        updates.append("updated_at = ?")
        values.append(utc_now())
        values.append(user_id)
        with db() as conn:
            conn.execute(f"UPDATE users SET {', '.join(updates)} WHERE id = ?", values)
        return self.get_user(user_id)

    def admin_overview(self) -> dict[str, Any]:
        self.require_role(ADMIN_ROLES | {"receptionist"})
        with db() as conn:
            counts = {
                "patients": conn.execute("SELECT COUNT(*) FROM users WHERE role = 'patient'").fetchone()[0],
                "staff": conn.execute("SELECT COUNT(*) FROM users WHERE role != 'patient'").fetchone()[0],
                "doctors": conn.execute("SELECT COUNT(*) FROM doctors").fetchone()[0],
                "appointments": conn.execute("SELECT COUNT(*) FROM appointments").fetchone()[0],
                "labBookings": conn.execute("SELECT COUNT(*) FROM lab_bookings").fetchone()[0],
                "emergencies": conn.execute("SELECT COUNT(*) FROM emergency_requests").fetchone()[0],
            }
        return {"counts": counts, "generatedAt": utc_now()}

    def admin_users(self, query: dict[str, str]) -> list[dict[str, Any]]:
        self.require_role(ADMIN_ROLES | {"receptionist"})
        clauses = []
        params: list[Any] = []
        if query.get("role"):
            clauses.append("role = ?")
            params.append(query["role"])
        if query.get("search"):
            search = f"%{query['search'].lower()}%"
            clauses.append("(lower(full_name) LIKE ? OR lower(email) LIKE ?)")
            params.extend([search, search])
        where = "WHERE " + " AND ".join(clauses) if clauses else ""
        with db() as conn:
            rows = conn.execute(
                f"""
                SELECT id, full_name AS fullName, email, phone, date_of_birth AS dateOfBirth,
                       location, blood_group AS bloodGroup, role, created_at AS createdAt,
                       updated_at AS updatedAt
                FROM users {where}
                ORDER BY role, full_name
                """,
                params,
            ).fetchall()
        return rows_to_list(rows)

    def admin_update_user(self, target_user_id: int, body: dict[str, Any]) -> dict[str, Any]:
        actor = self.require_role(ADMIN_ROLES)
        allowed = {
            "fullName": "full_name",
            "phone": "phone",
            "dateOfBirth": "date_of_birth",
            "location": "location",
            "bloodGroup": "blood_group",
            "role": "role",
        }
        updates = []
        values = []
        for key, column in allowed.items():
            if key in body:
                if key == "role" and body[key] not in STAFF_ROLES | {"patient"}:
                    raise ApiError(400, "Invalid role")
                updates.append(f"{column} = ?")
                values.append(str(body[key]))
        if not updates:
            return self.get_user(target_user_id)
        updates.append("updated_at = ?")
        values.extend([utc_now(), target_user_id])
        with db() as conn:
            cur = conn.execute(f"UPDATE users SET {', '.join(updates)} WHERE id = ?", values)
            if cur.rowcount == 0:
                raise ApiError(404, "User not found")
        self.audit(actor["id"], "user.updated", "user", target_user_id, body)
        return self.get_user(target_user_id)

    def admin_create_user(self, body: dict[str, Any]) -> dict[str, Any]:
        actor = self.require_role(ADMIN_ROLES)
        full_name = str(body.get("fullName") or "").strip()
        email = str(body.get("email") or "").strip().lower()
        password = str(body.get("password") or "").strip()
        role = str(body.get("role") or "patient").strip()
        if not full_name or not email or not password:
            raise ApiError(400, "fullName, email, and password are required")
        if role not in STAFF_ROLES | {"patient"}:
            raise ApiError(400, "Invalid role")
        if len(password) < 6:
            raise ApiError(400, "Password must be at least 6 characters")
        now = utc_now()
        with db() as conn:
            try:
                cur = conn.execute(
                    """
                    INSERT INTO users (full_name, email, password_hash, phone, date_of_birth, location, blood_group, role, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        full_name,
                        email,
                        hash_password(password),
                        str(body.get("phone") or ""),
                        str(body.get("dateOfBirth") or ""),
                        str(body.get("location") or ""),
                        str(body.get("bloodGroup") or ""),
                        role,
                        now,
                        now,
                    ),
                )
            except sqlite3.IntegrityError:
                raise ApiError(409, "A user with this email already exists")
        user_id = cur.lastrowid
        self.audit(actor["id"], "user.created", "user", user_id, body)
        return self.get_user(user_id)

    def list_payments(self, query: dict[str, str]) -> list[dict[str, Any]]:
        user = self.current_user()
        clauses = []
        params: list[Any] = []
        if query.get("patientId"):
            clauses.append("p.user_id = ?")
            params.append(int(query["patientId"]))
        if query.get("status"):
            clauses.append("p.status = ?")
            params.append(query["status"])
        if user["role"] == "patient":
            clauses.append("p.user_id = ?")
            params.append(user["id"])
        if user["role"] not in STAFF_ROLES | {"patient"}:
            raise ApiError(403, "You do not have permission for this action")
        where = "WHERE " + " AND ".join(clauses) if clauses else ""
        with db() as conn:
            rows = conn.execute(
                f"""
                SELECT p.id, p.invoice_id AS invoiceId, p.user_id AS patientId, u.full_name AS patientName,
                       p.amount, p.currency, p.method, p.provider,
                       p.transaction_reference AS transactionReference, p.status, p.created_at AS createdAt
                FROM payments p
                JOIN users u ON u.id = p.user_id
                {where}
                ORDER BY p.created_at DESC
                """,
                params,
            ).fetchall()
        return rows_to_list(rows)

    def create_department(self, body: dict[str, Any]) -> dict[str, Any]:
        actor = self.require_role(ADMIN_ROLES)
        name = str(body.get("name") or "").strip()
        if not name:
            raise ApiError(400, "Department name is required")
        now = utc_now()
        services = body.get("services") if isinstance(body.get("services"), list) else []
        with db() as conn:
            cur = conn.execute(
                """
                INSERT INTO departments (name, description, image_path, services, created_at)
                VALUES (?, ?, ?, ?, ?)
                """,
                (name, str(body.get("description") or ""), str(body.get("imagePath") or ""), json.dumps(services), now),
            )
            department_id = cur.lastrowid
        self.audit(actor["id"], "department.created", "department", department_id, body)
        return [d for d in self.departments({}) if d["id"] == department_id][0]

    def update_department(self, department_id: int, body: dict[str, Any]) -> dict[str, Any]:
        actor = self.require_role(ADMIN_ROLES)
        allowed = {"name": "name", "description": "description", "imagePath": "image_path"}
        updates = []
        values = []
        for key, column in allowed.items():
            if key in body:
                updates.append(f"{column} = ?")
                values.append(str(body[key]))
        if "services" in body:
            updates.append("services = ?")
            values.append(json.dumps(body["services"] if isinstance(body["services"], list) else []))
        if not updates:
            matches = [d for d in self.departments({}) if d["id"] == department_id]
            if not matches:
                raise ApiError(404, "Department not found")
            return matches[0]
        values.append(department_id)
        with db() as conn:
            cur = conn.execute(f"UPDATE departments SET {', '.join(updates)} WHERE id = ?", values)
            if cur.rowcount == 0:
                raise ApiError(404, "Department not found")
        self.audit(actor["id"], "department.updated", "department", department_id, body)
        return [d for d in self.departments({}) if d["id"] == department_id][0]

    def create_doctor(self, body: dict[str, Any]) -> dict[str, Any]:
        actor = self.require_role(ADMIN_ROLES)
        name = str(body.get("name") or "").strip()
        department_id = int(body.get("departmentId") or 0)
        if not name or not department_id:
            raise ApiError(400, "name and departmentId are required")
        now = utc_now()
        with db() as conn:
            cur = conn.execute(
                """
                INSERT INTO doctors
                (department_id, user_id, name, specialty, rating, reviews, image_path, available, experience, fee, location, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    department_id,
                    body.get("userId"),
                    name,
                    str(body.get("specialty") or ""),
                    float(body.get("rating") or 4.5),
                    int(body.get("reviews") or 0),
                    str(body.get("imagePath") or ""),
                    1 if body.get("available", True) else 0,
                    str(body.get("experience") or ""),
                    int(body.get("fee") or 0),
                    str(body.get("location") or "QmedCO Main Clinic"),
                    now,
                ),
            )
            doctor_id = cur.lastrowid
        self.audit(actor["id"], "doctor.created", "doctor", doctor_id, body)
        return [d for d in self.doctors({}) if d["id"] == doctor_id][0]

    def update_doctor(self, doctor_id: int, body: dict[str, Any]) -> dict[str, Any]:
        actor = self.require_role(ADMIN_ROLES)
        allowed = {
            "departmentId": "department_id",
            "userId": "user_id",
            "name": "name",
            "specialty": "specialty",
            "rating": "rating",
            "reviews": "reviews",
            "imagePath": "image_path",
            "available": "available",
            "experience": "experience",
            "fee": "fee",
            "location": "location",
        }
        updates = []
        values = []
        for key, column in allowed.items():
            if key in body:
                updates.append(f"{column} = ?")
                value = body[key]
                if key == "available":
                    value = 1 if value else 0
                values.append(value)
        if not updates:
            matches = [d for d in self.doctors({}) if d["id"] == doctor_id]
            if not matches:
                raise ApiError(404, "Doctor not found")
            return matches[0]
        values.append(doctor_id)
        with db() as conn:
            cur = conn.execute(f"UPDATE doctors SET {', '.join(updates)} WHERE id = ?", values)
            if cur.rowcount == 0:
                raise ApiError(404, "Doctor not found")
        self.audit(actor["id"], "doctor.updated", "doctor", doctor_id, body)
        return [d for d in self.doctors({}) if d["id"] == doctor_id][0]

    def departments(self, query: dict[str, str]) -> list[dict[str, Any]]:
        search = f"%{query.get('search', '').lower()}%"
        with db() as conn:
            rows = conn.execute(
                """
                SELECT d.*, COUNT(doc.id) AS doctorCount
                FROM departments d
                LEFT JOIN doctors doc ON doc.department_id = d.id
                WHERE lower(d.name) LIKE ? OR lower(d.description) LIKE ?
                GROUP BY d.id
                ORDER BY d.name
                """,
                (search, search),
            ).fetchall()
        result = rows_to_list(rows)
        for item in result:
            item["services"] = json.loads(item["services"])
            item["imagePath"] = item.pop("image_path")
            item["createdAt"] = item.pop("created_at")
        return result

    def doctors(self, query: dict[str, str]) -> list[dict[str, Any]]:
        clauses = []
        params: list[Any] = []
        search = query.get("search")
        specialty = query.get("specialty")
        department_id = query.get("departmentId")
        doctor_id = query.get("doctorId")
        available = query.get("available")
        if search:
            clauses.append("(lower(doc.name) LIKE ? OR lower(doc.specialty) LIKE ?)")
            params.extend([f"%{search.lower()}%", f"%{search.lower()}%"])
        if specialty:
            clauses.append("lower(doc.specialty) LIKE ?")
            params.append(f"%{specialty.lower()}%")
        if department_id:
            clauses.append("doc.department_id = ?")
            params.append(int(department_id))
        if doctor_id:
            clauses.append("doc.id = ?")
            params.append(int(doctor_id))
        if available in {"true", "false", "1", "0"}:
            clauses.append("doc.available = ?")
            params.append(1 if available in {"true", "1"} else 0)
        where = "WHERE " + " AND ".join(clauses) if clauses else ""
        with db() as conn:
            rows = conn.execute(
                f"""
                SELECT doc.id, doc.department_id AS departmentId, dep.name AS department,
                       doc.name, doc.specialty, doc.rating, doc.reviews,
                       doc.image_path AS imagePath, doc.available, doc.experience,
                       doc.fee, doc.location
                FROM doctors doc
                JOIN departments dep ON dep.id = doc.department_id
                {where}
                ORDER BY doc.available DESC, doc.rating DESC, doc.name
                """,
                params,
            ).fetchall()
        result = rows_to_list(rows)
        for item in result:
            item["available"] = bool(item["available"])
        return result

    def specialties(self, query: dict[str, str]) -> list[str]:
        q = (query.get("q") or "").strip().lower()
        with db() as conn:
            if q:
                rows = conn.execute(
                    "SELECT DISTINCT specialty FROM doctors WHERE lower(specialty) LIKE ? ORDER BY specialty",
                    (f"%{q}%",),
                ).fetchall()
            else:
                rows = conn.execute(
                    "SELECT DISTINCT specialty FROM doctors WHERE specialty != '' ORDER BY specialty",
                ).fetchall()
        return [row["specialty"] for row in rows if row["specialty"]]

    def time_slots(self, query: dict[str, str]) -> list[dict[str, Any]]:
        doctor_id = int(query.get("doctorId") or 0)
        date = query.get("date") or dt.date.today().isoformat()
        if not doctor_id:
            raise ApiError(400, "doctorId is required")
        weekday = get_weekday(date)
        with db() as conn:
            rows = conn.execute(
                """
                SELECT weekday, start_time, end_time, slot_minutes, max_patients, active
                FROM doctor_availability
                WHERE doctor_id = ? AND weekday = ? AND active = 1
                ORDER BY start_time
                """,
                (doctor_id, weekday),
            ).fetchall()
            blocked = conn.execute(
                """
                SELECT block_date, start_time, end_time
                FROM doctor_blocked_slots
                WHERE doctor_id = ? AND block_date = ?
                """,
                (doctor_id, date),
            ).fetchall()
            booked_rows = conn.execute(
                """
                SELECT appointment_time FROM appointments
                WHERE doctor_id = ? AND appointment_date = ? AND status != 'cancelled'
                """,
                (doctor_id, date),
            ).fetchall()
        blocked_slots = [
            (normalize_time_string(row["start_time"]), normalize_time_string(row["end_time"]))
            for row in blocked
        ]
        max_patients = 1
        slot_counts: dict[str, int] = {}
        for row in booked_rows:
            time_value = normalize_time_string(row["appointment_time"])
            if not time_value:
                continue
            slot_counts[time_value] = slot_counts.get(time_value, 0) + 1
        slots: list[dict[str, Any]] = []
        if not rows:
            rows = [
                {"start_time": "09:00", "end_time": "16:00", "slot_minutes": 30, "max_patients": 1}
            ]
        for row in rows:
            start = normalize_time_string(row["start_time"])
            end = normalize_time_string(row["end_time"])
            interval = int(row["slot_minutes"] or 30)
            max_patients = int(row["max_patients"] or 1)
            try:
                start_dt = dt.datetime.strptime(start, "%H:%M")
                end_dt = dt.datetime.strptime(end, "%H:%M")
            except ValueError:
                continue
            current = start_dt
            while current + dt.timedelta(minutes=interval) <= end_dt:
                slot = current.strftime("%H:%M")
                is_blocked = any(
                    block_start <= slot < block_end
                    for block_start, block_end in blocked_slots
                )
                count = slot_counts.get(slot, 0)
                slots.append(
                    {
                        "time": slot,
                        "available": not is_blocked and count < max_patients,
                        "maxPatients": max_patients,
                        "booked": count,
                    }
                )
                current += dt.timedelta(minutes=interval)
        return slots

    def doctor_portal(self) -> dict[str, Any]:
        user = self.require_role(CLINICAL_ROLES)
        doctor_id = self.doctor_id_for_user(user["id"]) if user["role"] == "doctor" else None
        query = {"doctorId": str(doctor_id)} if doctor_id else {}
        appointments = self.staff_appointments(query)
        return {
            "doctor": self.doctors({"doctorId": str(doctor_id)})[0] if doctor_id else None,
            "todayAppointments": [a for a in appointments if a["date"] == dt.date.today().isoformat()],
            "appointments": appointments[:25],
            "consultations": self.staff_consultations(doctor_id),
        }

    def doctor_availability(self, query: dict[str, str]) -> list[dict[str, Any]]:
        user = self.require_role(CLINICAL_ROLES | ADMIN_ROLES)
        doctor_id = int(query.get("doctorId") or (self.doctor_id_for_user(user["id"]) if user["role"] == "doctor" else 0))
        if not doctor_id:
            raise ApiError(400, "doctorId is required")
        with db() as conn:
            rows = conn.execute(
                """
                SELECT id, doctor_id AS doctorId, weekday, start_time AS startTime,
                       end_time AS endTime, slot_minutes AS slotMinutes,
                       max_patients AS maxPatients, active
                FROM doctor_availability
                WHERE doctor_id = ?
                ORDER BY weekday, start_time
                """,
                (doctor_id,),
            ).fetchall()
        result = rows_to_list(rows)
        for item in result:
            item["active"] = bool(item["active"])
        return result

    def create_doctor_availability(self, body: dict[str, Any]) -> dict[str, Any]:
        actor = self.require_role(CLINICAL_ROLES | ADMIN_ROLES)
        doctor_id = int(body.get("doctorId") or (self.doctor_id_for_user(actor["id"]) if actor["role"] == "doctor" else 0))
        if not doctor_id:
            raise ApiError(400, "doctorId is required")
        with db() as conn:
            cur = conn.execute(
                """
                INSERT OR REPLACE INTO doctor_availability
                (doctor_id, weekday, start_time, end_time, slot_minutes, max_patients, active)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    doctor_id,
                    int(body.get("weekday") or 1),
                    str(body.get("startTime") or "09:00"),
                    str(body.get("endTime") or "16:00"),
                    int(body.get("slotMinutes") or 30),
                    int(body.get("maxPatients") or 1),
                    1 if body.get("active", True) else 0,
                ),
            )
            availability_id = cur.lastrowid
        self.audit(actor["id"], "doctor.availability.saved", "doctor", doctor_id, body)
        return {"id": availability_id, "doctorId": doctor_id, **body}

    def create_blocked_slot(self, body: dict[str, Any]) -> dict[str, Any]:
        actor = self.require_role(CLINICAL_ROLES | ADMIN_ROLES)
        doctor_id = int(body.get("doctorId") or (self.doctor_id_for_user(actor["id"]) if actor["role"] == "doctor" else 0))
        if not doctor_id:
            raise ApiError(400, "doctorId is required")
        now = utc_now()
        with db() as conn:
            cur = conn.execute(
                """
                INSERT OR IGNORE INTO doctor_blocked_slots
                (doctor_id, block_date, start_time, end_time, reason, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (
                    doctor_id,
                    str(body.get("date") or ""),
                    str(body.get("startTime") or ""),
                    str(body.get("endTime") or ""),
                    str(body.get("reason") or ""),
                    now,
                ),
            )
            blocked_id = cur.lastrowid
        self.audit(actor["id"], "doctor.slot_blocked", "doctor", doctor_id, body)
        return {"id": blocked_id, "doctorId": doctor_id, "createdAt": now, **body}

    def appointments(self, user_id: int | None, query: dict[str, str]) -> list[dict[str, Any]]:
        status = query.get("status")
        params: list[Any] = [user_id]
        status_clause = ""
        if status:
            status_clause = "AND ap.status = ?"
            params.append(status)
        with db() as conn:
            rows = conn.execute(
                f"""
                SELECT ap.id, ap.appointment_date AS date, ap.appointment_time AS time,
                       ap.room, ap.reason, ap.notes, ap.status, ap.created_at AS createdAt,
                       ap.updated_at AS updatedAt,
                       doc.id AS doctorId, doc.name AS doctor, doc.specialty,
                       doc.image_path AS imagePath, doc.location, doc.fee,
                       dep.id AS departmentId, dep.name AS department
                FROM appointments ap
                JOIN doctors doc ON doc.id = ap.doctor_id
                JOIN departments dep ON dep.id = ap.department_id
                WHERE ap.user_id = ? {status_clause}
                ORDER BY ap.appointment_date, ap.appointment_time
                """,
                params,
            ).fetchall()
        return rows_to_list(rows)

    def staff_appointments(self, query: dict[str, str]) -> list[dict[str, Any]]:
        user = self.require_role(STAFF_ROLES)
        clauses = []
        params: list[Any] = []
        if user["role"] == "doctor":
            clauses.append("ap.doctor_id = ?")
            params.append(self.doctor_id_for_user(user["id"]))
        elif query.get("doctorId"):
            clauses.append("ap.doctor_id = ?")
            params.append(int(query["doctorId"]))
        if query.get("status"):
            clauses.append("ap.status = ?")
            params.append(query["status"])
        if query.get("date"):
            clauses.append("ap.appointment_date = ?")
            params.append(query["date"])
        where = "WHERE " + " AND ".join(clauses) if clauses else ""
        with db() as conn:
            rows = conn.execute(
                f"""
                SELECT ap.id, ap.user_id AS patientId, u.full_name AS patientName,
                       u.phone AS patientPhone, ap.appointment_date AS date,
                       ap.appointment_time AS time, ap.room, ap.reason, ap.notes,
                       ap.status, ap.created_at AS createdAt, ap.updated_at AS updatedAt,
                       doc.id AS doctorId, doc.name AS doctor, doc.specialty,
                       dep.id AS departmentId, dep.name AS department
                FROM appointments ap
                JOIN users u ON u.id = ap.user_id
                JOIN doctors doc ON doc.id = ap.doctor_id
                JOIN departments dep ON dep.id = ap.department_id
                {where}
                ORDER BY ap.appointment_date, ap.appointment_time
                """,
                params,
            ).fetchall()
        return rows_to_list(rows)

    def staff_appointment_by_id(self, appointment_id: int) -> dict[str, Any]:
        matches = [a for a in self.staff_appointments({}) if a["id"] == appointment_id]
        if not matches:
            raise ApiError(404, "Appointment not found")
        return matches[0]

    def staff_update_appointment(self, appointment_id: int, body: dict[str, Any]) -> dict[str, Any]:
        actor = self.require_role(STAFF_ROLES)
        status = body.get("status")
        if status is not None and status not in APPOINTMENT_STATUSES:
            raise ApiError(400, "Invalid appointment status")
        updates = []
        values: list[Any] = []
        for key, column in {"status": "status", "date": "appointment_date", "time": "appointment_time", "room": "room", "notes": "notes"}.items():
            if key in body:
                updates.append(f"{column} = ?")
                values.append(str(body[key]))
        if not updates:
            return self.staff_appointment_by_id(appointment_id)
        updates.append("updated_at = ?")
        values.extend([utc_now(), appointment_id])
        with db() as conn:
            before = conn.execute("SELECT user_id FROM appointments WHERE id = ?", (appointment_id,)).fetchone()
            if before is None:
                raise ApiError(404, "Appointment not found")
            conn.execute(f"UPDATE appointments SET {', '.join(updates)} WHERE id = ?", values)
        if status:
            self.notify(before["user_id"], "Appointment updated", f"Your appointment status is now {status}.", "appointment")
        self.audit(actor["id"], "appointment.updated", "appointment", appointment_id, body)
        return self.staff_appointment_by_id(appointment_id)

    def create_appointment(self, user_id: int | None, body: dict[str, Any]) -> dict[str, Any]:
        doctor_id = int(body.get("doctorId") or 0)
        date = str(body.get("date") or body.get("appointmentDate") or "").strip()
        slot = normalize_time_string(str(body.get("time") or body.get("appointmentTime") or "").strip())
        status = str(body.get("status") or "requested").strip()
        if not doctor_id or not date or not slot:
            raise ApiError(400, "doctorId, date, and time are required")
        if status not in APPOINTMENT_STATUSES:
            raise ApiError(400, "Invalid appointment status")
        with db() as conn:
            doctor = conn.execute("SELECT id, department_id, available FROM doctors WHERE id = ?", (doctor_id,)).fetchone()
            if doctor is None:
                raise ApiError(404, "Doctor not found")
            if not doctor["available"] and status not in {"requested", "pending"}:
                raise ApiError(409, "Doctor is currently unavailable")
            now = utc_now()
            try:
                cur = conn.execute(
                    """
                    INSERT INTO appointments
                    (user_id, doctor_id, department_id, appointment_date, appointment_time, room, reason, notes, status, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        user_id,
                        doctor_id,
                        doctor["department_id"],
                        date,
                        slot,
                        str(body.get("room") or ""),
                        str(body.get("reason") or ""),
                        str(body.get("notes") or ""),
                        status,
                        now,
                        now,
                    ),
                )
            except sqlite3.IntegrityError:
                raise ApiError(409, "Selected time slot is already booked")
            appointment_id = cur.lastrowid
        return self.appointment_by_id(user_id, appointment_id)

    def appointment_by_id(self, user_id: int | None, appointment_id: int) -> dict[str, Any]:
        matches = [a for a in self.appointments(user_id, {}) if a["id"] == appointment_id]
        if not matches:
            raise ApiError(404, "Appointment not found")
        return matches[0]

    def update_appointment(self, user_id: int | None, appointment_id: int, body: dict[str, Any]) -> dict[str, Any]:
        allowed_statuses = {"upcoming", "confirmed", "pending", "completed", "cancelled", "rescheduled"}
        status = body.get("status")
        date = body.get("date")
        slot = body.get("time")
        updates = []
        values: list[Any] = []
        if status is not None:
            if status not in allowed_statuses:
                raise ApiError(400, "Invalid appointment status")
            updates.append("status = ?")
            values.append(status)
        if date is not None:
            updates.append("appointment_date = ?")
            values.append(str(date))
        if slot is not None:
            updates.append("appointment_time = ?")
            values.append(str(slot))
        if "notes" in body:
            updates.append("notes = ?")
            values.append(str(body["notes"]))
        if not updates:
            return self.appointment_by_id(user_id, appointment_id)
        updates.append("updated_at = ?")
        values.extend([utc_now(), user_id, appointment_id])
        with db() as conn:
            cur = conn.execute(
                f"UPDATE appointments SET {', '.join(updates)} WHERE user_id = ? AND id = ?",
                values,
            )
            if cur.rowcount == 0:
                raise ApiError(404, "Appointment not found")
        return self.appointment_by_id(user_id, appointment_id)

    def lab_tests(self) -> list[dict[str, Any]]:
        with db() as conn:
            rows = conn.execute("SELECT * FROM lab_tests ORDER BY name").fetchall()
        return rows_to_list(rows)

    def lab_packages(self) -> list[dict[str, Any]]:
        with db() as conn:
            rows = conn.execute(
                """
                SELECT id, name, tests, turnaround, price, badge,
                       badge_color AS badgeColor, icon, created_at AS createdAt
                FROM lab_packages ORDER BY id
                """
            ).fetchall()
        return rows_to_list(rows)

    def lab_locations(self) -> list[dict[str, Any]]:
        with db() as conn:
            rows = conn.execute(
                """
                SELECT id, name, address, rating, distance, open, hours, specialties,
                       created_at AS createdAt
                FROM lab_locations ORDER BY rating DESC
                """
            ).fetchall()
        result = rows_to_list(rows)
        for item in result:
            item["open"] = bool(item["open"])
            item["specialties"] = json.loads(item["specialties"])
        return result

    def lab_results(self, user_id: int | None) -> list[dict[str, Any]]:
        with db() as conn:
            rows = conn.execute(
                """
                SELECT id, test_name AS testName, lab_name AS labName,
                       result_date AS date, status, doctor_reviewed AS doctorReviewed,
                       created_at AS createdAt
                FROM lab_results
                WHERE user_id = ?
                ORDER BY result_date DESC
                """,
                (user_id,),
            ).fetchall()
        result = rows_to_list(rows)
        for item in result:
            item["doctorReviewed"] = bool(item["doctorReviewed"])
        return result

    def create_lab_booking(self, user_id: int | None, body: dict[str, Any]) -> dict[str, Any]:
        test_id = int(body.get("labTestId") or body.get("testId") or 0)
        date = str(body.get("date") or "").strip()
        slot = str(body.get("time") or "").strip()
        if not test_id or not date or not slot:
            raise ApiError(400, "labTestId, date, and time are required")
        now = utc_now()
        with db() as conn:
            if conn.execute("SELECT 1 FROM lab_tests WHERE id = ?", (test_id,)).fetchone() is None:
                raise ApiError(404, "Lab test not found")
            cur = conn.execute(
                """
                INSERT INTO lab_bookings
                (user_id, lab_test_id, booking_date, booking_time, notes, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (user_id, test_id, date, slot, str(body.get("notes") or ""), now, now),
            )
            booking_id = cur.lastrowid
        return [b for b in self.lab_bookings(user_id) if b["id"] == booking_id][0]

    def lab_bookings(self, user_id: int | None) -> list[dict[str, Any]]:
        with db() as conn:
            rows = conn.execute(
                """
                SELECT lb.id, lt.id AS labTestId, lt.name, lt.price, lb.booking_date AS date,
                       lb.booking_time AS time, lb.notes, lb.status, lb.created_at AS createdAt
                FROM lab_bookings lb
                JOIN lab_tests lt ON lt.id = lb.lab_test_id
                WHERE lb.user_id = ?
                ORDER BY lb.booking_date, lb.booking_time
                """,
                (user_id,),
            ).fetchall()
        return rows_to_list(rows)

    def create_consultation(self, user_id: int | None, body: dict[str, Any]) -> dict[str, Any]:
        doctor_id = int(body.get("doctorId") or 0)
        mode = str(body.get("mode") or "chat").strip().lower()
        if mode not in {"chat", "voice", "video"}:
            raise ApiError(400, "mode must be chat, voice, or video")
        now = utc_now()
        with db() as conn:
            if conn.execute("SELECT 1 FROM doctors WHERE id = ?", (doctor_id,)).fetchone() is None:
                raise ApiError(404, "Doctor not found")
            cur = conn.execute(
                """
                INSERT INTO consultations (user_id, doctor_id, mode, symptoms, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (user_id, doctor_id, mode, str(body.get("symptoms") or ""), now, now),
            )
            consultation_id = cur.lastrowid
        return [c for c in self.consultations(user_id) if c["id"] == consultation_id][0]

    def consultations(self, user_id: int | None) -> list[dict[str, Any]]:
        with db() as conn:
            rows = conn.execute(
                """
                SELECT c.id, c.mode, c.symptoms, c.status, c.created_at AS createdAt,
                       d.id AS doctorId, d.name AS doctor, d.specialty
                FROM consultations c
                JOIN doctors d ON d.id = c.doctor_id
                WHERE c.user_id = ?
                ORDER BY c.created_at DESC
                """,
                (user_id,),
            ).fetchall()
        return rows_to_list(rows)

    def staff_consultations(self, doctor_id: int | None = None) -> list[dict[str, Any]]:
        clauses = []
        params: list[Any] = []
        if doctor_id:
            clauses.append("c.doctor_id = ?")
            params.append(doctor_id)
        where = "WHERE " + " AND ".join(clauses) if clauses else ""
        with db() as conn:
            rows = conn.execute(
                f"""
                SELECT c.id, c.user_id AS patientId, u.full_name AS patientName,
                       c.mode, c.symptoms, c.status, c.created_at AS createdAt,
                       d.id AS doctorId, d.name AS doctor, d.specialty
                FROM consultations c
                JOIN users u ON u.id = c.user_id
                JOIN doctors d ON d.id = c.doctor_id
                {where}
                ORDER BY c.created_at DESC
                """,
                params,
            ).fetchall()
        return rows_to_list(rows)

    def staff_update_consultation(self, consultation_id: int, body: dict[str, Any]) -> dict[str, Any]:
        actor = self.require_role(CLINICAL_ROLES | ADMIN_ROLES | {"receptionist"})
        status = str(body.get("status") or "").strip()
        if status not in {"requested", "accepted", "in_progress", "completed", "cancelled"}:
            raise ApiError(400, "Invalid consultation status")
        with db() as conn:
            row = conn.execute("SELECT user_id, doctor_id FROM consultations WHERE id = ?", (consultation_id,)).fetchone()
            if row is None:
                raise ApiError(404, "Consultation not found")
            conn.execute(
                "UPDATE consultations SET status = ?, updated_at = ? WHERE id = ?",
                (status, utc_now(), consultation_id),
            )
        self.notify(row["user_id"], "Consultation updated", f"Your consultation is now {status}.", "consultation")
        self.audit(actor["id"], "consultation.updated", "consultation", consultation_id, body)
        matches = [c for c in self.staff_consultations(row["doctor_id"]) if c["id"] == consultation_id]
        return matches[0] if matches else {"id": consultation_id, "status": status}

    def lab_portal(self, query: dict[str, str]) -> dict[str, Any]:
        self.require_role(ADMIN_ROLES | {"lab_tech", "doctor", "nurse"})
        bookings = self.staff_lab_bookings(query)
        return {
            "pendingBookings": [b for b in bookings if b["status"] in {"scheduled", "pending", "confirmed"}],
            "processingBookings": [b for b in bookings if b["status"] in {"sample_collected", "processing"}],
            "recentResults": self.staff_lab_results(query)[:20],
        }

    def password_reset_request(self, body: dict[str, Any]) -> str:
        email = str(body.get("email") or "").strip().lower()
        if "@" not in email:
            raise ApiError(400, "Valid email is required")
        with db() as conn:
            row = conn.execute("SELECT id FROM users WHERE email = ?", (email,)).fetchone()
            if row is None:
                raise ApiError(404, "User not found")
            user_id = row["id"]
            token = secrets.token_urlsafe(32)
            expires_at = (dt.datetime.now(dt.timezone.utc) + dt.timedelta(seconds=PASSWORD_RESET_TOKEN_TTL)).isoformat()
            conn.execute(
                "INSERT INTO password_reset_tokens (user_id, token, expires_at, created_at) VALUES (?, ?, ?, ?)",
                (user_id, token, expires_at, utc_now()),
            )
        self.notify(user_id, "Password reset requested", f"Use this token to reset your password: {token}", "security", channel="email")
        return "Password reset instructions have been sent if the email exists."

    def password_reset(self, body: dict[str, Any]) -> str:
        token = str(body.get("token") or "").strip()
        password = str(body.get("password") or "")
        if len(password) < 6:
            raise ApiError(400, "Password must be at least 6 characters")
        with db() as conn:
            row = conn.execute(
                "SELECT id, user_id, expires_at, used FROM password_reset_tokens WHERE token = ?",
                (token,),
            ).fetchone()
            if row is None:
                raise ApiError(404, "Invalid or expired token")
            if row["used"]:
                raise ApiError(400, "This token has already been used")
            if dt.datetime.fromisoformat(row["expires_at"]).timestamp() < time.time():
                raise ApiError(400, "Token has expired")
            conn.execute(
                "UPDATE users SET password_hash = ?, updated_at = ? WHERE id = ?",
                (hash_password(password), utc_now(), row["user_id"]),
            )
            conn.execute(
                "UPDATE password_reset_tokens SET used = 1 WHERE id = ?",
                (row["id"],),
            )
        self.notify(row["user_id"], "Password reset completed", "Your password has been updated.", "security", channel="email")
        return "Password has been reset successfully."

    def list_invoices(self, query: dict[str, str]) -> list[dict[str, Any]]:
        user = self.current_user()
        clauses = []
        params: list[Any] = []
        if query.get("patientId"):
            clauses.append("inv.user_id = ?")
            params.append(int(query["patientId"]))
        if query.get("status"):
            clauses.append("inv.status = ?")
            params.append(query["status"])
        if user["role"] == "patient":
            clauses.append("inv.user_id = ?")
            params.append(user["id"])
        if user["role"] not in STAFF_ROLES | {"patient"}:
            raise ApiError(403, "You do not have permission for this action")
        where = "WHERE " + " AND ".join(clauses) if clauses else ""
        with db() as conn:
            rows = conn.execute(
                f"""
                SELECT inv.id, inv.user_id AS patientId, u.full_name AS patientName,
                       inv.appointment_id AS appointmentId, inv.lab_booking_id AS labBookingId,
                       inv.description, inv.amount, inv.currency, inv.status,
                       inv.due_date AS dueDate, inv.paid_at AS paidAt,
                       inv.created_at AS createdAt, inv.updated_at AS updatedAt
                FROM invoices inv
                JOIN users u ON u.id = inv.user_id
                {where}
                ORDER BY inv.created_at DESC
                """,
                params,
            ).fetchall()
        return rows_to_list(rows)

    def create_invoice(self, body: dict[str, Any]) -> dict[str, Any]:
        actor = self.require_role(ADMIN_ROLES | {"receptionist"})
        patient_id = int(body.get("patientId") or 0)
        amount = int(body.get("amount") or 0)
        description = str(body.get("description") or "Invoice")
        if not patient_id or amount <= 0:
            raise ApiError(400, "patientId and positive amount are required")
        now = utc_now()
        with db() as conn:
            cur = conn.execute(
                """
                INSERT INTO invoices (user_id, appointment_id, lab_booking_id, description, amount, currency, status, due_date, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, 'pending', ?, ?, ?)
                """,
                (
                    patient_id,
                    body.get("appointmentId"),
                    body.get("labBookingId"),
                    description,
                    amount,
                    str(body.get("currency") or "TZS"),
                    str(body.get("dueDate") or dt.date.today().isoformat()),
                    now,
                    now,
                ),
            )
            invoice_id = cur.lastrowid
        self.audit(actor["id"], "invoice.created", "invoice", invoice_id, body)
        return [inv for inv in self.list_invoices({"patientId": str(patient_id)}) if inv["id"] == invoice_id][0]

    def create_payment(self, body: dict[str, Any]) -> dict[str, Any]:
        user = self.current_user()
        invoice_id = int(body.get("invoiceId") or 0)
        amount = int(body.get("amount") or 0)
        if not invoice_id or amount <= 0:
            raise ApiError(400, "invoiceId and positive amount are required")
        with db() as conn:
            invoice = conn.execute("SELECT user_id, amount, status FROM invoices WHERE id = ?", (invoice_id,)).fetchone()
            if invoice is None:
                raise ApiError(404, "Invoice not found")
            if invoice["status"] == "paid":
                raise ApiError(409, "Invoice is already paid")
            transaction_ref = secrets.token_hex(12)
            now = utc_now()
            cur = conn.execute(
                """
                INSERT INTO payments (invoice_id, user_id, amount, currency, method, provider, transaction_reference, status, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, 'paid', ?)
                """,
                (
                    invoice_id,
                    user["id"],
                    amount,
                    str(body.get("currency") or "TZS"),
                    str(body.get("method") or "card"),
                    str(body.get("provider") or "local"),
                    transaction_ref,
                    now,
                ),
            )
            conn.execute("UPDATE invoices SET status = 'paid', paid_at = ?, updated_at = ? WHERE id = ?", (now, now, invoice_id))
        self.notify(user["id"], "Payment received", f"Payment of {amount} for invoice {invoice_id} was received.", "billing", channel="email")
        self.audit(user["id"], "payment.created", "payment", cur.lastrowid, body)
        return {
            "id": cur.lastrowid,
            "invoiceId": invoice_id,
            "amount": amount,
            "currency": str(body.get("currency") or "TZS"),
            "method": str(body.get("method") or "card"),
            "provider": str(body.get("provider") or "local"),
            "transactionReference": transaction_ref,
            "status": "paid",
            "createdAt": now,
        }

    def billing_summary(self, query: dict[str, str]) -> dict[str, Any]:
        self.require_role(ADMIN_ROLES | {"receptionist"})
        with db() as conn:
            totals = conn.execute(
                """
                SELECT status, SUM(amount) AS total, COUNT(*) AS count
                FROM invoices
                GROUP BY status
                """,
            ).fetchall()
            recent_payments = conn.execute(
                """
                SELECT p.id, p.invoice_id AS invoiceId, p.user_id AS patientId, u.full_name AS patientName,
                       p.amount, p.currency, p.method, p.provider, p.transaction_reference AS transactionReference,
                       p.status, p.created_at AS createdAt
                FROM payments p
                JOIN users u ON u.id = p.user_id
                ORDER BY p.created_at DESC LIMIT 30
                """,
            ).fetchall()
        return {
            "invoiceStatus": rows_to_list(totals),
            "recentPayments": rows_to_list(recent_payments),
            "generatedAt": utc_now(),
        }

    def staff_lab_bookings(self, query: dict[str, str]) -> list[dict[str, Any]]:
        clauses = []
        params: list[Any] = []
        if query.get("status"):
            clauses.append("lb.status = ?")
            params.append(query["status"])
        where = "WHERE " + " AND ".join(clauses) if clauses else ""
        with db() as conn:
            rows = conn.execute(
                f"""
                SELECT lb.id, lb.user_id AS patientId, u.full_name AS patientName,
                       lt.id AS labTestId, lt.name, lt.price, lb.booking_date AS date,
                       lb.booking_time AS time, lb.notes, lb.status, lb.created_at AS createdAt
                FROM lab_bookings lb
                JOIN users u ON u.id = lb.user_id
                JOIN lab_tests lt ON lt.id = lb.lab_test_id
                {where}
                ORDER BY lb.booking_date, lb.booking_time
                """,
                params,
            ).fetchall()
        return rows_to_list(rows)

    def lab_update_booking(self, booking_id: int, body: dict[str, Any]) -> dict[str, Any]:
        actor = self.require_role(ADMIN_ROLES | {"lab_tech", "nurse"})
        status = body.get("status")
        if status and status not in LAB_STATUSES:
            raise ApiError(400, "Invalid lab booking status")
        updates = []
        values: list[Any] = []
        for key, column in {"status": "status", "notes": "notes", "date": "booking_date", "time": "booking_time"}.items():
            if key in body:
                updates.append(f"{column} = ?")
                values.append(str(body[key]))
        if not updates:
            matches = [b for b in self.staff_lab_bookings({}) if b["id"] == booking_id]
            if not matches:
                raise ApiError(404, "Lab booking not found")
            return matches[0]
        updates.append("updated_at = ?")
        values.extend([utc_now(), booking_id])
        with db() as conn:
            before = conn.execute("SELECT user_id FROM lab_bookings WHERE id = ?", (booking_id,)).fetchone()
            if before is None:
                raise ApiError(404, "Lab booking not found")
            conn.execute(f"UPDATE lab_bookings SET {', '.join(updates)} WHERE id = ?", values)
        if status:
            self.notify(before["user_id"], "Lab booking updated", f"Your lab booking status is now {status}.", "lab")
        self.audit(actor["id"], "lab_booking.updated", "lab_booking", booking_id, body)
        return [b for b in self.staff_lab_bookings({}) if b["id"] == booking_id][0]

    def staff_lab_results(self, query: dict[str, str]) -> list[dict[str, Any]]:
        clauses = []
        params: list[Any] = []
        if query.get("patientId"):
            clauses.append("lr.user_id = ?")
            params.append(int(query["patientId"]))
        where = "WHERE " + " AND ".join(clauses) if clauses else ""
        with db() as conn:
            rows = conn.execute(
                f"""
                SELECT lr.id, lr.user_id AS patientId, u.full_name AS patientName,
                       lr.test_name AS testName, lr.lab_name AS labName,
                       lr.result_date AS date, lr.status, lr.result_value AS resultValue,
                       lr.notes, lr.doctor_reviewed AS doctorReviewed,
                       lr.created_at AS createdAt
                FROM lab_results lr
                LEFT JOIN users u ON u.id = lr.user_id
                {where}
                ORDER BY lr.result_date DESC
                """,
                params,
            ).fetchall()
        result = rows_to_list(rows)
        for item in result:
            item["doctorReviewed"] = bool(item["doctorReviewed"])
        return result

    def create_lab_result(self, body: dict[str, Any]) -> dict[str, Any]:
        actor = self.require_role(ADMIN_ROLES | {"lab_tech"})
        patient_id = int(body.get("patientId") or body.get("userId") or 0)
        if not patient_id:
            raise ApiError(400, "patientId is required")
        now = utc_now()
        with db() as conn:
            cur = conn.execute(
                """
                INSERT INTO lab_results
                (user_id, test_name, lab_name, result_date, status, result_value, notes, doctor_reviewed, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    patient_id,
                    str(body.get("testName") or ""),
                    str(body.get("labName") or "QmedCO Lab"),
                    str(body.get("date") or dt.date.today().isoformat()),
                    str(body.get("status") or "result_ready"),
                    str(body.get("resultValue") or ""),
                    str(body.get("notes") or ""),
                    1 if body.get("doctorReviewed") else 0,
                    now,
                ),
            )
            result_id = cur.lastrowid
        self.notify(patient_id, "Lab result ready", f"Your {body.get('testName', 'lab')} result is ready.", "lab_result")
        self.audit(actor["id"], "lab_result.created", "lab_result", result_id, body)
        return [r for r in self.staff_lab_results({"patientId": str(patient_id)}) if r["id"] == result_id][0]

    def create_emergency(self, user_id: int | None, body: dict[str, Any]) -> dict[str, Any]:
        patient_name = str(body.get("patientName") or body.get("name") or "").strip()
        phone = str(body.get("phone") or "").strip()
        location = str(body.get("location") or "").strip()
        emergency_type = str(body.get("emergencyType") or body.get("type") or "Medical emergency").strip()
        if not patient_name or not phone or not location:
            raise ApiError(400, "patientName, phone, and location are required")
        now = utc_now()
        with db() as conn:
            cur = conn.execute(
                """
                INSERT INTO emergency_requests
                (user_id, patient_name, phone, location, emergency_type, notes, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (user_id, patient_name, phone, location, emergency_type, str(body.get("notes") or ""), now, now),
            )
            row = conn.execute("SELECT * FROM emergency_requests WHERE id = ?", (cur.lastrowid,)).fetchone()
        item = dict(row)
        item["patientName"] = item.pop("patient_name")
        item["emergencyType"] = item.pop("emergency_type")
        item["createdAt"] = item.pop("created_at")
        item["updatedAt"] = item.pop("updated_at")
        return item

    def emergencies(self, user_id: int | None) -> list[dict[str, Any]]:
        with db() as conn:
            rows = conn.execute("SELECT * FROM emergency_requests WHERE user_id = ? ORDER BY created_at DESC", (user_id,)).fetchall()
        result = rows_to_list(rows)
        for item in result:
            item["patientName"] = item.pop("patient_name")
            item["emergencyType"] = item.pop("emergency_type")
            item["createdAt"] = item.pop("created_at")
            item["updatedAt"] = item.pop("updated_at")
        return result

    def staff_emergencies(self, query: dict[str, str]) -> list[dict[str, Any]]:
        self.require_role(STAFF_ROLES)
        params: list[Any] = []
        where = ""
        if query.get("status"):
            where = "WHERE status = ?"
            params.append(query["status"])
        with db() as conn:
            rows = conn.execute(
                f"""
                SELECT er.*, u.full_name AS accountName
                FROM emergency_requests er
                LEFT JOIN users u ON u.id = er.user_id
                {where}
                ORDER BY er.created_at DESC
                """,
                params,
            ).fetchall()
        result = rows_to_list(rows)
        for item in result:
            item["patientName"] = item.pop("patient_name")
            item["emergencyType"] = item.pop("emergency_type")
            item["createdAt"] = item.pop("created_at")
            item["updatedAt"] = item.pop("updated_at")
        return result

    def staff_update_emergency(self, emergency_id: int, body: dict[str, Any]) -> dict[str, Any]:
        actor = self.require_role(STAFF_ROLES)
        status = str(body.get("status") or "").strip()
        if status not in {"received", "dispatched", "in_progress", "resolved", "cancelled"}:
            raise ApiError(400, "Invalid emergency status")
        with db() as conn:
            row = conn.execute("SELECT user_id FROM emergency_requests WHERE id = ?", (emergency_id,)).fetchone()
            if row is None:
                raise ApiError(404, "Emergency request not found")
            conn.execute(
                "UPDATE emergency_requests SET status = ?, updated_at = ? WHERE id = ?",
                (status, utc_now(), emergency_id),
            )
        if row["user_id"]:
            self.notify(row["user_id"], "Emergency request updated", f"Your emergency request is now {status}.", "emergency")
        self.audit(actor["id"], "emergency.updated", "emergency_request", emergency_id, body)
        matches = [e for e in self.staff_emergencies({}) if e["id"] == emergency_id]
        return matches[0]

    def messages(self, user_id: int | None, query: dict[str, str]) -> list[dict[str, Any]]:
        params: list[Any] = [user_id]
        doctor_clause = ""
        if query.get("doctorId"):
            doctor_clause = "AND m.doctor_id = ?"
            params.append(int(query["doctorId"]))
        with db() as conn:
            rows = conn.execute(
                f"""
                SELECT m.id, m.doctor_id AS doctorId, d.name AS doctor, m.direction,
                       m.body, m.created_at AS createdAt, m.read_at AS readAt
                FROM messages m
                LEFT JOIN doctors d ON d.id = m.doctor_id
                WHERE m.user_id = ? {doctor_clause}
                ORDER BY m.created_at
                """,
                params,
            ).fetchall()
        return rows_to_list(rows)

    def chat_threads(self, query: dict[str, str]) -> list[dict[str, Any]]:
        clauses = []
        params: list[Any] = []
        if query.get("category") and query["category"] != "all":
            clauses.append("category = ?")
            params.append(query["category"])
        if query.get("search"):
            clauses.append("(lower(name) LIKE ? OR lower(specialty) LIKE ? OR lower(last_message) LIKE ?)")
            search = f"%{query['search'].lower()}%"
            params.extend([search, search, search])
        where = "WHERE " + " AND ".join(clauses) if clauses else ""
        with db() as conn:
            rows = conn.execute(
                f"""
                SELECT id, name, specialty, last_message AS lastMessage,
                       display_time AS time, unread_count AS unreadCount,
                       avatar_icon AS avatarIcon, avatar_color AS avatarColor,
                       category, is_online AS isOnline, is_emergency AS isEmergency,
                       created_at AS createdAt
                FROM chat_threads
                {where}
                ORDER BY is_emergency DESC, unread_count DESC, id
                """,
                params,
            ).fetchall()
        result = rows_to_list(rows)
        for item in result:
            item["isOnline"] = bool(item["isOnline"])
            item["isEmergency"] = bool(item["isEmergency"])
        return result

    def create_message(self, user_id: int | None, body: dict[str, Any]) -> dict[str, Any]:
        doctor_id = body.get("doctorId")
        message = str(body.get("message") or body.get("body") or "").strip()
        if not message:
            raise ApiError(400, "message is required")
        now = utc_now()
        with db() as conn:
            if doctor_id and conn.execute("SELECT 1 FROM doctors WHERE id = ?", (int(doctor_id),)).fetchone() is None:
                raise ApiError(404, "Doctor not found")
            cur = conn.execute(
                "INSERT INTO messages (user_id, doctor_id, direction, body, created_at) VALUES (?, ?, 'outbound', ?, ?)",
                (user_id, int(doctor_id) if doctor_id else None, message, now),
            )
            msg_id = cur.lastrowid
        return [m for m in self.messages(user_id, {}) if m["id"] == msg_id][0]

    def health_tips(self, query: dict[str, str]) -> list[dict[str, Any]]:
        params: list[Any] = []
        where = ""
        if query.get("category"):
            where = "WHERE lower(category) = ?"
            params.append(query["category"].lower())
        with db() as conn:
            rows = conn.execute(
                f"SELECT id, title, body, category, image_path AS imagePath, created_at AS createdAt FROM health_tips {where} ORDER BY created_at DESC",
                params,
            ).fetchall()
        return rows_to_list(rows)

    def patient_scope_user_id(self, query: dict[str, str] | dict[str, Any]) -> int:
        actor = self.current_user()
        requested = query.get("patientId") or query.get("userId")
        if actor["role"] == "patient":
            return int(actor["id"])
        if actor["role"] in STAFF_ROLES and requested:
            return int(requested)
        if actor["role"] in STAFF_ROLES:
            raise ApiError(400, "patientId is required for staff requests")
        raise ApiError(403, "You do not have permission for this action")

    def medical_records(self, query: dict[str, str]) -> list[dict[str, Any]]:
        patient_id = self.patient_scope_user_id(query)
        with db() as conn:
            rows = conn.execute(
                """
                SELECT mr.id, mr.user_id AS patientId, u.full_name AS patientName,
                       mr.doctor_id AS doctorId, d.name AS doctor,
                       mr.appointment_id AS appointmentId, mr.record_type AS recordType,
                       mr.title, mr.diagnosis, mr.notes, mr.allergies, mr.attachments,
                       mr.created_at AS createdAt, mr.updated_at AS updatedAt
                FROM medical_records mr
                JOIN users u ON u.id = mr.user_id
                LEFT JOIN doctors d ON d.id = mr.doctor_id
                WHERE mr.user_id = ?
                ORDER BY mr.created_at DESC
                """,
                (patient_id,),
            ).fetchall()
        result = rows_to_list(rows)
        for item in result:
            item["attachments"] = json.loads(item["attachments"] or "[]")
        return result

    def create_medical_record(self, body: dict[str, Any]) -> dict[str, Any]:
        actor = self.require_role(CLINICAL_ROLES)
        patient_id = int(body.get("patientId") or body.get("userId") or 0)
        if not patient_id:
            raise ApiError(400, "patientId is required")
        doctor_id = body.get("doctorId")
        if not doctor_id and actor["role"] == "doctor":
            doctor_id = self.doctor_id_for_user(actor["id"])
        now = utc_now()
        with db() as conn:
            cur = conn.execute(
                """
                INSERT INTO medical_records
                (user_id, doctor_id, appointment_id, record_type, title, diagnosis, notes, allergies, attachments, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    patient_id,
                    doctor_id,
                    body.get("appointmentId"),
                    str(body.get("recordType") or "visit_note"),
                    str(body.get("title") or "Clinical note"),
                    str(body.get("diagnosis") or ""),
                    str(body.get("notes") or ""),
                    str(body.get("allergies") or ""),
                    json.dumps(body.get("attachments") if isinstance(body.get("attachments"), list) else []),
                    now,
                    now,
                ),
            )
            record_id = cur.lastrowid
        self.audit(actor["id"], "medical_record.created", "medical_record", record_id, body)
        self.notify(patient_id, "Medical record updated", "A clinician added a new record to your profile.", "medical_record")
        return [r for r in self.medical_records({"patientId": str(patient_id)}) if r["id"] == record_id][0]

    def vitals(self, query: dict[str, str]) -> list[dict[str, Any]]:
        patient_id = self.patient_scope_user_id(query)
        with db() as conn:
            rows = conn.execute(
                """
                SELECT id, user_id AS patientId, recorded_by AS recordedBy,
                       temperature, blood_pressure AS bloodPressure, pulse,
                       weight, height, notes, created_at AS createdAt
                FROM patient_vitals
                WHERE user_id = ?
                ORDER BY created_at DESC
                """,
                (patient_id,),
            ).fetchall()
        return rows_to_list(rows)

    def create_vital(self, body: dict[str, Any]) -> dict[str, Any]:
        actor = self.require_role(CLINICAL_ROLES)
        patient_id = int(body.get("patientId") or body.get("userId") or 0)
        if not patient_id:
            raise ApiError(400, "patientId is required")
        now = utc_now()
        with db() as conn:
            cur = conn.execute(
                """
                INSERT INTO patient_vitals
                (user_id, recorded_by, temperature, blood_pressure, pulse, weight, height, notes, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    patient_id,
                    actor["id"],
                    str(body.get("temperature") or ""),
                    str(body.get("bloodPressure") or ""),
                    str(body.get("pulse") or ""),
                    str(body.get("weight") or ""),
                    str(body.get("height") or ""),
                    str(body.get("notes") or ""),
                    now,
                ),
            )
            vital_id = cur.lastrowid
        self.audit(actor["id"], "vital.created", "vital", vital_id, body)
        return [v for v in self.vitals({"patientId": str(patient_id)}) if v["id"] == vital_id][0]

    def prescriptions(self, query: dict[str, str]) -> list[dict[str, Any]]:
        patient_id = self.patient_scope_user_id(query)
        with db() as conn:
            rows = conn.execute(
                """
                SELECT p.id, p.user_id AS patientId, p.doctor_id AS doctorId,
                       d.name AS doctor, p.appointment_id AS appointmentId,
                       p.medication, p.dosage, p.frequency, p.duration,
                       p.instructions, p.status, p.created_at AS createdAt
                FROM prescriptions p
                JOIN doctors d ON d.id = p.doctor_id
                WHERE p.user_id = ?
                ORDER BY p.created_at DESC
                """,
                (patient_id,),
            ).fetchall()
        return rows_to_list(rows)

    def create_prescription(self, body: dict[str, Any]) -> dict[str, Any]:
        actor = self.require_role(CLINICAL_ROLES)
        patient_id = int(body.get("patientId") or body.get("userId") or 0)
        if not patient_id:
            raise ApiError(400, "patientId is required")
        doctor_id = int(body.get("doctorId") or (self.doctor_id_for_user(actor["id"]) if actor["role"] == "doctor" else 0))
        if not doctor_id:
            raise ApiError(400, "doctorId is required")
        now = utc_now()
        with db() as conn:
            cur = conn.execute(
                """
                INSERT INTO prescriptions
                (user_id, doctor_id, appointment_id, medication, dosage, frequency, duration, instructions, status, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    patient_id,
                    doctor_id,
                    body.get("appointmentId"),
                    str(body.get("medication") or ""),
                    str(body.get("dosage") or ""),
                    str(body.get("frequency") or ""),
                    str(body.get("duration") or ""),
                    str(body.get("instructions") or ""),
                    str(body.get("status") or "active"),
                    now,
                ),
            )
            prescription_id = cur.lastrowid
        self.audit(actor["id"], "prescription.created", "prescription", prescription_id, body)
        self.notify(patient_id, "Prescription added", f"{body.get('medication', 'A medication')} was added to your prescriptions.", "prescription")
        return [p for p in self.prescriptions({"patientId": str(patient_id)}) if p["id"] == prescription_id][0]

    def notifications(self) -> list[dict[str, Any]]:
        user_id = self.current_user_id()
        with db() as conn:
            rows = conn.execute(
                """
                SELECT id, title, body, channel, type, read_at AS readAt, created_at AS createdAt
                FROM notifications WHERE user_id = ? ORDER BY created_at DESC
                """,
                (user_id,),
            ).fetchall()
        return rows_to_list(rows)

    def mark_notification_read(self, notification_id: int) -> dict[str, Any]:
        user_id = self.current_user_id()
        with db() as conn:
            cur = conn.execute(
                "UPDATE notifications SET read_at = ? WHERE id = ? AND user_id = ?",
                (utc_now(), notification_id, user_id),
            )
            if cur.rowcount == 0:
                raise ApiError(404, "Notification not found")
            row = conn.execute(
                "SELECT id, title, body, channel, type, read_at AS readAt, created_at AS createdAt FROM notifications WHERE id = ?",
                (notification_id,),
            ).fetchone()
        return dict(row)

    def audit_logs(self, query: dict[str, str]) -> list[dict[str, Any]]:
        self.require_role(ADMIN_ROLES)
        params: list[Any] = []
        where = ""
        if query.get("entityType"):
            where = "WHERE entity_type = ?"
            params.append(query["entityType"])
        with db() as conn:
            rows = conn.execute(
                f"""
                SELECT al.id, al.actor_user_id AS actorUserId, u.full_name AS actorName,
                       al.action, al.entity_type AS entityType, al.entity_id AS entityId,
                       al.metadata, al.created_at AS createdAt
                FROM audit_logs al
                LEFT JOIN users u ON u.id = al.actor_user_id
                {where}
                ORDER BY al.created_at DESC
                LIMIT 200
                """,
                params,
            ).fetchall()
        result = rows_to_list(rows)
        for item in result:
            item["metadata"] = json.loads(item["metadata"] or "{}")
        return result

    def reports_summary(self, query: dict[str, str]) -> dict[str, Any]:
        self.require_role(ADMIN_ROLES | {"receptionist"})
        with db() as conn:
            appt_by_status = rows_to_list(conn.execute("SELECT status, COUNT(*) AS count FROM appointments GROUP BY status").fetchall())
            lab_by_status = rows_to_list(conn.execute("SELECT status, COUNT(*) AS count FROM lab_bookings GROUP BY status").fetchall())
            doctor_volume = rows_to_list(
                conn.execute(
                    """
                    SELECT d.name AS doctor, COUNT(ap.id) AS appointments
                    FROM doctors d
                    LEFT JOIN appointments ap ON ap.doctor_id = d.id
                    GROUP BY d.id
                    ORDER BY appointments DESC
                    """
                ).fetchall()
            )
            daily_appointments = rows_to_list(
                conn.execute(
                    """
                    SELECT appointment_date AS date, COUNT(*) AS count
                    FROM appointments GROUP BY appointment_date
                    ORDER BY appointment_date DESC LIMIT 30
                    """
                ).fetchall()
            )
        return {
            "appointmentStatus": appt_by_status,
            "labStatus": lab_by_status,
            "doctorVolume": doctor_volume,
            "dailyAppointments": daily_appointments,
            "generatedAt": utc_now(),
        }

    def dashboard(self, user_id: int | None) -> dict[str, Any]:
        with db() as conn:
            counts = conn.execute(
                """
                SELECT
                  SUM(status IN ('upcoming', 'requested', 'approved', 'confirmed', 'pending')) AS upcoming,
                  SUM(status = 'completed') AS completed,
                  SUM(status = 'cancelled') AS cancelled
                FROM appointments WHERE user_id = ?
                """,
                (user_id,),
            ).fetchone()
        return {
            "user": self.get_user(user_id),
            "appointmentSummary": {
                "upcoming": counts["upcoming"] or 0,
                "completed": counts["completed"] or 0,
                "cancelled": counts["cancelled"] or 0,
            },
            "upcomingAppointments": self.appointments(user_id, {"status": "upcoming"})[:3],
            "healthTips": self.health_tips({})[:3],
        }


def main() -> None:
    parser = argparse.ArgumentParser(description="Run the QmedCO backend API")
    parser.add_argument("--host", default=os.environ.get("QMEDCO_HOST", "127.0.0.1"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("QMEDCO_PORT", "8000")))
    args = parser.parse_args()
    init_db()
    server = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f"QmedCO backend running at http://{args.host}:{args.port}")
    print(f"SQLite database: {DB_PATH}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down QmedCO backend")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
