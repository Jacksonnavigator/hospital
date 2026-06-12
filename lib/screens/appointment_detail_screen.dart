import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════
//  ClinicBook · Appointment Detail Screen
//  Design: Doctor profile hero (image fills top), info chips,
//  time-slot pills, purple Book Now — mirrors reference UI
// ═══════════════════════════════════════════════════════════════════

class AppointmentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;
  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen>
    with SingleTickerProviderStateMixin {

  // ─── Palette ─────────────────────────────────────────────────────
  static const Color _purple      = Color(0xFF7C4DFF);
  static const Color _purpleLight = Color(0xFFEDE7FF);
  static const Color _bg          = Color(0xFFF8F7FC);
  static const Color _white       = Colors.white;
  static const Color _textDark    = Color(0xFF1A1A2E);
  static const Color _textMid     = Color(0xFF6B7280);
  static const Color _textLight   = Color(0xFFB0B8C5);
  static const Color _green       = Color(0xFF4CAF50);
  static const Color _amber       = Color(0xFFFFB300);
  static const Color _rose        = Color(0xFFEF5350);

  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
        begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> get a => widget.appointment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Hero ──────────────────────────────────────────
              _buildHeroSliver(context),

              // ── Body ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slide,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoChips(),
                          const SizedBox(height: 28),
                          _buildAppointmentCard(),
                          const SizedBox(height: 24),
                          _buildNotesCard(),
                          const SizedBox(height: 24),
                          _buildChecklist(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom Buttons ─────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomButtons(context),
          ),
        ],
      ),
    );
  }

  // ─── Hero sliver ────────────────────────────────────────────────
  Widget _buildHeroSliver(BuildContext ctx) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      elevation: 0,
      backgroundColor: _purple,
      leading: GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: Colors.white),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            icon: const Icon(Icons.phone_rounded,
                size: 18, color: Colors.white),
            onPressed: () {},
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6A35D8), Color(0xFF9C6FFF)],
                ),
              ),
            ),

            // Doctor image — right-aligned, bottom-anchored
            Positioned(
              right: 0, bottom: 0, top: 40,
              child: AspectRatio(
                aspectRatio: 0.72,
                child: Image.asset(
                  a['image'] ?? 'lib/assets/pediatricsdoctot.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(Icons.person_rounded,
                        size: 100,
                        color: Colors.white.withOpacity(0.35)),
                  ),
                ),
              ),
            ),

            // Text overlay — left side
            Positioned(
              left: 20, bottom: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      a['specialty'] ?? 'Specialist',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    a['doctorName'] ?? 'Dr. Name',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.local_hospital_rounded,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      a['hospitalName'] ?? 'Hospital',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12.5),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      a['location'] ?? 'Location',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ]),
                ],
              ),
            ),

            // Status badge top-right of text area
            Positioned(
              left: 20, top: 80,
              child: _statusBadge(a['status'] ?? 'Confirmed'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final isConfirmed = status.toLowerCase() == 'confirmed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isConfirmed ? _green : _rose,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: (isConfirmed ? _green : _rose).withOpacity(0.40),
          blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Text(status,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  // ─── Doctor info chips (experience, language, availability) ──────
  Widget _buildInfoChips() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Doctor Information',
              style: TextStyle(
                  color: _textDark,
                  fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoChip(Icons.work_outline_rounded,
                  a['experience'] ?? '10 Years', 'Experience'),
              _verticalDivider(),
              _infoChip(Icons.translate_rounded,
                  a['language'] ?? 'English', 'Language'),
              _verticalDivider(),
              _infoChip(Icons.access_time_rounded,
                  a['availability'] ?? '8:00 - 18:00', 'Availability'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String value, String label) {
    return Column(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: _purpleLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _purple, size: 20),
      ),
      const SizedBox(height: 7),
      Text(value,
          style: const TextStyle(
              color: _textDark,
              fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(color: _textLight, fontSize: 10.5)),
    ]);
  }

  Widget _verticalDivider() => Container(
    height: 50, width: 1,
    color: Colors.grey.withOpacity(0.15),
  );

  // ─── Appointment details card ────────────────────────────────────
  Widget _buildAppointmentCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Appointment',
              style: TextStyle(
                  color: _textDark,
                  fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          // Date row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(a['date'] ?? 'Mon, 28 Apr',
                  style: const TextStyle(
                      color: _textDark,
                      fontSize: 14, fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _purpleLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month_rounded,
                    color: _purple, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Time pills
          Wrap(
            spacing: 10, runSpacing: 10,
            children: (a['timeSlots'] as List<String>? ??
                    ['08:00', '09:40', '10:00', '11:50', '12:30'])
                .map((t) {
              final isBooked = t == (a['time'] ?? '10:00');
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: isBooked ? _purple : _bg,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: isBooked
                        ? _purple
                        : Colors.grey.withOpacity(0.25)),
                  boxShadow: isBooked
                      ? [BoxShadow(
                          color: _purple.withOpacity(0.30),
                          blurRadius: 8, offset: const Offset(0, 3))]
                      : null,
                ),
                child: Text(t,
                    style: TextStyle(
                      color: isBooked ? Colors.white : _textMid,
                      fontSize: 13, fontWeight: FontWeight.w600)),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          // Room info
          Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: _purpleLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.meeting_room_rounded,
                  color: _purple, size: 18),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Room',
                  style: TextStyle(color: _textLight, fontSize: 11)),
              Text(a['room'] ?? 'Room 204',
                  style: const TextStyle(
                      color: _textDark,
                      fontSize: 13.5, fontWeight: FontWeight.w700)),
            ]),
          ]),
        ],
      ),
    );
  }

  // ─── Notes card ─────────────────────────────────────────────────
  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notes',
              style: TextStyle(
                  color: _textDark,
                  fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(
            a['notes'] ?? 'No notes added.',
            style: const TextStyle(
                color: _textMid, fontSize: 13.5, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ─── Pre-appointment checklist ───────────────────────────────────
  Widget _buildChecklist() {
    final items = [
      'Bring valid ID and insurance card',
      'Arrive 10–15 minutes early',
      'Bring list of current medications',
      'Fill out any required forms',
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Before Your Appointment',
              style: TextStyle(
                  color: _textDark,
                  fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: _green, size: 15),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(item,
                    style: const TextStyle(
                        color: _textMid, fontSize: 13.5)),
              ),
            ]),
          )),
        ],
      ),
    );
  }

  // ─── Bottom buttons ──────────────────────────────────────────────
  Widget _buildBottomButtons(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: BoxDecoration(
        color: _bg,
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: Row(children: [
        // Chat button
        Container(
          width: 52, height: 52,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _purple.withOpacity(0.25)),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: const Icon(Icons.chat_bubble_outline_rounded,
              color: _purple, size: 20),
        ),

        // Reschedule / Cancel
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => _showCancelDialog(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Reschedule',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ]),
    );
  }

  // ─── Cancel dialog ───────────────────────────────────────────────
  void _showCancelDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Cancel Appointment?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          'Are you sure you want to cancel this appointment? '
          'This action cannot be undone.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: const Text('Appointment cancelled'),
                  backgroundColor: _rose,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Cancel',
                style: TextStyle(color: _rose)),
          ),
        ],
      ),
    );
  }
}