import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shapepro/l10n/app_localizations.dart';

class ExerciseCard extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final int index;
  final Color accentColor;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.index,
    required this.accentColor,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final nome = ex['nome'] ?? '';
    final series = ex['series'] ?? 0;
    final reps = ex['repeticoes'] ?? '';
    final dicas = ex['dicas'] ?? '';
    final equipamento = ex['equipamento'] ?? '';
    final musculos = ex['musculos_trabalhados'] as List<dynamic>? ?? [];
    final dificuldade = ex['dificuldade'] ?? 'intermediario';

    return GestureDetector(
      onTap: _toggleExpand,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: _isExpanded
              ? widget.accentColor.withValues(alpha: 0.06)
              : const Color(0xFF16162A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isExpanded
                ? widget.accentColor.withValues(alpha: 0.3)
                : const Color(0xFF2A2A4A),
          ),
        ),
        child: Column(
          children: [
            // ── Main content ────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Exercise Image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E38),
                      borderRadius: BorderRadius.circular(12),
                      image: ex['imagem'] != null && ex['imagem'].toString().isNotEmpty
                          ? DecorationImage(
                              image: ex['imagem'].toString().startsWith('assets/')
                                  ? AssetImage(ex['imagem'])
                                  : NetworkImage(ex['imagem']) as ImageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: ex['imagem'] == null || ex['imagem'].toString().isEmpty
                        ? Icon(Icons.fitness_center, color: widget.accentColor.withValues(alpha: 0.5))
                        : null,
                  ),
                  const SizedBox(width: 14),
                  // Exercise info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nome, style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildTag(AppLocalizations.of(context)!.series(series.toString()), widget.accentColor),
                            const SizedBox(width: 6),
                            _buildTag(AppLocalizations.of(context)!.reps(reps.toString()), const Color(0xFF00D2FF)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Expand icon
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),

            // ── Expanded detail ─────────────────────────────
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: const Color(0xFF2A2A4A).withValues(alpha: 0.5), height: 1),
                    const SizedBox(height: 14),

                    // Difficulty
                    Row(
                      children: [
                        Icon(Icons.signal_cellular_alt, color: widget.accentColor, size: 16),
                        const SizedBox(width: 6),
                        Text('${AppLocalizations.of(context)!.difficulty}: ', style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 12,
                        )),
                        _buildDifficultyBadge(dificuldade),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Muscles
                    if (musculos.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.accessibility_new, color: widget.accentColor, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: musculos.map((m) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A4A),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(m.toString(), style: GoogleFonts.inter(
                                  color: Colors.white60, fontSize: 11,
                                )),
                              )).toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Equipment
                    if (equipamento.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.fitness_center, color: widget.accentColor, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(equipamento, style: GoogleFonts.inter(
                              color: Colors.white60, fontSize: 12,
                            )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Tips
                    if (dicas.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA502).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFA502).withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline, color: Color(0xFFFFA502), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(dicas, style: GoogleFonts.inter(
                                color: const Color(0xFFFFA502).withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              )),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color == Colors.white24 ? Colors.white38 : color,
      )),
    );
  }

  Widget _buildDifficultyBadge(String dificuldade) {
    Color color;
    String label;
    switch (dificuldade.toLowerCase()) {
      case 'iniciante':
        color = const Color(0xFF2ED573);
        label = AppLocalizations.of(context)!.beginner;
        break;
      case 'avancado':
        color = const Color(0xFFFD4556);
        label = AppLocalizations.of(context)!.advanced;
        break;
      default:
        color = const Color(0xFFFFA502);
        label = AppLocalizations.of(context)!.intermediate;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w700, color: color,
      )),
    );
  }
}
