import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shapepro/l10n/app_localizations.dart';
import '../widgets/exercise_card.dart';
import 'workout_active.dart';

class WorkoutDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> treino;
  final Color accentColor;

  const WorkoutDetailsScreen({
    super.key,
    required this.treino,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final exercicios = treino['exercicios'] as List<dynamic>? ?? [];
    final nome = treino['nome'] ?? '';
    final tipo = treino['tipo'] ?? '';
    final tempo = treino['tempo_estimado'] ?? '--';
    final nivel = treino['nivel'] ?? 'intermediario';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF16162A),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF0A0A1A),
                      accentColor.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.fitness_center, color: accentColor, size: 40),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Treino $tipo',
                        style: GoogleFonts.inter(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: Text(
                nome,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
            ),
          ),

          // ── Stats ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(context, Icons.timer_outlined, tempo, "Tempo"),
                  _buildStat(context, Icons.format_list_numbered, '${exercicios.length}', AppLocalizations.of(context)!.exercises),
                  _buildStat(context, Icons.bar_chart, nivel.toUpperCase(), AppLocalizations.of(context)!.difficulty),
                ],
              ),
            ),
          ),

          // ── Start Button ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutActiveScreen(
                          treino: treino,
                          accentColor: accentColor,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_circle_filled, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.startWorkout.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Exercises Header ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
              child: Text(
                AppLocalizations.of(context)!.exercises,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // ── Exercises List ────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                  child: ExerciseCard(
                    exercise: exercicios[index],
                    index: index + 1,
                    accentColor: accentColor,
                  ),
                );
              },
              childCount: exercicios.length,
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white38, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
