import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rmpdf/student_work_tracker.dart';
import 'generate_letter_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Professional Dark Blue Color Palette
const Color primaryNavy = Color(0xFF0F1C3F);
const Color deepBlue = Color(0xFF1A2B5C);
const Color royalBlue = Color(0xFF2A4B8C);
const Color skyBlue = Color(0xFF4A7BD9);
const Color accentGold = Color(0xFFD4AF37);
const Color lightGold = Color(0xFFFFE8A3);
const Color cardSurface = Color(0xFFFFFFFF);
const Color bgLight = Color(0xFFF8FAFF);
const Color textPrimary = Color(0xFF1A237E);
const Color textSecondary = Color(0xFF5A6B8C);
const Color sidebarBg = Color(0xFFFFFFFF);
const Color sidebarBorder = Color(0xFFE8EAF6);

void main() {
  runApp(const OleraApp());
}

class OleraApp extends StatelessWidget {
  const OleraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSRL – Cyber Security Research Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        primaryColor: primaryNavy,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryNavy,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: bgLight,
        appBarTheme: AppBarTheme(
          backgroundColor: cardSurface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: primaryNavy,
            letterSpacing: -0.3,
          ),
          iconTheme: const IconThemeData(color: primaryNavy),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: cardSurface,
          surfaceTintColor: Colors.transparent,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: royalBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const OleraHomePage(),
    );
  }
}

class OleraHomePage extends StatefulWidget {
  const OleraHomePage({super.key});

  @override
  State<OleraHomePage> createState() => _OleraHomePageState();
}

class _OleraHomePageState extends State<OleraHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _slideUp;
  bool _isSidebarVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _slideUp = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return '🌅';
    if (hour >= 12 && hour < 17) return '☀️';
    if (hour >= 17 && hour < 21) return '🌆';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Row(
        children: [
          // Main Content Area
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting Section
                    _buildGreetingSection(),
                    const SizedBox(height: 32),

                    // Live Time Display with Boxed Design
                    _buildTimeSection(),
                    const SizedBox(height: 40),

                    // Quick Stats
                    _buildStatsSection(),
                    const SizedBox(height: 40),

                    // Main Actions
                    _buildActionCards(),
                    const SizedBox(height: 60),

                    // Footer
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),

          // Sidebar Toggle Button
          if (!_isSidebarVisible)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton.small(
                    onPressed: () {
                      setState(() {
                        _isSidebarVisible = true;
                      });
                    },
                    backgroundColor: royalBlue,
                    child: const Icon(Icons.chevron_left, color: Colors.white),
                  ),
                ],
              ),
            ),

          // Right Sidebar
          if (_isSidebarVisible)
            Container(
              width: 320,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: sidebarBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: sidebarBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 30,
                    offset: const Offset(-5, 0),
                  ),
                ],
              ),
              child: _buildSidebarContent(),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar Header with Close Button
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryNavy,
                ),
              ),
              IconButton(
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primaryNavy.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close, size: 18),
                ),
                onPressed: () {
                  setState(() {
                    _isSidebarVisible = false;
                  });
                },
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: sidebarBorder),

        // University Logo Section
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sidebarBorder),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTcNl2v55ROw-DZ9Kw7P8oYT1Xirbie2DJCvw&s',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.account_balance, size: 40, color: Colors.grey),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.account_balance, size: 40, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Jashore University of Science and Technology',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CyberSecurity Research LAB',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Quick Action Buttons
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildQuickActionButton(
                  icon: Icons.add,
                  title: 'Generate Letter',
                  subtitle: 'Create from scratch',
                  color: royalBlue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GenerateLetterPage(),
                      ),
                    );
                  },
                ),
                // const SizedBox(height: 12),
                // _buildQuickActionButton(
                //   icon: Icons.content_copy,
                //   title: 'Use Template',
                //   subtitle: 'Pre-designed formats',
                //   color: const Color(0xFF7C4DFF),
                //   onTap: () {},
                // ),
                // const SizedBox(height: 12),
                // _buildQuickActionButton(
                //   icon: Icons.history,
                //   title: 'Recent Letters',
                //   subtitle: 'View past 10 entries',
                //   color: const Color(0xFF00B894),
                //   onTap: () {},
                // ),
                // const SizedBox(height: 12),
                // _buildQuickActionButton(
                //   icon: Icons.download,
                //   title: 'Export Data',
                //   subtitle: 'PDF, Word, Excel',
                //   color: const Color(0xFFFD79A8),
                //   onTap: () {},
                // ),
                const SizedBox(height: 12),
                _buildQuickActionButton(
                  icon: Icons.groups,
                  title: 'Student List',
                  subtitle: 'Manage all students',
                  color: const Color(0xFFFDCB6E),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentWorkTracker(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildQuickActionButton(
                  icon: Icons.settings,
                  title: 'Settings',
                  subtitle: 'Customize preferences',
                  color: const Color(0xFF636E72),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),

        // Sidebar Footer
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: sidebarBorder)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: accentGold,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tip of the Day',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primaryNavy,
                          ),
                        ),
                        Text(
                          'Use this app to track student work progress and to generate recommendation letters faster.',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryNavy.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Storage:',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 0.24,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: skyBlue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: textSecondary.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [royalBlue, skyBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CSRL'),
              Text(
                'Cyber Security Research LAB',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryNavy.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_none, size: 22),
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isSidebarVisible ? royalBlue.withOpacity(0.1) : primaryNavy.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _isSidebarVisible ? Icons.menu_open : Icons.menu,
              color: _isSidebarVisible ? royalBlue : textSecondary,
              size: 22,
            ),
          ),
          onPressed: () {
            setState(() {
              _isSidebarVisible = !_isSidebarVisible;
            });
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildGreetingSection() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, _slideUp.value),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getGreetingIcon(),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Good ${_getGreetingIcon() == '🌅' ? 'Morning' : _getGreetingIcon() == '☀️' ? 'Afternoon' : _getGreetingIcon() == '🌆' ? 'Evening' : 'Night'}, Professor',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'WELCOME TO\nCYBER SECURITY RESEARCH LAB',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: primaryNavy,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Professional tools for recommendation letters and student tracking. '
                  'Streamline your academic workflow with precision.',
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [deepBlue, primaryNavy],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: primaryNavy.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.schedule,
                  color: lightGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'LIVE TIME - DHAKA UTC+6',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: lightGold.withOpacity(0.9),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            StreamBuilder<DateTime>(
              stream: Stream.periodic(
                const Duration(seconds: 1),
                (_) => DateTime.now(),
              ),
              builder: (context, snapshot) {
                final now = snapshot.data ?? DateTime.now();
                return Column(
                  children: [
                    // Time Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TimeBox(
                          value: DateFormat('hh').format(now),
                          label: 'HOURS',
                          isActive: true,
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          ':',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w300,
                            color: lightGold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        _TimeBox(
                          value: DateFormat('mm').format(now),
                          label: 'MINUTES',
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          ':',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w300,
                            color: lightGold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        _TimeBox(
                          value: DateFormat('ss').format(now),
                          label: 'SECONDS',
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          ':',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w300,
                            color: lightGold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        _TimeBox(
                          value: DateFormat('a').format(now),
                          label: 'AM/PM',
                        ),
                        
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Date Display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(now),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.rocket_launch_outlined,
            value: '30s',
            label: 'Letter Generation',
            color: skyBlue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.verified_outlined,
            value: '100%',
            label: 'Professional Quality',
            color: accentGold,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.track_changes_outlined,
            value: '∞',
            label: 'Student Tracking',
            color: const Color(0xFF7C4DFF),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCards() {
    return Column(
      children: [
        // Main Action Card
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GenerateLetterPage(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [royalBlue.withOpacity(0.9), skyBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.edit_document,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Generate Letter',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create recommendation letters',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Secondary Action Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentWorkTracker(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Student Tracker',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Monitor and manage student progress',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: textSecondary.withOpacity(0.6),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryNavy.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: royalBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CyberSecurity Research LAB',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Dept. of Computer Science & Engineering',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFE8EAF6)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _ContactChip(
                  icon: Icons.email_outlined,
                  text: 'n.amin@just.edu.bd',
                ),
                _ContactChip(
                  icon: Icons.phone_outlined,
                  text: '+880 01714-492550',
                ),
                _ContactChip(
                  icon: Icons.location_on_outlined,
                  text: 'Room 227, Kazi Nazrul Islam Academic Building',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Jashore University of Science and Technology (JUST)\n'
              'Jashore-7408, Bangladesh',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'CSRL v1.0 • Powered by Cyber Security Research LAB',
              style: TextStyle(
                fontSize: 11,
                color: textSecondary.withOpacity(0.7),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String value;
  final String label;
  final bool isActive;

  const _TimeBox({
    required this.value,
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: isActive ? accentGold : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? accentGold : Colors.white.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: accentGold.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w700,
                color: isActive ? primaryNavy : Colors.white,
                fontFamily: 'Roboto Mono',
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.8),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: primaryNavy.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: royalBlue,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}