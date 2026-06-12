import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'booking_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  ClinicBook  ·  Doctor Screen  (Full Doctors List)
//  lib/screens/doctor_screen.dart
// ═══════════════════════════════════════════════════════════════════

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen>
    with TickerProviderStateMixin {

  // ─── Palette (matches HomeScreen) ──────────────────────────────
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

  // ─── All doctors data ──────────────────────────────────────────
  static const _allDoctors = <_DocData>[
    _DocData('Dr. Hyasinta Kessy',   'Pediatrics',              4.9, 128, 'lib/assets/pediatricsdoctot.png',            true,  '11 yrs'),
    _DocData('Dr. Anna Sikawa',      'Obstetrics & Gynecology', 4.7,  95, 'lib/assets/obstetrics_gynecologydoctor.jpg', true,  '9 yrs'),
    _DocData('Dr. Shaziri Mustapha', 'Ophthalmology',           4.8, 112, 'lib/assets/eyedoctor.png',                   false, '7 yrs'),
    _DocData('Dr. Allan Michael',    'Dentistry',               4.6,  80, 'lib/assets/dentaldoctor.jpg',                true,  '5 yrs'),
    _DocData('Dr. Sophia Mollel',    'Pediatrics',              4.8,  91, 'lib/assets/Sophia Mollel.png',               true,  '8 yrs'),
    _DocData('Dr. Nathani Temu',     'Ophthalmology',           4.9, 102, 'lib/assets/Nathani Temu.jpeg',               true,  '12 yrs'),
    _DocData('Dr. Jesca Tesha',      'Obstetrics & Gynecology', 4.7,  88, 'lib/assets/Jesca Tesha.jpg',                false, '10 yrs'),
    _DocData('Dr. Benjamin Mushi',   'Dentistry',               4.6,  75, 'lib/assets/Benjamin Mushi.jpeg',             true,  '6 yrs'),
  ];

  static const _specialties = <String>[
    'All',
    'Pediatrics',
    'Obstetrics & Gynecology',
    'Ophthalmology',
    'Dentistry',
  ];

  // ─── State ─────────────────────────────────────────────────────
  String _selectedSpecialty = 'All';
  String _searchQuery       = '';

  // ─── Animation ─────────────────────────────────────────────────
  late final AnimationController _headerCtrl;
  late final AnimationController _floatCtrl;
  late final Animation<double>   _headerFade;
  late final Animation<Offset>   _headerSlide;
  late final Animation<double>   _floatAnim;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _headerFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));
    _headerSlide = Tween<Offset>(
            begin: const Offset(0, -0.06), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _headerCtrl, curve: Curves.easeOutCubic));

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _floatAnim =
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut);

    _headerCtrl.forward();
    _searchCtrl.addListener(
        () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _floatCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_DocData> get _filtered {
    return _allDoctors.where((d) {
      final matchSpec = _selectedSpecialty == 'All' ||
          d.specialty == _selectedSpecialty;
      final matchSearch = _searchQuery.isEmpty ||
          d.name.toLowerCase().contains(_searchQuery) ||
          d.specialty.toLowerCase().contains(_searchQuery);
      return matchSpec && matchSearch;
    }).toList();
  }

  void _goBooking() => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => BookingScreen(),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0), end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 380),
        ),
      );

  Widget _glowDot(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [BoxShadow(color: color, blurRadius: size * 1.5)],
        ),
      );

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ── Header ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _headerSlide,
              child: FadeTransition(
                opacity: _headerFade,
                child: _buildHeader(),
              ),
            ),
          ),

          // ── Search bar ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildSearchBar(),
            ),
          ),

          // ── Specialty filter chips ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildSpecialtyChips(),
            ),
          ),

          // ── Results count ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} doctor${filtered.length != 1 ? 's' : ''} found',
                    style: const TextStyle(
                      color:      _textMid,
                      fontSize:   13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Doctor list ─────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, idx) {
                final doc = filtered[idx];
                return TweenAnimationBuilder<double>(
                  key:      ValueKey(doc.name),
                  tween:    Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 350 + idx * 60),
                  curve:    Curves.easeOutCubic,
                  builder: (_, v, child) => Transform.translate(
                    offset: Offset(0, 24 * (1 - v)),
                    child:  Opacity(opacity: v.clamp(0, 1), child: child),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        20, idx == 0 ? 8 : 0, 20, 14),
                    child: _DoctorListCard(doc: doc, onBook: _goBooking),
                  ),
                );
              },
              childCount: filtered.length,
            ),
          ),

          // ── Bottom padding ──────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  HEADER  (matches HomeScreen gradient style)
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
          // Blob top-right
          Positioned(
            top: -50, right: -40,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF3B9EFF).withOpacity(0.25),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Blob bottom-left
          Positioned(
            bottom: 10, left: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF1976D2).withOpacity(0.18),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Accent ring
          Positioned(
            top: 52, left: 160,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:  Colors.white.withOpacity(0.06),
                border: Border.all(
                    color: Colors.white.withOpacity(0.10), width: 1),
              ),
            ),
          ),
          // Floating dots
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (_, __) {
              final dy = math.sin(_floatAnim.value * math.pi) * 8;
              return Positioned(
                top: 44 + dy, right: 20,
                child: _glowDot(10, _blueSky.withOpacity(0.75)),
              );
            },
          ),
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (_, __) {
              final dy = math.cos(_floatAnim.value * math.pi) * 9;
              return Positioned(
                top: 100 + dy, right: 70,
                child: _glowDot(6, Colors.white.withOpacity(0.30)),
              );
            },
          ),

          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color:        Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.22), width: 1),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size:  18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Top Doctors',
                          style: TextStyle(
                            color:      Colors.white,
                            fontSize:   22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Find & book your specialist',
                          style: TextStyle(
                            color:    Colors.white.withOpacity(0.65),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Filter icon
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color:        Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.22), width: 1),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size:  20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  SEARCH BAR  (matches HomeScreen style)
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
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText:       'Search doctor, specialty...',
              hintStyle: TextStyle(color: _textLight, fontSize: 14.5),
              border:         InputBorder.none,
              isDense:        true,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(color: _textDark, fontSize: 14.5),
          ),
        ),
        if (_searchQuery.isNotEmpty)
          GestureDetector(
            onTap: () {
              _searchCtrl.clear();
              setState(() => _searchQuery = '');
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.close_rounded,
                  color: _textLight, size: 18),
            ),
          ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  SPECIALTY FILTER CHIPS
  // ─────────────────────────────────────────────────────────────────
  Widget _buildSpecialtyChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection:  Axis.horizontal,
        physics:          const BouncingScrollPhysics(),
        padding:          const EdgeInsets.symmetric(horizontal: 20),
        itemCount:        _specialties.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final spec    = _specialties[i];
          final isActive = spec == _selectedSpecialty;
          return GestureDetector(
            onTap: () => setState(() => _selectedSpecialty = spec),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve:    Curves.easeOutCubic,
              padding:  const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(colors: [_navy, _blue])
                    : null,
                color:        isActive ? null : _white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isActive
                        ? _blue.withOpacity(0.30)
                        : Colors.blueGrey.withOpacity(0.08),
                    blurRadius: isActive ? 10 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  spec,
                  style: TextStyle(
                    color: isActive ? _white : _textMid,
                    fontSize:   12.5,
                    fontWeight: isActive
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DOCTOR LIST CARD  (horizontal layout, press feedback)
// ═══════════════════════════════════════════════════════════════════
class _DoctorListCard extends StatefulWidget {
  final _DocData     doc;
  final VoidCallback onBook;
  const _DoctorListCard({required this.doc, required this.onBook});

  @override
  State<_DoctorListCard> createState() => _DoctorListCardState();
}

class _DoctorListCardState extends State<_DoctorListCard>
    with SingleTickerProviderStateMixin {

  static const Color _navy      = Color(0xFF0A2459);
  static const Color _blue      = Color(0xFF1565C0);
  static const Color _blueTint  = Color(0xFFE8F3FF);
  static const Color _card      = Color(0xFFFFFFFF);
  static const Color _textDark  = Color(0xFF0D1F3C);
  static const Color _textMid   = Color(0xFF3A5A8A);
  static const Color _textLight = Color(0xFF8AAAC8);
  static const Color _green     = Color(0xFF00C896);
  static const Color _amber     = Color(0xFFFFB300);

  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this,
        duration:   const Duration(milliseconds: 100),
        lowerBound: 0.96,
        upperBound: 1.0,
        value:      1.0);
  }

  @override
  void dispose() { _pressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    return GestureDetector(
      onTapDown:   (_) => _pressCtrl.reverse(),
      onTapUp:     (_) => _pressCtrl.forward(),
      onTapCancel: ()  => _pressCtrl.forward(),
      child: ScaleTransition(
        scale: _pressCtrl,
        child: Container(
          decoration: BoxDecoration(
            color:        _card,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color:      Colors.blueGrey.withOpacity(0.10),
                blurRadius: 20, offset: const Offset(0, 6)),
              BoxShadow(
                color:      _blue.withOpacity(0.04),
                blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Photo ──────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 90, height: 100,
                    child: Image.asset(
                      doc.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _blueTint,
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white54, size: 40),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // ── Info ────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Name + availability badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              doc.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color:      _textDark,
                                fontSize:   14.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: doc.available
                                  ? const Color(0xFFE8FBF3)
                                  : const Color(0xFFFFEEEE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: doc.available
                                        ? _green
                                        : const Color(0xFFEF5350),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  doc.available ? 'Available' : 'Busy',
                                  style: TextStyle(
                                    color: doc.available
                                        ? const Color(0xFF00A67A)
                                        : const Color(0xFFEF5350),
                                    fontSize:   10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Specialty
                      Text(
                        doc.specialty,
                        style: const TextStyle(
                          color:      _blue,
                          fontSize:   12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Rating + Experience
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: _amber, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            '${doc.rating}',
                            style: const TextStyle(
                              color:      _textDark,
                              fontSize:   12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            ' (${doc.reviews})',
                            style: const TextStyle(
                                color: _textLight, fontSize: 11.5),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.work_outline_rounded,
                              color: _textLight, size: 13),
                          const SizedBox(width: 3),
                          Text(
                            doc.experience,
                            style: const TextStyle(
                              color:      _textMid,
                              fontSize:   11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Book Now button
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: doc.available
                              ? const LinearGradient(
                                  colors: [_navy, _blue])
                              : null,
                          color: doc.available
                              ? null
                              : const Color(0xFFEEF2F8),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: doc.available
                              ? [BoxShadow(
                                  color:      _blue.withOpacity(0.28),
                                  blurRadius: 8,
                                  offset:     const Offset(0, 3))]
                              : null,
                        ),
                        child: ElevatedButton(
                          onPressed: doc.available ? widget.onBook : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor:     Colors.transparent,
                            foregroundColor: doc.available
                                ? Colors.white
                                : _textLight,
                            disabledForegroundColor: _textLight,
                            disabledBackgroundColor: Colors.transparent,
                            minimumSize: const Size(double.infinity, 36),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13)),
                          ),
                          child: Text(
                            doc.available ? 'Book Now' : 'Unavailable',
                            style: const TextStyle(
                              fontSize:   13,
                              fontWeight: FontWeight.w700,
                            ),
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

// ═══════════════════════════════════════════════════════════════════
//  DATA MODEL
// ═══════════════════════════════════════════════════════════════════
@immutable
class _DocData {
  final String name;
  final String specialty;
  final double rating;
  final int    reviews;
  final String image;
  final bool   available;
  final String experience;
  const _DocData(this.name, this.specialty, this.rating,
      this.reviews, this.image, this.available, this.experience);
}