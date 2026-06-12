// ignore_for_file: deprecated_member_use, unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'register_screen.dart';
import '../services/session_service.dart';
import 'role_router.dart';

// ═══════════════════════════════════════════════════════════════════
//  ClinicBook — Login Screen  (dark theme, matches welcome screen)
//  File: lib/screens/login_screen.dart
// ═══════════════════════════════════════════════════════════════════

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  bool _obscure   = true;
  bool _isLoading = false;

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  static const _navy    = Color(0xFF0A1628);
  static const _panel   = Color(0xFF0D1E3A);
  static const _accent  = Color(0xFF4EA8DE);
  static const _fieldBg = Color(0xFF152035);
  static const _border  = Color(0xFF1E3050);
  static const _hint    = Color(0xFF5A7A9A);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _fadeAnim  = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = await SessionService.instance.login(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
      if (!mounted) return;
      RoleRouter.go(context, user);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goRegister() => Navigator.of(context).pushReplacement(PageRouteBuilder(
    pageBuilder:        (_, __, ___) => const RegisterScreen(),
    transitionsBuilder: (_, a, __, child) =>
        FadeTransition(opacity: a, child: child),
    transitionDuration: const Duration(milliseconds: 350),
  ));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _navy,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [

          // ── Brain background image ─────────────────────────────
          SizedBox.expand(
            child: Image.asset(
              'lib/assets/registerlogin.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ── Deep navy gradient overlay ─────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin:  Alignment.topCenter,
                end:    Alignment.bottomCenter,
                colors: [
                  Color(0xBB0A1628),
                  Color(0xF00A1628),
                ],
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: size.height),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const SizedBox(height: 24),

                          // ── Back button ───────────────────────
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color:        Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── Headline ──────────────────────────
                          const Text(
                            'Welcome\nBack',
                            style: TextStyle(
                              color:         Colors.white,
                              fontSize:      36,
                              fontWeight:    FontWeight.w800,
                              height:        1.15,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Sign in to your clinic account',
                            style: TextStyle(
                              color:    Colors.white.withOpacity(0.45),
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── Dark frosted card ─────────────────
                          Container(
                            decoration: BoxDecoration(
                              color: _panel.withOpacity(0.88),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _accent.withOpacity(0.15),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:      Colors.black.withOpacity(0.40),
                                  blurRadius: 32,
                                  offset:     const Offset(0, 12),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  // Email
                                  _DarkField(
                                    controller:   _emailCtrl,
                                    hint:         'Email address',
                                    icon:         Icons.mail_outline_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Enter your email';
                                      if (!v.contains('@'))
                                        return 'Enter a valid email';
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 14),

                                  // Password
                                  _DarkField(
                                    controller: _passCtrl,
                                    hint:       'Password',
                                    icon:       Icons.lock_outline_rounded,
                                    obscure:    _obscure,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: _hint,
                                        size:  20,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Enter your password';
                                      if (v.length < 6)
                                        return 'Min 6 characters';
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 10),

                                  // Forgot password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () {},
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color:      _accent,
                                          fontSize:   13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 22),

                                  // Login button
                                  _GlowButton(
                                    label:     'Login',
                                    isLoading: _isLoading,
                                    onTap:     _login,
                                  ),

                                  const SizedBox(height: 22),

                                  // Divider
                                  Row(children: [
                                    Expanded(child: Divider(
                                        color: Colors.white.withOpacity(0.10))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                      child: Text('or',
                                          style: TextStyle(
                                            color:    Colors.white.withOpacity(0.30),
                                            fontSize: 13,
                                          )),
                                    ),
                                    Expanded(child: Divider(
                                        color: Colors.white.withOpacity(0.10))),
                                  ]),

                                  const SizedBox(height: 16),

                                  // Google
                                  _DarkSocialButton(
                                    label:      'Sign In with Google',
                                    iconWidget: const _GoogleIcon(),
                                    onTap:      () {},
                                  ),


                                  const SizedBox(height: 22),

                                  // Register link
                                  Center(
                                    child: GestureDetector(
                                      onTap: _goRegister,
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white.withOpacity(0.40),
                                          ),
                                          children: [
                                            const TextSpan(
                                                text: "Don't have an account?  "),
                                            const TextSpan(
                                              text: 'Register',
                                              style: TextStyle(
                                                color:      _accent,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
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
//  DARK INPUT FIELD
// ──────────────────────────────────────────────────────────────────
class _DarkField extends StatelessWidget {
  final TextEditingController      controller;
  final String                     hint;
  final IconData                   icon;
  final bool                       obscure;
  final Widget?                    suffixIcon;
  final TextInputType?             keyboardType;
  final String? Function(String?)? validator;

  const _DarkField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure      = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  static const _fieldBg = Color(0xFF152035);
  static const _border  = Color(0xFF1E3050);
  static const _hint    = Color(0xFF5A7A9A);
  static const _accent  = Color(0xFF4EA8DE);

  @override
  Widget build(BuildContext context) => TextFormField(
    controller:   controller,
    obscureText:  obscure,
    keyboardType: keyboardType,
    validator:    validator,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      filled:      true,
      fillColor:   _fieldBg,
      hintText:    hint,
      hintStyle:   const TextStyle(color: _hint, fontSize: 14),
      prefixIcon:  Icon(icon, color: _hint, size: 20),
      suffixIcon:  suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   const BorderSide(color: _border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   const BorderSide(color: _border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   const BorderSide(color: _accent, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}

// ──────────────────────────────────────────────────────────────────
//  GLOWING PRIMARY BUTTON
// ──────────────────────────────────────────────────────────────────
class _GlowButton extends StatefulWidget {
  final String       label;
  final bool         isLoading;
  final VoidCallback onTap;
  const _GlowButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });
  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => setState(() => _down = true),
    onTapUp:     (_) { setState(() => _down = false); widget.onTap(); },
    onTapCancel: ()  => setState(() => _down = false),
    child: AnimatedScale(
      scale:    _down ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: Container(
        height: 54,
        width:  double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4EA8DE), Color(0xFF2D6BC4)],
            begin:  Alignment.centerLeft,
            end:    Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color:      const Color(0xFF4EA8DE)
                  .withOpacity(_down ? 0.15 : 0.40),
              blurRadius: 22,
              offset:     const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Text(
                  widget.label,
                  style: const TextStyle(
                    color:         Colors.white,
                    fontSize:      16,
                    fontWeight:    FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    ),
  );
}

// ──────────────────────────────────────────────────────────────────
//  DARK SOCIAL BUTTON
// ──────────────────────────────────────────────────────────────────
class _DarkSocialButton extends StatefulWidget {
  final String       label;
  final Widget       iconWidget;
  final VoidCallback onTap;
  const _DarkSocialButton({
    required this.label,
    required this.iconWidget,
    required this.onTap,
  });
  @override
  State<_DarkSocialButton> createState() => _DarkSocialButtonState();
}

class _DarkSocialButtonState extends State<_DarkSocialButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => setState(() => _down = true),
    onTapUp:     (_) { setState(() => _down = false); widget.onTap(); },
    onTapCancel: ()  => setState(() => _down = false),
    child: AnimatedScale(
      scale:    _down ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: Container(
        height: 50,
        width:  double.infinity,
        decoration: BoxDecoration(
          color:        const Color(0xFF152035),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E3050), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.iconWidget,
            const SizedBox(width: 12),
            Text(widget.label,
              style: const TextStyle(
                color:      Colors.white,
                fontSize:   14,
                fontWeight: FontWeight.w600,
              )),
          ],
        ),
      ),
    ),
  );
}

// ──────────────────────────────────────────────────────────────────
//  GOOGLE ICON
// ──────────────────────────────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 24, height: 24,
    child: CustomPaint(painter: _GooglePainter()),
  );
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Scale factor – the path was designed on a 24×24 grid
    final double sx = w / 24.0;
    final double sy = h / 24.0;

    void drawPath(Path path, Color color) {
      canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
    }

    // ── Blue: top arc of the "G" ring ──────────────────────────────
    final Path blue = Path();
    blue.moveTo(21.805 * sx, 10.023 * sy);
    blue.lineTo(12.000 * sx, 10.023 * sy);
    blue.lineTo(12.000 * sx, 13.977 * sy);
    blue.lineTo(17.606 * sx, 13.977 * sy);
    blue.cubicTo(17.235 * sx, 15.658 * sy, 16.218 * sx, 17.043 * sy, 14.741 * sx, 17.966 * sy);
    blue.lineTo(17.691 * sx, 20.625 * sy);
    blue.cubicTo(19.875 * sx, 18.618 * sy, 21.21  * sx, 15.685 * sy, 21.21  * sx, 12.000 * sy);
    blue.cubicTo(21.21  * sx, 11.329 * sy, 21.138 * sx, 10.668 * sy, 21.000 * sx, 10.023 * sy);
    blue.close();
    drawPath(blue, const Color(0xFF4285F4));

    // ── Green: bottom-right ─────────────────────────────────────────
    final Path green = Path();
    green.moveTo(12.000 * sx, 22.000 * sy);
    green.cubicTo(14.919 * sx, 22.000 * sy, 17.380 * sx, 21.015 * sy, 19.157 * sx, 19.327 * sy);
    green.lineTo(16.207 * sx, 16.668 * sy);
    green.cubicTo(15.165 * sx, 17.364 * sy, 13.780 * sx, 17.773 * sy, 12.000 * sx, 17.773 * sy);
    green.cubicTo(9.179  * sx, 17.773 * sy, 6.794  * sx, 15.807 * sy, 5.965  * sx, 13.133 * sy);
    green.lineTo(2.923  * sx, 15.848 * sy);
    green.cubicTo(4.680  * sx, 19.360 * sy, 8.084  * sx, 22.000 * sy, 12.000 * sx, 22.000 * sy);
    green.close();
    drawPath(green, const Color(0xFF34A853));

    // ── Yellow: bottom-left ─────────────────────────────────────────
    final Path yellow = Path();
    yellow.moveTo(5.965 * sx, 13.133 * sy);
    yellow.cubicTo(5.745 * sx, 12.494 * sy, 5.625 * sx, 11.811 * sy, 5.625 * sx, 11.109 * sy);
    yellow.cubicTo(5.625 * sx, 10.407 * sy, 5.745 * sx,  9.724 * sy, 5.965 * sx,  9.085 * sy);
    yellow.lineTo(2.923 * sx,  6.370 * sy);
    yellow.cubicTo(2.115 * sx,  7.937 * sy, 1.655 * sx,  9.672 * sy, 1.655 * sx, 11.109 * sy);
    yellow.cubicTo(1.655 * sx, 12.546 * sy, 2.115 * sx, 14.281 * sy, 2.923 * sx, 15.848 * sy);
    yellow.close();
    drawPath(yellow, const Color(0xFFFBBC05));

    // ── Red: top-left ───────────────────────────────────────────────
    final Path red = Path();
    red.moveTo(12.000 * sx,  5.227 * sy);
    red.cubicTo(13.908 * sx,  5.227 * sy, 15.628 * sx,  5.892 * sy, 16.980 * sx,  7.140 * sy);
    red.lineTo(19.248 * sx,  4.908 * sy);
    red.cubicTo(17.373 * sx,  3.168 * sy, 14.912 * sx,  2.000 * sy, 12.000 * sx,  2.000 * sy);
    red.cubicTo( 8.084 * sx,  2.000 * sy,  4.680 * sx,  4.640 * sy,  2.923 * sx,  8.152 * sy);
    red.lineTo( 5.965 * sx,  9.085 * sy);
    red.cubicTo( 6.794 * sx,  7.211 * sy,  9.179 * sx,  5.227 * sy, 12.000 * sx,  5.227 * sy);
    red.close();
    drawPath(red, const Color(0xFFEA4335));
  }

  @override
  bool shouldRepaint(_GooglePainter old) => false;
}
