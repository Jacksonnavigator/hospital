import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════
//  ClinicBook  ·  Appointment Screen
//  File : lib/screens/appointment_screen.dart
// ═══════════════════════════════════════════════════════════════════

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen>
    with TickerProviderStateMixin {

  // ── Palette (matches home screen image exactly) ─────────────────
  static const Color _navyDeep  = Color(0xFF0F2B5B);   // deep navy (Top Doctors header)
  static const Color _ocean     = Color(0xFF1A3D8F);   // rich blue (Book Now button)
  static const Color _pale      = Color(0xFFBDD5EC);   // pale blue border/tint
  static const Color _ice       = Color(0xFFEEF4FB);   // chip background
  static const Color _bg        = Color(0xFFEEF4FB);   // screen background
  static const Color _white     = Colors.white;
  static const Color _textDark  = Color(0xFF0F2B5B);   // near-black navy text
  static const Color _textMid   = Color(0xFF6B92B8);   // medium blue-grey
  static const Color _textLight = Color(0xFF8BAFC4);   // light muted blue
  static const Color _green     = Color(0xFF16A34A);   // available badge green
  static const Color _amber     = Color(0xFFF59E0B);   // star/pending amber
  static const Color _rose      = Color(0xFFDC2626);   // busy/cancel red

  // ── State ────────────────────────────────────────────────────────
  int _tabIndex = 0; // 0 = Upcoming, 1 = Completed, 2 = Cancelled

  // ── Entrance animation ───────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double>    _fadeAnim;
  late final Animation<Offset>    _slideAnim;

  // ── Tab controller ───────────────────────────────────────────────
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));

    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() => _tabIndex = _tabCtrl.index);
      }
    });

    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Sample data ──────────────────────────────────────────────────
  final List<_AppointmentData> _upcoming = const [
    _AppointmentData(
      doctor:    'Dr. Hyasinta Kessy',
      specialty: 'Pediatrics',
      date:      'Mon, 28 Apr 2026',
      time:      '10:00 AM',
      room:      'Room 101',
      status:    _ApptStatus.confirmed,
      image:     'lib/assets/pediatricsdoctot.png',
    ),
    _AppointmentData(
      doctor:    'Dr. Anna Sikawa',
      specialty: 'Obstetrics & Gynecology',
      date:      'Wed, 30 Apr 2026',
      time:      '09:40 AM',
      room:      'Room 205',
      status:    _ApptStatus.pending,
      image:     'lib/assets/obstetrics_gynecologydoctor.jpg',
    ),
  ];

  final List<_AppointmentData> _completed = const [
    _AppointmentData(
      doctor:    'Dr. Shaziri Mustapha',
      specialty: 'Eye Clinic',
      date:      'Thu, 10 Apr 2026',
      time:      '08:00 AM',
      room:      'Room 303',
      status:    _ApptStatus.completed,
      image:     'lib/assets/eyedoctor.jpg',
    ),
    _AppointmentData(
      doctor:    'Dr. Allan Michael',
      specialty: 'Dental Clinic',
      date:      'Mon, 01 Apr 2026',
      time:      '11:50 AM',
      room:      'Room 110',
      status:    _ApptStatus.completed,
      image:     'lib/assets/dentaldoctor.jpg',
    ),
  ];

  final List<_AppointmentData> _cancelled = const [
    _AppointmentData(
      doctor:    'Dr. Anna Sikawa',
      specialty: 'Obstetrics & Gynecology',
      date:      'Fri, 05 Apr 2026',
      time:      '17:40',
      room:      'Room 205',
      status:    _ApptStatus.cancelled,
      image:     'lib/assets/obstetrics_gynecologydoctor.jpg',
    ),
  ];

  List<_AppointmentData> get _currentList =>
      [_upcoming, _completed, _cancelled][_tabIndex];

  // ═════════════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar ──────────────────────────────────────────
              SliverToBoxAdapter(child: _buildHeader()),

              // ── Summary chips ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildSummaryRow(),
                ),
              ),

              // ── Tab bar ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildTabBar(),
                ),
              ),

              // ── List ─────────────────────────────────────────────
              _currentList.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmpty(),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildCard(_currentList[i]),
                          ),
                          childCount: _currentList.length,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),

      // ── FAB ──────────────────────────────────────────────────────
      floatingActionButton: _tabIndex == 0 ? _buildFab() : null,
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  HEADER — navy → ocean gradient (matches HTML preview exactly)
  // ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
          // Matches home screen header: deep navy → rich royal blue → vivid sky
          colors: [Color(0xFF0F2B5B), Color(0xFF1A3D8F), Color(0xFF1E5FAD)],
          stops:  [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles — matches HTML ::before / ::after / .header-orb
          Positioned(top: -28, right: -28,
              child: _circle(130, Colors.white, 0.06)),
          Positioned(top: 22,  right: 48,
              child: _circle(58,  Colors.white, 0.05)),
          Positioned(bottom: 20, left: -20,
              child: _circle(80,  Colors.white, 0.04)),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
              child: Row(
                children: [
                  // Title block
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Appointments',
                            style: TextStyle(
                              color:         Colors.white,
                              fontSize:      22,
                              fontWeight:    FontWeight.w800,
                              letterSpacing: -0.5,
                            )),
                        SizedBox(height: 3),
                        Text('Track & manage your visits',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),

                  // Notification bell with red dot
                  _headerIconBtn(
                    icon:  Icons.notifications_outlined,
                    badge: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  SUMMARY ROW
  // ──────────────────────────────────────────────────────────────────
  Widget _buildSummaryRow() {
    return Row(
      children: [
        _summaryChip('${_upcoming.length}',  'Upcoming',  _ocean, Icons.calendar_today_rounded),
        const SizedBox(width: 10),
        _summaryChip('${_completed.length}', 'Completed', _green, Icons.check_circle_outline_rounded),
        const SizedBox(width: 10),
        _summaryChip('${_cancelled.length}', 'Cancelled', _rose,  Icons.cancel_outlined),
      ],
    );
  }

  Widget _summaryChip(String count, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:        _white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color:      _navyDeep.withOpacity(0.08),
              blurRadius: 18,
              offset:     const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color:        color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(count,
                style: TextStyle(
                  color:      color,
                  fontSize:   18,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: _textLight, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  TAB BAR
  // ──────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    const tabs = ['Upcoming', 'Completed', 'Cancelled'];
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color:        _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      _navyDeep.withOpacity(0.07),
            blurRadius: 14,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: tabs.asMap().entries.map((e) {
            final active = _tabIndex == e.key;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _tabIndex = e.key);
                  _tabCtrl.animateTo(e.key);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve:    Curves.easeOut,
                  decoration: BoxDecoration(
                    // Active: navy → ocean (matches HTML .tab.active)
                    gradient: active
                        ? const LinearGradient(
                            colors: [Color(0xFF0F2B5B), Color(0xFF1A3D8F)],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color:      _ocean.withOpacity(0.30),
                              blurRadius: 10,
                              offset:     const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(e.value,
                        style: TextStyle(
                          color:      active ? _white : _textLight,
                          fontSize:   12.5,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                        )),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  APPOINTMENT CARD
  // ──────────────────────────────────────────────────────────────────
  Widget _buildCard(_AppointmentData appt) {
    final statusColor = _statusColor(appt.status);
    final statusLabel = _statusLabel(appt.status);
    final statusIcon  = _statusIcon(appt.status);
    final isUpcoming  = appt.status == _ApptStatus.confirmed ||
                        appt.status == _ApptStatus.pending;

    return Container(
      decoration: BoxDecoration(
        color:        _white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:      _navyDeep.withOpacity(0.08),
            blurRadius: 20,
            offset:     const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Doctor info row ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                // Avatar with pale-blue border (matches HTML .doc-avatar)
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _pale, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      appt.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _pale,
                        child: const Icon(Icons.person_rounded,
                            color: Color(0xFF6B92B8), size: 28),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Doctor name + specialty
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appt.doctor,
                          style: const TextStyle(
                            color:         _textDark,
                            fontSize:      15.5,
                            fontWeight:    FontWeight.w800,
                            letterSpacing: -0.2,
                          )),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.work_outline_rounded,
                              size: 12, color: _textLight),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(appt.specialty,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color:    _textMid,
                                  fontSize: 12.5,
                                )),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:        statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: statusColor.withOpacity(0.30), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 11),
                      const SizedBox(width: 4),
                      Text(statusLabel,
                          style: TextStyle(
                            color:      statusColor,
                            fontSize:   11,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Divider(
                color: _navyDeep.withOpacity(0.07), height: 1),
          ),

          // ── Date / time / room chips ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                _infoChip(Icons.calendar_today_rounded, appt.date),
                const SizedBox(width: 8),
                _infoChip(Icons.access_time_rounded, appt.time),
                const SizedBox(width: 8),
                _infoChip(Icons.room_outlined, appt.room),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Action buttons ───────────────────────────────────────
          if (isUpcoming)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // Cancel
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(context, appt),
                      icon: const Icon(Icons.cancel_outlined,
                          size: 15, color: _rose),
                      label: const Text('Cancel',
                          style: TextStyle(
                              color:      _rose,
                              fontSize:   13,
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: _rose.withOpacity(0.40), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Reschedule
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F2B5B), Color(0xFF1A3D8F)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:      _ocean.withOpacity(0.32),
                            blurRadius: 12,
                            offset:     const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit_calendar_rounded,
                            size: 15),
                        label: const Text('Reschedule',
                            style: TextStyle(
                                fontSize:   13,
                                fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor:     Colors.transparent,
                          foregroundColor: _white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // Book Again — for completed / cancelled
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F2B5B), Color(0xFF1A3D8F)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color:      _ocean.withOpacity(0.25),
                      blurRadius: 10,
                      offset:     const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh_rounded, size: 15),
                  label: const Text('Book Again',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor:     Colors.transparent,
                    foregroundColor: _white,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  EMPTY STATE
  // ──────────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    final labels = ['upcoming', 'completed', 'cancelled'];
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              color:        _ice,
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(Icons.calendar_month_outlined,
                color: _ocean, size: 44),
          ),
          const SizedBox(height: 20),
          Text('No ${labels[_tabIndex]} appointments',
              style: const TextStyle(
                color:      _textDark,
                fontSize:   17,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 6),
          Text('Your ${labels[_tabIndex]} appointments\nwill appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _textLight, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  FAB
  // ──────────────────────────────────────────────────────────────────
  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2B5B), Color(0xFF1A3D8F)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:      _ocean.withOpacity(0.40),
            blurRadius: 20,
            offset:     const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: Colors.transparent,
        elevation:       0,
        icon: const Icon(Icons.add_rounded, color: _white),
        label: const Text('New Appointment',
            style: TextStyle(
              color:      _white,
              fontSize:   14,
              fontWeight: FontWeight.w700,
            )),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  CANCEL DIALOG
  // ──────────────────────────────────────────────────────────────────
  void _showCancelDialog(BuildContext context, _AppointmentData appt) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(
            horizontal: 28, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color:        _rose.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.cancel_outlined,
                    color: _rose, size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Cancel Appointment',
                  style: TextStyle(
                    color:      _textDark,
                    fontSize:   17,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to cancel your appointment with ${appt.doctor}?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _textMid, fontSize: 13.5, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: _textLight.withOpacity(0.5), width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Keep It',
                          style: TextStyle(
                            color:      _textMid,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _rose,
                        foregroundColor: _white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Yes, Cancel',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  HELPERS
  // ──────────────────────────────────────────────────────────────────
  Widget _circle(double size, Color color, double opacity) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(opacity),
        ),
      );

  Widget _headerIconBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool badge = false,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color:        Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Colors.white.withOpacity(0.20), width: 1),
          ),
          child: Stack(
            children: [
              Center(child: Icon(icon, color: Colors.white, size: 22)),
              if (badge)
                Positioned(
                  top: 9, right: 10,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5252),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  /// Info chip — _ice background, _ocean icon (matches HTML .chip)
  Widget _infoChip(IconData icon, String text) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 7),
          decoration: BoxDecoration(
            color:        _ice,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: _ocean, size: 13),
              const SizedBox(width: 5),
              Flexible(
                child: Text(text,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color:      _textMid,
                      fontSize:   10.5,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
        ),
      );

  Color _statusColor(_ApptStatus s) {
    switch (s) {
      case _ApptStatus.confirmed: return _green;
      case _ApptStatus.pending:   return _amber;
      case _ApptStatus.completed: return _ocean;   // ocean blue for completed
      case _ApptStatus.cancelled: return _rose;
    }
  }

  String _statusLabel(_ApptStatus s) {
    switch (s) {
      case _ApptStatus.confirmed: return 'Confirmed';
      case _ApptStatus.pending:   return 'Pending';
      case _ApptStatus.completed: return 'Completed';
      case _ApptStatus.cancelled: return 'Cancelled';
    }
  }

  IconData _statusIcon(_ApptStatus s) {
    switch (s) {
      case _ApptStatus.confirmed: return Icons.check_circle_rounded;
      case _ApptStatus.pending:   return Icons.hourglass_top_rounded;
      case _ApptStatus.completed: return Icons.task_alt_rounded;
      case _ApptStatus.cancelled: return Icons.cancel_rounded;
    }
  }
}

// ── Data models ────────────────────────────────────────────────────

enum _ApptStatus { confirmed, pending, completed, cancelled }

@immutable
class _AppointmentData {
  final String      doctor;
  final String      specialty;
  final String      date;
  final String      time;
  final String      room;
  final _ApptStatus status;
  final String      image;

  const _AppointmentData({
    required this.doctor,
    required this.specialty,
    required this.date,
    required this.time,
    required this.room,
    required this.status,
    required this.image,
  });
}