# QmedCO Backend

Dependency-free local REST API for the QmedCO Flutter app.

## Start

```bash
python3 backend/qmedco_api.py --host 127.0.0.1 --port 8000
```

The SQLite database is created automatically at `backend/data/qmedco.sqlite3`.

## Main Endpoints

- `GET /health`
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/me`
- `PATCH /api/me`
- `GET /api/dashboard`
- `GET /api/admin/overview`
- `GET /api/admin/users`
- `PATCH /api/admin/users/{id}`
- `GET /api/departments`
- `POST /api/departments`
- `PATCH /api/departments/{id}`
- `GET /api/doctors`
- `POST /api/doctors`
- `PATCH /api/doctors/{id}`
- `GET /api/doctor/portal`
- `GET /api/doctor/availability`
- `POST /api/doctor/availability`
- `POST /api/doctor/blocked-slots`
- `GET /api/time-slots?doctorId=1&date=2026-06-01`
- `GET /api/appointments`
- `POST /api/appointments`
- `PATCH /api/appointments/{id}`
- `GET /api/staff/appointments`
- `PATCH /api/staff/appointments/{id}`
- `GET /api/lab-tests`
- `GET /api/lab-packages`
- `GET /api/lab-locations`
- `GET /api/lab-results`
- `POST /api/lab-results`
- `POST /api/lab-bookings`
- `GET /api/lab-bookings`
- `GET /api/lab/portal`
- `PATCH /api/lab/bookings/{id}`
- `POST /api/consultations`
- `GET /api/consultations`
- `POST /api/emergency-requests`
- `GET /api/emergency-requests`
- `GET /api/messages`
- `POST /api/messages`
- `GET /api/chat-threads`
- `GET /api/health-tips`
- `GET /api/medical-records`
- `POST /api/medical-records`
- `GET /api/vitals`
- `POST /api/vitals`
- `GET /api/prescriptions`
- `POST /api/prescriptions`
- `GET /api/notifications`
- `PATCH /api/notifications/{id}`
- `GET /api/audit-logs`
- `GET /api/reports/summary`
- `POST /api/auth/password-reset-request`
- `POST /api/auth/password-reset`
- `GET /api/billing/invoices`
- `POST /api/billing/invoices`
- `POST /api/payments`
- `GET /api/billing/summary`

## Seeded App Data

The backend seeds the app's current mock data into SQLite on startup:

- doctors and departments from Home, Doctors, Booking, Department, and Consult screens
- sample appointments for `patient@example.com`
- lab tests, lab packages, nearby labs, upcoming lab bookings, and recent results
- chat/message thread data from the Messages screen
- health tips for pregnancy, children, eye care, dental care, wellness, medication, and prevention

Demo login:

```text
email: patient@example.com
password: secret123
```

Staff logins:

```text
admin@qmedco.test / secret123
doctor@qmedco.test / secret123
nurse@qmedco.test / secret123
lab@qmedco.test / secret123
reception@qmedco.test / secret123
```

## Implementation Stages

Payments and password reset support are now included.

1. Patient app backend: auth, profile, doctors, departments, appointments, lab bookings, consultations, messages, health tips.
2. Clinic operations: admin users, staff appointment queue, richer appointment workflow, doctor scheduling, blocked slots.
3. Clinical care: doctor portal, vitals, medical records, prescriptions, patient notifications.
4. Lab operations: lab portal, booking status workflow, result creation, recent results.
5. Payments & billing: invoices, payments, billing summary, invoice status tracking.
6. Governance: role-based access, audit logs, password reset, operational reports.

Authenticated routes require:

```text
Authorization: Bearer <token>
```

## Example

```bash
curl -s http://127.0.0.1:8000/health

curl -s -X POST http://127.0.0.1:8000/api/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"fullName":"Test Patient","email":"patient@example.com","password":"secret123"}'
```
