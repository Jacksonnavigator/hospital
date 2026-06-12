import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════
//  ProfileScreen — Healthcare Profile (Premium Redesign)
//  File: lib/screens/profile_screen.dart
//
//  Design improvements:
//   • Modern gradient header with glassmorphism effects
//   • Larger, more prominent avatar with premium styling
//   • Enhanced typography system with better hierarchy
//   • Card elevation and smooth shadows for depth
//   • Improved spacing system (8px grid basis)
//   • Larger touch targets for better UX
//   • Modern stat cards with hover animations
//   • Enhanced toggle switches with custom styling
//   • Smooth entrance animations with staggered children
//   • Better color palette with healthcare theme
// ═══════════════════════════════════════════════════════════════════

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // ── Premium Color Palette — matched to Appointments screen ──────
  static const Color _primaryColor = Color(0xFF1A3A5C);   // dark navy (tab/button colour)
  static const Color _primaryDark  = Color(0xFF0F2540);   // deeper navy
  static const Color _secondaryColor = Color(0xFF2E6DA4); // mid-blue accent
  static const Color _successColor = Color(0xFF4CAF50);
  static const Color _warningColor = Color(0xFFFFA726);
  static const Color _errorColor = Color(0xFFEF5350);
  static const Color _textPrimary = Color(0xFF1A2B3C);
  static const Color _textSecondary = Color(0xFF6B7A8A);
  static const Color _textTertiary = Color(0xFF9AA6B5);
  static const Color _surfaceColor = Color(0xFFEBF0F8);   // light blue-grey page bg
  static const Color _cardBg = Colors.white;
  static const Color _borderLight = Color(0xFFDDE5F0);

  // Gradient colors — mirrors the appointment header navy gradient
  static const LinearGradient _headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E5799), // medium navy-blue
      Color(0xFF1A3A5C), // dark navy
      Color(0xFF0F2540), // deepest navy
    ],
  );

  static const LinearGradient _statCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white,
      Color(0xFFF0F4FB),
    ],
  );

  // ── Dummy user data ──────────────────────────────────────────────
  final String _userName = 'John Mwangi';
  final String _userEmail = 'john.mwangi@email.com';
  final String _userPhone = '+255 712 345 678';
  final String _userDOB = '14 March 1990';
  final String _userCity = 'Arusha, Tanzania';
  final String _bloodGroup = 'O+';
  final String _memberSince = 'Jan 2024';
  final String _userTitle = 'Premium Member';
  final int _appointmentsCount = 12;
  final double _rating = 4.8;

  // ── Toggle states ─────────────────────────────────────────────────
  bool _notificationsOn = true;
  bool _remindersOn = true;
  bool _darkMode = false;

  // ── Animation ─────────────────────────────────────────────────────
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late List<Animation<double>> _staggeredAnimations;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    );
    
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    ));
    
    // Staggered animations for children
    _staggeredAnimations = List.generate(8, (index) {
      return CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(
          index * 0.05,
          1.0,
          curve: Curves.easeOutCubic,
        ),
      );
    });
    
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String get _initials {
    final parts = _userName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0].substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _surfaceColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _buildPremiumHeader()),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _staggeredAnimations[0],
                  child: _buildModernStatCards(),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _staggeredAnimations[1],
                  child: _buildSectionHeader('Patient Information', Icons.person_outline),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _staggeredAnimations[2],
                  child: _buildPatientInfoCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _staggeredAnimations[3],
                  child: _buildSectionHeader('Settings', Icons.settings_outlined),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _staggeredAnimations[4],
                  child: _buildSettingsCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _staggeredAnimations[5],
                  child: _buildSectionHeader('Quick Actions', Icons.flash_on_outlined),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _staggeredAnimations[6],
                  child: _buildQuickActionsGrid(),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _staggeredAnimations[7],
                  child: _buildModernLogoutButton(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  PREMIUM HEADER with Glassmorphism
  // ─────────────────────────────────────────────
  Widget _buildPremiumHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: _headerGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Decorative background elements
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar with edit button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildPremiumEditButton(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Premium avatar and info row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPremiumAvatar(),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _userTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _userEmail,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildMemberBadge(),
                          ],
                        ),
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

  Widget _buildPremiumAvatar() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFE3F2FD)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryColor, _primaryDark],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _successColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumEditButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.edit_outlined,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildMemberBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 6),
          Text(
            'Member since $_memberSince',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  MODERN STAT CARDS with Animations
  // ─────────────────────────────────────────────
  Widget _buildModernStatCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          _buildAnimatedStatCard(
            icon: Icons.water_drop_outlined,
            value: _bloodGroup,
            label: 'Blood Group',
            color: const Color(0xFFE53935),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEF5350), Color(0xFFE53935)],
            ),
          ),
          const SizedBox(width: 12),
          _buildAnimatedStatCard(
            icon: Icons.calendar_today_outlined,
            value: '$_appointmentsCount',
            label: 'Appointments',
            color: _primaryColor,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E5799), Color(0xFF1A3A5C)],
            ),
          ),
          const SizedBox(width: 12),
          _buildAnimatedStatCard(
            icon: Icons.star_outline_rounded,
            value: '$_rating',
            label: 'Rating',
            color: _warningColor,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFA726), Color(0xFFFB8C00)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Gradient gradient,
  }) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 400),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            gradient: _statCardGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  SECTION HEADER with better typography
  // ─────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  PATIENT INFORMATION CARD
  // ─────────────────────────────────────────────
  Widget _buildPatientInfoCard() {
    final infoItems = [
      _InfoItem(
        icon: Icons.phone_outlined,
        label: 'Phone Number',
        value: _userPhone,
      ),
      _InfoItem(
        icon: Icons.cake_outlined,
        label: 'Date of Birth',
        value: _userDOB,
      ),
      _InfoItem(
        icon: Icons.location_on_outlined,
        label: 'Location',
        value: _userCity,
        isLast: true,
      ),
    ];

    return _buildPremiumCard(
      children: infoItems.map((item) => _buildInfoRow(item)).toList(),
    );
  }

  Widget _buildInfoRow(_InfoItem item) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: _primaryColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.copy_outlined,
                size: 18,
                color: _textTertiary,
              ),
            ],
          ),
        ),
        if (!item.isLast)
          Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
            color: _borderLight,
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  SETTINGS CARD with Custom Switches
  // ─────────────────────────────────────────────
  Widget _buildSettingsCard() {
    final settings = [
      _SettingItem(
        icon: Icons.notifications_outlined,
        label: 'Notifications',
        value: _notificationsOn,
        onChanged: (v) => setState(() => _notificationsOn = v),
      ),
      _SettingItem(
        icon: Icons.access_time_outlined,
        label: 'Appointment Reminders',
        value: _remindersOn,
        onChanged: (v) => setState(() => _remindersOn = v),
      ),
      _SettingItem(
        icon: Icons.dark_mode_outlined,
        label: 'Dark Mode',
        value: _darkMode,
        onChanged: (v) => setState(() => _darkMode = v),
        isLast: true,
      ),
    ];

    return _buildPremiumCard(
      children: settings.map((item) => _buildSettingRow(item)).toList(),
    );
  }

  Widget _buildSettingRow(_SettingItem item) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: _primaryColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: item.value,
                  onChanged: item.onChanged,
                  activeColor: _primaryColor,
                  activeTrackColor: _primaryColor.withOpacity(0.4),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: _borderLight,
                ),
              ),
            ],
          ),
        ),
        if (!item.isLast)
          Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
            color: _borderLight,
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  QUICK ACTIONS GRID (Modern Layout)
  // ─────────────────────────────────────────────
  Widget _buildQuickActionsGrid() {
    final actions = [
      _QuickAction(
        icon: Icons.favorite_border_rounded,
        label: 'Medical History',
        color: const Color(0xFFEF5350),
      ),
      _QuickAction(
        icon: Icons.file_download_outlined,
        label: 'Download Records',
        color: const Color(0xFF42A5F5),
      ),
      _QuickAction(
        icon: Icons.headset_mic_outlined,
        label: 'Help & Support',
        color: const Color(0xFF66BB6A),
      ),
      _QuickAction(
        icon: Icons.shield_outlined,
        label: 'Privacy Policy',
        color: const Color(0xFFFFA726),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return _buildQuickActionCard(action);
        },
      ),
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(action.icon, color: action.color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              action.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  MODERN LOGOUT BUTTON
  // ─────────────────────────────────────────────
  Widget _buildModernLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Material(
        elevation: 2,
        shadowColor: _errorColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            // Handle logout
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _errorColor.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  color: _errorColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Log Out',
                  style: TextStyle(
                    color: _errorColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  REUSABLE PREMIUM CARD
  // ─────────────────────────────────────────────
  Widget _buildPremiumCard({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: _borderLight, width: 0.5),
        ),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HELPER DATA CLASSES
// ─────────────────────────────────────────────

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });
}

class _SettingItem {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;
  
  const _SettingItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
  });
}