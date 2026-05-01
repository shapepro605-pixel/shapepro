import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shapepro/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<TutorialStep> get _steps => [
    TutorialStep(
      title: (context) => AppLocalizations.of(context)!.tutorialHomeTitle,
      description: (context) => AppLocalizations.of(context)!.tutorialHomeDesc,
      icon: Icons.dashboard_customize_rounded,
      color: const Color(0xFF6C5CE7),
    ),
    TutorialStep(
      title: (context) => AppLocalizations.of(context)!.tutorialWorkoutTitle,
      description: (context) => AppLocalizations.of(context)!.tutorialWorkoutDesc,
      icon: Icons.fitness_center_rounded,
      color: const Color(0xFF00D2FF),
    ),
    TutorialStep(
      title: (context) => AppLocalizations.of(context)!.tutorialAICoachTitle,
      description: (context) => AppLocalizations.of(context)!.tutorialAICoachDesc,
      icon: Icons.psychology_rounded,
      color: const Color(0xFF2ED573),
    ),
    TutorialStep(
      title: (context) => AppLocalizations.of(context)!.tutorialDietTitle,
      description: (context) => AppLocalizations.of(context)!.tutorialDietDesc,
      icon: Icons.restaurant_menu_rounded,
      color: const Color(0xFFFFA502),
    ),
    TutorialStep(
      title: (context) => AppLocalizations.of(context)!.tutorialScannerTitle,
      description: (context) => AppLocalizations.of(context)!.tutorialScannerDesc,
      icon: Icons.accessibility_new_rounded,
      color: const Color(0xFFFF4757),
    ),
    TutorialStep(
      title: (context) => AppLocalizations.of(context)!.tutorialGamificationTitle,
      description: (context) => AppLocalizations.of(context)!.tutorialGamificationDesc,
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFFFFD32A),
    ),
    TutorialStep(
      title: (context) => AppLocalizations.of(context)!.tutorialWearablesTitle,
      description: (context) => AppLocalizations.of(context)!.tutorialWearablesDesc,
      icon: Icons.watch_rounded,
      color: const Color(0xFF1E90FF),
    ),
  ];

  Future<void> _finishTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_tutorial', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = _steps;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A1A),
        ),
        child: Stack(
          children: [
            // Background Glow
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: steps[_currentPage].color.withOpacity(0.15),
                ),
              ).animate(target: _currentPage.toDouble()).blur(begin: 100, end: 100),
            ),

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.tutorialTitle,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white54,
                            letterSpacing: 1.5,
                          ),
                        ),
                        TextButton(
                          onPressed: _finishTutorial,
                          child: Text(
                            l10n.later.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: Colors.white38,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (idx) => setState(() => _currentPage = idx),
                      itemCount: steps.length,
                      itemBuilder: (context, index) {
                        final step = steps[index];
                        return Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Animated Icon Container
                              Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  color: step.color.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: step.color.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  step.icon,
                                  size: 80,
                                  color: step.color,
                                ),
                              ).animate(key: ValueKey(index))
                                .scale(duration: 600.ms, curve: Curves.backOut)
                                .shimmer(delay: 800.ms, duration: 1500.ms),
                              
                              const SizedBox(height: 50),
                              
                              Text(
                                step.title(context),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ).animate(key: ValueKey('t$index'))
                                .fadeIn(delay: 200.ms)
                                .moveY(begin: 20, end: 0),
                              
                              const SizedBox(height: 20),
                              
                              Text(
                                step.description(context),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  height: 1.5,
                                ),
                              ).animate(key: ValueKey('d$index'))
                                .fadeIn(delay: 400.ms)
                                .moveY(begin: 20, end: 0),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Footer
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Page Indicators
                        Row(
                          children: List.generate(steps.length, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(right: 8),
                              height: 8,
                              width: _currentPage == index ? 24 : 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index 
                                  ? steps[index].color 
                                  : Colors.white10,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),

                        // Action Button
                        GestureDetector(
                          onTap: () {
                            if (_currentPage < steps.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _finishTutorial();
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  steps[_currentPage].color,
                                  steps[_currentPage].color.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: steps[_currentPage].color.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentPage == steps.length - 1 
                                    ? l10n.tutorialGetStarted
                                    : l10n.tutorialNext,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
                              ],
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
        ),
      ),
    );
  }
}

class TutorialStep {
  final String Function(BuildContext) title;
  final String Function(BuildContext) description;
  final IconData icon;
  final Color color;

  TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
