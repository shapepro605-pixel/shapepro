import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChallengeActiveScreen extends StatefulWidget {
  final dynamic challenge;

  const ChallengeActiveScreen({super.key, required this.challenge});

  @override
  State<ChallengeActiveScreen> createState() => _ChallengeActiveScreenState();
}

class _ChallengeActiveScreenState extends State<ChallengeActiveScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.challenge['nome'] ?? 'Campeonato Ativo';
    final desc = widget.challenge['descricao'] ?? 'Siga as missões abaixo.';
    final xp = widget.challenge['pontos_xp'] ?? 500;
    final icon = widget.challenge['icone'] ?? '🏆';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00D2FF).withValues(alpha: 0.2),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Main View
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                expandedHeight: 280,
                floating: false,
                pinned: true,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C5CE7), Color(0xFF00D2FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C5CE7).withValues(alpha: 0.5),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Center(
                            child: Text(icon, style: const TextStyle(fontSize: 40)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            desc,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress Overview
                        _buildProgressGlassCard(xp),
                        const SizedBox(height: 30),
                        
                        Text(
                          "MISSÕES SEMANAIS",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white54,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tasks
                        _buildPremiumTaskTile(
                          icon: Icons.directions_run_rounded,
                          title: "Caminhar 5km",
                          subtitle: "Finalize antes de Domingo",
                          progressValue: 0.6,
                          xpReward: 100,
                          color: const Color(0xFF00D2FF),
                        ),
                        const SizedBox(height: 14),
                        _buildPremiumTaskTile(
                          icon: Icons.fitness_center_rounded,
                          title: "Treino de Alta Intensidade",
                          subtitle: "Concluir 2/3 da rotina semanal",
                          progressValue: 0.66,
                          xpReward: 250,
                          color: const Color(0xFFFF6B6B),
                        ),
                        const SizedBox(height: 14),
                        _buildPremiumTaskTile(
                          icon: Icons.water_drop_rounded,
                          title: "Meta de Hidratação",
                          subtitle: "Registrar 3L de Água por 7 dias",
                          progressValue: 1.0,  // Completed
                          xpReward: 150,
                          color: const Color(0xFF2ED573),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FadeTransition(
        opacity: _fadeAnimation,
        child: FloatingActionButton.extended(
          onPressed: () {
            // Action to log something quickly
          },
          backgroundColor: const Color(0xFF6C5CE7),
          elevation: 10,
          highlightElevation: 20,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.flash_on, color: Colors.white),
          label: Text("RESGATAR PONTOS", style: GoogleFonts.inter(
            fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13,
          )),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildProgressGlassCard(int totalXp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E38).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("SEU PROGRESSO", style: GoogleFonts.inter(
                    color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1
                  )),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text("65", style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900,
                      )),
                      Text("%", style: GoogleFonts.inter(
                        color: const Color(0xFF00D2FF), fontSize: 24, fontWeight: FontWeight.w900,
                      )),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD93D).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFFFFD93D), size: 18),
                    const SizedBox(width: 6),
                    Text("$totalXp XP", style: GoogleFonts.inter(
                      color: const Color(0xFFFFD93D), fontWeight: FontWeight.w800, fontSize: 13,
                    )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.65,
              minHeight: 12,
              backgroundColor: Color(0xFF14142D),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D2FF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTaskTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double progressValue,
    required int xpReward,
    required Color color,
  }) {
    final bool isCompleted = progressValue >= 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCompleted ? color.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.05),
          width: isCompleted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isCompleted ? color : color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isCompleted ? [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5))
              ] : null,
            ),
            child: Icon(
              isCompleted ? Icons.check_rounded : icon,
              color: isCompleted ? Colors.white : color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 6,
                    backgroundColor: const Color(0xFF1E1E38),
                    valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? color : color.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "+$xpReward",
            style: GoogleFonts.inter(
              color: isCompleted ? color : Colors.white24,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
