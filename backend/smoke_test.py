#!/usr/bin/env python3
"""Smoke test for a running QmedCO backend."""

from __future__ import annotations

import json
import os
import time
import urllib.error
import urllib.request


fuck yBASE = os.environ.get("QMEDCO_BASE", "http://127.0.0.1:8000")


def request(method: str, path: str, body: dict | None = None, token: str | None = None) -> dict:
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(BASE + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=5) as res:
            return json.loads(res.read().decode())
    except urllib.error.HTTPError as exc:
        details = exc.read().decode()
        raise RuntimeError(f"{method} {path} failed: {exc.code} {details}") from exc


def main() -> None:
    stamp = int(time.time())
    health = request("GET", "/health")
    assert health["ok"] is True

    auth = request(
        "POST",
        "/api/auth/register",
        {
            "fullName": "Smoke Test Patient",
            "email": f"smoke{stamp}@example.com",
            "password": "secret123",
            "phone": "+255700000000",
            "location": "Dar es Salaam",
        },
    )
    token = auth["token"]
    doctors = request("GET", "/api/doctors", token=token)["doctors"]
    departments = request("GET", "/api/departments", token=token)["departments"]
    assert doctors and departments

    slots = request("GET", f"/api/time-slots?doctorId={doctors[0]['id']}&date=2026-06-01", token=token)["slots"]
    slot = next(item["time"] for item in slots if item["available"])

    appointment = request(
        "POST",
        "/api/appointments",
        {
            "doctorId": doctors[0]["id"],
            "date": "2026-06-01",
            "time": slot,
            "reason": "General consultation",
            "status": "requested",
        },
        token=token,
    )["appointment"]
    assert appointment["status"] == "requested"

    lab_test = request("GET", "/api/lab-tests", token=token)["labTests"][0]
    lab_booking = request(
        "POST",
        "/api/lab-bookings",
        {"labTestId": lab_test["id"], "date": "2026-06-02", "time": "10:00"},
        token=token,
    )["labBooking"]
    assert lab_booking["status"] == "scheduled"

    message = request(
        "POST",
        "/api/messages",
        {"doctorId": doctors[0]["id"], "message": "Hello doctor"},
        token=token,
    )["message"]
    assert message["body"] == "Hello doctor"

    dashboard = request("GET", "/api/dashboard", token=token)
    assert dashboard["appointmentSummary"]["upcoming"] >= 1

    admin = request(
        "POST",
        "/api/auth/login",
        {"email": "admin@qmedco.test", "password": "secret123"},
    )["token"]
    doctor_token = request(
        "POST",
        "/api/auth/login",
        {"email": "doctor@qmedco.test", "password": "secret123"},
    )["token"]
    lab_token = request(
        "POST",
        "/api/auth/login",
        {"email": "lab@qmedco.test", "password": "secret123"},
    )["token"]

    overview = request("GET", "/api/admin/overview", token=admin)
    assert overview["counts"]["doctors"] >= 1

    staff_appointments = request("GET", "/api/staff/appointments", token=admin)["appointments"]
    assert staff_appointments
    updated = request(
        "PATCH",
        f"/api/staff/appointments/{staff_appointments[0]['id']}",
        {"status": "checked_in"},
        token=admin,
    )["appointment"]
    assert updated["status"] == "checked_in"

    portal = request("GET", "/api/doctor/portal", token=doctor_token)
    assert "appointments" in portal

    consultation = request(
        "POST",
        "/api/consultations",
        {"doctorId": doctors[0]["id"], "mode": "chat", "symptoms": "Smoke test consult"},
        token=token,
    )["consultation"]
    consult_update = request(
        "PATCH",
        f"/api/staff/consultations/{consultation['id']}",
        {"status": "accepted"},
        token=doctor_token,
    )["consultation"]
    assert consult_update["status"] == "accepted"

    patient_id = auth["user"]["id"]
    vital = request(
        "POST",
        "/api/vitals",
        {"patientId": patient_id, "temperature": "36.8", "bloodPressure": "120/80"},
        token=doctor_token,
    )["vital"]
    assert vital["bloodPressure"] == "120/80"

    record = request(
        "POST",
        "/api/medical-records",
        {"patientId": patient_id, "title": "Smoke test visit", "diagnosis": "Stable", "notes": "No acute issue."},
        token=doctor_token,
    )["medicalRecord"]
    assert record["title"] == "Smoke test visit"

    prescription = request(
        "POST",
        "/api/prescriptions",
        {
            "patientId": patient_id,
            "medication": "Paracetamol",
            "dosage": "500mg",
            "frequency": "Twice daily",
            "duration": "3 days",
        },
        token=doctor_token,
    )["prescription"]
    assert prescription["medication"] == "Paracetamol"

    lab_portal = request("GET", "/api/lab/portal", token=lab_token)
    assert "pendingBookings" in lab_portal
    lab_result = request(
        "POST",
        "/api/lab-results",
        {
            "patientId": patient_id,
            "testName": "Smoke CBC",
            "labName": "QmedCO Lab",
            "status": "result_ready",
            "resultValue": "Normal",
        },
        token=lab_token,
    )["labResult"]
    assert lab_result["resultValue"] == "Normal"

    notifications = request("GET", "/api/notifications", token=token)["notifications"]
    assert notifications
    request("PATCH", f"/api/notifications/{notifications[0]['id']}", {}, token=token)

    emergency = request(
        "POST",
        "/api/emergency-requests",
        {
            "patientName": "Smoke Test Patient",
            "phone": "+255700000000",
            "location": "Dar es Salaam",
            "emergencyType": "Medical emergency",
            "notes": "Smoke test emergency",
        },
        token=token,
    )["emergencyRequest"]
    emergency_update = request(
        "PATCH",
        f"/api/staff/emergency-requests/{emergency['id']}",
        {"status": "dispatched"},
        token=admin,
    )["emergencyRequest"]
    assert emergency_update["status"] == "dispatched"

    report = request("GET", "/api/reports/summary", token=admin)
    assert "appointmentStatus" in report

    invoice = request(
        "POST",
        "/api/billing/invoices",
        {"patientId": patient_id, "amount": 12000, "description": "Consultation fee"},
        token=admin,
    )["invoice"]
    assert invoice["status"] == "pending"

    payment = request(
        "POST",
        "/api/payments",
        {"invoiceId": invoice["id"], "amount": 12000},
        token=token,
    )["payment"]
    assert payment["status"] == "paid"

    audit = request("GET", "/api/audit-logs", token=admin)["auditLogs"]
    assert audit
    print("QmedCO backend smoke test passed")


if __name__ == "__main__":
    main()
