// lib/screens/emergency_screen.dart
//
// Emergency Screen — ClinicBook  (Professional Redesign v2)
// ─────────────────────────────────────────────────────────
//  Sections:
//   1. Status bar + rich red header with GPS status & 3-stat bar
//   2. Call Emergency  (animated ripple pulse)
//   3. Request Ambulance  (ETA badge)
//   4. Your Location  (mini schematic map + share)
//   5. Nearby Hospitals  (ranked list, navigate)
//   6. Immediate Support  (Video Call · Emergency Chat)
//   7. Medical ID  (blood type, allergy, medication)
//   8. SOS card  (hold 3 s, ripple ring animation)

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});
  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with TickerProviderStateMixin {

  // ── Palette ───────────────────────────────────────────────────────
  static const Color _bg       = Color(0xFF0C0C0E);
  static const Color _surface  = Color(0xFF161618);
  static const Color _card2    = Color(0xFF1F2937);
  static const Color _border   = Color(0xFF222226);
  static const Color _border2  = Color(0xFF1F2937);
  static const Color _red      = Color(0xFFB91C1C);
  static const Color _redLight = Color(0xFFEF4444);
  static const Color _green    = Color(0xFF16A34A);
  static const Color _greenL   = Color(0xFF22C55E);
  static const Color _blue     = Color(0xFF2563EB);
  static const Color _blueL    = Color(0xFF3B82F6);
  static const Color _white    = Colors.white;
  static const Color _textPri  = Color(0xFFF3F4F6);
  static const Color _textSec  = Color(0xFF9CA3AF);
  static const Color _textMut  = Color(0xFF6B7280);
  static const Color _textHint = Color(0xFF4B5563);

  // ── Animation controllers ─────────────────────────────────────────
  late final AnimationController _rippleCtrl;   // CTA pulse
  late final AnimationController _sosRingCtrl;  // SOS ring
  late final AnimationController _blinkCtrl;    // live dot
  late final AnimationController _slideCtrl;    // entrance

  late final Animation<double> _rippleAnim;
  late final Animation<double> _rippleOpacity;
  late final Animation<double> _sosRingAnim;
  late final Animation<double> _sosRingOpacity;
  late final Animation<double> _blinkAnim;

  // entrance animations — 6 staggered layers
  final List<Animation<double>>  _fadeIn = [];
  final List<Animation<Offset>>  _slideUp = [];

  // ── SOS long-press state ──────────────────────────────────────────
  bool   _sosHeld     = false;
  double _sosProgress = 0;
  late final AnimationController _sosHoldCtrl;

  // ── Location shared toggle ────────────────────────────────────────
  bool _locationShared = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // ── Ripple pulse on Call Emergency button ─────────────────────
    _rippleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();
    _rippleAnim = Tween<double>(begin: 1.0, end: 2.4).animate(
        CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut));
    _rippleOpacity = Tween<double>(begin: 0.55, end: 0.0).animate(
        CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut));

    // ── SOS ring pulse ────────────────────────────────────────────
    _sosRingCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _sosRingAnim = Tween<double>(begin: 1.0, end: 1.6).animate(
        CurvedAnimation(parent: _sosRingCtrl, curve: Curves.easeOut));
    _sosRingOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
        CurvedAnimation(parent: _sosRingCtrl, curve: Curves.easeOut));

    // ── GPS live dot blink ────────────────────────────────────────
    _blinkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300))
      ..repeat(reverse: true);
    _blinkAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut));

    // ── SOS hold-progress ────────────────────────────────────────
    _sosHoldCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000));
    _sosHoldCtrl.addListener(() {
      setState(() => _sosProgress = _sosHoldCtrl.value);
    });
    _sosHoldCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _triggerSOS();
    });

    // ── Entrance stagger ─────────────────────────────────────────
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    const starts = [0.00, 0.12, 0.22, 0.34, 0.46, 0.58];
    const ends   = [0.30, 0.42, 0.54, 0.66, 0.78, 0.92];
    for (int i = 0; i < 6; i++) {
      _fadeIn.add(Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _slideCtrl,
              curve: Interval(starts[i], ends[i], curve: Curves.easeOut))));
      _slideUp.add(Tween<Offset>(
              begin: const Offset(0, 0.12), end: Offset.zero)
          .animate(CurvedAnimation(parent: _slideCtrl,
              curve: Interval(starts[i], ends[i],
                  curve: Curves.easeOutCubic))));
    }
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _rippleCtrl.dispose();
    _sosRingCtrl.dispose();
    _blinkCtrl.dispose();
    _slideCtrl.dispose();
    _sosHoldCtrl.dispose();
    super.dispose();
  }

  // ── Stagger wrapper ───────────────────────────────────────────────
  Widget _anim(int i, Widget child) => SlideTransition(
        position: _slideUp[i],
        child: FadeTransition(opacity: _fadeIn[i], child: child),
      );

  // ── Actions ───────────────────────────────────────────────────────
  void _callEmergency() {
    HapticFeedback.heavyImpact();
    _snack('Connecting to emergency services (112)…', _red);
  }

  void _requestAmbulance() {
    HapticFeedback.mediumImpact();
    _snack('Ambulance dispatched — ETA ~8 min', _redLight);
  }

  void _shareLocation() {
    HapticFeedback.lightImpact();
    setState(() => _locationShared = true);
    _snack('Location shared with emergency contacts', _green);
  }

  void _navigate(String name) {
    HapticFeedback.selectionClick();
    _snack('Opening navigation to $name…', _blue);
  }

  void _videoCall()      { HapticFeedback.mediumImpact(); _snack('Connecting to on-call doctor…', _blue); }
  void _emergencyChat()  { HapticFeedback.mediumImpact(); _snack('Opening emergency chat…', _green); }
  void _editMedicalID()  { HapticFeedback.selectionClick(); _snack('Opening Medical ID editor…', _textMut); }

  void _triggerSOS() {
    HapticFeedback.heavyImpact();
    _snack('SOS activated! Calling 112 & alerting all contacts…', _red);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(color: Colors.white, fontSize: 13.5,
              fontWeight: FontWeight.w500)),
      backgroundColor: color,
      duration:        const Duration(seconds: 3),
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
    ));
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ── 1. Header ────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader()),

          // ── 2-8. Body sections ───────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Call Emergency
                _anim(0, _buildCallEmergencyBtn()),
                const SizedBox(height: 12),

                // Request Ambulance
                _anim(0, _buildAmbulanceBtn()),
                const SizedBox(height: 22),

                // Location
                _anim(1, _buildSectionLabel('Your location')),
                const SizedBox(height: 8),
                _anim(1, _buildLocationCard()),
                const SizedBox(height: 22),

                // Hospitals
                _anim(2, _buildSectionRow('Nearby hospitals', 'See all', () {})),
                const SizedBox(height: 8),
                _anim(2, _buildHospitalList()),
                const SizedBox(height: 22),

                // Support
                _anim(3, _buildSectionLabel('Immediate support')),
                const SizedBox(height: 8),
                _anim(3, _buildSupportGrid()),
                const SizedBox(height: 22),

                // Medical ID
                _anim(4, _buildSectionLabel('Medical ID')),
                const SizedBox(height: 8),
                _anim(4, _buildMedicalIDCard()),
                const SizedBox(height: 22),

                // SOS
                _anim(5, _buildSOSCard()),

              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  1. HEADER
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      color: _red,
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // accent circles
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 170, height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -70, left: -35,
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // top row: back | title + subtitle | avatar
                  Row(
                    children: [
                      // back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // title column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Emergency',
                                style: TextStyle(
                                  color:      Colors.white,
                                  fontSize:   20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                )),
                            const SizedBox(height: 3),
                            Row(children: [
                              // blink dot
                              AnimatedBuilder(
                                animation: _blinkAnim,
                                builder: (_, __) => Opacity(
                                  opacity: _blinkAnim.value,
                                  child: Container(
                                    width: 7, height: 7,
                                    decoration: const BoxDecoration(
                                        color: Color(0xFF4ADE80),
                                        shape: BoxShape.circle),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text('Active · GPS tracking on',
                                  style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12)),
                            ]),
                          ],
                        ),
                      ),

                      // profile avatar
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.25)),
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // stat chips row
                  Row(
                    children: [
                      _statChip('112',    'Emergency'),
                      const SizedBox(width: 8),
                      _statChip('~8 min', 'Ambulance ETA'),
                      const SizedBox(width: 8),
                      _statChip('3',      'Nearby hospitals'),
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

  Widget _statChip(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.22),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   15,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color:    Colors.white60, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  2. CALL EMERGENCY BUTTON  (ripple pulse)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildCallEmergencyBtn() {
    return _Pressable(
      onTap: _callEmergency,
      borderRadius: 20,
      child: Container(
        decoration: BoxDecoration(
          color:        _red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // animated ripple circle behind icon
            Positioned(
              left: 18,
              child: AnimatedBuilder(
                animation: _rippleCtrl,
                builder: (_, __) => Opacity(
                  opacity: _rippleOpacity.value,
                  child: Transform.scale(
                    scale: _rippleAnim.value,
                    child: Container(
                      width: 58, height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.18),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // icon tile
                  Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      color:        Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.phone_in_talk_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),

                  // text
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Call Emergency',
                            style: TextStyle(
                              color:      Colors.white,
                              fontSize:   21,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            )),
                        SizedBox(height: 4),
                        Text('Connects to 112 · 911 instantly',
                            style: TextStyle(
                                color:    Colors.white70,
                                fontSize: 12.5)),
                      ],
                    ),
                  ),

                  // arrow
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color:        Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  3. REQUEST AMBULANCE  (ETA badge)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildAmbulanceBtn() {
    return _Pressable(
      onTap: _requestAmbulance,
      borderRadius: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color:        _surface,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: _redLight, width: 1.5),
        ),
        child: Row(
          children: [
            // icon
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color:        _redLight.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.local_hospital_rounded,
                  color: _redLight, size: 26),
            ),
            const SizedBox(width: 14),

            // text
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Request Ambulance',
                      style: TextStyle(
                        color:      _textPri,
                        fontSize:   17,
                        fontWeight: FontWeight.w700,
                      )),
                  SizedBox(height: 3),
                  Text('Nearest unit dispatched to you',
                      style: TextStyle(
                          color: _textMut, fontSize: 12)),
                ],
              ),
            ),

            // ETA badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:  _redLight.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _redLight.withOpacity(0.30)),
              ),
              child: Column(
                children: const [
                  Text('8 min',
                      style: TextStyle(
                        color:      _redLight,
                        fontSize:   15,
                        fontWeight: FontWeight.w700,
                      )),
                  SizedBox(height: 1),
                  Text('ETA',
                      style: TextStyle(
                          color: _textSec, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  4. LOCATION CARD  (schematic map + address + share)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildLocationCard() {
    return Container(
      decoration: BoxDecoration(
        color:        _surface,
        borderRadius: BorderRadius.circular(18),
        border:       Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // schematic map strip
          SizedBox(
            height: 76,
            child: CustomPaint(
              painter: _MapGridPainter(),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // ring
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        shape:  BoxShape.circle,
                        border: Border.all(
                            color: _red.withOpacity(0.35), width: 2),
                      ),
                    ),
                    // pin dot
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color:  _red,
                        shape:  BoxShape.circle,
                        border: Border.all(
                            color: Colors.white, width: 3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // address row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                // live dot
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                      color: _greenL, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),

                // address
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nyerere Rd, Mwanza',
                          style: TextStyle(
                            color:      _textPri,
                            fontSize:   13.5,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        _locationShared
                            ? 'Location shared · tracking active'
                            : 'Location verified · sharing active',
                        style: const TextStyle(
                            color: _textMut, fontSize: 11),
                      ),
                    ],
                  ),
                ),

                // share button
                GestureDetector(
                  onTap: _shareLocation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color:        _green,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.share_rounded,
                            color: Colors.white, size: 14),
                        SizedBox(width: 5),
                        Text('Share',
                            style: TextStyle(
                              color:      Colors.white,
                              fontSize:   13,
                              fontWeight: FontWeight.w600,
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
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  5. HOSPITAL LIST
  // ═══════════════════════════════════════════════════════════════════
  static const List<_HospData> _hospitals = [
    _HospData('Bugando Medical Centre',  '1.2 km'),
    _HospData('Sekou Toure Hospital',    '2.7 km'),
    _HospData('Mwanza Referral Clinic',  '4.1 km'),
  ];

  Widget _buildHospitalList() {
    return Column(
      children: List.generate(_hospitals.length, (i) {
        final h      = _hospitals[i];
        final isTop  = i == 0;
        return Padding(
          padding: EdgeInsets.only(bottom: i < _hospitals.length - 1 ? 8 : 0),
          child: _Pressable(
            onTap: () => _navigate(h.name),
            borderRadius: 16,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              decoration: BoxDecoration(
                color:        _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isTop ? _card2 : _border),
              ),
              child: Row(
                children: [
                  // rank number
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: isTop
                          ? _redLight.withOpacity(0.15)
                          : _card2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                          style: TextStyle(
                            color:      isTop ? _redLight : _textSec,
                            fontSize:   13,
                            fontWeight: FontWeight.w700,
                          )),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.name,
                            style: const TextStyle(
                              color:      _textPri,
                              fontSize:   13.5,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.location_on_rounded,
                              color: _textMut, size: 12),
                          const SizedBox(width: 3),
                          Text(h.distance,
                              style: const TextStyle(
                                  color: _textMut, fontSize: 11.5)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Open 24 hrs',
                                style: TextStyle(
                                  color:      _greenL,
                                  fontSize:   10,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                        ]),
                      ],
                    ),
                  ),

                  // navigate button
                  GestureDetector(
                    onTap: () => _navigate(h.name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color:        _red,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.navigation_rounded,
                              color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Go',
                              style: TextStyle(
                                color:      Colors.white,
                                fontSize:   12.5,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  6. SUPPORT GRID
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSupportGrid() {
    return Row(
      children: [
        Expanded(child: _SupportCard(
          icon:    Icons.videocam_rounded,
          iconBg:  _blue.withOpacity(0.14),
          iconFg:  _blueL,
          label:   'Video Call',
          sub:     'Doctor in <2 min',
          onTap:   _videoCall,
        )),
        const SizedBox(width: 10),
        Expanded(child: _SupportCard(
          icon:    Icons.chat_bubble_rounded,
          iconBg:  _green.withOpacity(0.14),
          iconFg:  _greenL,
          label:   'Emergency Chat',
          sub:     'Text a medic now',
          onTap:   _emergencyChat,
        )),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  7. MEDICAL ID CARD
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildMedicalIDCard() {
    return Container(
      decoration: BoxDecoration(
        color:        _surface,
        borderRadius: BorderRadius.circular(18),
        border:       Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // header row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            child: Row(
              children: [
                const Icon(Icons.monitor_heart_rounded,
                    color: _redLight, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Quick medical profile',
                      style: TextStyle(
                        color:      _textPri,
                        fontSize:   14.5,
                        fontWeight: FontWeight.w600,
                      )),
                ),
                GestureDetector(
                  onTap: _editMedicalID,
                  child: Row(
                    children: const [
                      Icon(Icons.edit_outlined,
                          color: _textMut, size: 14),
                      SizedBox(width: 4),
                      Text('Edit',
                          style: TextStyle(
                              color: _textMut, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // divider
          Container(height: 0.5, color: _border2),

          // data cells
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(child: _MedCell('O+',         'Blood type')),
                Container(width: 0.5, color: _border2),
                Expanded(child: _MedCell('Penicillin', 'Allergy')),
                Container(width: 0.5, color: _border2),
                Expanded(child: _MedCell('Metformin',  'Medication')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  8. SOS CARD
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSOSCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color:        _surface,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: _border),
      ),
      child: Row(
        children: [
          // SOS button with ring
          GestureDetector(
            onLongPressStart:  (_) { setState(() => _sosHeld = true);  _sosHoldCtrl.forward(); },
            onLongPressEnd:    (_) { setState(() => _sosHeld = false); _sosHoldCtrl.reset();   },
            onLongPressCancel: ()  { setState(() => _sosHeld = false); _sosHoldCtrl.reset();   },
            child: SizedBox(
              width: 72, height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // outer pulse ring
                  AnimatedBuilder(
                    animation: _sosRingCtrl,
                    builder: (_, __) => Transform.scale(
                      scale:   _sosRingAnim.value,
                      child: Opacity(
                        opacity: _sosRingOpacity.value,
                        child: Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            shape:  BoxShape.circle,
                            border: Border.all(
                                color: _redLight.withOpacity(0.5),
                                width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // progress ring
                  if (_sosHeld)
                    SizedBox(
                      width: 68, height: 68,
                      child: CircularProgressIndicator(
                        value:       _sosProgress,
                        strokeWidth: 3.5,
                        color:       _redLight,
                        backgroundColor: _redLight.withOpacity(0.15),
                      ),
                    ),

                  // button circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width:  _sosHeld ? 54 : 60,
                    height: _sosHeld ? 54 : 60,
                    decoration: BoxDecoration(
                      color:  _red,
                      shape:  BoxShape.circle,
                      border: Border.all(color: _redLight, width: 2.5),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('SOS',
                            style: TextStyle(
                              color:         Colors.white,
                              fontSize:      17,
                              fontWeight:    FontWeight.w800,
                              letterSpacing: 1.0,
                            )),
                        SizedBox(height: 1),
                        Text('Hold 3s',
                            style: TextStyle(
                                color:    Colors.white54,
                                fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // description
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emergency SOS',
                    style: TextStyle(
                      color:      _textPri,
                      fontSize:   15,
                      fontWeight: FontWeight.w700,
                    )),
                SizedBox(height: 5),
                Text(
                  'Hold to call 112 and instantly\nalert all emergency contacts',
                  style: TextStyle(
                    color:      _textMut,
                    fontSize:   12,
                    height:     1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) => Text(
        label.toUpperCase(),
        style: const TextStyle(
          color:         _textHint,
          fontSize:      11,
          fontWeight:    FontWeight.w700,
          letterSpacing: 0.8,
        ),
      );

  Widget _buildSectionRow(
      String label, String link, VoidCallback onLink) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionLabel(label),
        GestureDetector(
          onTap: onLink,
          child: Text(link,
              style: const TextStyle(
                  color: _textMut, fontSize: 12.5)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CUSTOM PAINTER — schematic map grid
// ═══════════════════════════════════════════════════════════════════
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6B7280).withOpacity(0.18)
      ..strokeWidth = 1.0;

    for (final frac in [0.25, 0.5, 0.75]) {
      canvas.drawLine(
          Offset(0, size.height * frac),
          Offset(size.width, size.height * frac),
          paint);
      canvas.drawLine(
          Offset(size.width * frac, 0),
          Offset(size.width * frac, size.height),
          paint);
    }
  }
  @override
  bool shouldRepaint(_MapGridPainter _) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════

/// Press scale-down feedback wrapper.
class _Pressable extends StatefulWidget {
  final Widget      child;
  final VoidCallback onTap;
  final double      borderRadius;
  const _Pressable({
    required this.child,
    required this.onTap,
    this.borderRadius = 16,
  });
  @override
  State<_Pressable> createState() => _PressableState();
}
class _PressableState extends State<_Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 80),
        lowerBound: 0.96, upperBound: 1.0, value: 1.0);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _c.reverse(),
      onTapUp:     (_) { _c.forward(); widget.onTap(); },
      onTapCancel: ()  => _c.forward(),
      child: ScaleTransition(scale: _c, child: widget.child),
    );
  }
}

/// Video Call / Emergency Chat card.
class _SupportCard extends StatelessWidget {
  final IconData     icon;
  final Color        iconBg;
  final Color        iconFg;
  final String       label;
  final String       sub;
  final VoidCallback onTap;

  const _SupportCard({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  static const Color _surface = Color(0xFF161618);
  static const Color _border  = Color(0xFF222226);
  static const Color _textPri = Color(0xFFF3F4F6);
  static const Color _textMut = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color:        _surface,
          borderRadius: BorderRadius.circular(18),
          border:       Border.all(color: _border),
        ),
        child: Column(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: iconFg, size: 24),
            ),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color:      _textPri,
                  fontSize:   13.5,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 3),
            Text(sub,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _textMut, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}

/// One cell in the Medical ID grid.
class _MedCell extends StatelessWidget {
  final String value;
  final String label;
  const _MedCell(this.value, this.label);

  static const Color _redLight = Color(0xFFEF4444);
  static const Color _textMut  = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                color:      _redLight,
                fontSize:   16,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _textMut, fontSize: 10.5)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════════════════════════════
@immutable
class _HospData {
  final String name;
  final String distance;
  const _HospData(this.name, this.distance);
}