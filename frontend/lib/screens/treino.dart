import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/api.dart';
import '../widgets/exercise_card.dart';
import 'workout_active.dart';

class TreinoScreen extends StatefulWidget {
  const TreinoScreen({super.key});

  @override
  State<TreinoScreen> createState() => _TreinoScreenState();
}

class _TreinoScreenState extends State<TreinoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _treinos = [];
  bool _isLoading = true;
  String _selectedTreino = 'A';

  final _treinoColors = {
    'A': const Color(0xFF6C5CE7),
    'B': const Color(0xFF00D2FF),
    'C': const Color(0xFFFF6B6B),
    'D': const Color(0xFFFFA502),
    'E': const Color(0xFF2ED573),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTreino = ['A', 'B', 'C', 'D', 'E'][_tabController.index];
        });
      }
    });
    _loadTreinos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTreinos() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final result = await api.getTreinos();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _treinos = result['treinos'] ?? [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A1A), Color(0xFF12122A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E38),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(AppLocalizations.of(context)!.treinos, style: GoogleFonts.inter(
                        fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white,
                      )),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _treinoColors[_selectedTreino]!.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.treinoNum(_selectedTreino),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: _treinoColors[_selectedTreino],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tab bar ─────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E38),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        _treinoColors[_selectedTreino]!,
                        _treinoColors[_selectedTreino]!.withOpacity(0.7),
                      ],
                    ),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                  unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 15),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'A'),
                    Tab(text: 'B'),
                    Tab(text: 'C'),
                    Tab(text: 'D'),
                    Tab(text: 'E'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Content ─────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
                    : TabBarView(
                        controller: _tabController,
                        children: List.generate(5, (i) => _buildTreinoTab(i)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTreinoTab(int index) {
    if (index >= _treinos.length) {
      return Center(child: Text(AppLocalizations.of(context)!.treinoNotAvailable,
          style: GoogleFonts.inter(color: Colors.white54)));
    }

    final treino = _treinos[index];
    final exercicios = treino['exercicios'] as List<dynamic>? ?? [];
    final tipo = treino['tipo'] ?? '';
    final nome = treino['nome'] ?? '';
    final tempo = treino['tempo_estimado'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _treinoColors[tipo]!.withOpacity(0.15),
                  _treinoColors[tipo]!.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _treinoColors[tipo]!.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: _treinoColors[tipo], size: 20),
                const SizedBox(width: 8),
                Text(tempo, style: GoogleFonts.inter(
                  color: _treinoColors[tipo], fontWeight: FontWeight.w600, fontSize: 13,
                )),
                const SizedBox(width: 18),
                Icon(Icons.format_list_numbered, color: _treinoColors[tipo], size: 20),
                const SizedBox(width: 8),
                Text('${exercicios.length} ${AppLocalizations.of(context)!.exercises}', style: GoogleFonts.inter(
                  color: _treinoColors[tipo], fontWeight: FontWeight.w600, fontSize: 13,
                )),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _treinoColors[tipo]!.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(nome, style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600,
                  )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // COMEÇAR TREINO BUTTON
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutActiveScreen(
                      treino: _treinos[index],
                      accentColor: _treinoColors[tipo] ?? const Color(0xFF6C5CE7),
                    ),
                  ),
                );
                // When coming back, maybe reload something if needed
                // _loadTreinos(); // usually static though
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _treinoColors[tipo] ?? const Color(0xFF6C5CE7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.startWorkout, style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Exercises list
          ...exercicios.asMap().entries.map((entry) {
            final ex = entry.value as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ExerciseCard(
                exercise: ex,
                index: entry.key + 1,
                accentColor: _treinoColors[tipo] ?? const Color(0xFF6C5CE7),
              ),
            );
          }),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
