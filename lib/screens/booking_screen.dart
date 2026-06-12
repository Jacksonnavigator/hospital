// lib/screens/booking_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// Redesigned to match HTML preview — floating round-corner cards, premium UI
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Color Palette ────────────────────────────────────────────────────────────
// Colors extracted from the "Top Doctors" screen design

// Primary blues — header gradient & buttons
const Color kNavy      = Color(0xFF0F2B5B);  // deep navy (header top)
const Color kOcean     = Color(0xFF1A3D8F);  // rich blue (Book Now button)
const Color kTeal      = Color(0xFF2B6CB0);  // medium blue (specialty text / accents)

// Background & surface
const Color kBg        = Color(0xFFEEF4FB);  // light blue-grey page background
const Color kPaleBlue  = Color(0xFFDCEBF8);  // pale blue (unselected chip bg)
const Color kIce       = Color(0xFFF5F9FF);  // near-white tint for inner containers
const Color kSurface   = Color(0xFFFFFFFF);  // card white

// Borders & dividers
const Color kDivider   = Color(0xFFD6E8F5);  // very light blue divider
const Color kCardBorder = Color(0xFFBDD5EC); // subtle card border

// Soft text / muted
const Color kSoftBlue  = Color(0xFF6B92B8);  // secondary/muted text

// Status — Available (green)
const Color kGreenOk   = Color(0xFF16A34A);  // available badge text/dot
const Color kGreenBg   = Color(0xFFDCFCE7);  // available badge background

// Status — Busy (red)
const Color kAmberText = Color(0xFFDC2626);  // busy badge text
const Color kAmberBg   = Color(0xFFFFE4E4);  // busy badge background

// Star / rating
const Color kStar      = Color(0xFFF59E0B);  // amber star

// ─── Gradients ────────────────────────────────────────────────────────────────

// "Book Now" button & primary CTAs — deep blue
const LinearGradient kPrimaryGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFF1A3D8F), Color(0xFF1E5FAD)],
);

// Hero header — dark navy to mid blue (matches top of image)
const LinearGradient kHeroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0A1E4A), Color(0xFF12336E), Color(0xFF1A5298)],
  stops: [0.0, 0.5, 1.0],
);

// Selected filter chip / selected day
const LinearGradient kSelectedGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF1A3D8F), Color(0xFF1E5FAD)],
);

// Selected doctor card highlight
const LinearGradient kDocSelectedGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0F2B5B), Color(0xFF1A3D8F)],
);

// ─── Data Models ─────────────────────────────────────────────────────────────

class Doctor {
  final String name;
  final String specialty;
  final String imagePath;
  final double rating;
  final int reviews;
  final bool isAvailable;

  const Doctor({
    required this.name,
    required this.specialty,
    required this.imagePath,
    required this.rating,
    required this.reviews,
    required this.isAvailable,
  });
}

// ─── Constants ────────────────────────────────────────────────────────────────

const List<Doctor> kDoctors = [
  Doctor(
    name: 'Dr. Hyasinta Kessy',
    specialty: 'Pediatrics',
    imagePath: 'lib/assets/pediatricsdoctot.png',
    rating: 4.8,
    reviews: 320,
    isAvailable: true,
  ),
  Doctor(
    name: 'Dr. Anna Sikawa',
    specialty: 'OB & Gynecology',
    imagePath: 'lib/assets/obstetrics_gynecologydoctor.jpg',
    rating: 5.0,
    reviews: 210,
    isAvailable: true,
  ),
  Doctor(
    name: 'Dr. Allan Michael',
    specialty: 'Dental',
    imagePath: 'lib/assets/dentaldoctor.jpg',
    rating: 4.7,
    reviews: 185,
    isAvailable: false,
  ),
  Doctor(
    name: 'Dr. Shaziri Mustapha',
    specialty: 'Eye Care',
    imagePath: 'lib/assets/eyedoctor.png',
    rating: 4.9,
    reviews: 264,
    isAvailable: true,
  ),
];

const List<String> kWeekDays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

const List<String> kTimeSlots = [
  '08:00 AM', '09:00 AM', '10:00 AM',
  '11:00 AM', '12:00 PM', '02:00 PM',
  '03:00 PM', '04:00 PM', '05:00 PM',
];

const Set<String> kBusySlots = {'08:00 AM', '12:00 PM', '04:00 PM'};
const Set<int>    kDotDays   = {2, 5, 7, 9, 13, 15, 19, 22, 26};

// ─── Booking Screen ───────────────────────────────────────────────────────────

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with TickerProviderStateMixin {

  // ── State ──────────────────────────────────────────────────────────────────
  int    _selectedDoctorIndex = 0;
  int    _selectedDay         = 7;
  String _selectedSlot        = '10:00 AM';
  bool   _bookingConfirmed    = false;
  bool   _buttonPressed       = false;

  // ── Animation Controllers ──────────────────────────────────────────────────
  late final AnimationController _entranceCtrl;
  late final AnimationController _buttonPulseCtrl;
  late final AnimationController _confirmCtrl;

  late final Animation<double> _heroFade;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _card1Fade;
  late final Animation<Offset> _card1Slide;
  late final Animation<double> _card2Fade;
  late final Animation<Offset> _card2Slide;
  late final Animation<double> _card3Fade;
  late final Animation<Offset> _card3Slide;
  late final Animation<double> _card4Fade;
  late final Animation<Offset> _card4Slide;

  late final Animation<double> _pulseAnim;
  late final Animation<double> _confirmScale;
  late final Animation<double> _confirmFade;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _heroFade   = _fade(0.00, 0.30);
    _heroSlide  = _slide(0.00, 0.30);
    _card1Fade  = _fade(0.18, 0.48);
    _card1Slide = _slide(0.18, 0.48);
    _card2Fade  = _fade(0.32, 0.62);
    _card2Slide = _slide(0.32, 0.62);
    _card3Fade  = _fade(0.46, 0.76);
    _card3Slide = _slide(0.46, 0.76);
    _card4Fade  = _fade(0.60, 1.00);
    _card4Slide = _slide(0.60, 1.00);

    _buttonPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _buttonPulseCtrl, curve: Curves.easeInOut),
    );

    _confirmCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _confirmScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _confirmCtrl, curve: Curves.elasticOut),
    );
    _confirmFade = CurvedAnimation(parent: _confirmCtrl, curve: Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _entranceCtrl.forward();
    });
  }

  Animation<double> _fade(double s, double e) => CurvedAnimation(
    parent: _entranceCtrl,
    curve: Interval(s, e, curve: Curves.easeOut),
  );

  Animation<Offset> _slide(double s, double e) =>
      Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic),
        ),
      );

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _buttonPulseCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _onConfirmTap() {
    HapticFeedback.mediumImpact();
    setState(() => _bookingConfirmed = true);
    _buttonPulseCtrl.stop();
    _confirmCtrl.forward();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: kBg,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHero()),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _card1Fade,
                    child: SlideTransition(
                      position: _card1Slide,
                      child: _buildDoctorCard(),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _card2Fade,
                    child: SlideTransition(
                      position: _card2Slide,
                      child: _buildCalendarCard(),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _card3Fade,
                    child: SlideTransition(
                      position: _card3Slide,
                      child: _buildTimeSlotsCard(),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _card4Fade,
                    child: SlideTransition(
                      position: _card4Slide,
                      child: _buildSummaryCard(),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ),
            if (_bookingConfirmed)
              FadeTransition(
                opacity: _confirmFade,
                child: _buildSuccessOverlay(),
              ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // HERO
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return FadeTransition(
      opacity: _heroFade,
      child: SlideTransition(
        position: _heroSlide,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(36),
            bottomRight: Radius.circular(36),
          ),
          child: Stack(
            children: [
              // ── Background image ──────────────────────────────────────
              Positioned.fill(
                child: Image.asset(
                  'lib/assets/backgroundbookingscr.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(gradient: kHeroGradient),
                  ),
                ),
              ),
              // ── Multi-stop dark overlay ───────────────────────────────
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xCC05192D),
                        Color(0x800A3D62),
                        Color(0xE005192D),
                      ],
                      stops: [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
              // ── Left vignette ─────────────────────────────────────────
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0x660A2A45), Colors.transparent],
                    ),
                  ),
                ),
              ),
              // ── Animated particles ────────────────────────────────────
              const SizedBox(
                height: 260,
                child: _HeroParticles(),
              ),
              // ── Content ───────────────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 38),
                          _heroPill('Book Appointment'),
                          _heroIconBtn(
                            Icons.notifications_none_rounded,
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      // Eyebrow
                      Text(
                        'HEALTHCARE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF7EB3E8),
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Title
                      const Text(
                        'Book Appointment',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Select a doctor and pick your preferred slot',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.52),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroIconBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    );
  }

  Widget _heroPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FLOATING CARD SHELL
  // ────────────────────────────────────────────────────────────────────────────

  Widget _floatCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kCardBorder.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: kNavy.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(String title, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A3D8F), Color(0xFF1E5FAD)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kNavy,
                ),
              ),
            ],
          ),
          if (trailing != null)
            Text(
              trailing,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: kTeal,
              ),
            ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // DOCTOR SECTION
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildDoctorCard() {
    return _floatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Available Doctors', trailing: 'View all →'),
          SizedBox(
            height: 188,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 16),
              itemCount: kDoctors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _buildDoctorItem(i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorItem(int index) {
    final doc = kDoctors[index];
    final isSelected = _selectedDoctorIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedDoctorIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 112,
        transform: Matrix4.identity()
          ..translate(0.0, isSelected ? -2.0 : 0.0),
        decoration: BoxDecoration(
          gradient: isSelected ? kDocSelectedGradient : null,
          color: isSelected ? null : const Color(0xFFF5FAFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kOcean : kDivider,
            width: isSelected ? 0 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kOcean.withOpacity(0.32),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: kNavy.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withOpacity(0.30)
                          : const Color(0xFFDBEEFF),
                      width: 2.5,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: kPaleBlue,
                    backgroundImage: AssetImage(doc.imagePath),
                    onBackgroundImageError: (_, __) {},
                  ),
                ),
                Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: doc.isAvailable
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    border: Border.all(
                      color: isSelected ? kOcean : kSurface,
                      width: 2.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              doc.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : kNavy,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              doc.specialty,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white.withOpacity(0.62) : kSoftBlue,
              ),
            ),
            const SizedBox(height: 5),
            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(5, (i) {
                  final filled = i < doc.rating.floor();
                  return Icon(
                    Icons.star_rounded,
                    size: 9,
                    color: filled
                        ? (isSelected
                            ? const Color(0xFFFFD97D)
                            : const Color(0xFFF59E0B))
                        : (isSelected
                            ? Colors.white.withOpacity(0.25)
                            : const Color(0xFFCBD5E1)),
                  );
                }),
                const SizedBox(width: 2),
                Text(
                  '${doc.rating}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white.withOpacity(0.88)
                        : kSoftBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: doc.isAvailable
                    ? (isSelected
                        ? Colors.white.withOpacity(0.15)
                        : kGreenBg)
                    : (isSelected
                        ? Colors.white.withOpacity(0.12)
                        : kAmberBg),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                doc.isAvailable ? '● Available' : '● Busy',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: doc.isAvailable
                      ? (isSelected
                          ? const Color(0xFF80FFD4)
                          : kGreenOk)
                      : (isSelected
                          ? Colors.white.withOpacity(0.7)
                          : kAmberText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // CALENDAR SECTION
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildCalendarCard() {
    return _floatCard(
      child: Column(
        children: [
          _sectionHeader('Select Date', trailing: 'May 2025'),
          // Month nav
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _calNavBtn(Icons.chevron_left_rounded),
                Column(
                  children: [
                    const Text(
                      'May 2025',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kNavy,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${kDotDays.length} appointments',
                      style: const TextStyle(
                        fontSize: 10,
                        color: kTeal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                _calNavBtn(Icons.chevron_right_rounded),
              ],
            ),
          ),
          // Weekday labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: kWeekDays
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: kSoftBlue.withOpacity(0.75),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: _buildCalendarGrid(),
          ),
        ],
      ),
    );
  }

  Widget _calNavBtn(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: kIce,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDivider, width: 1.5),
      ),
      child: Icon(icon, color: kOcean, size: 20),
    );
  }

  Widget _buildCalendarGrid() {
    const int startWeekday = 4; // May 2025 starts on Thursday
    const int daysInMonth  = 31;
    const int prevDays     = 30;

    final List<_CalDay> days = [];
    for (int i = startWeekday - 1; i >= 0; i--) {
      days.add(_CalDay(day: prevDays - i, isCurrentMonth: false));
    }
    for (int d = 1; d <= daysInMonth; d++) {
      days.add(_CalDay(day: d, isCurrentMonth: true));
    }
    while (days.length % 7 != 0) {
      days.add(_CalDay(
        day: days.length - daysInMonth - startWeekday + 1,
        isCurrentMonth: false,
      ));
    }

    return Column(
      children: List.generate(days.length ~/ 7, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cell       = days[row * 7 + col];
            final isSelected = cell.isCurrentMonth && cell.day == _selectedDay;
            final isToday    = cell.isCurrentMonth && cell.day == 1;
            final hasDot     = cell.isCurrentMonth && kDotDays.contains(cell.day);

            return Expanded(
              child: GestureDetector(
                onTap: cell.isCurrentMonth
                    ? () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedDay = cell.day);
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: isSelected ? kSelectedGradient : null,
                    color: isSelected
                        ? null
                        : isToday
                            ? kOcean.withOpacity(0.05)
                            : Colors.transparent,
                    border: isToday && !isSelected
                        ? Border.all(color: kOcean, width: 1.5)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: kOcean.withOpacity(0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${cell.day}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected || isToday
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : isToday
                                        ? kOcean
                                        : cell.isCurrentMonth
                                            ? kNavy
                                            : const Color(0xFFCBD5E1),
                              ),
                            ),
                            if (hasDot) ...[
                              const SizedBox(height: 2),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.65)
                                      : kTeal,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // TIME SLOTS SECTION
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildTimeSlotsCard() {
    return _floatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Available Times',
            trailing: 'Wed, $_selectedDay May',
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                _legendItem(kOcean, 'Available'),
                const SizedBox(width: 12),
                _legendItem(const Color(0xFFCBD5E1), 'Busy'),
                const SizedBox(width: 12),
                _legendItem(kOcean, 'Selected', outlined: true),
              ],
            ),
          ),
          // Grid
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.6,
              ),
              itemCount: kTimeSlots.length,
              itemBuilder: (_, i) => _buildTimeSlot(kTimeSlots[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, {bool outlined = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: outlined
                ? Border.all(color: Colors.white, width: 2)
                : null,
            boxShadow: outlined
                ? [BoxShadow(color: color, blurRadius: 0, spreadRadius: 1.5)]
                : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: kSoftBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlot(String slot) {
    final isBusy   = kBusySlots.contains(slot);
    final isPicked = _selectedSlot == slot && !isBusy;

    return GestureDetector(
      onTap: isBusy
          ? null
          : () {
              HapticFeedback.selectionClick();
              setState(() => _selectedSlot = slot);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: isPicked ? kPrimaryGradient : null,
          color: isPicked
              ? null
              : isBusy
                  ? const Color(0xFFF5F8FA)
                  : const Color(0xFFF5FAFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPicked
                ? Colors.transparent
                : isBusy
                    ? const Color(0xFFEBF1F5)
                    : kDivider,
            width: 1.5,
          ),
          boxShadow: isPicked
              ? [
                  BoxShadow(
                    color: kOcean.withOpacity(0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          isPicked ? '✓ $slot' : slot,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isPicked
                ? Colors.white
                : isBusy
                    ? const Color(0xFFAABFCC)
                    : kNavy,
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // BOOKING SUMMARY CARD
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    final doc = kDoctors[_selectedDoctorIndex];

    return _floatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Booking Summary'),

          // Inner summary rows container
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5FAFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kDivider),
            ),
            child: Column(
              children: [
                // Doctor row
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: _summaryRow(
                    key: ValueKey('doc-${doc.name}'),
                    icon: Icons.person_outline_rounded,
                    label: 'Doctor',
                    value: doc.name,
                    subValue: doc.specialty,
                    isLast: false,
                  ),
                ),
                // Date & Time row
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: _summaryRow(
                    key: ValueKey('dt-$_selectedDay-$_selectedSlot'),
                    icon: Icons.calendar_today_outlined,
                    label: 'Date & Time',
                    value: 'Wed, $_selectedDay May · $_selectedSlot',
                    isLast: false,
                  ),
                ),
                _summaryRow(
                  key: const ValueKey('loc'),
                  icon: Icons.local_hospital_outlined,
                  label: 'Location',
                  value: 'In-Person · Room 101',
                  subValue: 'Muhimbili National Hospital',
                  isLast: false,
                ),
                _summaryRow(
                  key: const ValueKey('fee'),
                  icon: Icons.receipt_long_outlined,
                  label: 'Consultation Fee',
                  value: 'TZS 25,000',
                  isLast: true,
                ),
              ],
            ),
          ),

          // Confirm button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Transform.scale(
                scale: _buttonPressed ? 0.96 : _pulseAnim.value,
                child: child,
              ),
              child: GestureDetector(
                onTapDown: (_) => setState(() => _buttonPressed = true),
                onTapUp: (_) {
                  setState(() => _buttonPressed = false);
                  _onConfirmTap();
                },
                onTapCancel: () => setState(() => _buttonPressed = false),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: kPrimaryGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: kOcean.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Confirm Booking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Cancel
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Center(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kSoftBlue,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required Key key,
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
    required bool isLast,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFEAF4FB), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEAF6FF), Color(0xFFDBEEFF)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD0E8F7)),
            ),
            child: Icon(icon, size: 16, color: kOcean),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: kSoftBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kNavy,
                  ),
                ),
                if (subValue != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subValue,
                    style: const TextStyle(
                      fontSize: 10,
                      color: kSoftBlue,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // SUCCESS OVERLAY
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildSuccessOverlay() {
    final doc = kDoctors[_selectedDoctorIndex];
    return Container(
      color: Colors.black.withOpacity(0.55),
      child: Center(
        child: ScaleTransition(
          scale: _confirmScale,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: kOcean.withOpacity(0.20),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16A34A).withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Booking Confirmed!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: kNavy,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your appointment has been\nsuccessfully scheduled.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: kSoftBlue,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: kIce,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kDivider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 13, color: kOcean),
                      const SizedBox(width: 8),
                      Text(
                        'Wed, $_selectedDay May · $_selectedSlot',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kNavy,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: kIce,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kDivider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 13, color: kOcean),
                      const SizedBox(width: 8),
                      Text(
                        doc.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kNavy,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).maybePop();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: kPrimaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: kOcean.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

// ─── Animated Hero Particles ─────────────────────────────────────────────────

class _HeroParticles extends StatefulWidget {
  const _HeroParticles();

  @override
  State<_HeroParticles> createState() => _HeroParticlesState();
}

class _HeroParticlesState extends State<_HeroParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<_Particle> _particles = List.generate(18, (_) => _Particle());

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _ParticlePainter(_particles, _ctrl.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  _Particle()
      : x = math.Random().nextDouble(),
        y = math.Random().nextDouble(),
        size = math.Random().nextDouble() * 3 + 1,
        speed = math.Random().nextDouble() * 0.4 + 0.1,
        opacity = math.Random().nextDouble() * 0.20 + 0.04;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;

  _ParticlePainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dy = (p.y - t * p.speed) % 1.0;
      final paint = Paint()
        ..color = Colors.white.withOpacity(p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(p.x * size.width, dy * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ─── Helper ───────────────────────────────────────────────────────────────────

class _CalDay {
  final int day;
  final bool isCurrentMonth;
  const _CalDay({required this.day, required this.isCurrentMonth});
}