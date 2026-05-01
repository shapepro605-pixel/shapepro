import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shapepro/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Caminhos das imagens geradas (simulando assets de produção)
  final List<String> _imagePaths = [
    'C:/Users/mae12/.gemini/antigravity/brain/44b1f9e6-1720-486d-b153-bcd2b45f4041/premium_3d_scanner_1777599080404.png',
    'C:/Users/mae12/.gemini/antigravity/brain/44b1f9e6-1720-486d-b153-bcd2b45f4041/premium_3d_workout_1777599096034.png',
    'C:/Users/mae12/.gemini/antigravity/brain/44b1f9e6-1720-486d-b153-bcd2b45f4041/premium_3d_workout_1777599096034.png', // Reutilizando para exemplo
    'C:/Users/mae12/.gemini/antigravity/brain/44b1f9e6-1720-486d-b153-bcd2b45f4041/premium_3d_nutrition_1777599109154.png',
    'C:/Users/mae12/.gemini/antigravity/brain/44b1f9e6-1720-486d-b153-bcd2b45f4041/premium_3d_scanner_1777599080404.png', // Reutilizando scanner
    'C:/Users/mae12/.gemini/antigravity/brain/44b1f9e6-1720-486d-b153-bcd2b45f4041/premium_3d_trophy_1777599126166.png',
    'C:/Users/mae12/.gemini/antigravity/brain/44b1f9e6-1720-486d-b153-bcd2b45f4041/premium_3d_heart_1777599140761.png',
  ];

  List<TutorialStep> get _steps => [
    TutorialStep(
      title: (context) => AppLocalizations.of(context)!.tutorialHomeTitle,
      description: (context) => AppLocalizations.of(context)!.tutorialHomeDesc,
      imagePath: _imagePaths[0],
      color: const Color(0xFF6C5CE7),
    ),
    TutorialStep(
      title: (context) => AppLocalizations.of(context)!.tutorialWorkoutTitle,
      description: (context) => AppLocalizations.of(context)!.tutorialWorkoutDesc,
      imagePath: _imagePaths[1],
      color: const Color(0xFF00D2FF),
    ),
    TutorialStep(
      title: (context) => AppLocalizations.of(context)!.tutorialAICoachTitle,
      description: (context) => AppLocalizations.of(context)!.tutorialAICoachDesc,
      imagePath: _imagePaths[2],
      color: const Color(0xFF2ED573),
    ),
    TutorialStep(
      title: (context) => AppLocalizations.of(context)!.tutorialDietTitle,
      description: (context) => AppLocalizations.of(context)!.tutorialDietDesc,
      imagePath: _imagePaths[3],
      color: const Color(0xFFFFA502),
    ),
    TutorialStep(
      title: (context) => AppLocalizations.of(context)!.tutorialScannerTitle,
      description: (context) => AppLocalizations.of(context)!.tutorialScannerDesc,
      imagePath: _imagePaths[4],
      color: const Color(0xFFFF4757),
    ),
    TutorialStep(
      title: (context) => AppLocalizations.of(context)!.tutorialGamificationTitle,
      description: (context) => AppLocalizations.of(context)!.tutorialGamificationDesc,
      imagePath: _imagePaths[5],
      color: const Color(0xFFFFD32A),
    ),
    TutorialStep(
      title: (context) => AppLocalizations.of(context)!.tutorialWearablesTitle,
      description: (context) => AppLocalizations.of(context)!.tutorialWearablesDesc,
      imagePath: _imagePaths[6],
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
          color: Color(0xFF020205), // Fundo ainda mais profundo
        ),
        child: Stack(
          children: [
            // Background Glow Animado
            AnimatedContainer(
              duration: const Duration(seconds: 1),
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.7, -0.6),
                  radius: 1.2,
                  colors: [
                    steps[_currentPage].color.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Header Minimalista
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.tutorialTitle.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white24,
                            letterSpacing: 3,
                          ),
                        ),
                        TextButton(
                          onPressed: _finishTutorial,
                          child: Text(
                            l10n.later,
                            style: GoogleFonts.outfit(
                              color: Colors.white30,
                              fontSize: 13,
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
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Ilustração 3D Premium
                              Container(
                                height: 280,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: step.color.withOpacity(0.1),
                                      blurRadius: 50,
                                      spreadRadius: -10,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Image.file(
                                    File(step.imagePath),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ).animate(key: ValueKey('img$index'))
                                .fadeIn(duration: 800.ms)
                                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutCubic),
                              
                              const SizedBox(height: 60),
                              
                              Text(
                                step.title(context),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                  height: 1.1,
                                ),
                              ).animate(key: ValueKey('t$index'))
                                .fadeIn(delay: 200.ms)
                                .moveY(begin: 30, end: 0, curve: Curves.easeOutCubic),
                              
                              const SizedBox(height: 18),
                              
                              Text(
                                step.description(context),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  color: Colors.white54,
                                  height: 1.6,
                                  fontWeight: FontWeight.w400,
                                ),
                              ).animate(key: ValueKey('d$index'))
                                .fadeIn(delay: 400.ms)
                                .moveY(begin: 30, end: 0, curve: Curves.easeOutCubic),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Navegação e Progresso
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Indicadores Ultra-Thin
                        Row(
                          children: List.generate(steps.length, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              margin: const EdgeInsets.only(right: 6),
                              height: 4,
                              width: _currentPage == index ? 28 : 12,
                              decoration: BoxDecoration(
                                color: _currentPage == index 
                                  ? steps[index].color 
                                  : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),

                        // Botão de Ação Moderno
                        GestureDetector(
                          onTap: () {
                            if (_currentPage < steps.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOutQuart,
                              );
                            } else {
                              _finishTutorial();
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentPage == steps.length - 1 
                                      ? l10n.tutorialGetStarted
                                      : l10n.tutorialNext,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                      fontSize: 14,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.black),
                                ],
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
        ),
      ),
    );
  }
}

class TutorialStep {
  final String Function(BuildContext) title;
  final String Function(BuildContext) description;
  final String imagePath;
  final Color color;

  TutorialStep({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.color,
  });
}
