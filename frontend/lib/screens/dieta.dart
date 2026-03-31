import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shapepro/l10n/app_localizations.dart';
import '../services/api.dart';
import '../widgets/upgrade_sheet.dart';
import 'workout_active.dart';

class DietaScreen extends StatefulWidget {
  const DietaScreen({super.key});

  @override
  State<DietaScreen> createState() => _DietaScreenState();
}

class _DietaScreenState extends State<DietaScreen> {
  Map<String, dynamic>? _dieta;
  bool _isLoading = true;
  bool _isGenerating = false;
  String _selectedObjetivo = 'manter';
  String _selectedRitmo = 'padrao';
  String _selectedOrcamento = 'padrao';
  List<dynamic> _treinosSincronizados = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final api = Provider.of<ApiService>(context, listen: false);
      setState(() {
        _selectedObjetivo = api.currentUser?['objetivo'] ?? 'manter';
        _selectedRitmo = api.currentUser?['ritmo_meta'] ?? 'padrao';
        _selectedOrcamento = api.currentUser?['orcamento'] ?? 'padrao';
      });
    });
    _loadDieta();
  }

  Future<void> _loadDieta() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final result = await api.getDietaAtiva();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _dieta = result['dieta'];
        }
      });
      if (result['success'] == true) {
        _loadTreinosSincronizados();
      }
    }
  }

  Future<void> _loadTreinosSincronizados() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final result = await api.getTreinos();
    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          _treinosSincronizados = result['treinos'] ?? [];
        }
      });
    }
  }

  Future<void> _gerarNovaDieta() async {
    setState(() => _isGenerating = true);
    final api = Provider.of<ApiService>(context, listen: false);

    // Save profile if things changed so the diet generator uses them
    if (_selectedObjetivo != api.currentUser?['objetivo'] || 
        _selectedRitmo != api.currentUser?['ritmo_meta'] ||
        _selectedOrcamento != api.currentUser?['orcamento']) {
      await api.updateProfile({
        'objetivo': _selectedObjetivo,
        'ritmo_meta': _selectedRitmo,
        'orcamento': _selectedOrcamento,
      });
    }

    final result = await api.gerarDieta(orcamento: _selectedOrcamento);
    if (mounted) {
      setState(() {
        _isGenerating = false;
        if (result['success'] == true) {
          _dieta = result['dieta'];
          _loadTreinosSincronizados();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text("${AppLocalizations.of(context)!.diet_generated} & Treinos atualizados!"),
              ],
            ),
            backgroundColor: const Color(0xFF2ED573),
            behavior: SnackBarBehavior.floating,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result['error'] ?? AppLocalizations.of(context)!.paymentError), // Using paymentError as a generic fallback error string if needed
            backgroundColor: const Color(0xFFFD4556),
          ));
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
            children: [
              // ── Header ──────────────────────────────────
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
                      child: Text(AppLocalizations.of(context)!.myDiet, style: GoogleFonts.inter(
                        fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white,
                      )),
                    ),
                    GestureDetector(
                      onTap: _isGenerating ? null : _gerarNovaDieta,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C5CE7), Color(0xFF00D2FF)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _isGenerating
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text(AppLocalizations.of(context)!.generate, style: GoogleFonts.inter(
                                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13,
                                  )),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildConfigSection(),
              // ── Content ─────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
                    : _dieta == null
                        ? _buildEmptyState()
                        : _buildDietaContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes, color: Color(0xFF00D2FF), size: 16),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.adjustRoute, style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
              )),
              const Spacer(),
              Text(AppLocalizations.of(context)!.changeBeforeGenerate, style: GoogleFonts.inter(
                fontSize: 10, color: Colors.white38,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildChip(AppLocalizations.of(context)!.dry, 'perder_peso', _selectedObjetivo, (v) => setState(() => _selectedObjetivo = v)),
              const SizedBox(width: 8),
              _buildChip(AppLocalizations.of(context)!.maintainWeight, 'manter', _selectedObjetivo, (v) => setState(() => _selectedObjetivo = v)),
              const SizedBox(width: 8),
              _buildChip(AppLocalizations.of(context)!.grow, 'ganhar_massa', _selectedObjetivo, (v) => setState(() => _selectedObjetivo = v)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildChip(AppLocalizations.of(context)!.healthy, 'leve', _selectedRitmo, (v) => setState(() => _selectedRitmo = v), icon: Icons.spa),
              const SizedBox(width: 8),
              _buildChip(AppLocalizations.of(context)!.standard, 'padrao', _selectedRitmo, (v) => setState(() => _selectedRitmo = v), icon: Icons.balance),
              const SizedBox(width: 8),
              _buildChip('${AppLocalizations.of(context)!.extreme}🔥', 'agressivo', _selectedRitmo, (v) => setState(() => _selectedRitmo = v), isExtreme: true),
            ],
          ),
          const SizedBox(height: 10),
          // --- Budget Section ---
          Row(
            children: [
               _buildChip('${AppLocalizations.of(context)!.economic} 💰', 'economico', _selectedOrcamento, (v) => setState(() => _selectedOrcamento = v)),
               const SizedBox(width: 8),
               _buildChip(AppLocalizations.of(context)!.standard, 'padrao', _selectedOrcamento, (v) => setState(() => _selectedOrcamento = v)),
               const SizedBox(width: 8),
               _buildChip('${AppLocalizations.of(context)!.premium} ✨', 'premium', _selectedOrcamento, (v) => setState(() => _selectedOrcamento = v), isPremium: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value, String groupValue, Function(String) onSelect, {IconData? icon, bool isExtreme = false, bool isPremium = false}) {
    final selected = value == groupValue;
    Color activeColor = isExtreme ? const Color(0xFFFD4556) : const Color(0xFF6C5CE7);
    if (isPremium) activeColor = const Color(0xFFFFD700); // Gold for premium
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? activeColor.withValues(alpha: 0.15) : const Color(0xFF1E1E38),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? activeColor : const Color(0xFF2A2A4A),
              width: selected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: selected ? activeColor : Colors.white54),
                const SizedBox(width: 4),
              ],
              Text(label, style: GoogleFonts.inter(
                fontSize: selected ? 11 : 10, 
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? (isExtreme ? const Color(0xFFFF6B6B) : Colors.white) : Colors.white54,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.restaurant_menu, color: Color(0xFF6C5CE7), size: 40),
            ),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context)!.noActiveDiet, style: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
            )),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.generatePersonalizedDiet,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _gerarNovaDieta,
              icon: const Icon(Icons.auto_awesome),
              label: Text(AppLocalizations.of(context)!.generateMyDiet, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietaContent() {
    final calorias = (_dieta!['calorias_totais'] as num?)?.toDouble() ?? 0;
    final proteinas = (_dieta!['proteinas_g'] as num?)?.toDouble() ?? 0;
    final carboidratos = (_dieta!['carboidratos_g'] as num?)?.toDouble() ?? 0;
    final gorduras = (_dieta!['gorduras_g'] as num?)?.toDouble() ?? 0;
    final refeicoes = _dieta!['refeicoes'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Macros donut chart ───────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF16162A),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF2A2A4A)),
            ),
            child: Column(
              children: [
                Text(AppLocalizations.of(context)!.dailySummary, style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
                )),
                const SizedBox(height: 20),
                SizedBox(
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 55,
                          sections: [
                            PieChartSectionData(
                              value: proteinas * 4,
                              color: const Color(0xFF00D2FF),
                              radius: 25,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: carboidratos * 4,
                              color: const Color(0xFFFFA502),
                              radius: 25,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: gorduras * 9,
                              color: const Color(0xFF6C5CE7),
                              radius: 25,
                              showTitle: false,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${calorias.toInt()}', style: GoogleFonts.inter(
                            fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white,
                          )),
                          Text('kcal', style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.white54,
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMacroLegend(AppLocalizations.of(context)!.proteins, '${proteinas.toInt()}g', const Color(0xFF00D2FF)),
                    _buildMacroLegend(AppLocalizations.of(context)!.carbs, '${carboidratos.toInt()}g', const Color(0xFFFFA502)),
                    _buildMacroLegend(AppLocalizations.of(context)!.fats, '${gorduras.toInt()}g', const Color(0xFF6C5CE7)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Meals ───────────────────────────────────
          Text(AppLocalizations.of(context)!.meals, style: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
          )),
          const SizedBox(height: 14),

          ...refeicoes.asMap().entries.map((entry) {
            final refeicao = entry.value as Map<String, dynamic>;
            return _buildRefeicaoCard(refeicao, entry.key);
          }),

          const SizedBox(height: 30),

          // ── Treinos Sincronizados ──────────────────────────────
          if (_treinosSincronizados.isNotEmpty) ...[
            Text('Treinos Sugeridos', style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
            )),
            const SizedBox(height: 6),
            Text('Planejados especialmente para seu objetivo (IA).', style: GoogleFonts.inter(
              fontSize: 13, color: Colors.white54,
            )),
            const SizedBox(height: 14),
            _buildTreinosSincronizadosList(),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  Widget _buildTreinosSincronizadosList() {
    final treinoColors = {
      'A': const Color(0xFF6C5CE7),
      'B': const Color(0xFF00D2FF),
      'C': const Color(0xFFFF6B6B),
      'D': const Color(0xFFFFA502),
      'E': const Color(0xFF2ED573),
    };

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _treinosSincronizados.length,
        itemBuilder: (context, index) {
          final treino = _treinosSincronizados[index];
          final tipo = treino['tipo'] ?? '';
          final color = treinoColors[tipo] ?? const Color(0xFF6C5CE7);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutActiveScreen(
                    treino: treino,
                    accentColor: color,
                  ),
                ),
              );
            },
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16162A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Treino $tipo', style: GoogleFonts.inter(
                      color: color, fontWeight: FontWeight.w800, fontSize: 13,
                    )),
                  ),
                  const SizedBox(height: 12),
                  Text(treino['nome'] ?? '', style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13, height: 1.2,
                  ), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Text(treino['tempo_estimado'] ?? '', style: GoogleFonts.inter(
                        color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500,
                      )),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMacroLegend(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
            )),
            Text(label, style: GoogleFonts.inter(
              fontSize: 11, color: Colors.white54,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildRefeicaoCard(Map<String, dynamic> refeicao, int index) {
    final nome = refeicao['nome'] ?? '';
    final horario = refeicao['horario'] ?? '';
    final alimentos = refeicao['alimentos'] as List<dynamic>? ?? [];
    final totalCal = refeicao['total_calorias'] ?? 0;

    // ── Padlock Logic ──
    final api = Provider.of<ApiService>(context, listen: false);
    final isTrial = api.currentUser?['is_trial'] ?? false;
    
    // Parse time to check if it's before 12:00
    bool isLocked = false;
    if (isTrial) {
      try {
        final hour = int.parse(horario.split(':')[0]);
        if (hour > 12) isLocked = true; // Lock meals after lunch (lanche, jantar, ceia)
      } catch (_) {}
    }

    final icons = [
      Icons.free_breakfast,
      Icons.apple,
      Icons.lunch_dining,
      Icons.coffee,
      Icons.dinner_dining,
      Icons.nightlight_round,
    ];

    final colors = [
      const Color(0xFFFFA502),
      const Color(0xFF2ED573),
      const Color(0xFFFF6B6B),
      const Color(0xFF00D2FF),
      const Color(0xFF6C5CE7),
      const Color(0xFFA29BFE),
    ];

    final accentColor = colors[index % colors.length];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isLocked ? Colors.white10 : const Color(0xFF2A2A4A)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Opacity(
          opacity: isLocked ? 0.6 : 1.0,
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            leading: Stack(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icons[index % icons.length], color: accentColor, size: 22),
                ),
                if (isLocked)
                  Positioned(
                    right: -2, bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A1A),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.lock_rounded, color: Color(0xFFFFD700), size: 14),
                    ),
                  ),
              ],
            ),
            title: Text(nome, style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, color: Colors.white, fontSize: 15,
            )),
            subtitle: Row(
              children: [
                Text(horario, style: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 12,
                )),
                const SizedBox(width: 12),
                Text('$totalCal kcal', style: GoogleFonts.inter(
                  color: accentColor, fontSize: 12, fontWeight: FontWeight.w600,
                )),
              ],
            ),
            trailing: isLocked 
              ? Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.lock_rounded, color: Color(0xFFFFD700), size: 16),
                )
              : null,
            onExpansionChanged: (expanded) {
              if (expanded && isLocked) {
                // Prevent expanding and show upgrade sheet
                showUpgradeSheet(context);
              }
            },
            iconColor: Colors.white38,
            collapsedIconColor: Colors.white38,
            children: isLocked ? [] : alimentos.map((alimento) {
              final a = alimento as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(a['nome'] ?? '', style: GoogleFonts.inter(
                        color: Colors.white70, fontSize: 13,
                      )),
                    ),
                    Text(a['porcao'] ?? '', style: GoogleFonts.inter(
                      color: Colors.white38, fontSize: 12,
                    )),
                    const SizedBox(width: 10),
                    Text('${a['calorias'] ?? 0} kcal', style: GoogleFonts.inter(
                      color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600,
                    )),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

}
