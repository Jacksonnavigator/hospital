import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════
//  QmedCO  ·  Health Tips Screen  (Redesigned — Intelly Style)
//  File: lib/screens/health_tips_screen.dart
// ═══════════════════════════════════════════════════════════════════

class HealthTipsScreen extends StatefulWidget {
  const HealthTipsScreen({super.key});

  @override
  State<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends State<HealthTipsScreen> {

  // ─── Palette ────────────────────────────────────────────────────
  static const Color _bg        = Color(0xFFF8F6F0);
  static const Color _dark      = Color(0xFF1A1A1A);
  static const Color _textDark  = Color(0xFF1A1A1A);
  static const Color _textMid   = Color(0xFF555555);
  static const Color _textLight = Color(0xFF999999);
  static const Color _featured  = Color(0xFFEBE7DB);

  // ─── Habit card colours ─────────────────────────────────────────
  static const Color _blueCardBg    = Color(0xFFD6E4F7);
  static const Color _blueStrip     = Color(0xFF1565C0);
  static const Color _blueTitle     = Color(0xFF0C3A6B);
  static const Color _blueDays      = Color(0xFF4A7FAA);
  static const Color _blueDesc      = Color(0xFF2A5A8A);

  static const Color _greenCardBg   = Color(0xFFE8F5E9);
  static const Color _greenStrip    = Color(0xFF388E3C);
  static const Color _greenTitle    = Color(0xFF1B5E20);
  static const Color _greenDays     = Color(0xFF388E3C);
  static const Color _greenDesc     = Color(0xFF2E7D32);

  static const Color _amberCardBg   = Color(0xFFFFF8E1);
  static const Color _amberStrip    = Color(0xFFFB8C00);
  static const Color _amberTitle    = Color(0xFF4E2600);
  static const Color _amberDays     = Color(0xFFBF360C);
  static const Color _amberDesc     = Color(0xFF7B3F00);

  static const Color _pinkCardBg    = Color(0xFFFCE4EC);
  static const Color _pinkStrip     = Color(0xFFAD1457);
  static const Color _pinkTitle     = Color(0xFF4A1528);
  static const Color _pinkDays      = Color(0xFF880E4F);
  static const Color _pinkDesc      = Color(0xFF6A1039);

  // ─── Explore card colours ───────────────────────────────────────
  static const Color _expBlue   = Color(0xFFDCEAFF);
  static const Color _expGreen  = Color(0xFFE8F5E9);
  static const Color _expAmber  = Color(0xFFFFF3CD);
  static const Color _expPink   = Color(0xFFFCE4EC);

  // ─── Habit add state ────────────────────────────────────────────
  final List<bool> _habitAdded = [false, false, false, false];

  // ═══════════════════════════════════════════════════════════════
  //  DATA
  // ═══════════════════════════════════════════════════════════════

  static const List<_Habit> _habits = [
    _Habit(
      title:   'Quit Smoking',
      days:    '60 days',
      desc:    'A big step toward better health. Your body begins repairing itself quickly after you stop.',
      bgColor: _blueCardBg,
      strip:   _blueStrip,
      titleC:  _blueTitle,
      daysC:   _blueDays,
      descC:   _blueDesc,
      btnC:    _blueStrip,
    ),
    _Habit(
      title:   'Drink 8 Glasses of Water',
      days:    '30 days',
      desc:    'Staying hydrated improves energy, skin health, and supports all body functions throughout the day.',
      bgColor: _greenCardBg,
      strip:   _greenStrip,
      titleC:  _greenTitle,
      daysC:   _greenDays,
      descC:   _greenDesc,
      btnC:    _greenStrip,
    ),
    _Habit(
      title:   'Walk 30 Minutes Daily',
      days:    '21 days',
      desc:    'Regular walking strengthens your heart, boosts your mood, and helps maintain a healthy weight.',
      bgColor: _amberCardBg,
      strip:   _amberStrip,
      titleC:  _amberTitle,
      daysC:   _amberDays,
      descC:   _amberDesc,
      btnC:    _amberStrip,
    ),
    _Habit(
      title:   'Sleep 8 Hours a Night',
      days:    '14 days',
      desc:    'Quality sleep restores the body, sharpens the mind, and strengthens your immune system.',
      bgColor: _pinkCardBg,
      strip:   _pinkStrip,
      titleC:  _pinkTitle,
      daysC:   _pinkDays,
      descC:   _pinkDesc,
      btnC:    _pinkStrip,
    ),
  ];

  static const List<_ExploreCategory> _explore = [
    _ExploreCategory(
      label:     'Pregnancy',
      subtitle:  'Prenatal care tips',
      icon:      Icons.favorite_rounded,
      pillColor: Color(0xFF1565C0),
      pillText:  Color(0xFFFFFFFF),
      bgColor:   _expBlue,
      tips:      _pregnancyTips,
    ),
    _ExploreCategory(
      label:     'Children',
      subtitle:  'Kids health guide',
      icon:      Icons.child_care_rounded,
      pillColor: Color(0xFF2E7D32),
      pillText:  Color(0xFFFFFFFF),
      bgColor:   _expGreen,
      tips:      _childrenTips,
    ),
    _ExploreCategory(
      label:     'Eye Care',
      subtitle:  'Vision health tips',
      icon:      Icons.visibility_rounded,
      pillColor: Color(0xFFE65100),
      pillText:  Color(0xFFFFFFFF),
      bgColor:   _expAmber,
      tips:      _eyeTips,
    ),
    _ExploreCategory(
      label:     'Dental',
      subtitle:  'Oral hygiene tips',
      icon:      Icons.medical_services_rounded,
      pillColor: Color(0xFFAD1457),
      pillText:  Color(0xFFFFFFFF),
      bgColor:   _expPink,
      tips:      _dentalTips,
    ),
  ];

  // ─── Tips data ──────────────────────────────────────────────────
  static const List<_Tip> _pregnancyTips = [
    _Tip(icon: Icons.water_drop_rounded,       title: 'Stay Well Hydrated',           body: 'Drink at least 8–10 glasses of water daily. Water helps transport nutrients to your baby and prevents dehydration during pregnancy.'),
    _Tip(icon: Icons.restaurant_rounded,       title: 'Eat a Nutritious Diet',        body: 'Eat a balanced diet rich in folic acid, iron, and calcium. Include green vegetables, legumes, eggs, and dairy products every day.'),
    _Tip(icon: Icons.local_hospital_rounded,   title: 'Attend All Antenatal Visits',  body: 'Attend all antenatal clinic (ANC) visits. Regular check-ups help detect any risks early and keep both mother and baby safe.'),
    _Tip(icon: Icons.self_improvement_rounded, title: 'Rest and Breathe Well',        body: 'Get 7–9 hours of sleep and rest when tired. Avoid heavy lifting and reduce stress through gentle walks or breathing exercises.'),
    _Tip(icon: Icons.smoke_free_rounded,       title: 'Avoid Smoking and Alcohol',    body: 'Avoid alcohol and smoking completely. These can cause serious harm to your baby, including low birth weight and developmental problems.'),
    _Tip(icon: Icons.medication_rounded,       title: 'Take Prenatal Vitamins',       body: 'Take prenatal vitamins prescribed by your doctor, especially folic acid (before and during pregnancy) to prevent birth defects.'),
  ];

  static const List<_Tip> _childrenTips = [
    _Tip(icon: Icons.vaccines_rounded,         title: 'Vaccinate on Schedule',        body: 'Follow the national immunisation schedule. Vaccines protect children from dangerous diseases like measles, polio, and tuberculosis.'),
    _Tip(icon: Icons.water_drop_rounded,       title: 'Drink Clean, Safe Water',      body: 'Give children clean, safe drinking water at all times. Dirty water causes diarrhoea, a leading cause of child illness in Tanzania.'),
    _Tip(icon: Icons.restaurant_menu_rounded,  title: 'Good Nutrition for Growth',    body: 'Feed children a variety of foods — vegetables, fruits, proteins, and grains. Good nutrition supports brain development and strong bones.'),
    _Tip(icon: Icons.wash_rounded,             title: 'Wash Hands Regularly',         body: 'Teach children to wash hands with soap before eating and after using the toilet. This simple habit prevents many infections and diseases.'),
    _Tip(icon: Icons.bedtime_rounded,          title: 'Ensure Enough Sleep',          body: 'Children need 9–12 hours of sleep per night. Adequate sleep supports healthy growth, learning, and a strong immune system.'),
    _Tip(icon: Icons.directions_run_rounded,   title: 'Encourage Active Play',        body: 'Encourage at least 60 minutes of active play daily. Physical activity builds strength, coordination, and supports mental wellbeing.'),
  ];

  static const List<_Tip> _eyeTips = [
    _Tip(icon: Icons.wb_sunny_rounded,         title: 'Protect Eyes from the Sun',    body: 'Wear sunglasses with UV protection when outdoors. Too much UV exposure can damage the eyes and increase the risk of cataracts over time.'),
    _Tip(icon: Icons.computer_rounded,         title: 'Rest Your Eyes — 20-20-20',    body: 'Every 20 minutes, look at something 20 feet away for 20 seconds. This reduces eye strain and prevents headaches from screen use.'),
    _Tip(icon: Icons.visibility_rounded,       title: 'Get an Annual Eye Exam',       body: 'Get a comprehensive eye exam at least once a year. Many eye conditions like glaucoma have no early symptoms and are only caught through testing.'),
    _Tip(icon: Icons.local_dining_rounded,     title: 'Eat Well for Eye Health',      body: 'Eat foods rich in vitamins A, C, and E — like carrots, spinach, and citrus fruits. These nutrients help maintain good vision and eye health.'),
    _Tip(icon: Icons.wash_rounded,             title: 'Do Not Touch Eyes with Dirty Hands', body: 'Avoid touching or rubbing your eyes with unwashed hands. This can transfer bacteria and viruses that cause infections like pink eye.'),
    _Tip(icon: Icons.lightbulb_rounded,        title: 'Read in Good Lighting',        body: 'Always read or work in well-lit areas. Poor lighting forces your eyes to work harder, causing fatigue and long-term strain.'),
  ];

  static const List<_Tip> _dentalTips = [
    _Tip(icon: Icons.cleaning_services_rounded, title: 'Brush Teeth Twice a Day',     body: 'Brush your teeth in the morning and before bed using fluoride toothpaste. Brushing removes plaque that causes tooth decay and gum disease.'),
    _Tip(icon: Icons.water_drop_rounded,        title: 'Choose Water Over Sugary Drinks', body: 'Drink water instead of sugary drinks like soda and juice. Sugar feeds harmful bacteria in the mouth that produce acids, destroying tooth enamel.'),
    _Tip(icon: Icons.local_hospital_rounded,    title: 'Visit Your Dentist Regularly', body: 'Visit your dentist every 6 months for a check-up and professional cleaning. Early detection saves teeth and reduces pain and costs.'),
    _Tip(icon: Icons.no_food_rounded,           title: 'Limit Sugar in Your Diet',    body: 'Limit sweets, biscuits, and sticky foods. If you eat sugary snacks, rinse your mouth with water afterwards and brush as soon as possible.'),
    _Tip(icon: Icons.child_friendly_rounded,    title: "Children's Teeth — Start Early", body: 'Start cleaning your baby\'s gums before teeth appear using a clean damp cloth. Begin brushing as soon as the first tooth comes in.'),
    _Tip(icon: Icons.smoke_free_rounded,        title: 'Quit Smoking for Better Oral Health', body: 'Smoking stains teeth, causes bad breath, and greatly increases the risk of gum disease and oral cancer. Quitting protects your mouth and body.'),
  ];

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildTopSection()),
            SliverToBoxAdapter(child: _buildHabitsSection()),
            SliverToBoxAdapter(child: _buildExploreSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TOP SECTION — back button + title + featured card + ask button
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color:        Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:       Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: _textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Page title
          const Text(
            'Health tips',
            style: TextStyle(
              color:      _textDark,
              fontSize:   28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Featured card
          _buildFeaturedCard(),
          const SizedBox(height: 8),

          // Suggested label
          const Text(
            'Suggested for you',
            style: TextStyle(color: _textLight, fontSize: 12),
          ),
          const SizedBox(height: 12),

          // Ask button
          GestureDetector(
            onTap: () => _showAskDialog(context),
            child: Container(
              width:   double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color:        _dark,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Center(
                child: Text(
                  'Ask about any health topic',
                  style: TextStyle(
                    color:      Colors.white,
                    fontSize:   14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        _featured,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:        Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Featured tip',
                    style: TextStyle(
                      color:      _textMid,
                      fontSize:   10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Take Multivitamin Supplements',
                  style: TextStyle(
                    color:      _textDark,
                    fontSize:   16,
                    fontWeight: FontWeight.w700,
                    height:     1.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'To ensure sufficient nutrient levels, taking a daily multivitamin supplement is a great idea.',
                  style: TextStyle(
                    color:    _textMid,
                    fontSize: 12,
                    height:   1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Decorative shapes
          SizedBox(
            width: 72, height: 80,
            child: Stack(
              children: [
                Positioned(
                  top: 0, right: 0,
                  child: Transform.rotate(
                    angle: -0.26,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color:        const Color(0xFFA8C47A),
                        borderRadius: const BorderRadius.only(
                          topLeft:    Radius.circular(16),
                          topRight:   Radius.circular(0),
                          bottomLeft: Radius.circular(16),
                          bottomRight:Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6, left: 0,
                  child: Container(
                    width: 26, height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4E06A),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 18, left: 10,
                  child: Container(
                    width: 20, height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE88FAA),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2, right: 8,
                  child: Container(
                    width: 14, height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFF9EC8F0),
                      shape: BoxShape.circle,
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

  // ═══════════════════════════════════════════════════════════════
  //  HABITS SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHabitsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New habits for you',
            style: TextStyle(
              color:      _textDark,
              fontSize:   20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add these habits to your daily routine to improve your health.\nEach completed habit earns points toward your health score.',
            style: TextStyle(
              color:    _textMid,
              fontSize: 12.5,
              height:   1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_habits.length, (i) => _buildHabitCard(i)),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildHabitCard(int index) {
    final h       = _habits[index];
    final isAdded = _habitAdded[index];

    return Container(
      margin:  const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        h.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left accent strip
          Container(
            width: 5, height: 70,
            decoration: BoxDecoration(
              color:        h.strip,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.title,
                  style: TextStyle(
                    color:      h.titleC,
                    fontSize:   15,
                    fontWeight: FontWeight.w700,
                  )),
                const SizedBox(height: 2),
                Text(h.days,
                  style: TextStyle(
                    color:    h.daysC,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  )),
                const SizedBox(height: 6),
                Text(h.desc,
                  style: TextStyle(
                    color:    h.descC,
                    fontSize: 12,
                    height:   1.45,
                  )),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Add / Added button
                    GestureDetector(
                      onTap: () => setState(() => _habitAdded[index] = !isAdded),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color:        isAdded ? h.btnC : Colors.white,
                          shape:        BoxShape.circle,
                          border:       isAdded ? null : Border.all(
                              color: h.btnC.withOpacity(0.3), width: 1),
                        ),
                        child: Icon(
                          isAdded ? Icons.check_rounded : Icons.add_rounded,
                          color: isAdded ? Colors.white : h.btnC,
                          size:  18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Learn more button
                    GestureDetector(
                      onTap: () => _showCategoryDetail(
                          context, _explore.firstWhere(
                              (e) => e.tips.any((t) => t.title == h.title),
                              orElse: () => _explore[0])),
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color:  Colors.white.withOpacity(0.55),
                          shape:  BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_forward_ios_rounded,
                            color: h.btnC, size: 14),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isAdded ? 'Added to your habits' : 'Add to your habits',
                      style: TextStyle(
                        color:    h.daysC,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  EXPLORE SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildExploreSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore',
            style: TextStyle(
              color:      _textDark,
              fontSize:   20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount:     2,
            shrinkWrap:         true,
            physics:            const NeverScrollableScrollPhysics(),
            crossAxisSpacing:   12,
            mainAxisSpacing:    12,
            childAspectRatio:   1.55,
            children: _explore.map((cat) => _buildExploreCard(cat)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreCard(_ExploreCategory cat) {
    return GestureDetector(
      onTap: () => _showCategoryDetail(context, cat),
      child: Container(
        decoration: BoxDecoration(
          color:        cat.bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            // Decorative icon (watermark)
            Positioned(
              bottom: 6, right: 8,
              child: Icon(cat.icon,
                  size:  44,
                  color: _dark.withOpacity(0.08)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:        cat.pillColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(cat.label,
                      style: TextStyle(
                        color:      cat.pillText,
                        fontSize:   10,
                        fontWeight: FontWeight.w700,
                      )),
                  ),
                  const SizedBox(height: 8),
                  Text(cat.subtitle,
                    style: const TextStyle(
                      color:      _textMid,
                      fontSize:   11,
                      fontWeight: FontWeight.w500,
                    )),
                  const SizedBox(height: 2),
                  Text('${cat.tips.length} tips',
                    style: const TextStyle(
                      color:    _textLight,
                      fontSize: 11,
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  MODALS
  // ═══════════════════════════════════════════════════════════════

  void _showAskDialog(BuildContext context) {
    showModalBottomSheet(
      context:       context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color:        Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Ask a health question',
                style: TextStyle(
                  fontSize:   18,
                  fontWeight: FontWeight.w700,
                  color:      _textDark,
                )),
              const SizedBox(height: 16),
              _quickTopic('What foods are good during pregnancy?',  Icons.favorite_rounded,     Color(0xFF1565C0)),
              _quickTopic('How often should children be vaccinated?',Icons.child_care_rounded,  Color(0xFF2E7D32)),
              _quickTopic('How do I protect my eyes from screens?', Icons.visibility_rounded,   Color(0xFFE65100)),
              _quickTopic('Tips for stronger teeth and gums',       Icons.medical_services_rounded, Color(0xFFAD1457)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickTopic(String text, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        margin:  const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: color.withOpacity(0.20)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                style: TextStyle(
                  color:      color,
                  fontSize:   13,
                  fontWeight: FontWeight.w500,
                )),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.5), size: 12),
          ],
        ),
      ),
    );
  }

  void _showCategoryDetail(BuildContext context, _ExploreCategory cat) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        maxChildSize:     0.95,
        minChildSize:     0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 4),
                child: Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color:        Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color:        cat.bgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(cat.icon, color: cat.pillColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${cat.label} Health Tips',
                            style: const TextStyle(
                              fontSize:   17,
                              fontWeight: FontWeight.w700,
                              color:      _textDark,
                            )),
                          Text('${cat.tips.length} tips to improve your health',
                            style: const TextStyle(
                              fontSize: 12,
                              color:    _textLight,
                            )),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color:        Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close_rounded, size: 18, color: _textMid),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.grey[100], height: 1),
              // Tips list
              Expanded(
                child: ListView.builder(
                  controller:  scrollCtrl,
                  physics:     const BouncingScrollPhysics(),
                  padding:     const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  itemCount:   cat.tips.length,
                  itemBuilder: (_, i) => _ModalTipCard(
                    tip:    cat.tips[i],
                    index:  i + 1,
                    accent: cat.pillColor,
                    tint:   cat.bgColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MODAL TIP CARD  (expandable)
// ═══════════════════════════════════════════════════════════════════
class _ModalTipCard extends StatefulWidget {
  final _Tip  tip;
  final int   index;
  final Color accent;
  final Color tint;
  const _ModalTipCard({
    required this.tip,
    required this.index,
    required this.accent,
    required this.tint,
  });

  @override
  State<_ModalTipCard> createState() => _ModalTipCardState();
}

class _ModalTipCardState extends State<_ModalTipCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin:   const EdgeInsets.only(bottom: 10),
        padding:  const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(18),
          border:       Border.all(
            color: _expanded
                ? widget.accent.withOpacity(0.30)
                : Colors.grey.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset:     const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color:        widget.tint,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(widget.tip.icon, color: widget.accent, size: 20),
                ),
                Positioned(
                  top: -4, right: -4,
                  child: Container(
                    width: 17, height: 17,
                    decoration: BoxDecoration(
                      color: widget.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${widget.index}',
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   9,
                          fontWeight: FontWeight.w800,
                        )),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(widget.tip.title,
                          style: const TextStyle(
                            color:      Color(0xFF1A1A1A),
                            fontSize:   13.5,
                            fontWeight: FontWeight.w700,
                            height:     1.3,
                          )),
                      ),
                      AnimatedRotation(
                        turns:    _expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child:    Icon(Icons.keyboard_arrow_down_rounded,
                            color: widget.accent, size: 20),
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    firstChild:  const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(
                            color:     widget.accent.withOpacity(0.15),
                            thickness: 1,
                            height:    1,
                          ),
                          const SizedBox(height: 8),
                          Text(widget.tip.body,
                            style: const TextStyle(
                              color:    Color(0xFF555555),
                              fontSize: 12.5,
                              height:   1.55,
                            )),
                        ],
                      ),
                    ),
                    crossFadeState: _expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration:  const Duration(milliseconds: 220),
                    sizeCurve: Curves.easeOutCubic,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════════════════════════════

@immutable
class _Habit {
  final String title;
  final String days;
  final String desc;
  final Color  bgColor;
  final Color  strip;
  final Color  titleC;
  final Color  daysC;
  final Color  descC;
  final Color  btnC;
  const _Habit({
    required this.title,
    required this.days,
    required this.desc,
    required this.bgColor,
    required this.strip,
    required this.titleC,
    required this.daysC,
    required this.descC,
    required this.btnC,
  });
}

@immutable
class _ExploreCategory {
  final String     label;
  final String     subtitle;
  final IconData   icon;
  final Color      pillColor;
  final Color      pillText;
  final Color      bgColor;
  final List<_Tip> tips;
  const _ExploreCategory({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.pillColor,
    required this.pillText,
    required this.bgColor,
    required this.tips,
  });
}

@immutable
class _Tip {
  final IconData icon;
  final String   title;
  final String   body;
  const _Tip({required this.icon, required this.title, required this.body});
}