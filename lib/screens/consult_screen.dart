import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════
//  ClinicBook  ·  Consult Screen  (Premium Redesign)
//  lib/screens/consult_screen.dart
//
//  Sections:
//   1. Gradient header with blobs & stats
//   2. Featured Doctor Hero Card (Video / Voice / Chat actions)
//   3. Quick Consult Action Cards (horizontal)
//   4. Floating Search Bar
//   5. Specialty Filter Chips with icons
//   6. Online Doctors Carousel
//   7. All Specialists vertical list
//   8. Health Tip Banner
//   9. Consult Bottom Sheet
// ═══════════════════════════════════════════════════════════════════

// ── Palette ────────────────────────────────────────────────────────
class _C {
  static const navy      = Color(0xFF0A2459);
  static const blue      = Color(0xFF1565C0);
  static const blueMed   = Color(0xFF1E88E5);
  static const blueTint  = Color(0xFFEAF4FF);
  static const bg        = Color(0xFFF2F7FF);
  static const white     = Colors.white;
  static const textDark  = Color(0xFF0D1F3C);
  static const textMid   = Color(0xFF3A5A8A);
  static const textLight = Color(0xFF8AAAC8);
  static const green     = Color(0xFF00C896);
  static const amber     = Color(0xFFFFB300);
  static const rose      = Color(0xFFEF5350);
  static const teal      = Color(0xFF00ACC1);
}

// ── Doctor model ───────────────────────────────────────────────────
@immutable
class _Doctor {
  final String name;
  final String specialty;
  final double rating;
  final int    reviews;
  final String image;
  final bool   available;
  final String experience;
  final String fee;
  final String? bio;
  const _Doctor({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.reviews,
    required this.image,
    required this.available,
    required this.experience,
    required this.fee,
    this.bio,
  });
}

// ── Doctor data ────────────────────────────────────────────────────
const _kDoctors = <_Doctor>[
  _Doctor(
    name:       'Dr. Hyasinta Kessy',
    specialty:  'Pediatrics',
    rating:     4.9,
    reviews:    128,
    image:      'lib/assets/pediatricsdoctot.png',
    available:  true,
    experience: '11 yrs',
    fee:        'TZS 15,000',
    bio:        'Caring specialist in child health & development with 11+ years of practice.',
  ),
  _Doctor(
    name:       'Dr. Anna Sikawa',
    specialty:  'Obstetrics & Gynecology',
    rating:     4.7,
    reviews:    95,
    image:      'lib/assets/obstetrics_gynecologydoctor.jpg',
    available:  true,
    experience: '9 yrs',
    fee:        'TZS 20,000',
  ),
  _Doctor(
    name:       'Dr. Shaziri Mustapha',
    specialty:  'Ophthalmology',
    rating:     4.8,
    reviews:    112,
    image:      'lib/assets/eyedoctor.png',
    available:  false,
    experience: '7 yrs',
    fee:        'TZS 18,000',
  ),
  _Doctor(
    name:       'Dr. Allan Michael',
    specialty:  'Dentistry',
    rating:     4.6,
    reviews:    80,
    image:      'lib/assets/dentaldoctor.jpg',
    available:  true,
    experience: '5 yrs',
    fee:        'TZS 12,000',
  ),
  _Doctor(
    name:       'Dr. Sophia Mollel',
    specialty:  'Pediatrics',
    rating:     4.8,
    reviews:    91,
    image:      'lib/assets/Sophia Mollel.png',
    available:  true,
    experience: '8 yrs',
    fee:        'TZS 15,000',
  ),
  _Doctor(
    name:       'Dr. Nathani Temu',
    specialty:  'Ophthalmology',
    rating:     4.9,
    reviews:    102,
    image:      'lib/assets/Nathani Temu.jpeg',
    available:  true,
    experience: '12 yrs',
    fee:        'TZS 18,000',
  ),
  _Doctor(
    name:       'Dr. Jesca Tesha',
    specialty:  'Obstetrics & Gynecology',
    rating:     4.7,
    reviews:    88,
    image:      'lib/assets/Jesca Tesha.jpg',
    available:  false,
    experience: '10 yrs',
    fee:        'TZS 20,000',
  ),
  _Doctor(
    name:       'Dr. Benjamin Mushi',
    specialty:  'Dentistry',
    rating:     4.6,
    reviews:    75,
    image:      'lib/assets/Benjamin Mushi.jpeg',
    available:  true,
    experience: '6 yrs',
    fee:        'TZS 12,000',
  ),
];

// ── Specialty filter data ──────────────────────────────────────────
const _kFilters = [
  ('All',                    Icons.apps_rounded),
  ('Pediatrics',             Icons.child_care_rounded),
  ('Obstetrics & Gynecology',Icons.pregnant_woman_rounded),
  ('Ophthalmology',          Icons.visibility_rounded),
  ('Dentistry',              Icons.sentiment_satisfied_alt_rounded),
];

// ═══════════════════════════════════════════════════════════════════
//  CONSULT SCREEN
// ═══════════════════════════════════════════════════════════════════
class ConsultScreen extends StatefulWidget {
  const ConsultScreen({super.key});

  @override
  State<ConsultScreen> createState() => _ConsultScreenState();
}

class _ConsultScreenState extends State<ConsultScreen>
    with TickerProviderStateMixin {

  // ── Entrance animation
  late final AnimationController _entranceCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  // ── State
  int    _selectedFilter = 0;
  String _searchQuery    = '';

  // ── Filtered lists
  List<_Doctor> get _onlineDoctors =>
      _kDoctors.where((d) => d.available).take(5).toList();

  List<_Doctor> get _allFiltered => _kDoctors.where((d) {
    final matchFilter = _selectedFilter == 0 ||
        d.specialty == _kFilters[_selectedFilter].$1;
    final matchSearch = _searchQuery.isEmpty ||
        d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        d.specialty.toLowerCase().contains(_searchQuery.toLowerCase());
    return matchFilter && matchSearch;
  }).toList();

  // ── Featured hero doctor (first available)
  _Doctor get _heroDoctor =>
      _kDoctors.firstWhere((d) => d.available, orElse: () => _kDoctors.first);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 620));
    _fadeAnim  = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceCtrl, curve: Curves.easeOutCubic));
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [

              // ── 1. Header ───────────────────────────────────────
              SliverToBoxAdapter(child: _buildHeader()),

              // ── 2. Hero Doctor Card ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: _HeroDoctorCard(
                    doc:   _heroDoctor,
                    onTap: () => _openConsultSheet(_heroDoctor),
                  ),
                ),
              ),

              // ── 3. Quick Consult Actions ────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: _buildQuickActions(),
                ),
              ),

              // ── 4. Search Bar ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: _buildSearchBar(),
                ),
              ),

              // ── 5. Specialty Filter Chips ───────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildFilterChips(),
                ),
              ),

              // ── 6. Online Doctors Carousel ──────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 22, 0, 0),
                  child: _buildOnlineCarousel(),
                ),
              ),

              // ── 7. All Specialists header ───────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                  child: _buildSectionHeader(
                    'All Specialists',
                    '${_allFiltered.length} found',
                  ),
                ),
              ),

              // ── 7. All Specialists list ─────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _SpecialistCard(
                        doc:   _allFiltered[i],
                        onTap: () => _openConsultSheet(_allFiltered[i]),
                      ),
                    ),
                    childCount: _allFiltered.length,
                  ),
                ),
              ),

              // ── 8. Health Tip Banner ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: _buildHealthTipBanner(),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  1. HEADER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
          colors: [Color(0xFF05163A), Color(0xFF0A2868),
                   Color(0xFF1150B0), Color(0xFF1A78D0)],
          stops:  [0.0, 0.28, 0.65, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Decorative blobs
          Positioned(
            top: -70, right: -55,
            child: _GlowBlob(size: 220,
                color: const Color(0xFF3B9EFF), opacity: 0.20),
          ),
          Positioned(
            top: 50, right: 60,
            child: _GlowBlob(size: 90,
                color: const Color(0xFF00E5FF), opacity: 0.12),
          ),
          Positioned(
            bottom: 0, left: -30,
            child: _GlowBlob(size: 130,
                color: const Color(0xFF1976D2), opacity: 0.16),
          ),
          // Subtle dot grid
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter()),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Top row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeaderBadge('ONLINE CONSULTATION'),
                          const SizedBox(height: 8),
                          const Text(
                            'Consult a Doctor',
                            style: TextStyle(
                              color: Colors.white, fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6, height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Connect with specialists anytime',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.62),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      _NotificationBell(),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Stats row
                  Row(children: [
                    _StatChip(Icons.person_outline_rounded,  '48',   'Online Now'),
                    const SizedBox(width: 10),
                    _StatChip(Icons.timer_outlined,          '< 5m', 'Avg Reply'),
                    const SizedBox(width: 10),
                    _StatChip(Icons.star_border_rounded,     '4.9',  'Avg Rating'),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  3. QUICK CONSULT ACTIONS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildQuickActions() {
    const actions = [
      (Icons.chat_bubble_rounded,    '💬',  'Instant\nChat',      Color(0xFF1565C0)),
      (Icons.videocam_rounded,       '📹',  'Video\nConsult',     Color(0xFF00ACC1)),
      (Icons.phone_rounded,          '📞',  'Voice\nCall',        Color(0xFF00C896)),
      (Icons.local_hospital_rounded, '🚑',  'Emergency\nHelp',    Color(0xFFEF5350)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Quick Connect', sub: 'Instant access'),
        const SizedBox(height: 14),
        Row(
          children: actions.map((a) {
            final (icon, emoji, label, color) = a;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _QuickActionCard(
                  icon: icon, emoji: emoji,
                  label: label, color: color,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  4. SEARCH BAR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSearchBar() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color:        _C.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:      Colors.blueGrey.withOpacity(0.10),
            blurRadius: 18, offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(children: [
        const SizedBox(width: 16),
        Icon(Icons.search_rounded, color: _C.blue.withOpacity(0.7), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: const InputDecoration(
              hintText:       'Search doctor or specialty...',
              hintStyle:      TextStyle(color: _C.textLight, fontSize: 14),
              border:         InputBorder.none,
              isDense:        true,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(color: _C.textDark, fontSize: 14),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_C.navy, _C.blue]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text('Filter',
                style: TextStyle(
                  color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  5. FILTER CHIPS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildFilterChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection:  Axis.horizontal,
        physics:          const BouncingScrollPhysics(),
        padding:          const EdgeInsets.symmetric(horizontal: 20),
        itemCount:        _kFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (label, icon) = _kFilters[i];
          final selected = i == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 230),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(colors: [_C.navy, _C.blue])
                    : null,
                color: selected ? null : _C.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? Colors.transparent
                                  : _C.textLight.withOpacity(0.35),
                ),
                boxShadow: selected
                    ? [BoxShadow(
                        color: _C.blue.withOpacity(0.28),
                        blurRadius: 10, offset: const Offset(0, 4))]
                    : [BoxShadow(
                        color: Colors.blueGrey.withOpacity(0.07),
                        blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 14,
                      color: selected ? Colors.white : _C.textMid),
                  const SizedBox(width: 6),
                  Text(label,
                      style: TextStyle(
                        color:      selected ? Colors.white : _C.textMid,
                        fontSize:   12.5,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  6. ONLINE DOCTORS CAROUSEL
  // ═══════════════════════════════════════════════════════════════
  Widget _buildOnlineCarousel() {
    final online = _onlineDoctors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SectionTitle(
            title: 'Online Now',
            sub:   '${online.length} available',
            showDot: true,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 216,
          child: ListView.separated(
            scrollDirection:  Axis.horizontal,
            physics:          const BouncingScrollPhysics(),
            padding:          const EdgeInsets.symmetric(horizontal: 20),
            itemCount:        online.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _OnlineDoctorCard(
              doc:   online[i],
              onTap: () => _openConsultSheet(online[i]),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SECTION HEADER helper
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSectionHeader(String title, String sub) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
              color: _C.textDark, fontSize: 17,
              fontWeight: FontWeight.w800,
            )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _C.blueTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(sub,
              style: const TextStyle(
                color: _C.blue, fontSize: 11.5,
                fontWeight: FontWeight.w600,
              )),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  8. HEALTH TIP BANNER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHealthTipBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
          colors: [Color(0xFF0A3070), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color:      _C.blue.withOpacity(0.30),
            blurRadius: 24, offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Decorative circles
          Positioned(
            right: -20, top: -20,
            child: _GlowBlob(size: 130, color: Colors.white, opacity: 0.07),
          ),
          Positioned(
            left: -10, bottom: -30,
            child: _GlowBlob(size: 100, color: Colors.white, opacity: 0.05),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'HEALTH TIP',
                        style: TextStyle(
                          color: Colors.white70, fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Feeling unwell?\nConnect instantly with a specialist.',
                      style: TextStyle(
                        color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w700, height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Get Help Now',
                          style: TextStyle(
                            color: _C.blue, fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Medical illustration placeholder
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medical_services_rounded,
                  color: Colors.white70, size: 38,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Bottom sheet ─────────────────────────────────────────────
  void _openConsultSheet(_Doctor doc) {
    if (!doc.available) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConsultBottomSheet(doc: doc),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  HERO DOCTOR CARD  (section 2)
// ═══════════════════════════════════════════════════════════════════
class _HeroDoctorCard extends StatefulWidget {
  final _Doctor      doc;
  final VoidCallback onTap;
  const _HeroDoctorCard({required this.doc, required this.onTap});

  @override
  State<_HeroDoctorCard> createState() => _HeroDoctorCardState();
}

class _HeroDoctorCardState extends State<_HeroDoctorCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final Animation<double>   _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -4.0, end: 4.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _floatCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
          colors: [Color(0xFF0D2D6B), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color:      _C.blue.withOpacity(0.35),
            blurRadius: 28,
            offset:     const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Blob decorations
          Positioned(
            top: -40, right: -40,
            child: _GlowBlob(size: 180, color: Colors.white, opacity: 0.07),
          ),
          Positioned(
            bottom: -20, left: -20,
            child: _GlowBlob(size: 100, color: Colors.white, opacity: 0.05),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Top section: floating doctor image + info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor image with floating animation
                    AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: child,
                      ),
                      child: Stack(
                        children: [
                          Container(
                            width: 100, height: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color:      Colors.black.withOpacity(0.25),
                                  blurRadius: 16, offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.asset(
                                doc.image, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.2),
                                        Colors.white.withOpacity(0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: const Icon(Icons.person_rounded,
                                      color: Colors.white54, size: 48),
                                ),
                              ),
                            ),
                          ),
                          // Online indicator
                          Positioned(
                            top: 8, right: 8,
                            child: _PulseDot(color: _C.green),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Doctor info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Available badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _C.green.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _C.green.withOpacity(0.40)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _C.green),
                                ),
                                const SizedBox(width: 5),
                                const Text('Online Now',
                                    style: TextStyle(
                                      color: _C.green, fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(doc.name,
                              style: const TextStyle(
                                color: Colors.white, fontSize: 17,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              )),
                          const SizedBox(height: 4),
                          Text(doc.specialty,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.70),
                                fontSize: 12.5,
                              )),
                          const SizedBox(height: 10),
                          // Rating
                          Row(children: [
                            const Icon(Icons.star_rounded,
                                color: _C.amber, size: 15),
                            const SizedBox(width: 4),
                            Text('${doc.rating}',
                                style: const TextStyle(
                                  color: Colors.white, fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                )),
                            Text(' (${doc.reviews})',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 11.5,
                                )),
                          ]),
                          const SizedBox(height: 6),
                          Text(
                            doc.bio ??
                                'Experienced specialist ready to consult you online.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 11.5, height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: Colors.white.withOpacity(0.15), height: 1),
                const SizedBox(height: 18),

                // Consult action buttons
                Row(children: [
                  _HeroActionBtn(
                    icon:  Icons.videocam_rounded,
                    label: 'Video',
                    color: const Color(0xFF00ACC1),
                    onTap: widget.onTap,
                  ),
                  const SizedBox(width: 10),
                  _HeroActionBtn(
                    icon:  Icons.phone_rounded,
                    label: 'Voice',
                    color: _C.green,
                    onTap: widget.onTap,
                  ),
                  const SizedBox(width: 10),
                  _HeroActionBtn(
                    icon:  Icons.chat_bubble_rounded,
                    label: 'Chat',
                    color: const Color(0xFFFFB300),
                    onTap: widget.onTap,
                    flex: 2,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ONLINE DOCTOR CARD  (carousel, section 6)
// ═══════════════════════════════════════════════════════════════════
class _OnlineDoctorCard extends StatefulWidget {
  final _Doctor      doc;
  final VoidCallback onTap;
  const _OnlineDoctorCard({required this.doc, required this.onTap});

  @override
  State<_OnlineDoctorCard> createState() => _OnlineDoctorCardState();
}

class _OnlineDoctorCardState extends State<_OnlineDoctorCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 100),
        lowerBound: 0.96, upperBound: 1.0, value: 1.0);
  }

  @override
  void dispose() { _pressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    return GestureDetector(
      onTapDown:   (_) => _pressCtrl.reverse(),
      onTapUp:     (_) { _pressCtrl.forward(); widget.onTap(); },
      onTapCancel: ()  => _pressCtrl.forward(),
      child: ScaleTransition(
        scale: _pressCtrl,
        child: Container(
          width: 130,
          decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color:      Colors.blueGrey.withOpacity(0.10),
                blurRadius: 18, offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // Image + pulse dot
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 72, height: 72,
                        child: Image.asset(doc.image, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: _C.blueTint,
                              child: const Icon(Icons.person_rounded,
                                  color: Colors.white54, size: 32),
                            )),
                      ),
                    ),
                    Positioned(
                      bottom: 2, right: 2,
                      child: _PulseDot(color: _C.green),
                    ),
                  ],
                ),

                const SizedBox(height: 9),
                Text(
                  doc.name.replaceFirst('Dr. ', ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _C.textDark, fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doc.specialty.split(' ').first,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _C.textLight, fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.star_rounded, color: _C.amber, size: 11),
                  const SizedBox(width: 3),
                  Text('${doc.rating}',
                      style: const TextStyle(
                        color: _C.textDark, fontSize: 11,
                        fontWeight: FontWeight.w700,
                      )),
                ]),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: widget.onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_C.navy, _C.blue]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('Consult',
                          style: TextStyle(
                            color: Colors.white, fontSize: 11,
                            fontWeight: FontWeight.w700,
                          )),
                    ),
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

// ═══════════════════════════════════════════════════════════════════
//  SPECIALIST CARD  (vertical list, section 7)
// ═══════════════════════════════════════════════════════════════════
class _SpecialistCard extends StatefulWidget {
  final _Doctor      doc;
  final VoidCallback onTap;
  const _SpecialistCard({required this.doc, required this.onTap});

  @override
  State<_SpecialistCard> createState() => _SpecialistCardState();
}

class _SpecialistCardState extends State<_SpecialistCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 100),
        lowerBound: 0.97, upperBound: 1.0, value: 1.0);
  }

  @override
  void dispose() { _pressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final statusColor = doc.available ? _C.green : _C.rose;
    final statusLabel = doc.available ? 'Available' : 'Busy';

    return GestureDetector(
      onTapDown:   (_) => _pressCtrl.reverse(),
      onTapUp:     (_) { _pressCtrl.forward(); widget.onTap(); },
      onTapCancel: ()  => _pressCtrl.forward(),
      child: ScaleTransition(
        scale: _pressCtrl,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color:      Colors.blueGrey.withOpacity(0.09),
                blurRadius: 20, offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [

                // Doctor photo
                Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: 78, height: 88,
                      child: Image.asset(doc.image, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_C.blueTint, Color(0xFFCDE8FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: Colors.white60, size: 36),
                          )),
                    ),
                  ),
                  Positioned(
                    bottom: 4, right: 4,
                    child: Container(
                      width: 13, height: 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:  statusColor,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ]),

                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(doc.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _C.textDark, fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              )),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(statusLabel,
                              style: TextStyle(
                                color: statusColor, fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                      ]),

                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.local_hospital_outlined,
                            color: _C.textLight, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(doc.specialty,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: _C.textMid, fontSize: 12.5)),
                        ),
                      ]),

                      const SizedBox(height: 8),
                      Row(children: [
                        // Rating
                        const Icon(Icons.star_rounded,
                            color: _C.amber, size: 13),
                        const SizedBox(width: 3),
                        Text('${doc.rating}',
                            style: const TextStyle(
                              color: _C.textDark, fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            )),
                        Text(' · ${doc.reviews} reviews',
                            style: const TextStyle(
                                color: _C.textLight, fontSize: 11)),
                      ]),

                      const SizedBox(height: 6),
                      Row(children: [
                        // Experience
                        const Icon(Icons.work_outline_rounded,
                            color: _C.textLight, size: 12),
                        const SizedBox(width: 4),
                        Text(doc.experience,
                            style: const TextStyle(
                                color: _C.textMid, fontSize: 11.5)),
                        const SizedBox(width: 14),
                        // Fee
                        const Icon(Icons.payments_outlined,
                            color: _C.textLight, size: 12),
                        const SizedBox(width: 4),
                        Text(doc.fee,
                            style: const TextStyle(
                              color: _C.blue, fontSize: 12,
                              fontWeight: FontWeight.w700,
                            )),
                      ]),

                      const SizedBox(height: 12),
                      // Consult button row
                      Row(children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: doc.available ? widget.onTap : null,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                gradient: doc.available
                                    ? const LinearGradient(
                                        colors: [_C.navy, _C.blue])
                                    : null,
                                color: !doc.available
                                    ? Colors.grey.shade200 : null,
                                borderRadius: BorderRadius.circular(13),
                                boxShadow: doc.available
                                    ? [BoxShadow(
                                        color: _C.blue.withOpacity(0.28),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3))]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  doc.available ? 'Consult Now' : 'Unavailable',
                                  style: TextStyle(
                                    color: !doc.available
                                        ? Colors.grey
                                        : Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]),
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

// ═══════════════════════════════════════════════════════════════════
//  CONSULT BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════
class _ConsultBottomSheet extends StatelessWidget {
  final _Doctor doc;
  const _ConsultBottomSheet({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Doctor row
          Row(children: [
            Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 70, height: 70,
                  child: Image.asset(doc.image, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _C.blueTint,
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white54, size: 32),
                      )),
                ),
              ),
              Positioned(
                bottom: 3, right: 3,
                child: _PulseDot(color: _C.green),
              ),
            ]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.name,
                      style: const TextStyle(
                        color: _C.textDark, fontSize: 16,
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 3),
                  Text(doc.specialty,
                      style: const TextStyle(
                          color: _C.textMid, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.star_rounded,
                        color: _C.amber, size: 13),
                    const SizedBox(width: 3),
                    Text('${doc.rating} (${doc.reviews} reviews)',
                        style: const TextStyle(
                            color: _C.textLight, fontSize: 12)),
                  ]),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFEEF3FB)),
          const SizedBox(height: 20),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Choose consult type',
                style: TextStyle(
                  color: _C.textDark, fontSize: 14,
                  fontWeight: FontWeight.w700,
                )),
          ),
          const SizedBox(height: 14),

          _ConsultOptionBtn(
            icon:  Icons.chat_bubble_outline_rounded,
            label: 'Text Chat',
            sub:   'Send a message · Usually replies in < 5 min',
            color: _C.blue,
          ),
          const SizedBox(height: 10),
          _ConsultOptionBtn(
            icon:  Icons.phone_outlined,
            label: 'Voice Call',
            sub:   'Talk directly with the doctor',
            color: _C.green,
          ),
          const SizedBox(height: 10),
          _ConsultOptionBtn(
            icon:  Icons.videocam_outlined,
            label: 'Video Call',
            sub:   'Face-to-face consultation',
            color: _C.teal,
          ),

          const SizedBox(height: 20),

          // Fee info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _C.blueTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: _C.blue, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Consultation fee: ${doc.fee} per session',
                  style: const TextStyle(
                    color: _C.blue, fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SMALL REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _HeaderBadge extends StatelessWidget {
  final String text;
  const _HeaderBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
            color: Colors.white70, fontSize: 9.5,
            fontWeight: FontWeight.w700, letterSpacing: 1.4,
          )),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Stack(alignment: Alignment.center, children: [
        const Icon(Icons.notifications_outlined,
            color: Colors.white, size: 22),
        Positioned(
          top: 9, right: 9,
          child: Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Color(0xFFEF5350),
            ),
          ),
        ),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String   value;
  final String   label;
  const _StatChip(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.13),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Column(children: [
          Icon(icon, color: Colors.white.withOpacity(0.75), size: 16),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                color: Colors.white, fontSize: 14,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 1),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.58), fontSize: 9.5)),
        ]),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String sub;
  final bool   showDot;
  const _SectionTitle({
    required this.title,
    required this.sub,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          if (showDot) ...[
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: _C.green),
            ),
            const SizedBox(width: 6),
          ],
          Text(title,
              style: const TextStyle(
                color: _C.textDark, fontSize: 17,
                fontWeight: FontWeight.w800,
              )),
        ]),
        Text(sub,
            style: const TextStyle(
                color: _C.textLight, fontSize: 12.5)),
      ],
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String   emoji;
  final String   label;
  final Color    color;
  const _QuickActionCard({
    required this.icon,
    required this.emoji,
    required this.label,
    required this.color,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 100),
        lowerBound: 0.93, upperBound: 1.0, value: 1.0);
  }

  @override
  void dispose() { _pressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _pressCtrl.reverse(),
      onTapUp:     (_) => _pressCtrl.forward(),
      onTapCancel: ()  => _pressCtrl.forward(),
      child: ScaleTransition(
        scale: _pressCtrl,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color:      Colors.blueGrey.withOpacity(0.09),
                blurRadius: 14, offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: widget.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _C.textDark, fontSize: 10.5,
                fontWeight: FontWeight.w700, height: 1.3,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _HeroActionBtn extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;
  final int          flex;
  const _HeroActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  color: color, fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                )),
          ]),
        ),
      ),
    );
  }
}

class _ConsultOptionBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   sub;
  final Color    color;
  const _ConsultOptionBtn({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      color: color, fontSize: 14,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 2),
                Text(sub,
                    style: const TextStyle(
                        color: _C.textLight, fontSize: 11.5)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: color, size: 14),
        ]),
      ),
    );
  }
}

// Animated pulse dot for online status
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.55, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 11, height: 11,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.55),
              blurRadius: 6, spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// Decorative glow blob
class _GlowBlob extends StatelessWidget {
  final double size;
  final Color  color;
  final double opacity;
  const _GlowBlob({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          color.withOpacity(opacity),
          Colors.transparent,
        ]),
      ),
    );
  }
}

// Subtle dot grid painter for header background texture
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.055)
      ..style = PaintingStyle.fill;
    const spacing = 22.0;
    const radius  = 1.5;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => false;
}