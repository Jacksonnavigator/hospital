// ignore_for_file: deprecated_member_use, unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'register_screen.dart';
import 'login_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  ClinicBook — Welcome / Splash Screen
//  File: lib/screens/welcome_screen.dart
//
//  Layout: Brain image top ~60% · frosted glass bottom panel with
//          title, subtitle, SIGN UP button, and "or Log in" link
//  ────────────────────────────────────────────────────────────────
//  Reference design: "Sign in for Fitness Success" splash layout
//  Background image: lib/assets/registerlogin.jpg  (brain photo)
// ═══════════════════════════════════════════════════════════════════

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  // ── Brand colours ───────────────────────────────────────────────
  static const _accentBlue   = Color(0xFF2D6BC4);
  static const _accentGlow   = Color(0xFF4EA8DE);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _goRegister() => Navigator.of(context).push(PageRouteBuilder(
        pageBuilder:        (_, __, ___) => const RegisterScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ));

  void _goLogin() => Navigator.of(context).push(PageRouteBuilder(
        pageBuilder:        (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(
        children: [

          // ── Brain photo — fills top ~65 % of screen ───────────
          Positioned(
            top:    0,
            left:   0,
            right:  0,
            height: size.height * 0.65,
            child: Image.asset(
              'lib/assets/registerlogin.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ── Subtle dark vignette over the photo ───────────────
          Positioned(
            top:    0,
            left:   0,
            right:  0,
            height: size.height * 0.65,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin:  Alignment.topCenter,
                  end:    Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    const Color(0xFF0A1628).withOpacity(0.6),
                    const Color(0xFF0A1628),
                  ],
                  stops: const [0.0, 0.55, 0.82, 1.0],
                ),
              ),
            ),
          ),

          // ── Small drag indicator at the very top of the panel ─
          // (matches the white pill in the reference design)

          // ── Bottom frosted-glass panel ────────────────────────
          Positioned(
            left:   0,
            right:  0,
            bottom: 0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1E3A).withOpacity(0.92),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: _accentGlow.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    28,
                    20,
                    28,
                    MediaQuery.of(context).padding.bottom + 36,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize:       MainAxisSize.min,
                    children: [

                      // ── Drag pill ──
                      Center(
                        child: Container(
                          width:  44,
                          height: 4,
                          decoration: BoxDecoration(
                            color:        Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ── Headline ──
                      const Text(
                        'Sign in for\nClinical Success',
                        style: TextStyle(
                          color:      Colors.white,
                          fontSize:   30,
                          fontWeight: FontWeight.w800,
                          height:     1.18,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Subtitle ──
                      Text(
                        'Fuel your health journey with our\ndynamic app designed for a\nhealthier lifestyle',
                        style: TextStyle(
                          color:      Colors.white.withOpacity(0.60),
                          fontSize:   14,
                          fontWeight: FontWeight.w400,
                          height:     1.55,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ── SIGN UP button + "or Log in" row ──────
                      Row(
                        children: [

                          // SIGN UP pill button
                          Expanded(
                            child: _SignUpButton(onTap: _goRegister),
                          ),

                          const SizedBox(width: 20),

                          // "or Log in" text button
                          GestureDetector(
                            onTap: _goLogin,
                            child: Text(
                              'or Log in',
                              style: TextStyle(
                                color:      Colors.white.withOpacity(0.70),
                                fontSize:   15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

// ──────────────────────────────────────────────────────────────────
//  SIGN UP  — dark pill with arrow  (mirrors reference design)
// ──────────────────────────────────────────────────────────────────
class _SignUpButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SignUpButton({required this.onTap});

  @override
  State<_SignUpButton> createState() => _SignUpButtonState();
}

class _SignUpButtonState extends State<_SignUpButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown:   (_) => setState(() => _down = true),
        onTapUp:     (_) { setState(() => _down = false); widget.onTap(); },
        onTapCancel: ()  => setState(() => _down = false),
        child: AnimatedScale(
          scale:    _down ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withOpacity(0.25),
                  blurRadius: 14,
                  offset:     const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'SIGN UP',
                  style: TextStyle(
                    color:         Color(0xFF0A1628),
                    fontSize:      14,
                    fontWeight:    FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width:  32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A1628),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size:  18,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
