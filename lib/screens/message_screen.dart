import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════
//  ClinicBook  ·  Message Screen
//  File : lib/screens/message_screen.dart
// ═══════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────
//  ENUMS & DATA MODELS
// ─────────────────────────────────────────────

enum ChatCategory { all, doctors, clinics, reminders, emergency }

/// Avatar type — icon-based (no emoji)
enum AvatarIcon {
  eye,
  tooth,
  heart,
  vaccine,
  bell,
  ambulance,
  glasses,
}

class ChatMessage {
  final String      id;
  final String      name;
  final String      specialty;
  final String      lastMessage;
  final String      time;
  final int         unreadCount;
  final AvatarIcon  avatarIcon;
  final Color       avatarColor;
  final ChatCategory category;
  final bool        isOnline;
  final bool        isEmergency;

  const ChatMessage({
    required this.id,
    required this.name,
    required this.specialty,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.avatarIcon,
    required this.avatarColor,
    required this.category,
    this.isOnline    = false,
    this.isEmergency = false,
  });
}

// ─────────────────────────────────────────────
//  DUMMY DATA
// ─────────────────────────────────────────────

final List<ChatMessage> _dummyChats = [
  ChatMessage(
    id:          '1',
    name:        'Dr. Sarah Kimani',
    specialty:   'Eye Clinic',
    lastMessage: 'Your prescription is ready for collection.',
    time:        '10:24 AM',
    unreadCount: 3,
    avatarIcon:  AvatarIcon.eye,
    avatarColor: const Color(0xFF1565C0),
    category:    ChatCategory.doctors,
    isOnline:    true,
  ),
  ChatMessage(
    id:          '2',
    name:        'Dental Care Centre',
    specialty:   'Dental Clinic',
    lastMessage: 'Reminder: Checkup tomorrow at 9:00 AM. Please arrive 10 mins early.',
    time:        'Yesterday',
    unreadCount: 1,
    avatarIcon:  AvatarIcon.tooth,
    avatarColor: const Color(0xFF00ACC1),
    category:    ChatCategory.clinics,
  ),
  ChatMessage(
    id:          '3',
    name:        'Mother & Child Clinic',
    specialty:   'Maternity Clinic',
    lastMessage: 'Your antenatal results are in. Please review at your convenience.',
    time:        'Mon',
    unreadCount: 0,
    avatarIcon:  AvatarIcon.heart,
    avatarColor: const Color(0xFF7B1FA2),
    category:    ChatCategory.clinics,
    isOnline:    true,
  ),
  ChatMessage(
    id:          '4',
    name:        'Dr. James Otieno',
    specialty:   'Pediatric Doctor',
    lastMessage: 'The vaccination schedule has been updated. Check your app.',
    time:        'Sun',
    unreadCount: 2,
    avatarIcon:  AvatarIcon.vaccine,
    avatarColor: const Color(0xFF388E3C),
    category:    ChatCategory.doctors,
  ),
  ChatMessage(
    id:          '5',
    name:        'Eye Clinic',
    specialty:   'Ophthalmology',
    lastMessage: 'New frames available in our optical shop. Visit us today!',
    time:        'Sat',
    unreadCount: 0,
    avatarIcon:  AvatarIcon.glasses,
    avatarColor: const Color(0xFF0288D1),
    category:    ChatCategory.clinics,
  ),
  ChatMessage(
    id:          '6',
    name:        'Appointment Reminder',
    specialty:   'System',
    lastMessage: 'Dental Checkup in 1 hour. Please confirm your attendance.',
    time:        'Now',
    unreadCount: 1,
    avatarIcon:  AvatarIcon.bell,
    avatarColor: const Color(0xFFF57C00),
    category:    ChatCategory.reminders,
  ),
  ChatMessage(
    id:          '7',
    name:        'Emergency Line',
    specialty:   'Emergency  ·  Available 24/7',
    lastMessage: 'Tap to call the emergency hotline.',
    time:        '--',
    unreadCount: 0,
    avatarIcon:  AvatarIcon.ambulance,
    avatarColor: const Color(0xFFEF5350),
    category:    ChatCategory.emergency,
    isOnline:    true,
    isEmergency: true,
  ),
];

// ═══════════════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════════════

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen>
    with SingleTickerProviderStateMixin {

  // ── Palette (matches home screen & appointment screen) ───────────
  static const Color _navyDeep  = Color(0xFF0D2137);
  static const Color _ocean     = Color(0xFF1565C0);
  static const Color _bg        = Color(0xFFEAF4FB);
  static const Color _ice       = Color(0xFFE3F2FD);
  static const Color _white     = Colors.white;
  static const Color _textDark  = Color(0xFF0F2236);
  static const Color _textMid   = Color(0xFF4A6880);
  static const Color _textLight = Color(0xFF8BAFC4);
  static const Color _green     = Color(0xFF22C55E);
  static const Color _rose      = Color(0xFFEF5350);

  // ── State ────────────────────────────────────────────────────────
  ChatCategory _selectedCategory = ChatCategory.all;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // ── Entrance animation ───────────────────────────────────────────
  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _animCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    _searchCtrl.addListener(
      () => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filtered list ────────────────────────────────────────────────
  List<ChatMessage> get _filtered => _dummyChats.where((c) {
        final byCategory = _selectedCategory == ChatCategory.all ||
            c.category == _selectedCategory;
        final bySearch = _searchQuery.isEmpty ||
            c.name.toLowerCase().contains(_searchQuery) ||
            c.lastMessage.toLowerCase().contains(_searchQuery) ||
            c.specialty.toLowerCase().contains(_searchQuery);
        return byCategory && bySearch;
      }).toList();

  int get _totalUnread =>
      _dummyChats.fold(0, (sum, c) => sum + c.unreadCount);
  int get _onlineCount =>
      _dummyChats.where((c) => c.isOnline).length;

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildSearchBar()),
                SliverToBoxAdapter(child: _buildCategoryChips()),
                SliverToBoxAdapter(child: _buildReminderCard()),
                SliverToBoxAdapter(child: _buildSectionHeader()),
                _filtered.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      )
                    : SliverPadding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(
                                  milliseconds: 280 + i * 70),
                              curve: Curves.easeOut,
                              builder: (_, v, child) => Transform.translate(
                                offset: Offset(0, 16 * (1 - v)),
                                child: Opacity(
                                    opacity: v, child: child),
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 10),
                                child: _ChatCard(
                                  chat:       _filtered[i],
                                  oceanColor: _ocean,
                                ),
                              ),
                            ),
                            childCount: _filtered.length,
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

  // ──────────────────────────────────────────────────────────────────
  //  HEADER
  // ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
          colors: [
            Color(0xFF0D2137),
            Color(0xFF1B4F8A),
            Color(0xFF1A7FC1),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          // Decorative orbs
          Positioned(
            top: -28, right: -28,
            child: _orb(130, 0.06),
          ),
          Positioned(
            top: 22, right: 48,
            child: _orb(58, 0.05),
          ),
          Positioned(
            bottom: 20, left: -20,
            child: _orb(80, 0.04),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Messages',
                              style: TextStyle(
                                color:         _white,
                                fontSize:      22,
                                fontWeight:    FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Chat with doctors & clinics',
                              style: TextStyle(
                                color:    Colors.white70,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Search icon
                      _headerIconBtn(
                        icon:  Icons.search_rounded,
                        onTap: () {},
                      ),
                      const SizedBox(width: 8),
                      // Notification bell with red dot
                      Stack(
                        children: [
                          _headerIconBtn(
                            icon:  Icons.notifications_outlined,
                            onTap: () {},
                          ),
                          Positioned(
                            top: 7, right: 7,
                            child: Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF3B30),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Quick stats row
                  Row(
                    children: [
                      _statPill('${_dummyChats.length}', 'Chats'),
                      const SizedBox(width: 8),
                      _statPill('$_totalUnread', 'Unread',
                          highlight: true),
                      const SizedBox(width: 8),
                      _statPill('$_onlineCount', 'Online'),
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

  // ──────────────────────────────────────────────────────────────────
  //  SEARCH BAR
  // ──────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color:        _white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:      _navyDeep.withOpacity(0.08),
              blurRadius: 14,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(fontSize: 13.5, color: _textDark),
          decoration: InputDecoration(
            hintText: 'Search messages...',
            hintStyle: const TextStyle(color: _textLight, fontSize: 13.5),
            prefixIcon: const Icon(Icons.search_rounded,
                color: _textLight, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        color: _textLight, size: 18),
                    onPressed: () => _searchCtrl.clear(),
                  )
                : null,
            border:         InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  CATEGORY CHIPS
  // ──────────────────────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    const tabs = [
      (ChatCategory.all,       'All'),
      (ChatCategory.doctors,   'Doctors'),
      (ChatCategory.clinics,   'Clinics'),
      (ChatCategory.reminders, 'Reminders'),
      (ChatCategory.emergency, 'Emergency'),
    ];

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        children: tabs.map((t) {
          final active = _selectedCategory == t.$1;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = t.$1);
              _animCtrl
                ..reset()
                ..forward();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve:    Curves.easeOut,
              margin:   const EdgeInsets.only(right: 8),
              padding:  const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(
                        colors: [Color(0xFF0D2137), Color(0xFF1565C0)],
                      )
                    : null,
                color:        active ? null : _white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: active
                        ? _ocean.withOpacity(0.32)
                        : _navyDeep.withOpacity(0.07),
                    blurRadius: active ? 8 : 6,
                    offset:     const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                t.$2,
                style: TextStyle(
                  color:      active ? _white : _textMid,
                  fontWeight: active
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: 12.5,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  APPOINTMENT REMINDER CARD
  // ──────────────────────────────────────────────────────────────────
  Widget _buildReminderCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin:  Alignment.centerLeft,
            end:    Alignment.centerRight,
            colors: [Color(0xFF0D2137), Color(0xFF1565C0)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:      _ocean.withOpacity(0.38),
              blurRadius: 16,
              offset:     const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color:        Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.medical_services_outlined,
                    color: _white, size: 24),
              ),
              const SizedBox(width: 14),

              // Text block
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dental Checkup',
                      style: TextStyle(
                        color:      _white,
                        fontSize:   15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            color: Colors.white70, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Tomorrow  ·  9:00 AM',
                          style: TextStyle(
                            color:    Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // View button
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color:        _white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      color:      _ocean,
                      fontSize:   12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  SECTION HEADER
  // ──────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Recent Conversations',
            style: TextStyle(
              color:      _textDark,
              fontSize:   15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'See All',
            style: TextStyle(
              color:      _ocean,
              fontSize:   13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  EMPTY STATE
  // ──────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              color:        _ice,
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: _ocean, size: 44),
          ),
          const SizedBox(height: 20),
          const Text(
            'No messages yet',
            style: TextStyle(
              color:      _textDark,
              fontSize:   17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your conversations with doctors\nand clinics will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:  _textLight,
              fontSize: 13,
              height:   1.6,
            ),
          ),
          const SizedBox(height: 28),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D2137), Color(0xFF1565C0)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color:      _ocean.withOpacity(0.35),
                  blurRadius: 14,
                  offset:     const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Book Appointment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor:     Colors.transparent,
                foregroundColor: _white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  //  HELPERS
  // ──────────────────────────────────────────────────────────────────

  Widget _orb(double size, double opacity) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );

  Widget _headerIconBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color:        Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.white.withOpacity(0.20), width: 1),
          ),
          child: Icon(icon, color: _white, size: 20),
        ),
      );

  Widget _statPill(String value, String label,
      {bool highlight = false}) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: highlight
                ? Colors.white.withOpacity(0.22)
                : Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color:      _white,
                  fontSize:   16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 10.5),
              ),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════
//  CHAT CARD
// ═══════════════════════════════════════════════════════════════════

class _ChatCard extends StatefulWidget {
  final ChatMessage chat;
  final Color       oceanColor;

  const _ChatCard({required this.chat, required this.oceanColor});

  @override
  State<_ChatCard> createState() => _ChatCardState();
}

class _ChatCardState extends State<_ChatCard> {
  bool _pressed = false;

  // Map AvatarIcon → Material IconData
  IconData _iconData(AvatarIcon av) {
    switch (av) {
      case AvatarIcon.eye:       return Icons.remove_red_eye_outlined;
      case AvatarIcon.tooth:     return Icons.hive_outlined;         // closest built-in
      case AvatarIcon.heart:     return Icons.favorite_border_rounded;
      case AvatarIcon.vaccine:   return Icons.vaccines_outlined;
      case AvatarIcon.bell:      return Icons.notifications_active_outlined;
      case AvatarIcon.ambulance: return Icons.emergency_outlined;
      case AvatarIcon.glasses:   return Icons.visibility_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat      = widget.chat;
    final hasUnread = chat.unreadCount > 0;

    return GestureDetector(
      onTapDown:  (_) => setState(() => _pressed = true),
      onTapUp:    (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap:      () {},
      child: AnimatedScale(
        scale:    _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: chat.isEmergency
                ? Border(
                    left: BorderSide(
                        color: chat.avatarColor, width: 3))
                : null,
            boxShadow: [
              BoxShadow(
                color:      const Color(0xFF0D2137).withOpacity(0.07),
                blurRadius: 14,
                offset:     const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // ── Avatar ──────────────────────────────────────────
                Stack(
                  children: [
                    Container(
                      width:  54,
                      height: 54,
                      decoration: BoxDecoration(
                        color:  chat.avatarColor.withOpacity(0.12),
                        shape:  BoxShape.circle,
                        border: Border.all(
                          color: chat.avatarColor.withOpacity(0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        _iconData(chat.avatarIcon),
                        color: chat.avatarColor,
                        size:  24,
                      ),
                    ),
                    // Online indicator
                    if (chat.isOnline)
                      Positioned(
                        bottom: 1, right: 1,
                        child: Container(
                          width:  13,
                          height: 13,
                          decoration: BoxDecoration(
                            color:  const Color(0xFF22C55E),
                            shape:  BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                // ── Content ─────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + time
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              chat.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize:   14.5,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: const Color(0xFF0F2236),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            chat.time,
                            style: TextStyle(
                              fontSize:   11,
                              color: hasUnread
                                  ? widget.oceanColor
                                  : const Color(0xFF8BAFC4),
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 2),

                      // Specialty tag
                      Text(
                        chat.specialty,
                        style: TextStyle(
                          fontSize:   11,
                          color:      chat.avatarColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 5),

                      // Last message + unread badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: hasUnread
                                    ? const Color(0xFF4A6880)
                                    : const Color(0xFF8BAFC4),
                                fontWeight: hasUnread
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              height:  20,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              constraints: const BoxConstraints(
                                  minWidth: 20),
                              decoration: BoxDecoration(
                                color: widget.oceanColor,
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${chat.unreadCount}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color:      Colors.white,
                                  fontSize:   11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
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