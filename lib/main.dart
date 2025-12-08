import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'generate_letter_page.dart';

const Color primaryBlue = Color(0xFF1E88E5);
const Color highlightYellow = Color(0xFFFFC107);
const Color backgroundWhite = Colors.white;

void main() {
  runApp(const OleraApp());
}

class OleraApp extends StatelessWidget {
  const OleraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Olera – Recommendation Letter Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundWhite,
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundWhite,
          elevation: 2,
          titleTextStyle: TextStyle(
            color: primaryBlue,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
          iconTheme: IconThemeData(color: primaryBlue),
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
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Determine greeting based on current hour
  String _getDynamicGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.description_outlined, size: 30),
            SizedBox(width: 10),
            Text(
              'Olera',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated Welcome Message with Dynamic Greeting
            FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hello,',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_getDynamicGreeting()}!',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Generate professional recommendation letters\nin seconds with perfect formatting.',
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Live Clock with Smooth Updates
            Center(
              child: StreamBuilder<DateTime>(
                stream: Stream.periodic(
                    const Duration(seconds: 1), (_) => DateTime.now()),
                builder: (context, snapshot) {
                  final now = snapshot.data ?? DateTime.now();
                  final timeString = DateFormat('HH:mm:ss').format(now);
                  final dateString =
                      DateFormat('EEEE, MMMM d, yyyy').format(now);

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: Container(
                      key: ValueKey(timeString),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 24),
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: highlightYellow, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withAlpha(77),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeString,
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              letterSpacing: 3,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dateString,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 60),

            // Start Generating Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GenerateLetterPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle, size: 32),
              label: const Text(
                'Start Generating Letter',
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: highlightYellow,
                foregroundColor: Colors.black87,
                minimumSize: const Size(double.infinity, 70),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 10,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),

            const Spacer(),

            // Footer Information
            const Center(
              child: Text(
                'Version 1.0 • CyberSecurity Research LAB\n'
                'Dept. of Computer Science and Engineering (CSE), Jashore University of Science and Technology (JUST)\n'
                'Email: n.amin@just.edu.bd • Phone: +880 01714-492550\n'
                'Kazi Nazrul Academic Building, Room NO: 227, Jashore-7408, Bangladesh',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}