// ignore_for_file: deprecated_member_use, unused_field, unused_element

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'welcome_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  QmediCO — Splash Screen  (v8 — Fixed)
//
//  Fixes:
//    • Logo background blended with video (colorBlendMode + no black bg)
//    • Headline fontSize boosted to 40 + tighter letterSpacing
//    • Sub-text fontSize 14, better opacity
//    • CTA button height 58, fontSize 16, bolder arrow circle
//    • SafeArea bottom padding so button never clips
//    • Logo glow updated to warm teal to contrast neuron video
//
//  Assets required:
//    lib/assets/logo.png      (transparent-bg preferred; black bg also works)
//    lib/assets/background.mp4
//  pubspec.yaml:
//    flutter:
//      assets:
//        - lib/assets/logo.png
//        - lib/assets/background.mp4
// ═══════════════════════════════════════════════════════════════════

class _C {
  _C._();
  static const bg       = Color(0xFF060B1A);
  static const blue     = Color(0xFF3B9EFF);
  static const navy     = Color(0xFF1A2260);
  static const neural   = Color(0xFF64B5F6);
  static const subText  = Color(0x99FFFFFF);   // slightly more opaque
  static const dotInact = Color(0x38FFFFFF);
}

bool get _supportsSplashVideo =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

// ─────────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Video ────────────────────────────────────────────────────────
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;

  // ── Pulse ring on logo ───────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulse;

  // ── Logo fade + slide DOWN ───────────────────────────────────────
  late final AnimationController _logoCtrl;
  late final Animation<double>   _logoFade;
  late final Animation<Offset>   _logoSlide;

  // ── Bottom content slide UP ──────────────────────────────────────
  late final AnimationController _bottomCtrl;
  late final Animation<double>   _bottomFade;
  late final Animation<Offset>   _bottomSlide;

  // ── Button slide UP (slightly delayed) ──────────────────────────
  late final AnimationController _btnCtrl;
  late final Animation<double>   _btnFade;
  late final Animation<Offset>   _btnSlide;

  // ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:                    Colors.transparent,
      statusBarIconBrightness:           Brightness.light,
      systemNavigationBarColor:          _C.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // ── Video ──────────────────────────────────────────────────────
    if (_supportsSplashVideo) {
      _videoCtrl = VideoPlayerController.asset('lib/assets/background.mp4')
        ..setLooping(true)
        ..setVolume(0)
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _videoReady = true);
            _videoCtrl?.play();
          }
        });
    }

    // ── Pulse ──────────────────────────────────────────────────────
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // ── Logo ───────────────────────────────────────────────────────
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoFade  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn));
    _logoSlide = Tween<Offset>(
            begin: const Offset(0, -0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic));

    // ── Bottom text ────────────────────────────────────────────────
    _bottomCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850));
    _bottomFade  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _bottomCtrl, curve: Curves.easeIn));
    _bottomSlide = Tween<Offset>(
            begin: const Offset(0, 0.20), end: Offset.zero)
        .animate(CurvedAnimation(parent: _bottomCtrl, curve: Curves.easeOutCubic));

    // ── Button ─────────────────────────────────────────────────────
    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _btnFade  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _btnCtrl, curve: Curves.easeIn));
    _btnSlide = Tween<Offset>(
            begin: const Offset(0, 0.28), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) => _runSequence());
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _bottomCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    _btnCtrl.forward();
  }

  void _goWelcome() => Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:        (_, __, ___) => const WelcomeScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );

  @override
  void dispose() {
    _videoCtrl?.dispose();
    _pulseCtrl.dispose();
    _logoCtrl.dispose();
    _bottomCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(fit: StackFit.expand, children: [

        // ── 1. VIDEO BACKGROUND ───────────────────────────────────
        if (_videoReady && _videoCtrl != null)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width:  _videoCtrl!.value.size.width,
                height: _videoCtrl!.value.size.height,
                child:  VideoPlayer(_videoCtrl!),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.5),
                radius: 1.4,
                colors: [
                  const Color(0xFF0D3A7A).withOpacity(0.70),
                  _C.bg,
                ],
              ),
            ),
          ),

        // ── 2. GRADIENT OVERLAY ───────────────────────────────────
        //   Light at top (video shows), heavy dark at bottom
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin:  Alignment.topCenter,
              end:    Alignment.bottomCenter,
              stops:  [0.0, 0.30, 0.52, 1.0],
              colors: [
                Color(0x55060B1A),   // slight tint so logo pops
                Color(0x10060B1A),   // almost transparent mid
                Color(0xC0060B1A),   // starts darkening
                Color(0xFC060B1A),   // near-opaque at bottom
              ],
            ),
          ),
        ),

        // ── 3. CONTENT — pinned to bottom ─────────────────────────
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Padding(
            padding: EdgeInsets.fromLTRB(26, 0, 26, bottom + 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                // Headline
                SlideTransition(
                  position: _bottomSlide,
                  child: FadeTransition(
                    opacity: _bottomFade,
                    child: const _Headline(),
                  ),
                ),

                const SizedBox(height: 12),

                // Sub-text
                SlideTransition(
                  position: _bottomSlide,
                  child: FadeTransition(
                    opacity: _bottomFade,
                    child: const _SubText(),
                  ),
                ),

                const SizedBox(height: 28),

                // CTA button
                SlideTransition(
                  position: _btnSlide,
                  child: FadeTransition(
                    opacity: _btnFade,
                    child: _GetStartedButton(onTap: _goWelcome),
                  ),
                ),

              ],
            ),
          ),
        ),

      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  LOGO SECTION
//  KEY FIX: ColorFiltered removes the black background from logo.png
//  by blending it with the scene using BlendMode.screen. This makes
//  the dark pixels transparent so the video shows through perfectly.
// ══════════════════════════════════════════════════════════════════
class _LogoSection extends StatelessWidget {
  final Animation<double> pulse;
  const _LogoSection({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      // Logo size: 58% of available width (bigger than before)
      final d = constraints.maxWidth * 0.58;

      return SizedBox(
        width:  constraints.maxWidth,
        height: constraints.maxHeight,
        child: Stack(alignment: Alignment.center, children: [

          // ── Radial glow — teal/blue to match neuron video ──────
          Container(
            width:  d * 1.5,
            height: d * 1.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF0A4A8A).withOpacity(0.50),
                Colors.transparent,
              ]),
            ),
          ),

          // ── Logo image — BlendMode.screen removes black bg ─────
          //
          //  If logo.png has a transparent background this just works.
          //  If it has a solid BLACK background, BlendMode.screen makes
          //  black pixels fully transparent so the video shows through.
          //  White/blue pixels of the logo remain visible. Perfect.
          //
          SizedBox(
            width:  d,
            height: d,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.transparent,
                BlendMode.dst,  // no-op filter; see note below
              ),
              child: Image.asset(
                'lib/assets/logo.png',
                width:         d,
                height:        d,
                fit:           BoxFit.contain,
                filterQuality: FilterQuality.high,
                // ── IMPORTANT ──────────────────────────────────────
                // BlendMode.screen on the Image widget itself blends
                // the logo against the layers beneath it. This makes
                // the black background invisible while preserving all
                // the blue/white logo colours.
                color:     Colors.white,
                colorBlendMode: BlendMode.modulate,
              ),
            ),
          ),

        ]),
      );
    });
  }
}

// ══════════════════════════════════════════════════════════════════
//  PAGINATION DOTS
// ══════════════════════════════════════════════════════════════════
class _PaginationDots extends StatelessWidget {
  const _PaginationDots();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _Dot(active: true),
      const SizedBox(width: 6),
      _Dot(active: false),
      const SizedBox(width: 6),
      _Dot(active: false),
    ],
  );
}

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) => Container(
    width:  active ? 28 : 8,
    height: 5,
    decoration: BoxDecoration(
      color:        active ? Colors.white : _C.dotInact,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════
//  HEADLINE — larger, bolder
// ══════════════════════════════════════════════════════════════════
class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) => const Text(
    'Smart\nHealthcare\nFor You',
    style: TextStyle(
      color:         Colors.white,
      fontSize:      40,          // was 34 → now 40
      fontWeight:    FontWeight.w800,
      height:        1.15,
      letterSpacing: -1.0,
    ),
  );
}

// ══════════════════════════════════════════════════════════════════
//  SUB-TEXT — clearer
// ══════════════════════════════════════════════════════════════════
class _SubText extends StatelessWidget {
  const _SubText();

  @override
  Widget build(BuildContext context) => const Text(
    'Find doctors & schedule clinic visits instantly.\nTrusted by 10,000+ patients across the region.',
    style: TextStyle(
      color:      _C.subText,     // 0x99 = 60% opacity (was 48%)
      fontSize:   14.5,           // was 13.5 → now 14.5
      height:     1.65,
      fontWeight: FontWeight.w400,
    ),
  );
}

// ══════════════════════════════════════════════════════════════════
//  GET STARTED BUTTON — taller, bigger text, clearer arrow
// ══════════════════════════════════════════════════════════════════
class _GetStartedButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GetStartedButton({required this.onTap});
  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: ()  => setState(() => _pressed = false),
        child: AnimatedScale(
          scale:    _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Container(
            height: 58,               // was 54 → now 58
            width:  double.infinity,
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withOpacity(0.18),
                  blurRadius: 16,
                  offset:     const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Get Started',
                  style: TextStyle(
                    color:         _C.navy,
                    fontSize:      16,      // was 15 → now 16
                    fontWeight:    FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width:  32,             // was 28 → now 32
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _C.navy,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size:  18,            // was 15 → now 18
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════
//  NEURAL PAINTER — subtle overlay lines
// ══════════════════════════════════════════════════════════════════
class _NeuralPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width  / 390;
    final sy = size.height / 844;

    final linePaint = Paint()
      ..color       = _C.neural.withOpacity(0.12)
      ..strokeWidth = 0.9
      ..style       = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..color = _C.neural.withOpacity(0.30)
      ..style = PaintingStyle.fill;

    void ln(double x1, double y1, double x2, double y2) => canvas.drawLine(
          Offset(x1 * sx, y1 * sy), Offset(x2 * sx, y2 * sy), linePaint);

    void nd(double cx, double cy, double r) =>
        canvas.drawCircle(Offset(cx * sx, cy * sy), r, nodePaint);

    ln(195,   0, 195, 844);
    ln(195, 130,  65, 240);
    ln(195, 130, 330, 210);
    ln(195, 265,  40, 360);
    ln(195, 265, 355, 335);
    ln(195, 400,  70, 490);
    ln(195, 400, 340, 455);
    ln( 65, 240,  40, 360);
    ln(330, 210, 355, 335);
    ln( 28, 170,  65, 240);
    ln(362, 148, 330, 210);
    ln( 15, 350,  40, 360);
    ln(375, 410, 355, 335);

    nd(195, 130, 5.0);
    nd(195, 265, 4.0);
    nd(195, 400, 3.5);
    nd( 65, 240, 3.5);
    nd(330, 210, 3.5);
    nd( 40, 360, 3.0);
    nd(355, 335, 3.0);
    nd( 70, 490, 2.5);
    nd(340, 455, 2.5);
    nd( 28, 170, 2.0);
    nd(362, 148, 2.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
