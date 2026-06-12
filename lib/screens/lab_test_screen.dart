import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════
//  ClinicBook  ·  Lab Tests Screen  ·  PREMIUM REDESIGN
//  lib/screens/lab_test_screen.dart
//
//  Sections:
//   1. Modern gradient header – greeting, search, filter
//   2. Quick filter chips     – horizontal scroll
//   3. Fast Results Banner    – gradient CTA promo
//   4. Featured Tests         – horizontal premium cards
//   5. Health Packages        – horizontal scroll
//   6. Nearby Labs            – vertical list
//   7. Upcoming Tests         – timeline design
//   8. Recent Results         – premium result cards
// ═══════════════════════════════════════════════════════════════════

class LabTestScreen extends StatefulWidget {
  const LabTestScreen({super.key});

  @override
  State<LabTestScreen> createState() => _LabTestScreenState();
}

class _LabTestScreenState extends State<LabTestScreen>
    with TickerProviderStateMixin {

  // ─── Design Tokens ──────────────────────────────────────────────
  static const Color _navy       = Color(0xFF0A2459);
  static const Color _navyMid    = Color(0xFF0D2F6E);
  static const Color _softBlue   = Color(0xFF4DA3FF);
  static const Color _skyBlue    = Color(0xFF7EC1FF);
  static const Color _bg         = Color(0xFFF5F8FC);
  static const Color _cardWhite  = Color(0xFFFFFFFF);
  static const Color _textDark   = Color(0xFF0D1F3C);
  static const Color _textMid    = Color(0xFF3E5A82);
  static const Color _textLight  = Color(0xFF93ADC8);
  static const Color _blueTint   = Color(0xFFEAF3FF);
  static const Color _green      = Color(0xFF00B87A);
  static const Color _greenBg    = Color(0xFFE6F7F2);
  static const Color _orange     = Color(0xFFF59D20);
  static const Color _orangeBg   = Color(0xFFFFF4E0);
  static const Color _red        = Color(0xFFEF3D54);
  static const Color _redBg      = Color(0xFFFFEBEE);

  // ─── Controllers ────────────────────────────────────────────────
  late final AnimationController _entranceCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _shimmerCtrl;
  late final Animation<double>   _pulseAnim;
  late final Animation<double>   _shimmerAnim;

  // Staggered section animations (8 layers)
  final List<Animation<double>>  _fadeAnims  = [];
  final List<Animation<Offset>>  _slideAnims = [];

  int _activeFilter = 0;
  final TextEditingController _searchCtrl = TextEditingController();

  // ─── Filter data ────────────────────────────────────────────────
  final List<Map<String, dynamic>> _filters = [
    {'label': 'All Tests',  'icon': Icons.apps_rounded},
    {'label': 'Blood',      'icon': Icons.water_drop_outlined},
    {'label': 'Scan',       'icon': Icons.radar_rounded},
    {'label': 'Pregnancy',  'icon': Icons.pregnant_woman_rounded},
    {'label': 'Eye',        'icon': Icons.remove_red_eye_outlined},
    {'label': 'Dental',     'icon': Icons.medical_services_outlined},
    {'label': 'Heart',      'icon': Icons.favorite_border_rounded},
    {'label': 'Diabetes',   'icon': Icons.monitor_heart_outlined},
  ];

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // ── Stagger entrance (8 layers) ─────────────────────────────
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));

    const double step = 0.10;
    for (int i = 0; i < 8; i++) {
      final start = i * step * 0.7;
      final end   = (start + 0.28).clamp(0.0, 1.0);
      _fadeAnims.add(
        Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _entranceCtrl,
              curve: Interval(start, end, curve: Curves.easeOut))));
      _slideAnims.add(
        Tween<Offset>(
            begin: i == 0 ? const Offset(0, -0.04) : const Offset(0, 0.08),
            end: Offset.zero)
          .animate(CurvedAnimation(parent: _entranceCtrl,
              curve: Interval(start, end, curve: Curves.easeOutCubic))));
    }

    // ── Notification pulse ──────────────────────────────────────
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // ── Shimmer for banner ──────────────────────────────────────
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget _section(int i, Widget child) => SlideTransition(
      position: _slideAnims[i],
      child: FadeTransition(opacity: _fadeAnims[i], child: child));

  // ════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // 1. Header
          SliverToBoxAdapter(child: _section(0, _buildHeader())),

          // 2. Filter chips
          SliverToBoxAdapter(child: _section(1, _buildFilterChips())),

          // 3. Fast Results Banner
          SliverToBoxAdapter(
            child: _section(2, Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              child: _buildFastResultsBanner(),
            )),
          ),

          // 4. Featured Tests
          SliverToBoxAdapter(
            child: _section(3, Padding(
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 0),
              child: _sectionHeader('Featured Tests', 'See All', () {}),
            )),
          ),
          SliverToBoxAdapter(
            child: _section(3, const SizedBox(height: 14)),
          ),
          SliverToBoxAdapter(
            child: _section(3, _buildFeaturedTests()),
          ),

          // 5. Health Packages
          SliverToBoxAdapter(
            child: _section(4, Padding(
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 0),
              child: _sectionHeader('Health Packages', 'See All', () {}),
            )),
          ),
          SliverToBoxAdapter(
            child: _section(4, const SizedBox(height: 14)),
          ),
          SliverToBoxAdapter(
            child: _section(4, _buildHealthPackages()),
          ),

          // 6. Nearby Labs
          SliverToBoxAdapter(
            child: _section(5, Padding(
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 0),
              child: _sectionHeader('Nearby Labs', 'View Map', () {}),
            )),
          ),
          SliverToBoxAdapter(
            child: _section(5, Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: _buildNearbyLabs(),
            )),
          ),

          // 7. Upcoming Tests
          SliverToBoxAdapter(
            child: _section(6, Padding(
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 0),
              child: _sectionHeader('Upcoming Tests', 'See All', () {}),
            )),
          ),
          SliverToBoxAdapter(
            child: _section(6, Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: _buildUpcomingTimeline(),
            )),
          ),

          // 8. Recent Results
          SliverToBoxAdapter(
            child: _section(7, Padding(
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 0),
              child: _sectionHeader('Recent Results', 'View All', () {}),
            )),
          ),
          SliverToBoxAdapter(
            child: _section(7, Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
              child: _buildRecentResults(),
            )),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════════════════════
  Widget _sectionHeader(String title, String action, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
          style: const TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          )),
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Text(action,
                style: const TextStyle(
                  color: _softBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                )),
              const SizedBox(width: 3),
              const Icon(Icons.chevron_right_rounded,
                  color: _softBlue, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  1. HEADER
  // ════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF06132E),
            Color(0xFF0A2459),
            Color(0xFF0F3A80),
            Color(0xFF1A5DB0),
          ],
          stops: [0.0, 0.30, 0.65, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Decorative glow circles
          Positioned(
            top: -70, right: -50,
            child: _glowBlob(200, const Color(0xFF4DA3FF), 0.15),
          ),
          Positioned(
            bottom: -20, left: -30,
            child: _glowBlob(140, const Color(0xFF7EC1FF), 0.10),
          ),
          Positioned(
            top: 80, right: 80,
            child: _glowBlob(60, Colors.white, 0.05),
          ),
          // Grid pattern overlay
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Top row ──────────────────────────────────
                  Row(
                    children: [
                      // Back button
                      _headerIconBtn(Icons.chevron_left_rounded,
                          onTap: () => Navigator.maybePop(context)),
                      const SizedBox(width: 12),

                      // Greeting
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Lab Tests',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                              )),
                            const SizedBox(height: 2),
                            Text('Diagnostics & medical testing',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.60),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              )),
                          ],
                        ),
                      ),

                      // Notification bell
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: _headerIconBtn(
                            Icons.notifications_outlined,
                            badge: true,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ── Stats row ────────────────────────────────
                  Row(children: [
                    _headerStat(Icons.science_outlined, '120+', 'Tests'),
                    const SizedBox(width: 10),
                    _headerStat(Icons.account_balance_outlined, '8', 'Labs'),
                    const SizedBox(width: 10),
                    _headerStat(Icons.timer_outlined, '24hr', 'Results'),
                  ]),

                  const SizedBox(height: 18),

                  // ── Search bar ───────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(children: [
                            const SizedBox(width: 14),
                            Icon(Icons.search_rounded,
                                color: _textLight, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                style: const TextStyle(
                                    color: _textDark, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Search tests, labs, packages…',
                                  hintStyle: TextStyle(
                                    color: _textLight.withOpacity(0.80),
                                    fontSize: 13.5,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Filter button
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.22)),
                        ),
                        child: const Icon(Icons.tune_rounded,
                            color: Colors.white, size: 20),
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

  Widget _headerIconBtn(IconData icon,
      {VoidCallback? onTap, bool badge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Stack(children: [
          Center(child: Icon(icon, color: Colors.white, size: 20)),
          if (badge)
            Positioned(
              top: 8, right: 8,
              child: Container(
                width: 7, height: 7,
                decoration: const BoxDecoration(
                    color: _red, shape: BoxShape.circle),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _headerStat(IconData icon, String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _softBlue.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _skyBlue, size: 14),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(val,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                )),
              Text(label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                )),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _glowBlob(double size, Color color, double opacity) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
            colors: [color.withOpacity(opacity), Colors.transparent]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  2. FILTER CHIPS
  // ════════════════════════════════════════════════════════════════
  Widget _buildFilterChips() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final active = _activeFilter == i;
          final f = _filters[i];
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: active
                  ? const LinearGradient(
                      colors: [_navy, Color(0xFF1A5DB0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
                color: active ? null : _cardWhite,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: active
                        ? _navy.withOpacity(0.28)
                        : Colors.blueGrey.withOpacity(0.07),
                    blurRadius: active ? 12 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(children: [
                Icon(
                  f['icon'] as IconData,
                  size: 13,
                  color: active ? Colors.white : _textMid,
                ),
                const SizedBox(width: 6),
                Text(
                  f['label'] as String,
                  style: TextStyle(
                    color: active ? Colors.white : _textMid,
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  3. FAST RESULTS BANNER
  // ════════════════════════════════════════════════════════════════
  Widget _buildFastResultsBanner() {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, child) {
        return Container(
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF0A2459), Color(0xFF1560C0), Color(0xFF2E80E0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _navy.withOpacity(0.28),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              // Shimmer sweep
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: CustomPaint(
                    painter: _ShimmerPainter(_shimmerAnim.value),
                  ),
                ),
              ),
              // Decorative circles
              Positioned(
                  right: -20, top: -20,
                  child: _glowBlob(110, Colors.white, 0.08)),
              Positioned(
                  right: 80, bottom: -30,
                  child: _glowBlob(70, _skyBlue, 0.15)),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('⚡ EXPRESS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                )),
                            ),
                          ]),
                          const SizedBox(height: 6),
                          const Text('Results within 24 hours',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            )),
                          const SizedBox(height: 3),
                          Text('Book now — same day collection available',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.70),
                              fontSize: 11,
                            )),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text('Book Now',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          )),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  4. FEATURED TESTS  (horizontal premium cards)
  // ════════════════════════════════════════════════════════════════
  Widget _buildFeaturedTests() {
    final tests = [
      _TestData(
        name: 'Complete Blood Count',
        lab: 'Aga Khan Lab',
        rating: 4.9,
        duration: '20 min',
        price: 'TZS 15,000',
        available: true,
        urgent: false,
        icon: Icons.water_drop_outlined,
        accentColor: _red,
        bgColor: _redBg,
        tests: 18,
      ),
      _TestData(
        name: 'Pelvic Ultrasound',
        lab: 'Muhimbili Diagnostics',
        rating: 4.7,
        duration: '30 min',
        price: 'TZS 35,000',
        available: true,
        urgent: false,
        icon: Icons.radar_rounded,
        accentColor: const Color(0xFF7E57C2),
        bgColor: const Color(0xFFF3E5F5),
        tests: 5,
      ),
      _TestData(
        name: 'Vision Screening',
        lab: 'ELCT Eye Center',
        rating: 4.8,
        duration: '15 min',
        price: 'TZS 10,000',
        available: true,
        urgent: false,
        icon: Icons.remove_red_eye_outlined,
        accentColor: const Color(0xFF00ACC1),
        bgColor: const Color(0xFFE0F7FA),
        tests: 6,
      ),
      _TestData(
        name: 'Malaria RDT',
        lab: 'Regency Medical',
        rating: 4.6,
        duration: '10 min',
        price: 'TZS 8,000',
        available: false,
        urgent: true,
        icon: Icons.biotech_outlined,
        accentColor: _green,
        bgColor: _greenBg,
        tests: 3,
      ),
      _TestData(
        name: 'Dental OPG X-Ray',
        lab: 'TMJ Dental Clinic',
        rating: 4.5,
        duration: '25 min',
        price: 'TZS 20,000',
        available: true,
        urgent: false,
        icon: Icons.medical_services_outlined,
        accentColor: _softBlue,
        bgColor: _blueTint,
        tests: 4,
      ),
    ];

    return SizedBox(
      height: 255,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: tests.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + i * 60),
            curve: Curves.easeOutBack,
            builder: (_, v, child) =>
                Transform.scale(scale: v, child: child),
            child: _FeaturedTestCard(data: tests[i]),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  5. HEALTH PACKAGES
  // ════════════════════════════════════════════════════════════════
  Widget _buildHealthPackages() {
    final packages = [
      _PackageData(
        name: 'Full Body\nCheckup',
        tests: 42,
        turnaround: '24 hrs',
        price: 'TZS 120,000',
        badge: 'POPULAR',
        badgeColor: _softBlue,
        gradientStart: const Color(0xFF0A2459),
        gradientEnd: const Color(0xFF1A5DB0),
        icon: Icons.monitor_heart_outlined,
      ),
      _PackageData(
        name: 'Diabetes\nProfile',
        tests: 12,
        turnaround: '4 hrs',
        price: 'TZS 45,000',
        badge: 'FAST',
        badgeColor: _orange,
        gradientStart: const Color(0xFF1B5E20),
        gradientEnd: const Color(0xFF2E7D32),
        icon: Icons.bloodtype_outlined,
      ),
      _PackageData(
        name: 'Pregnancy\nCare',
        tests: 18,
        turnaround: '12 hrs',
        price: 'TZS 80,000',
        badge: 'NEW',
        badgeColor: const Color(0xFF7E57C2),
        gradientStart: const Color(0xFF4A148C),
        gradientEnd: const Color(0xFF7B1FA2),
        icon: Icons.pregnant_woman_rounded,
      ),
      _PackageData(
        name: 'Heart\nScreening',
        tests: 15,
        turnaround: '8 hrs',
        price: 'TZS 95,000',
        badge: 'VITAL',
        badgeColor: _red,
        gradientStart: const Color(0xFF880E4F),
        gradientEnd: const Color(0xFFC62828),
        icon: Icons.favorite_border_rounded,
      ),
    ];

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: packages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => _PackageCard(data: packages[i]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  6. NEARBY LABS
  // ════════════════════════════════════════════════════════════════
  Widget _buildNearbyLabs() {
    final labs = [
      _LabData(
        name: 'Aga Khan Hospital Lab',
        address: 'Ocean Road, Dar es Salaam',
        rating: 4.9,
        distance: '1.2 km',
        open: true,
        hours: 'Open until 10:00 PM',
        specialties: ['Blood', 'Imaging', 'Pathology'],
      ),
      _LabData(
        name: 'Muhimbili Diagnostics',
        address: 'Upanga, Dar es Salaam',
        rating: 4.6,
        distance: '2.8 km',
        open: true,
        hours: 'Open until 8:00 PM',
        specialties: ['Ultrasound', 'X-Ray', 'ECG'],
      ),
      _LabData(
        name: 'Regency Medical Centre',
        address: 'Masaki Peninsula',
        rating: 4.7,
        distance: '4.1 km',
        open: false,
        hours: 'Opens at 8:00 AM',
        specialties: ['Full Body', 'Cardiac', 'Dental'],
      ),
    ];

    return Column(
      children: labs.map((l) => _LabCard(data: l)).toList(),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  7. UPCOMING TESTS TIMELINE
  // ════════════════════════════════════════════════════════════════
  Widget _buildUpcomingTimeline() {
    final items = [
      _UpcomingData(
        testName: 'Pelvic Ultrasound',
        labName: 'Aga Khan Lab',
        dateLabel: 'Tomorrow',
        dateNum: '28',
        month: 'MAY',
        time: '10:30 AM',
        status: _UpStatus.confirmed,
        icon: Icons.radar_rounded,
        iconColor: const Color(0xFF7E57C2),
        iconBg: const Color(0xFFF3E5F5),
      ),
      _UpcomingData(
        testName: 'Complete Blood Count',
        labName: 'Muhimbili Diagnostics',
        dateLabel: 'Wednesday',
        dateNum: '29',
        month: 'MAY',
        time: '8:00 AM',
        status: _UpStatus.pending,
        icon: Icons.water_drop_outlined,
        iconColor: _red,
        iconBg: _redBg,
      ),
      _UpcomingData(
        testName: 'Full Body Checkup',
        labName: 'Regency Medical',
        dateLabel: 'Friday',
        dateNum: '31',
        month: 'MAY',
        time: '9:00 AM',
        status: _UpStatus.pending,
        icon: Icons.monitor_heart_outlined,
        iconColor: _softBlue,
        iconBg: _blueTint,
      ),
    ];

    return Column(
      children: List.generate(items.length, (i) {
        final isLast = i == items.length - 1;
        return _TimelineItem(data: items[i], isLast: isLast);
      }),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  8. RECENT RESULTS
  // ════════════════════════════════════════════════════════════════
  Widget _buildRecentResults() {
    final results = [
      _ResultData(
        testName: 'Vision Screening',
        labName: 'ELCT Eye Center',
        date: '20 May 2026',
        status: _ResultStatus.normal,
        doctorReviewed: true,
        icon: Icons.remove_red_eye_outlined,
        iconColor: const Color(0xFF00ACC1),
        iconBg: const Color(0xFFE0F7FA),
      ),
      _ResultData(
        testName: 'Hemoglobin Test',
        labName: 'Aga Khan Lab',
        date: '15 May 2026',
        status: _ResultStatus.borderline,
        doctorReviewed: true,
        icon: Icons.water_drop_outlined,
        iconColor: _red,
        iconBg: _redBg,
      ),
      _ResultData(
        testName: 'Dental OPG X-Ray',
        labName: 'TMJ Dental Clinic',
        date: '10 May 2026',
        status: _ResultStatus.pending,
        doctorReviewed: false,
        icon: Icons.medical_services_outlined,
        iconColor: _softBlue,
        iconBg: _blueTint,
      ),
    ];

    return Column(
      children: results.map((r) => _ResultCard(data: r)).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PAINTERS
// ═══════════════════════════════════════════════════════════════════

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..strokeWidth = 0.5;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  const _ShimmerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final shimmerX = progress * size.width;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment(-1.5, 0),
        end: Alignment(1.5, 0),
        transform: GradientRotation(math.pi / 6),
      ).createShader(Rect.fromLTWH(shimmerX - 80, 0, 180, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════
//  EXTRACTED WIDGETS
// ═══════════════════════════════════════════════════════════════════

// ── Featured Test Card ───────────────────────────────────────────
class _FeaturedTestCard extends StatefulWidget {
  final _TestData data;
  const _FeaturedTestCard({required this.data});

  @override
  State<_FeaturedTestCard> createState() => _FeaturedTestCardState();
}

class _FeaturedTestCardState extends State<_FeaturedTestCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.96,
      upperBound: 1.00,
      value: 1.0,
    );
  }

  @override
  void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return GestureDetector(
      onTapDown:   (_) => _press.reverse(),
      onTapUp:     (_) => _press.forward(),
      onTapCancel: ()  => _press.forward(),
      child: ScaleTransition(
        scale: _press,
        child: Container(
          width: 170,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.blueGrey.withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Colored top section ──────────────────────
              Container(
                height: 75,
                decoration: BoxDecoration(
                  color: d.bgColor,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24)),
                ),
                child: Stack(
                  children: [
                    // Background circle
                    Positioned(
                      right: -15, top: -15,
                      child: Container(
                        width: 75, height: 75,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: d.accentColor.withOpacity(0.08),
                        ),
                      ),
                    ),
                    // Icon
                    Positioned(
                      left: 14, top: 14,
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: d.accentColor.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(d.icon, color: d.accentColor, size: 22),
                      ),
                    ),
                    // Availability badge
                    Positioned(
                      right: 10, top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: d.available
                              ? const Color(0xFF00B87A).withOpacity(0.14)
                              : const Color(0xFFF59D20).withOpacity(0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          Container(
                            width: 5, height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: d.available
                                  ? const Color(0xFF00B87A)
                                  : const Color(0xFFF59D20),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            d.available ? 'Open' : 'Busy',
                            style: TextStyle(
                              color: d.available
                                  ? const Color(0xFF00B87A)
                                  : const Color(0xFFF59D20),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Card body ────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0D1F3C),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          height: 1.25,
                        )),
                      const SizedBox(height: 4),
                      Text(d.lab,
                        style: const TextStyle(
                          color: Color(0xFF8AAAC8),
                          fontSize: 10.5,
                        )),
                      const SizedBox(height: 8),
                      // Rating + duration row
                      Row(children: [
                        Icon(Icons.star_rounded,
                            color: Colors.amber.shade600, size: 12),
                        const SizedBox(width: 3),
                        Text('${d.rating}',
                          style: const TextStyle(
                            color: Color(0xFF3E5A82),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                        const Spacer(),
                        Icon(Icons.schedule_rounded,
                            color: const Color(0xFF8AAAC8), size: 11),
                        const SizedBox(width: 3),
                        Text(d.duration,
                          style: const TextStyle(
                            color: Color(0xFF8AAAC8),
                            fontSize: 10.5,
                          )),
                      ]),
                      const SizedBox(height: 6),
                      Text(d.price,
                        style: TextStyle(
                          color: d.accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        )),
                    ],
                  ),
                ),
              ),

              // ── Book button ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: Container(
                  width: double.infinity,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A2459), Color(0xFF1560C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1560C0).withOpacity(0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_circle_outline_rounded,
                            color: Colors.white, size: 13),
                        const SizedBox(width: 5),
                        const Text('Book Test',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          )),
                      ],
                    ),
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

// ── Package Card ─────────────────────────────────────────────────
class _PackageCard extends StatelessWidget {
  final _PackageData data;
  const _PackageCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [data.gradientStart, data.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: data.gradientStart.withOpacity(0.30),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Bg glow
          Positioned(
            right: -15, bottom: -15,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            left: -10, top: -10,
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge + icon row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: data.badgeColor.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: data.badgeColor.withOpacity(0.40)),
                      ),
                      child: Text(data.badge,
                        style: TextStyle(
                          color: data.badgeColor,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        )),
                    ),
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(data.icon,
                          color: Colors.white.withOpacity(0.90), size: 16),
                    ),
                  ],
                ),
                const Spacer(),
                Text(data.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.2,
                  )),
                const SizedBox(height: 8),
                Row(children: [
                  _pkgStat('${data.tests}', 'tests'),
                  const SizedBox(width: 12),
                  _pkgStat(data.turnaround, 'results'),
                ]),
                const SizedBox(height: 10),
                Text(data.price,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pkgStat(String val, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(val,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        )),
      Text(label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.60),
          fontSize: 9,
        )),
    ],
  );
}

// ── Lab Card ──────────────────────────────────────────────────────
class _LabCard extends StatelessWidget {
  final _LabData data;
  const _LabCard({required this.data});

  static const Color _navy    = Color(0xFF0A2459);
  static const Color _softBlue = Color(0xFF4DA3FF);
  static const Color _green   = Color(0xFF00B87A);
  static const Color _orange  = Color(0xFFF59D20);
  static const Color _textDark  = Color(0xFF0D1F3C);
  static const Color _textLight = Color(0xFF93ADC8);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.09),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Lab icon
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A2459), Color(0xFF1560C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.account_balance_outlined,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.name,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      )),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          color: _textLight, size: 11),
                      const SizedBox(width: 3),
                      Text(data.address,
                        style: const TextStyle(
                          color: _textLight,
                          fontSize: 11,
                        )),
                    ]),
                  ],
                ),
              ),

              // Distance badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(data.distance,
                  style: const TextStyle(
                    color: _softBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  )),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(children: [
            // Rating
            Icon(Icons.star_rounded,
                color: Colors.amber.shade600, size: 13),
            const SizedBox(width: 3),
            Text('${data.rating}',
              style: const TextStyle(
                color: _textDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              )),
            const SizedBox(width: 10),

            // Open status
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.open ? _green : _orange,
              ),
            ),
            const SizedBox(width: 5),
            Text(data.hours,
              style: TextStyle(
                color: data.open ? _green : _orange,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              )),

            const Spacer(),

            // Book button
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_navy, Color(0xFF1560C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _navy.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text('Book',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  )),
              ),
            ),
          ]),

          const SizedBox(height: 10),

          // Specialty chips
          Row(
            children: data.specialties.map((s) => Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FC),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(s,
                style: const TextStyle(
                  color: Color(0xFF3E5A82),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                )),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Timeline Item ─────────────────────────────────────────────────
class _TimelineItem extends StatelessWidget {
  final _UpcomingData data;
  final bool isLast;
  const _TimelineItem({required this.data, required this.isLast});

  static const Color _green  = Color(0xFF00B87A);
  static const Color _orange = Color(0xFFF59D20);
  static const Color _navy   = Color(0xFF0A2459);
  static const Color _textDark  = Color(0xFF0D1F3C);
  static const Color _textLight = Color(0xFF93ADC8);

  @override
  Widget build(BuildContext context) {
    final isConf = data.status == _UpStatus.confirmed;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Timeline date column ────────────────────────
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Container(
                  width: 48, height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A2459), Color(0xFF1560C0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(data.dateNum,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        )),
                      Text(data.month,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.60),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        )),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4DA3FF).withOpacity(0.3),
                            const Color(0xFF4DA3FF).withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Card ────────────────────────────────────────
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueGrey.withOpacity(0.09),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(children: [
                // Test icon
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: data.iconBg,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(data.icon, color: data.iconColor, size: 20),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(data.dateLabel,
                          style: TextStyle(
                            color: _textLight,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          )),
                        const SizedBox(width: 6),
                        Container(
                          width: 3, height: 3,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF93ADC8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(data.time,
                          style: const TextStyle(
                            color: _textLight,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          )),
                      ]),
                      const SizedBox(height: 3),
                      Text(data.testName,
                        style: const TextStyle(
                          color: _textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        )),
                      const SizedBox(height: 2),
                      Text(data.labName,
                        style: const TextStyle(
                          color: Color(0xFF8AAAC8),
                          fontSize: 11,
                        )),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isConf
                        ? _green.withOpacity(0.10)
                        : _orange.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isConf
                          ? _green.withOpacity(0.25)
                          : _orange.withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    isConf ? 'Confirmed' : 'Pending',
                    style: TextStyle(
                      color: isConf ? _green : _orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    )),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Result Card ───────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final _ResultData data;
  const _ResultCard({required this.data});

  static const Color _navy  = Color(0xFF0A2459);
  static const Color _green = Color(0xFF00B87A);
  static const Color _orange = Color(0xFFF59D20);
  static const Color _softBlue = Color(0xFF4DA3FF);
  static const Color _textDark  = Color(0xFF0D1F3C);
  static const Color _textLight = Color(0xFF93ADC8);

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    Color statusBg;

    switch (data.status) {
      case _ResultStatus.normal:
        statusColor = _green;
        statusBg    = const Color(0xFFE6F7F2);
        statusLabel = 'Normal';
        break;
      case _ResultStatus.borderline:
        statusColor = _orange;
        statusBg    = const Color(0xFFFFF4E0);
        statusLabel = 'Borderline';
        break;
      case _ResultStatus.pending:
        statusColor = _softBlue;
        statusBg    = const Color(0xFFEAF3FF);
        statusLabel = 'Processing';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.09),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(children: [
            // Icon
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: data.iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(data.icon, color: data.iconColor, size: 22),
            ),
            const SizedBox(width: 12),

            // Name + date + reviewed
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.testName,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    )),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: _textLight, size: 11),
                    const SizedBox(width: 4),
                    Text(data.date,
                      style: const TextStyle(
                        color: _textLight,
                        fontSize: 11,
                      )),
                    if (data.doctorReviewed) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A2459).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(children: [
                          const Icon(Icons.verified_outlined,
                              color: _navy, size: 9),
                          const SizedBox(width: 3),
                          const Text('Dr. Reviewed',
                            style: TextStyle(
                              color: _navy,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            )),
                        ]),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 5),
                  Text(data.labName,
                    style: const TextStyle(
                      color: Color(0xFF8AAAC8),
                      fontSize: 11,
                    )),
                ],
              ),
            ),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                )),
            ),
          ]),

          if (data.status != _ResultStatus.pending) ...[
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: const Color(0xFFF0F4F8),
            ),
            const SizedBox(height: 12),
            Row(children: [
              // View Result
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A2459), Color(0xFF1560C0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        BoxShadow(
                          color: _navy.withOpacity(0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart_rounded,
                            color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text('View Result',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Download PDF
              GestureDetector(
                onTap: () {},
                child: Container(
                  height: 36, width: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.download_outlined,
                      color: _softBlue, size: 17),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════════════════════════════

@immutable
class _TestData {
  final String   name;
  final String   lab;
  final double   rating;
  final String   duration;
  final String   price;
  final bool     available;
  final bool     urgent;
  final IconData icon;
  final Color    accentColor;
  final Color    bgColor;
  final int      tests;

  const _TestData({
    required this.name,
    required this.lab,
    required this.rating,
    required this.duration,
    required this.price,
    required this.available,
    required this.urgent,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.tests,
  });
}

@immutable
class _PackageData {
  final String   name;
  final int      tests;
  final String   turnaround;
  final String   price;
  final String   badge;
  final Color    badgeColor;
  final Color    gradientStart;
  final Color    gradientEnd;
  final IconData icon;

  const _PackageData({
    required this.name,
    required this.tests,
    required this.turnaround,
    required this.price,
    required this.badge,
    required this.badgeColor,
    required this.gradientStart,
    required this.gradientEnd,
    required this.icon,
  });
}

@immutable
class _LabData {
  final String       name;
  final String       address;
  final double       rating;
  final String       distance;
  final bool         open;
  final String       hours;
  final List<String> specialties;

  const _LabData({
    required this.name,
    required this.address,
    required this.rating,
    required this.distance,
    required this.open,
    required this.hours,
    required this.specialties,
  });
}

enum _UpStatus { confirmed, pending }

@immutable
class _UpcomingData {
  final String   testName;
  final String   labName;
  final String   dateLabel;
  final String   dateNum;
  final String   month;
  final String   time;
  final _UpStatus status;
  final IconData icon;
  final Color    iconColor;
  final Color    iconBg;

  const _UpcomingData({
    required this.testName,
    required this.labName,
    required this.dateLabel,
    required this.dateNum,
    required this.month,
    required this.time,
    required this.status,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

enum _ResultStatus { normal, borderline, pending }

@immutable
class _ResultData {
  final String        testName;
  final String        labName;
  final String        date;
  final _ResultStatus status;
  final bool          doctorReviewed;
  final IconData      icon;
  final Color         iconColor;
  final Color         iconBg;

  const _ResultData({
    required this.testName,
    required this.labName,
    required this.date,
    required this.status,
    required this.doctorReviewed,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}