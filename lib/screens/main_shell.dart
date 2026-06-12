import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_screen.dart';
import 'booking_screen.dart';
import 'appointment_screen.dart' hide DepartmentScreen;
import 'login_screen.dart';
import 'message_screen.dart';
import 'profile_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  MainShell  ·  Persistent Bottom Nav Wrapper
//  lib/screens/main_shell.dart
//
//  Wraps all main screens with a shared animated bottom navigation
//  bar. Screens are kept alive (IndexedStack) so scroll positions
//  and state are preserved when switching tabs.
// ═══════════════════════════════════════════════════════════════════

class MainShell extends StatefulWidget {
  /// Start on a specific tab (0=Home, 1=Bookings, 2=Schedule, 3=Messages, 4=Profile)
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {

  // ─── Palette (same as HomeScreen) ───────────────────────────────
  static const Color _navy      = Color(0xFF0A2459);
  static const Color _blue      = Color(0xFF1565C0);
  static const Color _white     = Colors.white;
  static const Color _textLight = Color(0xFF8AAAC8);

  // ─── Nav items ──────────────────────────────────────────────────
  static const List<_NavItem> _navItems = [
    _NavItem(Icons.home_rounded,           Icons.home_outlined,              'Home'),
    _NavItem(Icons.calendar_month_rounded, Icons.calendar_month_outlined,    'Bookings'),
    _NavItem(Icons.event_note_rounded,     Icons.event_note_outlined,        'Schedule'),
    _NavItem(Icons.chat_bubble_rounded,    Icons.chat_bubble_outline_rounded,'Messages'),
    _NavItem(Icons.person_rounded,         Icons.person_outline_rounded,     'Profile'),
  ];

  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  // ─── Screens for each tab ───────────────────────────────────────
  // Using IndexedStack keeps each screen alive (preserves scroll/state)
  Widget _buildBody() {
    return IndexedStack(
      index: _currentIndex,
      children: [
        const _HomeBody(),         // tab 0 – Home
        const BookingScreen(),     // tab 1 – Bookings
        const AppointmentScreen(), // tab 2 – Schedule
        const MessageScreen(),     // tab 3 – Messages ✅
        ProfileScreen(),           // tab 4 – Profile  ✅
      ],
    );
  }

  // ─── Bottom nav ─────────────────────────────────────────────────
  Widget _buildBottomNav() {
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
            children: List.generate(_navItems.length, (i) {
              final item   = _navItems[i];
              final active = _currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _currentIndex = i),
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      body:              _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  _HomeBody
//  HomeScreen yangu ilikuwa na bottomNavigationBar yake ndani yake.
//  Hapa tunatumia HomeScreen body tu (bila bottom nav yake ya awali).
//  Njia rahisi zaidi: tumia HomeScreen yenyewe lakini ondoa
//  bottomNavigationBar yake — au tenganisha body kama hapa chini.
//
//  ► CHAGUO 1 (rahisi): Wrap HomeScreen bila mabadiliko yoyote.
//    MainShell itaonyesha bottom nav JUU ya HomeScreen's nav, kwa hivyo
//    unaweza kuondoa _buildBottomNav() call ndani ya home_screen.dart.
//
//  ► CHAGUO 2 (safi): Tenganisha _HomeBody kutoka HomeScreen.
//    (Inahitaji refactor ndogo ya home_screen.dart)
//
//  Kwa sasa tunatumia CHAGUO 1 — HomeScreen inabaki unchanged,
//  na MainShell inaongeza nav kwa screens zote.
// ═══════════════════════════════════════════════════════════════════

/// Thin wrapper — inaonyesha HomeScreen kama tab bila mabadiliko yoyote.
/// Ikitaka kuondoa double nav bar, ondoa `bottomNavigationBar: _buildBottomNav()`
/// kutoka ndani ya home_screen.dart build() method.
class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) => const HomeScreen();
}

// ─── Placeholder for tabs not yet implemented ────────────────────
class _PlaceholderScreen extends StatelessWidget {
  final String   label;
  final IconData icon;
  const _PlaceholderScreen({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: const Color(0xFF1565C0).withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(label,
              style: const TextStyle(
                fontSize:   22,
                fontWeight: FontWeight.w700,
                color:      Color(0xFF0D1F3C),
              )),
            const SizedBox(height: 8),
            const Text('Coming soon',
              style: TextStyle(color: Color(0xFF8AAAC8), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─── Nav item data model ─────────────────────────────────────────
@immutable
class _NavItem {
  final IconData active;
  final IconData inactive;
  final String   label;
  const _NavItem(this.active, this.inactive, this.label);
}