import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/session_service.dart';
import 'login_screen.dart';

const _bg = Color(0xFFF3F7FB);
const _navy = Color(0xFF0F2B5B);
const _blue = Color(0xFF1565C0);
const _rose = Color(0xFFDC2626);

class PortalScaffold extends StatefulWidget {
  final String title;
  final List<PortalTab> tabs;
  const PortalScaffold({super.key, required this.title, required this.tabs});

  @override
  State<PortalScaffold> createState() => _PortalScaffoldState();
}

class _PortalScaffoldState extends State<PortalScaffold> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = SessionService.instance.user;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            Text(
              '${user?['fullName'] ?? ''} · ${user?['role'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await SessionService.instance.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: widget.tabs[_index].child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          for (final tab in widget.tabs)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}

class PortalTab {
  final String label;
  final IconData icon;
  final Widget child;
  const PortalTab(this.label, this.icon, this.child);
}

class PatientPortalScreen extends StatelessWidget {
  const PatientPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PortalScaffold(
      title: 'QmedCO Patient',
      tabs: [
        PortalTab('Home', Icons.home_rounded, PatientHomeTab()),
        PortalTab('Book', Icons.add_circle_rounded, PatientBookingTab()),
        PortalTab('Records', Icons.folder_shared_rounded, PatientRecordsTab()),
        PortalTab('Care', Icons.medical_information_rounded, PatientCareTab()),
      ],
    );
  }
}

class AdminPortalScreen extends StatelessWidget {
  const AdminPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PortalScaffold(
      title: 'QmedCO Admin',
      tabs: [
        PortalTab('Overview', Icons.dashboard_rounded, AdminOverviewTab()),
        PortalTab('Ops', Icons.fact_check_rounded, StaffAppointmentsTab()),
        PortalTab('Catalog', Icons.local_hospital_rounded, AdminCatalogTab()),
        PortalTab('People', Icons.admin_panel_settings_rounded, AdminPeopleTab()),
        PortalTab('Reports', Icons.bar_chart_rounded, ReportsTab()),
      ],
    );
  }
}

class DoctorPortalScreen extends StatelessWidget {
  const DoctorPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PortalScaffold(
      title: 'QmedCO Doctor',
      tabs: [
        PortalTab('Overview', Icons.dashboard_rounded, DoctorOverviewTab()),
        PortalTab('Queue', Icons.fact_check_rounded, DoctorAppointmentsTab()),
        PortalTab('Patients', Icons.assignment_ind_rounded, ClinicalActionsTab()),
        PortalTab('Schedule', Icons.event_busy_rounded, DoctorScheduleTab()),
        PortalTab('Consults', Icons.video_call_rounded, DoctorConsultsTab()),
      ],
    );
  }
}

class LabPortalScreen extends StatelessWidget {
  const LabPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PortalScaffold(
      title: 'QmedCO Lab',
      tabs: [
        PortalTab('Queue', Icons.science_rounded, LabQueueTab()),
        PortalTab('Results', Icons.upload_file_rounded, LabResultTab()),
        PortalTab('Reports', Icons.bar_chart_rounded, ReportsTab()),
      ],
    );
  }
}

class StaffPortalScreen extends StatelessWidget {
  const StaffPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PortalScaffold(
      title: 'QmedCO Staff',
      tabs: [
        PortalTab('Appointments', Icons.fact_check_rounded, StaffAppointmentsTab()),
        PortalTab('Patients', Icons.people_rounded, ClinicalActionsTab()),
        PortalTab('Emergency', Icons.emergency_rounded, EmergencyQueueTab()),
        PortalTab('Reports', Icons.bar_chart_rounded, ReportsTab()),
      ],
    );
  }
}

class ApiFuture<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext, T, VoidCallback) builder;
  const ApiFuture({super.key, required this.load, required this.builder});

  @override
  State<ApiFuture<T>> createState() => _ApiFutureState<T>();
}

class _ApiFutureState<T> extends State<ApiFuture<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  void _reload() => setState(() => _future = widget.load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _ErrorState(error: snap.error.toString(), onRetry: _reload);
        }
        return widget.builder(context, snap.data as T, _reload);
      },
    );
  }
}

class PatientHomeTab extends StatelessWidget {
  const PatientHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () => ApiClient.instance.get('/api/dashboard'),
      builder: (context, data, reload) {
        final summary = data['appointmentSummary'] as Map<String, dynamic>;
        final appointments = data['upcomingAppointments'] as List;
        final tips = data['healthTips'] as List;
        return RefreshIndicator(
          onRefresh: () async => reload(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatGrid(items: {
                'Upcoming': summary['upcoming'],
                'Completed': summary['completed'],
                'Cancelled': summary['cancelled'],
              }),
              _Section('Upcoming appointments', [
                for (final item in appointments)
                  _InfoTile(
                    title: item['doctor'],
                    subtitle: '${item['date']} · ${item['time']} · ${item['status']}',
                    icon: Icons.event_note_rounded,
                  ),
              ]),
              _Section('Health tips', [
                for (final item in tips)
                  _InfoTile(
                    title: item['title'],
                    subtitle: item['body'],
                    icon: Icons.tips_and_updates_rounded,
                  ),
              ]),
            ],
          ),
        );
      },
    );
  }
}

class PatientBookingTab extends StatefulWidget {
  const PatientBookingTab({super.key});

  @override
  State<PatientBookingTab> createState() => _PatientBookingTabState();
}

class _PatientBookingTabState extends State<PatientBookingTab> {
  int? _doctorId;
  String _date = '2026-06-01';
  String? _slot;
  bool _saving = false;

  Future<void> _book(VoidCallback reload) async {
    if (_doctorId == null || _slot == null) return;
    setState(() => _saving = true);
    try {
      await ApiClient.instance.post('/api/appointments', {
        'doctorId': _doctorId,
        'date': _date,
        'time': _slot,
        'reason': 'App booking',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment booked')));
      reload();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () async {
        final doctors = await ApiClient.instance.get('/api/doctors?available=true');
        if (_doctorId == null && (doctors['doctors'] as List).isNotEmpty) {
          _doctorId = (doctors['doctors'] as List).first['id'];
        }
        final slots = _doctorId == null
            ? {'slots': []}
            : await ApiClient.instance.get('/api/time-slots?doctorId=$_doctorId&date=$_date');
        return {'doctors': doctors['doctors'], 'slots': slots['slots']};
      },
      builder: (context, data, reload) {
        final doctors = data['doctors'] as List;
        final slots = data['slots'] as List;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelTitle('Book an appointment'),
                  DropdownButtonFormField<int>(
                    initialValue: _doctorId,
                    items: [
                      for (final doctor in doctors)
                        DropdownMenuItem<int>(
                          value: doctor['id'],
                          child: Text('${doctor['name']} · ${doctor['specialty']}'),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _doctorId = value;
                        _slot = null;
                      });
                      reload();
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _date,
                    decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                    onChanged: (value) => _date = value,
                    onFieldSubmitted: (_) => reload(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final slot in slots)
                        ChoiceChip(
                          label: Text(slot['time']),
                          selected: _slot == slot['time'],
                          onSelected: slot['available']
                              ? (_) => setState(() => _slot = slot['time'])
                              : null,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _saving ? null : () => _book(reload),
                    icon: const Icon(Icons.event_available_rounded),
                    label: Text(_saving ? 'Booking...' : 'Confirm booking'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const PatientAppointmentsList(),
          ],
        );
      },
    );
  }
}

class PatientAppointmentsList extends StatelessWidget {
  const PatientAppointmentsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () => ApiClient.instance.get('/api/appointments'),
      builder: (_, data, __) => _Section('My appointments', [
        for (final appt in data['appointments'] as List)
          _InfoTile(
            title: appt['doctor'],
            subtitle: '${appt['date']} · ${appt['time']} · ${appt['status']}',
            icon: Icons.calendar_month_rounded,
          ),
      ]),
    );
  }
}

class PatientCareTab extends StatefulWidget {
  const PatientCareTab({super.key});

  @override
  State<PatientCareTab> createState() => _PatientCareTabState();
}

class _PatientCareTabState extends State<PatientCareTab> {
  int? _doctorId;
  int? _labTestId;
  final _symptoms = TextEditingController(text: 'I need a medical consultation.');
  final _emergencyNotes = TextEditingController(text: 'Need urgent support.');
  final _phone = TextEditingController(text: '+255 700 000 000');
  final _location = TextEditingController(text: 'Dar es Salaam');

  @override
  void dispose() {
    _symptoms.dispose();
    _emergencyNotes.dispose();
    _phone.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _consult() async {
    if (_doctorId == null) return;
    await ApiClient.instance.post('/api/consultations', {
      'doctorId': _doctorId,
      'mode': 'chat',
      'symptoms': _symptoms.text,
    });
    if (!mounted) return;
    _toast(context, 'Consultation requested');
  }

  Future<void> _labBook() async {
    if (_labTestId == null) return;
    await ApiClient.instance.post('/api/lab-bookings', {
      'labTestId': _labTestId,
      'date': '2026-06-02',
      'time': '10:00',
      'notes': 'Booked from patient app',
    });
    if (!mounted) return;
    _toast(context, 'Lab test booked');
  }

  Future<void> _emergency() async {
    final name = SessionService.instance.user?['fullName']?.toString() ?? 'Patient';
    await ApiClient.instance.post('/api/emergency-requests', {
      'patientName': name,
      'phone': _phone.text,
      'location': _location.text,
      'emergencyType': 'Medical emergency',
      'notes': _emergencyNotes.text,
    });
    if (!mounted) return;
    _toast(context, 'Emergency request sent');
  }

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () async => {
        'doctors': (await ApiClient.instance.get('/api/doctors?available=true'))['doctors'],
        'tests': (await ApiClient.instance.get('/api/lab-tests'))['labTests'],
        'threads': (await ApiClient.instance.get('/api/chat-threads'))['chatThreads'],
      },
      builder: (context, data, reload) {
        final doctors = data['doctors'] as List;
        final tests = data['tests'] as List;
        if (_doctorId == null && doctors.isNotEmpty) _doctorId = doctors.first['id'];
        if (_labTestId == null && tests.isNotEmpty) _labTestId = tests.first['id'];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelTitle('Request consultation'),
                  DropdownButtonFormField<int>(
                    initialValue: _doctorId,
                    items: [
                      for (final doctor in doctors)
                        DropdownMenuItem<int>(value: doctor['id'], child: Text('${doctor['name']} · ${doctor['specialty']}')),
                    ],
                    onChanged: (value) => setState(() => _doctorId = value),
                  ),
                  TextField(controller: _symptoms, maxLines: 2, decoration: const InputDecoration(labelText: 'Symptoms')),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: _consult, icon: const Icon(Icons.chat_rounded), label: const Text('Request chat consult')),
                ],
              ),
            ),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelTitle('Book lab test'),
                  DropdownButtonFormField<int>(
                    initialValue: _labTestId,
                    items: [
                      for (final test in tests)
                        DropdownMenuItem<int>(value: test['id'], child: Text('${test['name']} · TZS ${test['price']}')),
                    ],
                    onChanged: (value) => setState(() => _labTestId = value),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: _labBook, icon: const Icon(Icons.science_rounded), label: const Text('Book test')),
                ],
              ),
            ),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelTitle('Emergency request'),
                  TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
                  TextField(controller: _location, decoration: const InputDecoration(labelText: 'Location')),
                  TextField(controller: _emergencyNotes, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: _rose),
                    onPressed: _emergency,
                    icon: const Icon(Icons.emergency_rounded),
                    label: const Text('Send emergency request'),
                  ),
                ],
              ),
            ),
            _Section('Messages', [
              for (final thread in data['threads'] as List)
                _InfoTile(title: thread['name'], subtitle: thread['lastMessage'], icon: Icons.chat_bubble_rounded),
            ]),
          ],
        );
      },
    );
  }
}

class PatientRecordsTab extends StatelessWidget {
  const PatientRecordsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () async => {
        'records': (await ApiClient.instance.get('/api/medical-records'))['medicalRecords'],
        'vitals': (await ApiClient.instance.get('/api/vitals'))['vitals'],
        'prescriptions': (await ApiClient.instance.get('/api/prescriptions'))['prescriptions'],
        'labs': (await ApiClient.instance.get('/api/lab-results'))['labResults'],
        'notifications': (await ApiClient.instance.get('/api/notifications'))['notifications'],
      },
      builder: (context, data, reload) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section('Notifications', [
            for (final n in data['notifications'] as List)
              _ActionCard(
                title: n['title'],
                subtitle: '${n['body']} · ${n['readAt'] == null ? 'Unread' : 'Read'}',
                actions: [
                  _MiniAction('Mark read', () async {
                    await ApiClient.instance.patch('/api/notifications/${n['id']}', {});
                    if (!context.mounted) return;
                    _toast(context, 'Notification marked read');
                    reload();
                  }),
                ],
              ),
          ]),
          _Section('Medical records', [
            for (final r in data['records'] as List)
              _InfoTile(title: r['title'], subtitle: '${r['diagnosis']} · ${r['notes']}', icon: Icons.folder_rounded),
          ]),
          _Section('Vitals', [
            for (final v in data['vitals'] as List)
              _InfoTile(title: v['createdAt'], subtitle: '${v['bloodPressure']} · ${v['temperature']}', icon: Icons.monitor_heart_rounded),
          ]),
          _Section('Prescriptions', [
            for (final p in data['prescriptions'] as List)
              _InfoTile(title: p['medication'], subtitle: '${p['dosage']} · ${p['frequency']} · ${p['duration']}', icon: Icons.medication_rounded),
          ]),
          _Section('Lab results', [
            for (final l in data['labs'] as List)
              _InfoTile(title: l['testName'], subtitle: '${l['status']} · ${l['date']}', icon: Icons.science_rounded),
          ]),
        ],
      ),
    );
  }
}

class MessagesTab extends StatelessWidget {
  const MessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () => ApiClient.instance.get('/api/chat-threads'),
      builder: (_, data, __) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final thread in data['chatThreads'] as List)
            _InfoTile(
              title: thread['name'],
              subtitle: thread['lastMessage'],
              icon: Icons.chat_bubble_rounded,
              trailing: thread['unreadCount'].toString(),
            ),
        ],
      ),
    );
  }
}

class AdminOverviewTab extends StatelessWidget {
  const AdminOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () => ApiClient.instance.get('/api/admin/overview'),
      builder: (_, data, __) {
        final counts = data['counts'] as Map<String, dynamic>;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatGrid(items: counts),
            const _UsersList(),
          ],
        );
      },
    );
  }
}

class _UsersList extends StatelessWidget {
  const _UsersList();

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () => ApiClient.instance.get('/api/admin/users'),
      builder: (_, data, __) => _Section('Users and staff', [
        for (final user in data['users'] as List)
          _InfoTile(
            title: user['fullName'],
            subtitle: '${user['email']} · ${user['role']}',
            icon: Icons.person_rounded,
          ),
      ]),
    );
  }
}

class AdminPeopleTab extends StatefulWidget {
  const AdminPeopleTab({super.key});

  @override
  State<AdminPeopleTab> createState() => _AdminPeopleTabState();
}

class _AdminPeopleTabState extends State<AdminPeopleTab> {
  int? _userId;
  String _role = 'patient';

  Future<void> _saveRole(VoidCallback reload) async {
    if (_userId == null) return;
    await ApiClient.instance.patch('/api/admin/users/$_userId', {'role': _role});
    if (!mounted) return;
    _toast(context, 'Role updated');
    reload();
  }

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () => ApiClient.instance.get('/api/admin/users'),
      builder: (_, data, reload) {
        final users = data['users'] as List;
        if (_userId == null && users.isNotEmpty) {
          _userId = users.first['id'];
          _role = users.first['role'];
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelTitle('Manage user role'),
                  DropdownButtonFormField<int>(
                    initialValue: _userId,
                    items: [
                      for (final user in users)
                        DropdownMenuItem<int>(value: user['id'], child: Text('${user['fullName']} · ${user['role']}')),
                    ],
                    onChanged: (value) {
                      final selected = users.firstWhere((u) => u['id'] == value);
                      setState(() {
                        _userId = value;
                        _role = selected['role'];
                      });
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    items: const [
                      DropdownMenuItem(value: 'patient', child: Text('Patient')),
                      DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                      DropdownMenuItem(value: 'nurse', child: Text('Nurse')),
                      DropdownMenuItem(value: 'lab_tech', child: Text('Lab Tech')),
                      DropdownMenuItem(value: 'receptionist', child: Text('Receptionist')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) => setState(() => _role = value ?? 'patient'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: () => _saveRole(reload), icon: const Icon(Icons.save_rounded), label: const Text('Save role')),
                ],
              ),
            ),
            _Section('All users', [
              for (final user in users)
                _InfoTile(title: user['fullName'], subtitle: '${user['email']} · ${user['role']}', icon: Icons.person_rounded),
            ]),
          ],
        );
      },
    );
  }
}

class StaffAppointmentsTab extends StatelessWidget {
  const StaffAppointmentsTab({super.key});

  Future<void> _setStatus(BuildContext context, int id, String status, VoidCallback reload) async {
    await ApiClient.instance.patch('/api/staff/appointments/$id', {'status': status});
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Marked $status')));
    reload();
  }

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () => ApiClient.instance.get('/api/staff/appointments'),
      builder: (context, data, reload) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final appt in data['appointments'] as List)
            _ActionCard(
              title: '${appt['patientName']} with ${appt['doctor']}',
              subtitle: '${appt['date']} · ${appt['time']} · ${appt['status']}',
              actions: [
                _MiniAction('Check in', () => _setStatus(context, appt['id'], 'checked_in', reload)),
                _MiniAction('In progress', () => _setStatus(context, appt['id'], 'in_progress', reload)),
                _MiniAction('Complete', () => _setStatus(context, appt['id'], 'completed', reload)),
                _MiniAction('No show', () => _setStatus(context, appt['id'], 'no_show', reload)),
              ],
            ),
        ],
      ),
    );
  }
}

class EmergencyQueueTab extends StatelessWidget {
  const EmergencyQueueTab({super.key});

  Future<void> _status(BuildContext context, int id, String status, VoidCallback reload) async {
    await ApiClient.instance.patch('/api/staff/emergency-requests/$id', {'status': status});
    if (!context.mounted) return;
    _toast(context, 'Emergency $status');
    reload();
  }

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () => ApiClient.instance.get('/api/staff/emergency-requests'),
      builder: (context, data, reload) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final e in data['emergencyRequests'] as List)
            _ActionCard(
              title: '${e['patientName']} · ${e['emergencyType']}',
              subtitle: '${e['phone']} · ${e['location']} · ${e['status']}',
              actions: [
                _MiniAction('Dispatch', () => _status(context, e['id'], 'dispatched', reload)),
                _MiniAction('In progress', () => _status(context, e['id'], 'in_progress', reload)),
                _MiniAction('Resolve', () => _status(context, e['id'], 'resolved', reload)),
                _MiniAction('Cancel', () => _status(context, e['id'], 'cancelled', reload)),
              ],
            ),
        ],
      ),
    );
  }
}

class AdminCatalogTab extends StatefulWidget {
  const AdminCatalogTab({super.key});

  @override
  State<AdminCatalogTab> createState() => _AdminCatalogTabState();
}

class _AdminCatalogTabState extends State<AdminCatalogTab> {
  final _departmentName = TextEditingController();
  final _departmentDescription = TextEditingController();
  final _doctorName = TextEditingController();
  final _doctorSpecialty = TextEditingController();
  int? _doctorDepartmentId;

  @override
  void dispose() {
    _departmentName.dispose();
    _departmentDescription.dispose();
    _doctorName.dispose();
    _doctorSpecialty.dispose();
    super.dispose();
  }

  Future<void> _createDepartment(VoidCallback reload) async {
    if (_departmentName.text.trim().isEmpty) return;
    await ApiClient.instance.post('/api/departments', {
      'name': _departmentName.text.trim(),
      'description': _departmentDescription.text.trim(),
      'imagePath': '',
      'services': ['Initial Consultation', 'Follow-up Visits'],
    });
    _departmentName.clear();
    _departmentDescription.clear();
    if (!mounted) return;
    _toast(context, 'Department created');
    reload();
  }

  Future<void> _createDoctor(VoidCallback reload) async {
    if (_doctorName.text.trim().isEmpty || _doctorDepartmentId == null) return;
    await ApiClient.instance.post('/api/doctors', {
      'name': _doctorName.text.trim(),
      'departmentId': _doctorDepartmentId,
      'specialty': _doctorSpecialty.text.trim(),
      'available': true,
      'fee': 15000,
      'experience': '1 yr',
      'imagePath': '',
    });
    _doctorName.clear();
    _doctorSpecialty.clear();
    if (!mounted) return;
    _toast(context, 'Doctor created');
    reload();
  }

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () async => {
        'departments': (await ApiClient.instance.get('/api/departments'))['departments'],
        'doctors': (await ApiClient.instance.get('/api/doctors'))['doctors'],
        'tests': (await ApiClient.instance.get('/api/lab-tests'))['labTests'],
      },
      builder: (_, data, reload) {
        final departments = data['departments'] as List;
        if (_doctorDepartmentId == null && departments.isNotEmpty) _doctorDepartmentId = departments.first['id'];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelTitle('Create department'),
                  TextField(controller: _departmentName, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(controller: _departmentDescription, decoration: const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: () => _createDepartment(reload), icon: const Icon(Icons.add_rounded), label: const Text('Create department')),
                ],
              ),
            ),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelTitle('Create doctor'),
                  TextField(controller: _doctorName, decoration: const InputDecoration(labelText: 'Doctor name')),
                  TextField(controller: _doctorSpecialty, decoration: const InputDecoration(labelText: 'Specialty')),
                  DropdownButtonFormField<int>(
                    initialValue: _doctorDepartmentId,
                    items: [
                      for (final d in departments)
                        DropdownMenuItem<int>(value: d['id'], child: Text(d['name'])),
                    ],
                    onChanged: (value) => setState(() => _doctorDepartmentId = value),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: () => _createDoctor(reload), icon: const Icon(Icons.person_add_rounded), label: const Text('Create doctor')),
                ],
              ),
            ),
            _Section('Departments', [
              for (final d in departments)
                _InfoTile(title: d['name'], subtitle: d['description'], icon: Icons.apartment_rounded),
            ]),
            _Section('Doctors', [
              for (final d in data['doctors'] as List)
                _InfoTile(title: d['name'], subtitle: '${d['specialty']} · TZS ${d['fee']}', icon: Icons.medical_services_rounded),
            ]),
            _Section('Lab tests', [
              for (final t in data['tests'] as List)
                _InfoTile(title: t['name'], subtitle: '${t['duration']} · TZS ${t['price']}', icon: Icons.science_rounded),
            ]),
          ],
        );
      },
    );
  }
}

class DoctorOverviewTab extends StatelessWidget {
  const DoctorOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () => ApiClient.instance.get('/api/doctor/portal'),
      builder: (_, data, __) {
        final appointments = data['appointments'] as List;
        final consults = data['consultations'] as List;
        final today = data['todayAppointments'] as List;
        final waiting = appointments.where((a) => ['confirmed', 'checked_in', 'in_progress', 'pending', 'upcoming'].contains(a['status'])).length;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatGrid(items: {
              'Today': today.length,
              'Active queue': waiting,
              'Consults': consults.length,
              'Completed': appointments.where((a) => a['status'] == 'completed').length,
            }),
            _Section('Today', [
              for (final a in today)
                _InfoTile(
                  title: a['patientName'],
                  subtitle: '${a['time']} · ${a['status']} · ${a['reason']}',
                  icon: Icons.today_rounded,
                ),
            ]),
            _Section('Consultation requests', [
              for (final c in consults.take(5))
                _InfoTile(
                  title: c['patientName'],
                  subtitle: '${c['mode']} · ${c['status']} · ${c['symptoms']}',
                  icon: Icons.video_call_rounded,
                ),
            ]),
          ],
        );
      },
    );
  }
}

class DoctorAppointmentsTab extends StatelessWidget {
  const DoctorAppointmentsTab({super.key});

  Future<void> _setStatus(BuildContext context, int id, String status, VoidCallback reload) async {
    await ApiClient.instance.patch('/api/staff/appointments/$id', {'status': status});
    if (!context.mounted) return;
    _toast(context, 'Appointment $status');
    reload();
  }

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () => ApiClient.instance.get('/api/staff/appointments'),
      builder: (context, data, reload) {
        final appointments = data['appointments'] as List;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section('Doctor queue', [
              for (final appt in appointments)
                _ActionCard(
                  title: appt['patientName'],
                  subtitle: '${appt['date']} · ${appt['time']} · ${appt['status']} · ${appt['reason']}',
                  actions: [
                    _MiniAction('Check in', () => _setStatus(context, appt['id'], 'checked_in', reload)),
                    _MiniAction('Start', () => _setStatus(context, appt['id'], 'in_progress', reload)),
                    _MiniAction('Complete', () => _setStatus(context, appt['id'], 'completed', reload)),
                    _MiniAction('No show', () => _setStatus(context, appt['id'], 'no_show', reload)),
                  ],
                ),
            ]),
          ],
        );
      },
    );
  }
}

class DoctorConsultsTab extends StatelessWidget {
  const DoctorConsultsTab({super.key});

  Future<void> _status(BuildContext context, int id, String status, VoidCallback reload) async {
    await ApiClient.instance.patch('/api/staff/consultations/$id', {'status': status});
    if (!context.mounted) return;
    _toast(context, 'Consultation $status');
    reload();
  }

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () => ApiClient.instance.get('/api/doctor/portal'),
      builder: (context, data, reload) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final c in data['consultations'] as List)
            _ActionCard(
              title: c['patientName'],
              subtitle: '${c['mode']} · ${c['status']} · ${c['symptoms']}',
              actions: [
                _MiniAction('Accept', () => _status(context, c['id'], 'accepted', reload)),
                _MiniAction('Start', () => _status(context, c['id'], 'in_progress', reload)),
                _MiniAction('Complete', () => _status(context, c['id'], 'completed', reload)),
                _MiniAction('Cancel', () => _status(context, c['id'], 'cancelled', reload)),
              ],
            ),
        ],
      ),
    );
  }
}

class ClinicalActionsTab extends StatefulWidget {
  const ClinicalActionsTab({super.key});

  @override
  State<ClinicalActionsTab> createState() => _ClinicalActionsTabState();
}

class _ClinicalActionsTabState extends State<ClinicalActionsTab> {
  int? _patientId;
  final _notes = TextEditingController(text: 'Patient is stable.');
  final _diagnosis = TextEditingController(text: 'Review completed');
  final _temperature = TextEditingController(text: '36.8');
  final _bloodPressure = TextEditingController(text: '120/80');
  final _medication = TextEditingController(text: 'Paracetamol');
  final _dosage = TextEditingController(text: '500mg');
  final _frequency = TextEditingController(text: 'Twice daily');
  final _duration = TextEditingController(text: '3 days');

  @override
  void dispose() {
    _notes.dispose();
    _diagnosis.dispose();
    _temperature.dispose();
    _bloodPressure.dispose();
    _medication.dispose();
    _dosage.dispose();
    _frequency.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _createRecord() async {
    if (_patientId == null) return;
    await ApiClient.instance.post('/api/vitals', {
      'patientId': _patientId,
      'temperature': _temperature.text,
      'bloodPressure': _bloodPressure.text,
    });
    await ApiClient.instance.post('/api/medical-records', {
      'patientId': _patientId,
      'title': 'Visit note',
      'diagnosis': _diagnosis.text,
      'notes': _notes.text,
    });
    await ApiClient.instance.post('/api/prescriptions', {
      'patientId': _patientId,
      'medication': _medication.text,
      'dosage': _dosage.text,
      'frequency': _frequency.text,
      'duration': _duration.text,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clinical record saved')));
  }

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () async {
        final appointments = (await ApiClient.instance.get('/api/staff/appointments'))['appointments'] as List;
        final seen = <int>{};
        final patients = <Map<String, dynamic>>[];
        for (final appt in appointments) {
          final id = appt['patientId'] as int;
          if (seen.add(id)) {
            patients.add({
              'id': id,
              'fullName': appt['patientName'],
              'phone': appt['patientPhone'],
            });
          }
        }
        if (_patientId == null && patients.isNotEmpty) _patientId = patients.first['id'];
        final patientPath = _patientId == null ? null : 'patientId=$_patientId';
        return {
          'patients': patients,
          'records': patientPath == null ? [] : (await ApiClient.instance.get('/api/medical-records?$patientPath'))['medicalRecords'],
          'vitals': patientPath == null ? [] : (await ApiClient.instance.get('/api/vitals?$patientPath'))['vitals'],
          'prescriptions': patientPath == null ? [] : (await ApiClient.instance.get('/api/prescriptions?$patientPath'))['prescriptions'],
        };
      },
      builder: (_, data, reload) {
        final patients = data['patients'] as List;
        if (_patientId == null && patients.isNotEmpty) _patientId = patients.first['id'];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelTitle('Create vitals, note, and prescription'),
                  DropdownButtonFormField<int>(
                    initialValue: _patientId,
                    items: [
                      for (final p in patients)
                        DropdownMenuItem<int>(value: p['id'], child: Text(p['fullName'])),
                    ],
                    onChanged: (value) {
                      setState(() => _patientId = value);
                      reload();
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _temperature,
                          decoration: const InputDecoration(labelText: 'Temp'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _bloodPressure,
                          decoration: const InputDecoration(labelText: 'BP'),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _diagnosis,
                    decoration: const InputDecoration(labelText: 'Diagnosis'),
                  ),
                  TextField(
                    controller: _notes,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Clinical notes'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _medication,
                          decoration: const InputDecoration(labelText: 'Medication'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _dosage,
                          decoration: const InputDecoration(labelText: 'Dosage'),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _frequency,
                          decoration: const InputDecoration(labelText: 'Frequency'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _duration,
                          decoration: const InputDecoration(labelText: 'Duration'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      await _createRecord();
                      reload();
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save clinical update'),
                  ),
                ],
              ),
            ),
            _Section('Medical records', [
              for (final r in data['records'] as List)
                _InfoTile(title: r['title'], subtitle: '${r['diagnosis']} · ${r['notes']}', icon: Icons.folder_rounded),
            ]),
            _Section('Vitals', [
              for (final v in data['vitals'] as List)
                _InfoTile(title: v['createdAt'], subtitle: '${v['bloodPressure']} · ${v['temperature']}', icon: Icons.monitor_heart_rounded),
            ]),
            _Section('Prescriptions', [
              for (final p in data['prescriptions'] as List)
                _InfoTile(title: p['medication'], subtitle: '${p['dosage']} · ${p['frequency']} · ${p['duration']}', icon: Icons.medication_rounded),
            ]),
          ],
        );
      },
    );
  }
}

class DoctorScheduleTab extends StatefulWidget {
  const DoctorScheduleTab({super.key});

  @override
  State<DoctorScheduleTab> createState() => _DoctorScheduleTabState();
}

class _DoctorScheduleTabState extends State<DoctorScheduleTab> {
  int _weekday = 1;
  final _start = TextEditingController(text: '09:00');
  final _end = TextEditingController(text: '16:00');
  final _blockDate = TextEditingController(text: '2026-06-03');
  final _blockReason = TextEditingController(text: 'Unavailable');

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    _blockDate.dispose();
    _blockReason.dispose();
    super.dispose();
  }

  Future<void> _saveAvailability(VoidCallback reload) async {
    await ApiClient.instance.post('/api/doctor/availability', {
      'weekday': _weekday,
      'startTime': _start.text,
      'endTime': _end.text,
      'slotMinutes': 30,
      'maxPatients': 1,
      'active': true,
    });
    if (!mounted) return;
    _toast(context, 'Availability saved');
    reload();
  }

  Future<void> _block(VoidCallback reload) async {
    await ApiClient.instance.post('/api/doctor/blocked-slots', {
      'date': _blockDate.text,
      'startTime': _start.text,
      'endTime': _end.text,
      'reason': _blockReason.text,
    });
    if (!mounted) return;
    _toast(context, 'Slot blocked');
    reload();
  }

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () async => {'availability': (await ApiClient.instance.get('/api/doctor/availability'))['availability']},
      builder: (_, data, reload) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelTitle('Set availability'),
                DropdownButtonFormField<int>(
                  initialValue: _weekday,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Monday')),
                    DropdownMenuItem(value: 2, child: Text('Tuesday')),
                    DropdownMenuItem(value: 3, child: Text('Wednesday')),
                    DropdownMenuItem(value: 4, child: Text('Thursday')),
                    DropdownMenuItem(value: 5, child: Text('Friday')),
                    DropdownMenuItem(value: 6, child: Text('Saturday')),
                    DropdownMenuItem(value: 7, child: Text('Sunday')),
                  ],
                  onChanged: (value) => setState(() => _weekday = value ?? 1),
                ),
                TextField(controller: _start, decoration: const InputDecoration(labelText: 'Start time')),
                TextField(controller: _end, decoration: const InputDecoration(labelText: 'End time')),
                const SizedBox(height: 12),
                FilledButton.icon(onPressed: () => _saveAvailability(reload), icon: const Icon(Icons.save_rounded), label: const Text('Save availability')),
              ],
            ),
          ),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelTitle('Block time'),
                TextField(controller: _blockDate, decoration: const InputDecoration(labelText: 'Date')),
                TextField(controller: _blockReason, decoration: const InputDecoration(labelText: 'Reason')),
                const SizedBox(height: 12),
                OutlinedButton.icon(onPressed: () => _block(reload), icon: const Icon(Icons.event_busy_rounded), label: const Text('Block slot')),
              ],
            ),
          ),
          _Section('Availability', [
            for (final a in data['availability'] as List)
              _InfoTile(
                title: 'Weekday ${a['weekday']}',
                subtitle: '${a['startTime']} - ${a['endTime']} · ${a['slotMinutes']} min',
                icon: Icons.schedule_rounded,
              ),
          ]),
        ],
      ),
    );
  }
}

class LabQueueTab extends StatelessWidget {
  const LabQueueTab({super.key});

  Future<void> _setStatus(BuildContext context, int id, String status, VoidCallback reload) async {
    await ApiClient.instance.patch('/api/lab/bookings/$id', {'status': status});
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lab booking $status')));
    reload();
  }

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () => ApiClient.instance.get('/api/lab/portal'),
      builder: (context, data, reload) {
        final bookings = [
          ...(data['pendingBookings'] as List),
          ...(data['processingBookings'] as List),
        ];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final b in bookings)
              _ActionCard(
                title: '${b['patientName']} · ${b['name']}',
                subtitle: '${b['date']} · ${b['time']} · ${b['status']}',
                actions: [
                  _MiniAction('Collected', () => _setStatus(context, b['id'], 'sample_collected', reload)),
                  _MiniAction('Processing', () => _setStatus(context, b['id'], 'processing', reload)),
                  _MiniAction('Ready', () => _setStatus(context, b['id'], 'result_ready', reload)),
                ],
              ),
          ],
        );
      },
    );
  }
}

class LabResultTab extends StatefulWidget {
  const LabResultTab({super.key});

  @override
  State<LabResultTab> createState() => _LabResultTabState();
}

class _LabResultTabState extends State<LabResultTab> {
  int? _patientId;
  final _testName = TextEditingController(text: 'Complete Blood Count');
  final _result = TextEditingController(text: 'Normal');

  @override
  void dispose() {
    _testName.dispose();
    _result.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_patientId == null) return;
    await ApiClient.instance.post('/api/lab-results', {
      'patientId': _patientId,
      'testName': _testName.text,
      'labName': 'QmedCO Lab',
      'status': 'result_ready',
      'resultValue': _result.text,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Result published')));
  }

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () async => {
        'users': (await ApiClient.instance.get('/api/admin/users?role=patient'))['users'],
        'results': (await ApiClient.instance.get('/api/lab/portal'))['recentResults'],
      },
      builder: (_, data, __) {
        final users = data['users'] as List;
        if (_patientId == null && users.isNotEmpty) _patientId = users.first['id'];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelTitle('Publish lab result'),
                  DropdownButtonFormField<int>(
                    initialValue: _patientId,
                    items: [
                      for (final u in users)
                        DropdownMenuItem<int>(value: u['id'], child: Text(u['fullName'])),
                    ],
                    onChanged: (value) => setState(() => _patientId = value),
                  ),
                  TextField(controller: _testName, decoration: const InputDecoration(labelText: 'Test name')),
                  TextField(controller: _result, decoration: const InputDecoration(labelText: 'Result')),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: _save, icon: const Icon(Icons.upload_rounded), label: const Text('Publish')),
                ],
              ),
            ),
            _Section('Recent results', [
              for (final r in data['results'] as List)
                _InfoTile(title: r['testName'], subtitle: '${r['patientName']} · ${r['status']}', icon: Icons.description_rounded),
            ]),
          ],
        );
      },
    );
  }
}

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () async => {
        'report': await ApiClient.instance.get('/api/reports/summary'),
        'audit': (await ApiClient.instance.get('/api/audit-logs'))['auditLogs'],
      },
      builder: (_, data, __) {
        final report = data['report'] as Map<String, dynamic>;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section('Appointment status', [
              for (final s in report['appointmentStatus'] as List)
                _InfoTile(title: s['status'], subtitle: '${s['count']} appointments', icon: Icons.pie_chart_rounded),
            ]),
            _Section('Lab status', [
              for (final s in report['labStatus'] as List)
                _InfoTile(title: s['status'], subtitle: '${s['count']} bookings', icon: Icons.science_rounded),
            ]),
            _Section('Audit log', [
              for (final a in data['audit'] as List)
                _InfoTile(title: a['action'], subtitle: '${a['actorName'] ?? 'System'} · ${a['createdAt']}', icon: Icons.history_rounded),
            ]),
          ],
        );
      },
    );
  }
}

class PaymentsTab extends StatelessWidget {
  const PaymentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ApiFuture<Map<String, dynamic>>(
      load: () async => {
        'invoices': (await ApiClient.instance.get('/api/billing/invoices'))['invoices'],
        'payments': (await ApiClient.instance.get('/api/payments'))['payments'],
      },
      builder: (_, data, __) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section('Invoices', [
            for (final inv in data['invoices'] as List)
              _ActionCard(
                title: '${inv['patientName']} · TZS ${inv['amount']}',
                subtitle: '${inv['description']} · ${inv['status']} · Due ${inv['dueDate'] ?? 'N/A'}',
                actions: [],
              ),
          ]),
          _Section('Payments', [
            for (final p in data['payments'] as List)
              _InfoTile(
                title: '${p['patientName']} · TZS ${p['amount']}',
                subtitle: '${p['method']} · ${p['provider']} · ${p['createdAt']}',
                icon: Icons.payment_rounded,
              ),
          ]),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final Map<String, dynamic> items;
  const _StatGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.9,
      children: [
        for (final entry in items.entries)
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${entry.value}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _navy)),
                Text(_title(entry.key), style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(title),
          if (children.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No records yet', style: TextStyle(color: Colors.black54)),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE8F3)),
      ),
      child: child,
    );
  }
}

class _PanelTitle extends StatelessWidget {
  final String title;
  const _PanelTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _navy)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? trailing;
  const _InfoTile({required this.title, required this.subtitle, required this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: const Color(0xFFE8F3FF), child: Icon(icon, color: _blue)),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: trailing == null ? null : Chip(label: Text(trailing!)),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_MiniAction> actions;
  const _ActionCard({required this.title, required this.subtitle, required this.actions});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: _navy)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in actions)
                OutlinedButton(onPressed: action.onTap, child: Text(action.label)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAction {
  final String label;
  final VoidCallback onTap;
  const _MiniAction(this.label, this.onTap);
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: _rose, size: 42),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _title(String value) {
  final spaced = value.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}').trim();
  return spaced.isEmpty ? value : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}
