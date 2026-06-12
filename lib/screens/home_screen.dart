import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'booking_screen.dart';
import 'department_screen.dart';
import 'appointment_screen.dart' hide DepartmentScreen;
import 'login_screen.dart';
import 'doctor_screen.dart';
import 'health_tips_screen.dart';
import 'emergency_screen.dart';
import 'lab_test_screen.dart';
import 'consult_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  ClinicBook  ·  Home Screen  (Enhanced Animated Edition v2)
//  lib/screens/home_screen.dart
//
//  Animations:
//   • Header fades + scales down from top with parallax circles
//   • Each section slides up + fades in with staggered delay
//   • Hero banner auto-pages every 3 s with smooth indicator dots
//   • Category tiles pop in with elastic scale, staggered per tile
//   • Doctor cards slide in from the right with spring curve
//   • Appointment card rises with a gentle bounce
//   • Bottom-nav icon uses animated scale + colour transition
//   • Notification badge pulses continuously
//   • Floating action particles in header
//   • Shimmer-ready card skeletons on first load
//   • Press feedback on interactive elements
// ═══════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {

  // ─── Palette ────────────────────────────────────────────────────
  static const Color _navy      = Color(0xFF0A2459);
  static const Color _blue      = Color(0xFF1565C0);
  static const Color _blueMed   = Color(0xFF1E88E5);
  static const Color _blueSky   = Color(0xFF64B5F6);
  static const Color _blueTint  = Color(0xFFE8F3FF);
  static const Color _bg        = Color(0xFFF2F7FF);
  static const Color _white     = Colors.white;
  static const Color _card      = Color(0xFFFFFFFF);
  static const Color _textDark  = Color(0xFF0D1F3C);
  static const Color _textMid   = Color(0xFF3A5A8A);
  static const Color _textLight = Color(0xFF8AAAC8);
  static const Color _green     = Color(0xFF00C896);
  static const Color _amber     = Color(0xFFFFB300);
  static const Color _rose      = Color(0xFFEF5350);
  static const Color _purple    = Color(0xFF8E24AA);
  static const Color _teal      = Color(0xFF00ACC1);
  static const Color _orange    = Color(0xFFFF7043);

  // ─── State ──────────────────────────────────────────────────────
  int _navIndex = 0;

  // ─── Department Carousel ────────────────────────────────────────
  late final PageController   _deptPageCtrl;
  int                         _deptPage    = 0;
  bool                        _userSwiping = false;

  // ─── Animation controllers ──────────────────────────────────────
  late final AnimationController _masterCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _floatCtrl;

  // ─── Master entrance animations (8 layers) ──────────────────────
  final List<Animation<double>>  _af = [];
  final List<Animation<Offset>>  _as = [];

  // ─── Pulse ──────────────────────────────────────────────────────
  late final Animation<double> _pulseAnim;

  // ─── Float (header particles) ───────────────────────────────────
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // ── Master stagger (1 500 ms total) ─────────────────────────
    _masterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));

    const starts = [0.00, 0.10, 0.18, 0.30, 0.36, 0.46, 0.52, 0.66];
    const ends   = [0.22, 0.32, 0.44, 0.50, 0.60, 0.64, 0.74, 0.92];

    for (int i = 0; i < 8; i++) {
      _af.add(Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _masterCtrl,
          curve: Interval(starts[i], ends[i], curve: Curves.easeOut))));
      final dy = i == 0 ? -0.05 : 0.12;
      _as.add(Tween<Offset>(begin: Offset(0, dy), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _masterCtrl,
              curve: Interval(starts[i], ends[i],
                  curve: Curves.easeOutCubic))));
    }

    // ── Notification pulse ───────────────────────────────────────
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.82, end: 1.18).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // ── Floating particles ───────────────────────────────────────
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _floatAnim = CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut);

    // ── Kick off ─────────────────────────────────────────────────
    _masterCtrl.forward();

    // ── Department carousel page controller ──────────────────────
    _deptPageCtrl = PageController(viewportFraction: 0.88);
    _startDeptAutoScroll();
  }

  // ── Department auto-scroll ────────────────────────────────────
  static const _depts = <_DeptData>[
    _DeptData(
      label:       'Pediatrics',
      image:       'lib/assets/Pediatrics.jpg',
      icon:        Icons.child_care_rounded,
      accentColor: Color(0xFF43A047),
      bgColor:     Color(0xFFE8F5E9),
    ),
    _DeptData(
      label:       'Obstetrics &\nGynecology',
      image:       'lib/assets/Obstetrics_Gynecology.jpg',
      icon:        Icons.pregnant_woman_rounded,
      accentColor: Color(0xFFEF5350),
      bgColor:     Color(0xFFFFEBEE),
    ),
    _DeptData(
      label:       'Dental Clinic',
      image:       'lib/assets/Dental.jpg',
      icon:        Icons.medical_services_rounded,
      accentColor: Color(0xFF1565C0),
      bgColor:     Color(0xFFE3F2FD),
    ),
    _DeptData(
      label:       'Eye Clinic',
      image:       'lib/assets/Eye.jpg',
      icon:        Icons.visibility_rounded,
      accentColor: Color(0xFF00ACC1),
      bgColor:     Color(0xFFE0F7FA),
    ),
  ];

  void _startDeptAutoScroll() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 3200));
      if (!mounted) return false;
      if (_userSwiping) return true;
      final next = (_deptPage + 1) % _depts.length;
      _deptPageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 680),
        curve: Curves.easeInOutCubic,
      );
      return true;
    });
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    _deptPageCtrl.dispose();
    _apptPageCtrl.dispose();
    super.dispose();
  }

  // ── Animated section wrapper ─────────────────────────────────────
  Widget _s(int i, Widget child) => SlideTransition(
        position: _as[i],
        child: FadeTransition(opacity: _af[i], child: child),
      );

  // ── Navigation ───────────────────────────────────────────────────
  void _goBooking()      => Navigator.push(context,
      _slideRoute(BookingScreen()));
  void _goEmergency()    => Navigator.push(context,
      _slideRoute(const EmergencyScreen()));
  void _goLabTests()     => Navigator.push(context,
      _slideRoute(const LabTestScreen()));
  void _goDepartment()   => Navigator.push(context,
      _slideRoute(DepartmentScreen()));
  void _goAppointments() => Navigator.push(context,
      _slideRoute(AppointmentScreen()));
  void _goLogin()        => Navigator.push(context,
      _slideRoute(LoginScreen()));
  void _goDoctors()      => Navigator.push(context,
      _slideRoute(const DoctorScreen()));
  void _goHealthTips()   => Navigator.push(context,
      _slideRoute(const HealthTipsScreen()));
  void _goConsult()      => Navigator.push(context,
      _slideRoute(const ConsultScreen()));

  PageRouteBuilder _slideRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, anim, __) => page,
    transitionsBuilder: (_, anim, __, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0), end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 380),
  );

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:        _bg,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ── 1. Header ──────────────────────────────────────────
          SliverToBoxAdapter(child: _s(0, _buildHeader())),

          // ── 2. Search bar ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _s(1, Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildSearchBar(),
            )),
          ),

          // ── 3. Quick services row ──────────────────────────────
          SliverToBoxAdapter(
            child: _s(2, Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: _buildQuickServices(),
            )),
          ),

          // ── 4. Department carousel ────────────────────────────
          SliverToBoxAdapter(
            child: _s(2, Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _buildSectionHeader(
                  title: 'Departments', onSeeAll: _goDepartment),
            )),
          ),
          SliverToBoxAdapter(
            child: _s(2, Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
              child: _buildDeptCards(),
            )),
          ),

          // ── 5. Top Doctors header ──────────────────────────────
          SliverToBoxAdapter(
            child: _s(5, Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: _buildSectionHeader(
                  title: 'Top Doctors', onSeeAll: _goDoctors),
            )),
          ),

          // ── 8. Doctors list ────────────────────────────────────
          SliverToBoxAdapter(
            child: _s(6, Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _buildDoctorsList(),
            )),
          ),

          // ── 9. Health tips ─────────────────────────────────────
          SliverToBoxAdapter(
            child: _s(6, Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: _buildSectionHeader(
                  title: 'Health Tips', onSeeAll: _goHealthTips),
            )),
          ),
          SliverToBoxAdapter(
            child: _s(6, Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _buildHealthTips(),
            )),
          ),

          // ── 10. Upcoming appointment ────────────────────────────
          SliverToBoxAdapter(
            child: _s(7, Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: _buildSectionHeader(
                  title: 'Upcoming Appointment',
                  onSeeAll: _goAppointments),
            )),
          ),
          SliverToBoxAdapter(
            child: _s(7, Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 38),
              child: _buildUpcomingCard(),
            )),
          ),
        ],
      ),
      // bottomNavigationBar removed — MainShell handles persistent nav
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  1. HEADER  — pill greeting · headline · subtitle · bell+avatar
  //               row · 3-chip stats row  (matches HTML Option A)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
          colors: [
            Color(0xFF05163A),
            Color(0xFF0A2868),
            Color(0xFF1150B0),
            Color(0xFF1A78D0),
          ],
          stops: [0.0, 0.28, 0.65, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(48),
          bottomRight: Radius.circular(48),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // ── Blob 1: top-right radial glow ──
          Positioned(
            top: -60, right: -50,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF3B9EFF).withOpacity(0.28),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // ── Blob 2: bottom-left radial glow (kept fully inside) ──
          Positioned(
            bottom: 20, left: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF1976D2).withOpacity(0.20),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // ── Accent ring ──
          Positioned(
            top: 52, left: 145,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:  Colors.white.withOpacity(0.06),
                border: Border.all(
                    color: Colors.white.withOpacity(0.10), width: 1),
              ),
            ),
          ),
          // ── Animated floating glow dots ──
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (_, __) {
              final dy = math.sin(_floatAnim.value * math.pi) * 8;
              return Positioned(
                top: 44 + dy, right: 20,
                child: _glowDot(11, _blueSky.withOpacity(0.75)),
              );
            },
          ),
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (_, __) {
              final dy = math.cos(_floatAnim.value * math.pi) * 10;
              return Positioned(
                top: 105 + dy, right: 74,
                child: _glowDot(7, Colors.white.withOpacity(0.32)),
              );
            },
          ),

          // ── Main content ──
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── TOP ROW: greeting-col | bell + avatar (horizontal) ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      // Greeting column — plain readable text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Greeting line
                            Text.rich(
                              const TextSpan(
                                text: 'Good morning, ',
                                style: TextStyle(
                                  color:    Colors.white60,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'John 👋',
                                    style: TextStyle(
                                      color:      Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Headline
                            const Text(
                              'Find your perfect\ndoctor today',
                              style: TextStyle(
                                color:         Colors.white,
                                fontSize:      22,
                                fontWeight:    FontWeight.w800,
                                letterSpacing: -0.6,
                                height:        1.22,
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Subtitle
                            Text(
                              'Book, consult & manage health',
                              style: TextStyle(
                                color:    Colors.white.withOpacity(0.65),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // ── Bell + Avatar side-by-side (horizontal Row) ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Bell icon button
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                    width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color:      Colors.black.withOpacity(0.15),
                                    blurRadius: 12,
                                    offset:     const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(Icons.notifications_outlined,
                                      color: Colors.white, size: 22),
                                  Positioned(
                                    top: 8, right: 8,
                                    child: AnimatedBuilder(
                                      animation: _pulseAnim,
                                      builder: (_, __) => Transform.scale(
                                        scale: _pulseAnim.value,
                                        child: Container(
                                          width: 9, height: 9,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF5252),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white,
                                                width: 1.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Avatar
                          GestureDetector(
                            onTap: _goLogin,
                            child: Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFBBDEFB),
                                    Color(0xFF90CAF9),
                                  ],
                                  begin: Alignment.topLeft,
                                  end:   Alignment.bottomRight,
                                ),
                                border: Border.all(
                                    color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color:      Colors.black.withOpacity(0.22),
                                    blurRadius: 12,
                                    offset:     const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.person_rounded,
                                  color: Color(0xFF1565C0), size: 26),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── STATS CHIPS ROW ───────────────────────────────
                  Row(
                    children: [
                      _statChip(
                        icon: Icons.people_alt_outlined,
                        value: '200+',
                        label: 'Doctors',
                      ),
                      const SizedBox(width: 8),
                      _statChip(
                        icon: Icons.grid_view_rounded,
                        value: '50+',
                        label: 'Departments',
                      ),
                      const SizedBox(width: 8),
                      _statChip(
                        icon: Icons.person_outline_rounded,
                        value: '10K+',
                        label: 'Patients',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String   value,
    required String   label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.13),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.white.withOpacity(0.20), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: Colors.white.withOpacity(0.75), size: 17),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color:      Colors.white,
                fontSize:   15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                color:    Colors.white.withOpacity(0.60),
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glowDot(double size, Color color) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [BoxShadow(color: color, blurRadius: size * 1.5)],
        ),
      );

  // ─────────────────────────────────────────────────────────────────
  //  2. SEARCH BAR
  // ─────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color:        _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:      Colors.blueGrey.withOpacity(0.11),
            blurRadius: 22, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(children: [
        const SizedBox(width: 16),
        Icon(Icons.search_rounded,
            color: _blue.withOpacity(0.75), size: 23),
        const SizedBox(width: 10),
        const Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText:       'Search doctor, specialty...',
              hintStyle: TextStyle(color: _textLight, fontSize: 14.5),
              border:         InputBorder.none,
              isDense:        true,
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(color: _textDark, fontSize: 14.5),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          width: 40, height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_navy, _blue]),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.tune_rounded,
              color: Colors.white, size: 20),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  3. QUICK SERVICES  (new horizontal pill row)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildQuickServices() {
    // Modern professional quick-service tiles with gradient icons
    const services = <_QuickServiceV2>[
      _QuickServiceV2(
        label:      'Book Now',
        icon:       Icons.calendar_month_rounded,
        gradStart:  Color(0xFF1565C0),
        gradEnd:    Color(0xFF42A5F5),
        shadowColor: Color(0xFF1565C0),
        bgColor:    Color(0xFFE8F3FF),
      ),
      _QuickServiceV2(
        label:      'Emergency',
        icon:       Icons.local_hospital_rounded,
        gradStart:  Color(0xFFD32F2F),
        gradEnd:    Color(0xFFFF7043),
        shadowColor: Color(0xFFD32F2F),
        bgColor:    Color(0xFFFFEBEE),
      ),
      _QuickServiceV2(
        label:      'Lab Tests',
        icon:       Icons.science_rounded,
        gradStart:  Color(0xFF6A1B9A),
        gradEnd:    Color(0xFFAB47BC),
        shadowColor: Color(0xFF6A1B9A),
        bgColor:    Color(0xFFF3E5F5),
      ),
      _QuickServiceV2(
        label:      'Consult',
        icon:       Icons.headset_mic_rounded,
        gradStart:  Color(0xFF00695C),
        gradEnd:    Color(0xFF26C6DA),
        shadowColor: Color(0xFF00695C),
        bgColor:    Color(0xFFE0F7FA),
      ),
    ];

    final taps = [_goBooking, _goEmergency, _goLabTests, _goConsult];

    return Row(
      children: List.generate(services.length, (i) {
        final svc = services[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left:  i == 0 ? 0 : 6,
              right: i == services.length - 1 ? 0 : 6,
            ),
            child: TweenAnimationBuilder<double>(
              tween:    Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 380 + i * 90),
              curve:    Curves.easeOutBack,
              builder:  (_, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: _QuickServiceTile(svc: svc, onTap: taps[i]),
            ),
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  4. DEPARTMENT CAROUSEL  (pager-style, auto-scroll, "Book Now")
  // ─────────────────────────────────────────────────────────────────
  Widget _buildDeptCards() {
    return Column(
      children: [
        // ── Page view ────────────────────────────────────────────
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller:  _deptPageCtrl,
            physics:     const BouncingScrollPhysics(),
            itemCount:   _depts.length,
            onPageChanged: (p) => setState(() => _deptPage = p),
            itemBuilder: (ctx, i) {
              return AnimatedBuilder(
                animation: _deptPageCtrl,
                builder: (_, child) {
                  double page = _deptPage.toDouble();
                  try {
                    page = _deptPageCtrl.page ?? _deptPage.toDouble();
                  } catch (_) {}
                  final diff   = (i - page).abs().clamp(0.0, 1.0);
                  final scale  = 1.0 - diff * 0.10;
                  final opacity= 1.0 - diff * 0.35;
                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  onPanDown: (_) {
                    _userSwiping = true;
                  },
                  onPanEnd: (_) {
                    Future.delayed(const Duration(seconds: 3), () {
                      if (mounted) _userSwiping = false;
                    });
                  },
                  child: _DeptCarouselCard(
                    dept:   _depts[i],
                    onBook: _goBooking,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // ── Dot indicators ───────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_depts.length, (i) {
            final active = i == _deptPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve:    Curves.easeOutCubic,
              margin:   const EdgeInsets.symmetric(horizontal: 4),
              width:    active ? 28 : 8,
              height:   8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: active ? _blue : _blueSky.withOpacity(0.5),
                boxShadow: active
                    ? [BoxShadow(
                        color:      _blue.withOpacity(0.40),
                        blurRadius: 8, offset: const Offset(0, 2))]
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  SECTION HEADER
  // ─────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader({
    required String       title,
    required VoidCallback onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
              color:         _textDark,
              fontSize:      18,
              fontWeight:    FontWeight.w800,
              letterSpacing: -0.4,
            )),
        GestureDetector(
          onTap: onSeeAll,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color:        _blueTint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('See All',
                style: TextStyle(
                  color:      _blue,
                  fontSize:   12.5,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  5. TOP DOCTORS  (slide-in from right with spring)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildDoctorsList() {
    final List<_DocData> docs = [
      _DocData('Dr. Hyasinta Kessy',  'Pediatrics',              4.9, 128, 'lib/assets/pediatricsdoctot.png'),
      _DocData('Dr. Anna Sikawa',     'Obstetrics & Gynecology', 4.7,  95, 'lib/assets/obstetrics_gynecologydoctor.jpg'),
      _DocData('Dr. Shaziri Mustapha','Eye Clinic',              4.8, 112, 'lib/assets/eyedoctor.png'),
      _DocData('Dr. Allan Michael',   'Dental Clinic',           4.6,  80, 'lib/assets/dentaldoctor.jpg'),
      _DocData('Dr. Sophia Mollel',   'Pediatrics',              4.8,  91, 'lib/assets/Sophia Mollel.png'),
      _DocData('Dr. Nathani Temu',    'Cardiology',              4.9, 102, 'lib/assets/Nathani Temu.jpeg'),
      _DocData('Dr. Jesca Tesha',     'Obstetrics & Gynecology', 4.7,  88, 'lib/assets/Jesca Tesha.jpg'),
      _DocData('Dr. Benjamin Mushi',  'General Medicine',        4.6,  75, 'lib/assets/Benjamin Mushi.jpeg'),
    ];

    return SizedBox(
      height: 252,
      child: ListView.separated(
        scrollDirection:  Axis.horizontal,
        physics:          const BouncingScrollPhysics(),
        padding:          const EdgeInsets.symmetric(horizontal: 20),
        itemCount:        docs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, idx) {
          final doc = docs[idx];
          return TweenAnimationBuilder<double>(
            tween:    Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 520 + idx * 130),
            curve:    Curves.easeOutBack,
            builder: (_, v, child) => Transform.translate(
              offset: Offset(30 * (1 - v), 0),
              child:  Opacity(opacity: v.clamp(0, 1), child: child),
            ),
            child: _DoctorCard(doc: doc, onTap: _goBooking),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  7. HEALTH TIPS
  // ─────────────────────────────────────────────────────────────────
  Widget _buildHealthTips() {
    final tips = [
      _TipData('Stay Hydrated', 'Drink 8 glasses of water daily for better health.',
          Icons.water_drop_rounded, _teal, const Color(0xFFE0F7FA)),
      _TipData('Sleep Well', 'Get 7–9 hours of quality sleep every night.',
          Icons.bedtime_rounded, _purple, const Color(0xFFF3E5F5)),
      _TipData('Move Daily', 'Even 30 min of walking lowers heart disease risk.',
          Icons.directions_run_rounded, _orange, const Color(0xFFFBE9E7)),
    ];

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection:  Axis.horizontal,
        physics:          const BouncingScrollPhysics(),
        itemCount:        tips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final tip = tips[i];
          return TweenAnimationBuilder<double>(
            tween:    Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 450 + i * 110),
            curve:    Curves.easeOut,
            builder: (_, v, child) =>
                Opacity(opacity: v, child: child),
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        _card,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.blueGrey.withOpacity(0.09),
                    blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color:        tip.bg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(tip.icon, color: tip.fg, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:  MainAxisAlignment.center,
                    children: [
                      Text(tip.title,
                          style: const TextStyle(
                            color:      _textDark,
                            fontSize:   13.5,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 4),
                      Text(tip.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color:    _textMid,
                            fontSize: 11.5,
                            height:   1.4,
                          )),
                    ],
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  8. UPCOMING APPOINTMENTS  (real data from appointment screen)
  // ─────────────────────────────────────────────────────────────────

  // Real upcoming appointment data (mirrors AppointmentScreen._upcoming)
  static const _upcomingAppts = <_UpcomingAppt>[
    _UpcomingAppt(
      doctor:    'Dr. Hyasinta Kessy',
      specialty: 'Pediatrics',
      date:      'Mon, 28 Apr 2026',
      time:      '10:00 AM',
      room:      'Room 101',
      image:     'lib/assets/pediatricsdoctot.png',
      isConfirmed: true,
    ),
    _UpcomingAppt(
      doctor:    'Dr. Anna Sikawa',
      specialty: 'Obstetrics & Gynecology',
      date:      'Wed, 30 Apr 2026',
      time:      '09:40 AM',
      room:      'Room 205',
      image:     'lib/assets/obstetrics_gynecologydoctor.jpg',
      isConfirmed: false,
    ),
  ];

  int _apptPage = 0;
  late final PageController _apptPageCtrl = PageController();

  Widget _buildUpcomingCard() {
    return TweenAnimationBuilder<double>(
      tween:    Tween(begin: 0.88, end: 1),
      duration: const Duration(milliseconds: 750),
      curve:    Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Column(
        children: [
          SizedBox(
            height: 210,
            child: PageView.builder(
              controller: _apptPageCtrl,
              itemCount:  _upcomingAppts.length,
              onPageChanged: (i) => setState(() => _apptPage = i),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildSingleApptCard(_upcomingAppts[i]),
              ),
            ),
          ),
          if (_upcomingAppts.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_upcomingAppts.length, (i) {
                final active = i == _apptPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width:  active ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : Colors.white.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleApptCard(_UpcomingAppt appt) {
    final statusColor  = appt.isConfirmed ? _green  : _amber;
    final statusLabel  = appt.isConfirmed ? 'Confirmed' : 'Pending';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
          colors: [_navy, Color(0xFF0D3480), _blue, _blueMed],
          stops:  [0.0, 0.35, 0.70, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color:      _blue.withOpacity(0.40),
            blurRadius: 28, offset: const Offset(0, 14)),
        ],
      ),
      child: Column(children: [
        // Doctor row
        Row(children: [
          // Doctor photo or fallback icon
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 60, height: 60,
              child: Image.asset(
                appt.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white.withOpacity(0.14),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white54, size: 30),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appt.doctor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color:         Colors.white,
                      fontSize:      15,
                      fontWeight:    FontWeight.w800,
                      letterSpacing: -0.2,
                    )),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.work_outline_rounded,
                      color: Colors.white54, size: 13),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(appt.specialty,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12)),
                  ),
                ]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color:        statusColor.withOpacity(0.20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: statusColor.withOpacity(0.50), width: 1),
            ),
            child: Text(statusLabel,
                style: TextStyle(
                  color:      statusColor,
                  fontSize:   11,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ]),

        const SizedBox(height: 14),
        Divider(color: Colors.white.withOpacity(0.14), height: 1),
        const SizedBox(height: 14),

        Row(children: [
          _apptChip(Icons.calendar_today_rounded, appt.date),
          const SizedBox(width: 10),
          _apptChip(Icons.access_time_rounded,    appt.time),
          const SizedBox(width: 10),
          _apptChip(Icons.room_outlined,          appt.room),
        ]),

        const SizedBox(height: 14),

        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.cancel_outlined,
                  size: 15, color: Colors.white70),
              label: const Text('Cancel',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: Colors.white.withOpacity(0.30), width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _goAppointments,
              icon: const Icon(Icons.info_outline_rounded, size: 15),
              label: const Text('Details',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _blue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _apptChip(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 14),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      );

  // ─────────────────────────────────────────────────────────────────
  //  BOTTOM NAVIGATION  (animated active pill)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    const List<_NavItem> items = [
      _NavItem(Icons.home_rounded,              Icons.home_outlined,              'Home'),
      _NavItem(Icons.calendar_month_rounded,    Icons.calendar_month_outlined,    'Bookings'),
      _NavItem(Icons.event_note_rounded,        Icons.event_note_outlined,        'Schedule'),
      _NavItem(Icons.chat_bubble_rounded,       Icons.chat_bubble_outline_rounded, 'Messages'),
      _NavItem(Icons.person_rounded,            Icons.person_outline_rounded,     'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _white,
        boxShadow: [
          BoxShadow(
            color:      Colors.blueGrey.withOpacity(0.12),
            blurRadius: 26, offset: const Offset(0, -6)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Row(
            children: List.generate(items.length, (i) {
              final item   = items[i];
              final active = _navIndex == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => _navIndex = i);
                    if (i == 1) _goBooking();
                    if (i == 2) _goAppointments();
                    if (i == 4) _goLogin();
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 270),
                        curve:    Curves.easeOutBack,
                        padding: EdgeInsets.symmetric(
                          horizontal: active ? 22 : 12,
                          vertical:   active ? 8  : 6,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? _blue.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: AnimatedScale(
                          scale:    active ? 1.18 : 1.0,
                          duration: const Duration(milliseconds: 230),
                          curve:    Curves.easeOutBack,
                          child: Icon(
                            active ? item.active : item.inactive,
                            color: active ? _blue : _textLight,
                            size:  24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 230),
                        style: TextStyle(
                          color:      active ? _blue : _textLight,
                          fontSize:   10,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                        child: Text(item.label),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DEPARTMENT CAROUSEL CARD  (full-width pager card with Book Now)
// ═══════════════════════════════════════════════════════════════════

class _DeptCarouselCard extends StatefulWidget {
  final _DeptData    dept;
  final VoidCallback onBook;
  const _DeptCarouselCard({required this.dept, required this.onBook});

  @override
  State<_DeptCarouselCard> createState() => _DeptCarouselCardState();
}

class _DeptCarouselCardState extends State<_DeptCarouselCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  static const Color _navy = Color(0xFF0A2459);
  static const Color _blue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.96, upperBound: 1.0, value: 1.0,
    );
  }

  @override
  void dispose() { _pressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final dept = widget.dept;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ScaleTransition(
        scale: _pressCtrl,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color:      dept.accentColor.withOpacity(0.32),
                blurRadius: 28,
                offset:     const Offset(0, 12),
              ),
              BoxShadow(
                color:      Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset:     const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Background photo ──
                Image.asset(
                  dept.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: dept.bgColor,
                    child: Icon(dept.icon,
                        color: dept.accentColor.withOpacity(0.4),
                        size: 72),
                  ),
                ),

                // ── Multi-stop gradient overlay ──
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin:  Alignment.topCenter,
                      end:    Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.18),
                        Colors.black.withOpacity(0.72),
                      ],
                      stops: const [0.0, 0.50, 1.0],
                    ),
                  ),
                ),

                // ── Accent colour tint strip at top-left ──
                Positioned(
                  top: 0, left: 0,
                  child: Container(
                    width: 6, height: double.infinity,
                    color: dept.accentColor.withOpacity(0.80),
                  ),
                ),

                // ── Icon badge (top-right) ──
                Positioned(
                  top: 16, right: 16,
                  child: Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color:        Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.30), width: 1.2),
                    ),
                    child: Icon(dept.icon, color: Colors.white, size: 24),
                  ),
                ),

                // ── "Tap to explore" label (top-left) ──
                Positioned(
                  top: 20, left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:        dept.accentColor.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(children: [
                      const Icon(Icons.local_hospital_rounded,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 5),
                      const Text('Department',
                          style: TextStyle(
                            color:      Colors.white,
                            fontSize:   10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          )),
                    ]),
                  ),
                ),

                // ── Bottom content: name + Book Now button ──
                Positioned(
                  left: 20, right: 20, bottom: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dept.label,
                        style: const TextStyle(
                          color:         Colors.white,
                          fontSize:      24,
                          fontWeight:    FontWeight.w900,
                          letterSpacing: -0.5,
                          height:        1.2,
                          shadows: [
                            Shadow(color: Colors.black54,
                                blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Book Now button ──
                      GestureDetector(
                        onTapDown:   (_) => _pressCtrl.reverse(),
                        onTapUp:     (_) { _pressCtrl.forward(); widget.onBook(); },
                        onTapCancel: ()  => _pressCtrl.forward(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [dept.accentColor, dept.accentColor.withOpacity(0.75)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:      dept.accentColor.withOpacity(0.5),
                                blurRadius: 14, offset: const Offset(0, 5)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.event_available_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Book Now',
                                  style: TextStyle(
                                    color:      Colors.white,
                                    fontSize:   15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  EXTRACTED WIDGET: Department Tile  (photo card with gradient)
// ─────────────────────────────────────────────────────────────────
class _DeptTile extends StatefulWidget {
  final _DeptData    dept;
  final VoidCallback onTap;
  const _DeptTile({required this.dept, required this.onTap});

  @override
  State<_DeptTile> createState() => _DeptTileState();
}

class _DeptTileState extends State<_DeptTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 110),
        lowerBound: 0.93, upperBound: 1.0, value: 1.0);
  }

  @override
  void dispose() { _pressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _pressCtrl.reverse(),
      onTapUp:     (_) { _pressCtrl.forward(); widget.onTap(); },
      onTapCancel: ()  => _pressCtrl.forward(),
      child: ScaleTransition(
        scale: _pressCtrl,
        child: Container(
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color:      widget.dept.accentColor.withOpacity(0.22),
                blurRadius: 18, offset: const Offset(0, 6)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background photo
                Image.asset(
                  widget.dept.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: widget.dept.bgColor,
                    child: Icon(widget.dept.icon,
                        color: widget.dept.accentColor.withOpacity(0.5),
                        size: 48),
                  ),
                ),
                // Gradient overlay — darkens bottom for text legibility
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin:  Alignment.topCenter,
                      end:    Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.62),
                      ],
                      stops: const [0.38, 1.0],
                    ),
                  ),
                ),
                // Label + icon pill at bottom
                Positioned(
                  left: 12, right: 12, bottom: 12,
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color:        widget.dept.accentColor.withOpacity(0.88),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(widget.dept.icon,
                            color: Colors.white, size: 17),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.dept.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color:      Colors.white,
                            fontSize:   13,
                            fontWeight: FontWeight.w800,
                            height:     1.25,
                            shadows: [
                              Shadow(color: Colors.black45,
                                  blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  EXTRACTED WIDGET: Doctor Card  (with tap feedback)
// ─────────────────────────────────────────────────────────────────
class _DoctorCard extends StatefulWidget {
  final _DocData     doc;
  final VoidCallback onTap;
  const _DoctorCard({required this.doc, required this.onTap});

  @override
  State<_DoctorCard> createState() => _DoctorCardState();
}

class _DoctorCardState extends State<_DoctorCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  static const Color _navy     = Color(0xFF0A2459);
  static const Color _blue     = Color(0xFF1565C0);
  static const Color _blueTint = Color(0xFFE8F3FF);
  static const Color _card     = Color(0xFFFFFFFF);
  static const Color _textDark = Color(0xFF0D1F3C);
  static const Color _textMid  = Color(0xFF3A5A8A);
  static const Color _textLight= Color(0xFF8AAAC8);
  static const Color _green    = Color(0xFF00C896);
  static const Color _amber    = Color(0xFFFFB300);

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 100),
        lowerBound: 0.94, upperBound: 1.0, value: 1.0);
  }

  @override
  void dispose() { _pressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _pressCtrl.reverse(),
      onTapUp:     (_) { _pressCtrl.forward(); widget.onTap(); },
      onTapCancel: ()  => _pressCtrl.forward(),
      child: ScaleTransition(
        scale: _pressCtrl,
        child: Container(
          width: 168,
          decoration: BoxDecoration(
            color:        _card,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color:      Colors.blueGrey.withOpacity(0.13),
                blurRadius: 24, offset: const Offset(0, 8)),
              BoxShadow(
                color:      _blue.withOpacity(0.05),
                blurRadius: 12, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24)),
                child: SizedBox(
                  height: 124, width: double.infinity,
                  child: Image.asset(
                    widget.doc.image, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: _blueTint,
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white54, size: 52),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.doc.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color:      _textDark,
                          fontSize:   13,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 2),
                    Text(widget.doc.specialty,
                        style: const TextStyle(
                            color: _textMid, fontSize: 11.5)),
                    const SizedBox(height: 7),
                    Row(children: [
                      const Icon(Icons.star_rounded,
                          color: _amber, size: 13),
                      const SizedBox(width: 3),
                      Text('${widget.doc.rating}',
                          style: const TextStyle(
                            color:      _textDark,
                            fontSize:   12,
                            fontWeight: FontWeight.w700,
                          )),
                      Text(' (${widget.doc.reviews})',
                          style: const TextStyle(
                              color: _textLight, fontSize: 11)),
                    ]),
                  ],
                ),
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_navy, _blue]),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color:      _blue.withOpacity(0.30),
                        blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: widget.onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor:     Colors.transparent,
                      foregroundColor: Colors.white,
                      minimumSize:     const Size(double.infinity, 36),
                      padding:         EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                    ),
                    child: const Text('Book Now',
                        style: TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════════════════════════════

@immutable
class _DeptData {
  final String   label;
  final String   image;
  final IconData icon;
  final Color    accentColor;
  final Color    bgColor;
  const _DeptData({
    required this.label,
    required this.image,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
  });
}

@immutable
class _DocData {
  final String name;
  final String specialty;
  final double rating;
  final int    reviews;
  final String image;
  const _DocData(this.name, this.specialty, this.rating,
      this.reviews, this.image);
}

@immutable
class _QuickService {
  final String   label;
  final IconData icon;
  final Color    fg;
  final Color    bg;
  const _QuickService(this.label, this.icon, this.fg, this.bg);
}

// ── Modern quick-service data model ────────────────────────────────
@immutable
class _QuickServiceV2 {
  final String   label;
  final IconData icon;
  final Color    gradStart;
  final Color    gradEnd;
  final Color    shadowColor;
  final Color    bgColor;
  const _QuickServiceV2({
    required this.label,
    required this.icon,
    required this.gradStart,
    required this.gradEnd,
    required this.shadowColor,
    required this.bgColor,
  });
}

// ── Modern quick-service tile widget ───────────────────────────────
class _QuickServiceTile extends StatefulWidget {
  final _QuickServiceV2 svc;
  final VoidCallback    onTap;
  const _QuickServiceTile({required this.svc, required this.onTap});

  @override
  State<_QuickServiceTile> createState() => _QuickServiceTileState();
}

class _QuickServiceTileState extends State<_QuickServiceTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.92, upperBound: 1.0, value: 1.0,
    );
  }

  @override
  void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final svc = widget.svc;
    return GestureDetector(
      onTapDown:   (_) => _press.reverse(),
      onTapUp:     (_) { _press.forward(); widget.onTap(); },
      onTapCancel: ()  => _press.forward(),
      child: ScaleTransition(
        scale: _press,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color:      svc.shadowColor.withOpacity(0.14),
                blurRadius: 16,
                offset:     const Offset(0, 6),
              ),
              BoxShadow(
                color:      Colors.blueGrey.withOpacity(0.06),
                blurRadius: 8,
                offset:     const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient icon container with inner glow
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin:  Alignment.topLeft,
                    end:    Alignment.bottomRight,
                    colors: [svc.gradStart, svc.gradEnd],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:      svc.gradEnd.withOpacity(0.40),
                      blurRadius: 12,
                      offset:     const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Subtle inner highlight
                    Positioned(
                      top: 4, left: 6,
                      child: Container(
                        width: 20, height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    Icon(svc.icon, color: Colors.white, size: 24),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              Text(
                svc.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:      svc.gradStart,
                  fontSize:   10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
class _TipData {
  final String   title;
  final String   body;
  final IconData icon;
  final Color    fg;
  final Color    bg;
  const _TipData(this.title, this.body, this.icon, this.fg, this.bg);
}

@immutable
class _UpcomingAppt {
  final String doctor;
  final String specialty;
  final String date;
  final String time;
  final String room;
  final String image;
  final bool   isConfirmed;
  const _UpcomingAppt({
    required this.doctor,
    required this.specialty,
    required this.date,
    required this.time,
    required this.room,
    required this.image,
    required this.isConfirmed,
  });
}

@immutable
class _NavItem {
  final IconData active;
  final IconData inactive;
  final String   label;
  const _NavItem(this.active, this.inactive, this.label);
}