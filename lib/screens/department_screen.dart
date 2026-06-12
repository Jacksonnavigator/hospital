import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── Palette (Top Doctors image) ───────────────────────────────────────────────
// Top-level so all classes in this file can access them
const Color _primaryBlue  = Color(0xFF1A3D8F);  // deep blue — header, Book button
const Color _navyDeep     = Color(0xFF0F2B5B);  // darkest navy
const Color _bgColor      = Color(0xFFEEF4FB);  // light blue-grey page bg
const Color _cardBorder   = Color(0xFFBDD5EC);  // subtle card border
const Color _paleBlueBg   = Color(0xFFDCEBF8);  // pale blue tint
const Color _textDark     = Color(0xFF0F2B5B);  // near-black navy text
const Color _textMid      = Color(0xFF6B92B8);  // muted blue-grey text
const Color _textLight    = Color(0xFF9BBDD6);  // light placeholder / hints
const Color _green        = Color(0xFF16A34A);  // available badge green
const Color _greenBg      = Color(0xFFDCFCE7);  // available badge background

class DepartmentScreen extends StatefulWidget {
  const DepartmentScreen({super.key});

  @override
  State<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends State<DepartmentScreen>
    with TickerProviderStateMixin {
  // ── Data ─────────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _departments = [
    {
      'id': 1,
      'name': 'Dentistry',
      'image': 'lib/assets/Dental.jpg',
      'description': 'Dental & oral health care',
      'doctor': {
        'name': 'Dr. Allan Michael',
        'role': 'Dentist',
        'image': 'lib/assets/dentaldoctor.jpg',
      },
    },
    {
      'id': 2,
      'name': 'Ophthalmology',
      'image': 'lib/assets/Eye.jpg',
      'description': 'Eye & vision care',
      'doctor': {
        'name': 'Dr. Shaziri Mustapha',
        'role': 'Ophthalmologist',
        'image': 'lib/assets/eyedoctor.png',
      },
    },
    {
      'id': 3,
      'name': 'OB & Gynecology',
      'image': 'lib/assets/Obstetrics_Gynecology.jpg',
      'description': "Women's health & maternity",
      'doctor': {
        'name': 'Dr. Anna Sikawa',
        'role': 'OB-GYN Specialist',
        'image': 'lib/assets/obstetrics_gynecologydoctor.jpg',
      },
    },
    {
      'id': 4,
      'name': 'Pediatrics',
      'image': 'lib/assets/Pediatrics.jpg',
      'description': 'Children & infant care',
      'doctor': {
        'name': 'Dr. Hyasinta Kessy',
        'role': 'Pediatrician',
        'image': 'lib/assets/pediatricsdoctot.png',
      },
    },
  ];

  String _searchQuery = '';

  // ── Scroll ────────────────────────────────────────────────────────────────
  final ScrollController _scrollController = ScrollController();

  // ── Entry animation controllers ──────────────────────────────────────────
  late final AnimationController _headerCtrl;
  late final AnimationController _searchCtrl;
  late final AnimationController _listCtrl;
  late final AnimationController _bannerCtrl;

  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _searchFade;
  late final Animation<Offset> _searchSlide;
  late final Animation<double> _bannerScale;
  late final Animation<double> _bannerFade;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
            CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    _searchCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _searchFade = CurvedAnimation(parent: _searchCtrl, curve: Curves.easeOut);
    _searchSlide =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
            CurvedAnimation(parent: _searchCtrl, curve: Curves.easeOutBack));

    _listCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _bannerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _bannerScale = Tween<double>(begin: 0.88, end: 1.0).animate(
        CurvedAnimation(parent: _bannerCtrl, curve: Curves.easeOutBack));
    _bannerFade = CurvedAnimation(parent: _bannerCtrl, curve: Curves.easeOut);

    _runEntrySequence();
  }

  Future<void> _runEntrySequence() async {
    _headerCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _searchCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _listCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _bannerCtrl.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerCtrl.dispose();
    _searchCtrl.dispose();
    _listCtrl.dispose();
    _bannerCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredDepartments {
    if (_searchQuery.isEmpty) return _departments;
    return _departments
        .where((d) =>
            d['name'].toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Column(
        children: [
          FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
                position: _headerSlide, child: _buildHeader()),
          ),
          FadeTransition(
            opacity: _searchFade,
            child: SlideTransition(
                position: _searchSlide, child: _buildSearchBar()),
          ),
          Expanded(
            child: _filteredDepartments.isEmpty
                ? _buildEmptyState()
                : ListView(
                    controller: _scrollController,
                    // BouncingScrollPhysics gives that natural iOS-like feel
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    children: [
                      FadeTransition(
                        opacity: _listCtrl,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(
                            '${_filteredDepartments.length} Departments Available',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _textMid,
                            ),
                          ),
                        ),
                      ),
                      ..._filteredDepartments.asMap().entries.map((entry) {
                        final index = entry.key;
                        final dept = entry.value;
                        return _ScrollRevealCard(
                          key: ValueKey(dept['id']),
                          index: index,
                          total: _filteredDepartments.length,
                          listController: _listCtrl,
                          scrollController: _scrollController,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildDepartmentCard(context, dept),
                          ),
                        );
                      }),
                      ScaleTransition(
                        scale: _bannerScale,
                        child: FadeTransition(
                          opacity: _bannerFade,
                          child: _buildBookNowBanner(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2B5B), Color(0xFF1A3D8F), Color(0xFF1E5FAD)],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 36,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Medical Departments',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              const SizedBox(height: 3),
              Text('Choose a department to book',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.72))),
            ],
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Transform.translate(
      offset: const Offset(0, -22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBDD5EC)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F2B5B).withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(fontSize: 14, color: _textDark),
            decoration: InputDecoration(
              hintText: 'Search departments...',
              hintStyle: TextStyle(fontSize: 14, color: _textLight),
              prefixIcon:
                  Icon(Icons.search, size: 22, color: _textLight),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ),
    );
  }

  // ── Department card ───────────────────────────────────────────────────────
  Widget _buildDepartmentCard(
      BuildContext context, Map<String, dynamic> department) {
    final doctor = department['doctor'] as Map<String, dynamic>;

    return _PressableCard(
      onTap: () => _showDepartmentDetails(context, department),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFBDD5EC)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F2B5B).withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 190,
              width: double.infinity,
              child: Image.asset(
                department['image'] as String,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFDCEBF8),
                  child: Center(
                      child: Icon(Icons.local_hospital,
                          size: 56, color: const Color(0xFFBDD5EC))),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(department['name'] as String,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _textDark)),
                  const SizedBox(height: 4),
                  Text(department['description'] as String,
                      style: TextStyle(
                          fontSize: 13,
                          color: _textMid,
                          height: 1.5)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Divider(height: 1, thickness: 0.5, color: const Color(0xFFDCEBF8)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFFBDD5EC), width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(doctor['image'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFDCEBF8),
                              child: Icon(Icons.person,
                                  size: 28, color: _textLight))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doctor['name'] as String,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _textDark)),
                        const SizedBox(height: 2),
                        Text(doctor['role'] as String,
                            style: TextStyle(
                                fontSize: 12, color: _textMid)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.circle,
                              size: 7, color: _green),
                          const SizedBox(width: 5),
                          Text('Available Today',
                              style: TextStyle(
                                  fontSize: 11, color: _green)),
                        ]),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        _showDepartmentDetails(context, department),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    child: const Text('Book'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Book Now Banner ───────────────────────────────────────────────────────
  Widget _buildBookNowBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Need urgent care?',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text('Book with an available doctor now',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.75),
                        height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Navigating to booking...')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _primaryBlue,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 72, color: const Color(0xFFBDD5EC)),
          const SizedBox(height: 16),
          Text('No departments found',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textMid)),
          const SizedBox(height: 6),
          Text('Try searching with different keywords',
              style: TextStyle(fontSize: 13, color: _textLight)),
        ],
      ),
    );
  }

  // ── Bottom sheet ──────────────────────────────────────────────────────────
  void _showDepartmentDetails(
      BuildContext context, Map<String, dynamic> department) {
    final doctor = department['doctor'] as Map<String, dynamic>;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AnimatedBottomSheet(
        department: department,
        doctor: doctor,
        primaryBlue: _primaryBlue,
        buildServiceItem: _buildServiceItem,
      ),
    );
  }

  Widget _buildServiceItem(String service) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 18, color: _primaryBlue),
          const SizedBox(width: 10),
          Text(service,
              style:
                  const TextStyle(fontSize: 14, color: _textDark)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ScrollRevealCard
//
// • Cards already visible on launch → driven by the stagger (listController).
// • Cards below the fold           → hidden (opacity 0) until they enter
//   the viewport, then a smooth fade + slide-up plays once.
//
// Detection uses the card's own RenderBox position relative to the
// ScrollController's viewport, so it works regardless of card height.
// ─────────────────────────────────────────────────────────────────────────────
class _ScrollRevealCard extends StatefulWidget {
  const _ScrollRevealCard({
    super.key,
    required this.index,
    required this.total,
    required this.listController,
    required this.scrollController,
    required this.child,
  });

  final int index;
  final int total;
  final AnimationController listController;
  final ScrollController scrollController;
  final Widget child;

  @override
  State<_ScrollRevealCard> createState() => _ScrollRevealCardState();
}

class _ScrollRevealCardState extends State<_ScrollRevealCard>
    with SingleTickerProviderStateMixin {
  // One-shot reveal controller for cards scrolled into view
  late final AnimationController _revealCtrl;
  late final Animation<double> _revealFade;
  late final Animation<Offset> _revealSlide;

  // Stagger animations for the initial visible cards
  late final Animation<double> _staggerFade;
  late final Animation<Offset> _staggerSlide;

  // Whether this card is in the initial visible set (≤ 2 cards typically)
  bool _isInitialCard = false;
  // Whether the scroll-reveal has already fired
  bool _revealed = false;

  final GlobalKey _boxKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // ── Scroll-reveal animation ───────────────────────────────────────────
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _revealFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOut));
    _revealSlide =
        Tween<Offset>(begin: const Offset(0, 0.16), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _revealCtrl, curve: Curves.easeOutCubic));

    // ── Stagger (initial load) ────────────────────────────────────────────
    final itemInterval = 1.0 / math.max(widget.total, 1);
    final start = (widget.index * itemInterval).clamp(0.0, 1.0);
    final end = (start + itemInterval * 1.5).clamp(0.0, 1.0);
    final staggerCurve = CurvedAnimation(
      parent: widget.listController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    _staggerFade =
        Tween<double>(begin: 0.0, end: 1.0).animate(staggerCurve);
    _staggerSlide =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
            .animate(staggerCurve);

    // After the first frame, check if this card is already in the viewport.
    // If so, let the stagger handle it. Otherwise register the scroll listener.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_checkVisible()) {
        // In view at launch — stagger handles it; mark revealed so the
        // scroll listener never re-fires.
        _isInitialCard = true;
        _revealed = true;
        _revealCtrl.value = 1.0;
      } else {
        // Below the fold — start fully hidden and wait for scroll
        widget.scrollController.addListener(_onScroll);
      }
    });
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _revealCtrl.dispose();
    super.dispose();
  }

  /// Returns true when the card has scrolled into the visible viewport.
  bool _checkVisible() {
    if (!widget.scrollController.hasClients) return false;
    final ctx = _boxKey.currentContext;
    if (ctx == null) return false;
    final renderBox = ctx.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return false;

    final cardTop = renderBox.localToGlobal(Offset.zero).dy;
    final cardBottom = cardTop + renderBox.size.height;
    final sh = MediaQuery.of(ctx).size.height;

    // Reveal when card enters the lower 92 % of the screen
    return cardBottom > 0 && cardTop < sh * 0.92;
  }

  void _onScroll() {
    if (_revealed || !mounted) return;
    if (_checkVisible()) {
      _revealed = true;
      widget.scrollController.removeListener(_onScroll);
      _revealCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cards in the initial viewport: use stagger
    if (_isInitialCard) {
      return FadeTransition(
        key: _boxKey,
        opacity: _staggerFade,
        child: SlideTransition(
            position: _staggerSlide, child: widget.child),
      );
    }

    // Cards below the fold: use scroll-reveal
    // Before reveal fires they are invisible (opacity 0 via _revealFade at 0)
    return FadeTransition(
      key: _boxKey,
      opacity: _revealFade,
      child:
          SlideTransition(position: _revealSlide, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PressableCard — subtle scale-down on press, spring back on release
// ─────────────────────────────────────────────────────────────────────────────
class _PressableCard extends StatefulWidget {
  const _PressableCard({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) async {
        await Future.delayed(const Duration(milliseconds: 80));
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AnimatedBottomSheet — elements stagger in after the sheet opens
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedBottomSheet extends StatefulWidget {
  const _AnimatedBottomSheet({
    required this.department,
    required this.doctor,
    required this.primaryBlue,
    required this.buildServiceItem,
  });

  final Map<String, dynamic> department;
  final Map<String, dynamic> doctor;
  final Color primaryBlue;
  final Widget Function(String) buildServiceItem;

  @override
  State<_AnimatedBottomSheet> createState() => _AnimatedBottomSheetState();
}

class _AnimatedBottomSheetState extends State<_AnimatedBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Animation<double> _f(double s, double e) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _ctrl,
          curve: Interval(s, e, curve: Curves.easeOut)));

  Animation<Offset> _s(double s, double e) =>
      Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(
              parent: _ctrl,
              curve: Interval(s, e, curve: Curves.easeOutCubic)));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: const Color(0xFFBDD5EC),
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),

          // Image
          FadeTransition(
            opacity: _f(0.0, 0.45),
            child: SlideTransition(
              position: _s(0.0, 0.45),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.asset(widget.department['image'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFDCEBF8),
                          child: Center(
                              child: Icon(Icons.local_hospital,
                                  size: 56,
                                  color: _textLight)))),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Name + description
          FadeTransition(
            opacity: _f(0.2, 0.6),
            child: SlideTransition(
              position: _s(0.2, 0.6),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.department['name'] as String,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _textDark)),
                    const SizedBox(height: 5),
                    Text(widget.department['description'] as String,
                        style: TextStyle(
                            fontSize: 14, color: _textMid)),
                  ]),
            ),
          ),
          const SizedBox(height: 20),

          // Doctor card
          FadeTransition(
            opacity: _f(0.35, 0.72),
            child: SlideTransition(
              position: _s(0.35, 0.72),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBDD5EC)),
                ),
                child: Row(children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFBDD5EC), width: 2)),
                    child: ClipOval(
                        child: Image.asset(widget.doctor['image'] as String,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFDCEBF8),
                                child: Icon(Icons.person,
                                    size: 30,
                                    color: _textLight)))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.doctor['name'] as String,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _textDark)),
                          const SizedBox(height: 3),
                          Text(widget.doctor['role'] as String,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _textMid)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Icon(Icons.circle,
                                size: 8, color: _green),
                            const SizedBox(width: 5),
                            Text('Available Today',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _green)),
                          ]),
                        ]),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Services
          FadeTransition(
            opacity: _f(0.5, 0.85),
            child: SlideTransition(
              position: _s(0.5, 0.85),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Services Available',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _textDark)),
                    const SizedBox(height: 12),
                    widget.buildServiceItem('Initial Consultation'),
                    widget.buildServiceItem('Diagnosis & Testing'),
                    widget.buildServiceItem('Treatment Plans'),
                    widget.buildServiceItem('Follow-up Visits'),
                  ]),
            ),
          ),
          const SizedBox(height: 26),

          // CTA
          FadeTransition(
            opacity: _f(0.65, 1.0),
            child: SlideTransition(
              position: _s(0.65, 1.0),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Booking appointment with ${widget.doctor['name']}')));
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Book Appointment',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}