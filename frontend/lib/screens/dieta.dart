import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shapepro/l10n/app_localizations.dart';
import '../services/api.dart';
import '../services/notification_service.dart';
import '../widgets/upgrade_sheet.dart';
import '../utils/currency_helper.dart';
import 'workout_details.dart';

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
          
          // Re-schedule notifications on load
          NotificationService.scheduleDietNotifications(_dieta?['refeicoes'] ?? []);
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
    final l10n = AppLocalizations.of(context);

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
          
          // Re-schedule notifications for the new diet
          NotificationService.scheduleDietNotifications(_dieta?['refeicoes'] ?? []);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text("${l10n?.diet_generated ?? ''} & ${l10n?.trainingCoordination ?? ''}"),
              ],
            ),
            backgroundColor: const Color(0xFF2ED573),
            behavior: SnackBarBehavior.floating,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result['error'] ?? AppLocalizations.of(context)?.paymentError ?? 'Erro'),
            backgroundColor: const Color(0xFFFD4556),
          ));
        }
      });
    }
  }

  void _showPriceDialog(String foodName) {
    final TextEditingController priceController = TextEditingController();
    final api = Provider.of<ApiService>(context, listen: false);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(l10n.reportPrice, style: GoogleFonts.inter(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.howMuchDoesThisCost, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixText: '${CurrencyHelper.getSymbol(api.currentUser?['moeda'])} ',
                hintText: l10n.pricePlaceholder,
                hintStyle: const TextStyle(color: Colors.white24),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceController.text.replaceAll(',', '.'));
              if (price != null) {
                final city = api.currentUser?['cidade'] ?? 'N/A';
                await api.reportFoodPrice(foodName: foodName, price: price, city: city);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l10n.priceReported),
                    backgroundColor: const Color(0xFF2ED573),
                  ));
                }
              }
            },
            child: Text(l10n.savePrice),
          ),
        ],
      ),
    );
  }

  void _showSubstitutionModal(Map<String, dynamic> alimentoAtual, int mealIndex, int foodIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return FutureBuilder<Map<String, dynamic>>(
              future: Provider.of<ApiService>(context, listen: false).sugerirSubstituicao(
                alimentoAtual: alimentoAtual['nome'] ?? '',
                caloriasAtual: (alimentoAtual['calorias'] as num).toDouble(),
                precoAtual: (alimentoAtual['preco_num'] as num?)?.toDouble() ?? 0.0,
              ),
              builder: (context, snapshot) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16162A),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb_outline, color: Color(0xFFFFD700), size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Substituição Inteligente", style: GoogleFonts.inter(
                                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700,
                                  )),
                                  const SizedBox(height: 4),
                                  Text("Economize mantendo suas calorias", style: GoogleFonts.inter(
                                    color: Colors.white54, fontSize: 13,
                                  )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF2ED573))))
                      else if (snapshot.hasError || snapshot.data?['success'] == false || snapshot.data?['sugestoes'] == null || (snapshot.data?['sugestoes'] as List).isEmpty)
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                "Nenhuma alternativa mais barata encontrada na base para este alimento no momento.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(color: Colors.white54, fontSize: 15),
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                            itemCount: (snapshot.data!['sugestoes'] as List).length,
                            itemBuilder: (context, idx) {
                              final sug = snapshot.data!['sugestoes'][idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E38),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF2A2A4A)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("${sug['nome']} (${sug['porcao_str']})", style: GoogleFonts.inter(
                                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16,
                                    )),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text("${sug['calorias']} kcal", style: GoogleFonts.inter(
                                          color: const Color(0xFF2ED573), fontSize: 14, fontWeight: FontWeight.w600,
                                        )),
                                        const SizedBox(width: 8),
                                        Text("•  💰 ${sug['preco_str']}", style: GoogleFonts.inter(
                                          color: Colors.white70, fontSize: 14,
                                        )),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2ED573).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.savings, color: Color(0xFF2ED573), size: 14),
                                              const SizedBox(width: 6),
                                              Text("Economia: ${sug['economia_str']}", style: GoogleFonts.inter(
                                                color: const Color(0xFF2ED573), fontSize: 12, fontWeight: FontWeight.w600,
                                              )),
                                            ],
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF6C5CE7),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          onPressed: () {
                                            _aplicarSubstituicao(mealIndex, foodIndex, sug);
                                            Navigator.pop(context);
                                          },
                                          child: Text("Trocar", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _aplicarSubstituicao(int mealIndex, int foodIndex, Map<String, dynamic> novaOpcao) {
    if (_dieta == null) return;
    setState(() {
      final refeicoes = _dieta!['refeicoes'] as List;
      final meal = refeicoes[mealIndex];
      final alimentos = meal['alimentos'] as List;
      
      final oldFood = alimentos[foodIndex];
      final oldCal = (oldFood['calorias'] as num).toDouble();
      
      final novoAlimento = {
        'nome': novaOpcao['nome'],
        'porcao': novaOpcao['porcao_str'],
        'calorias': novaOpcao['calorias'],
        'preco_num': novaOpcao['preco_num'],
        'proteina': novaOpcao['proteina'],
        'carboidrato': novaOpcao['carboidrato'],
        'gordura': novaOpcao['gordura'],
      };
      
      // Update the food in the list
      alimentos[foodIndex] = novoAlimento;
      
      // Update meal calories
      final diffCal = novaOpcao['calorias'] - oldCal;
      meal['total_calorias'] = ((meal['total_calorias'] as num) + diffCal).round();
      
      // Update diet total macros/calories (optional, but good for UX)
      _dieta!['calorias_totais'] = ((_dieta!['calorias_totais'] as num) + diffCal).round();
      
      if (novaOpcao['proteina'] != null && oldFood['proteina'] != null) {
        _dieta!['proteinas_g'] = ((_dieta!['proteinas_g'] as num) + (novaOpcao['proteina'] - oldFood['proteina'])).round();
      }
      if (novaOpcao['carboidrato'] != null && oldFood['carboidrato'] != null) {
        _dieta!['carboidratos_g'] = ((_dieta!['carboidratos_g'] as num) + (novaOpcao['carboidrato'] - oldFood['carboidrato'])).round();
      }
      if (novaOpcao['gordura'] != null && oldFood['gordura'] != null) {
        _dieta!['gorduras_g'] = ((_dieta!['gorduras_g'] as num) + (novaOpcao['gordura'] - oldFood['gordura'])).round();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Substituído com sucesso! Economia aplicada."),
        backgroundColor: const Color(0xFF2ED573),
      ));
    });
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
              Row(
                children: [
                   const Icon(Icons.info_outline, color: Colors.white38, size: 14),
                   const SizedBox(width: 6),
                   Text(
                     AppLocalizations.of(context)!.approximateValues,
                     style: GoogleFonts.inter(fontSize: 11, color: Colors.white38, fontStyle: FontStyle.italic),
                   ),
                ],
              ),
              const SizedBox(height: 24),

              if (_dieta?['projecao_30d'] != null) ...[
                _buildProjectionCard(),
                const SizedBox(height: 24),
              ],

              // ── Meals ───────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.meals, style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
              )),
              Builder(
                builder: (context) {
                  String displayTotal = '';
                  if (_dieta?['preco_total_diario_str'] != null) {
                    displayTotal = _dieta!['preco_total_diario_str'];
                  } else {
                    // Fallback calculate
                    final cur = Provider.of<ApiService>(context, listen: false).currentUser?['moeda'] ?? 'BRL';
                    double total = 0;
                    final refs = _dieta?['refeicoes'] as List? ?? [];
                    for (var r in refs) {
                      final alim = r['alimentos'] as List? ?? [];
                      for (var a in alim) {
                        total += (a['preco_num'] as num?)?.toDouble() ?? 0;
                      }
                    }
                    if (total > 0) displayTotal = CurrencyHelper.format(total, cur);
                  }
                  if (displayTotal.isEmpty) return const SizedBox.shrink();
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ED573).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2ED573).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.savings_outlined, color: Color(0xFF2ED573), size: 14),
                        const SizedBox(width: 6),
                        Text("Valor de hoje: $displayTotal", style: GoogleFonts.inter(
                          color: const Color(0xFF2ED573), fontSize: 12, fontWeight: FontWeight.w700,
                        )),
                      ],
                    ),
                  );
                }
              ),
            ],
          ),
          const SizedBox(height: 14),

          ...refeicoes.asMap().entries.map((entry) {
            final refeicao = entry.value as Map<String, dynamic>;
            return _buildRefeicaoCard(refeicao, entry.key);
          }),

          const SizedBox(height: 24),
          _buildBudgetSummary(),
          const SizedBox(height: 24),

          const SizedBox(height: 30),

          // ── Treinos Sincronizados ──────────────────────────────
          if (_treinosSincronizados.isNotEmpty) ...[
            Text(AppLocalizations.of(context)!.suggestedWorkouts, style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
            )),
            const SizedBox(height: 6),
            Text(AppLocalizations.of(context)!.suggestedWorkoutsDesc, style: GoogleFonts.inter(
              fontSize: 13, color: Colors.white54,
            )),
            const SizedBox(height: 14),
            _buildTreinosSincronizadosList(),
            const SizedBox(height: 30),
          ],
          
          if (_dieta?['projecao_30d'] != null) ...[
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => _showMonthResultModal(context),
                icon: const Icon(Icons.emoji_events, color: Colors.white),
                label: Text(
                  'Registrar Resultado de 30 Dias',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectionCard() {
    final proj = _dieta?['projecao_30d'];
    if (proj == null) return const SizedBox.shrink();

    final perdaKg = (proj['perda_estimada_kg'] as num?)?.toDouble() ?? 0.0;
    final aguaMl = _dieta?['agua_recomendada_ml']?.toString() ?? '2500';
    final fibraG = _dieta?['fibra_meta_g']?.toString() ?? '25';
    
    // Only show projection if there is actual weight loss expected
    if (perdaKg <= 0.1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF4834D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6C5CE7).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Projeção ShapePro IA', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProjectionItem(Icons.monitor_weight_outlined, '-${perdaKg}kg', 'em 30 dias'),
              _buildProjectionItem(Icons.water_drop_outlined, '${aguaMl}ml', 'água/dia'),
              _buildProjectionItem(Icons.grass_outlined, '${fibraG}g', 'fibras/dia'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectionItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  void _showMonthResultModal(BuildContext context) {
    final TextEditingController weightController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E38),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 24),
                const Icon(Icons.celebration, color: Color(0xFF2ED573), size: 48),
                const SizedBox(height: 16),
                Text('Resultado de 30 Dias', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('Parabéns por seguir a dieta! Quantos quilos você perdeu neste mês?', 
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Ex: 4.5',
                    hintStyle: GoogleFonts.inter(color: Colors.white24),
                    suffixText: 'kg',
                    suffixStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 18),
                    filled: true,
                    fillColor: const Color(0xFF16162A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (weightController.text.isEmpty) return;
                      final val = double.tryParse(weightController.text.replaceAll(',', '.'));
                      if (val != null) {
                        Navigator.pop(ctx);
                        final api = Provider.of<ApiService>(context, listen: false);
                        final res = await api.reportDietResult(val);
                        if (res['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(child: Text(res['message'] ?? 'Sucesso! Peso atualizado no perfil.')),
                              ],
                            ),
                            backgroundColor: const Color(0xFF2ED573),
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2ED573), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Text('Confirmar & Atualizar Perfil', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
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
                  builder: (_) => WorkoutDetailsScreen(
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
                    child: Text(AppLocalizations.of(context)!.workoutNum(tipo), style: GoogleFonts.inter(
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
                const SizedBox(width: 12),
                Builder(
                  builder: (context) {
                    String mealTotal = '';
                    if (refeicao['total_preco_str'] != null) {
                      mealTotal = refeicao['total_preco_str'];
                    } else {
                      final cur = Provider.of<ApiService>(context, listen: false).currentUser?['moeda'] ?? 'BRL';
                      double t = 0;
                      for (var a in alimentos) {
                        t += (a['preco_num'] as num?)?.toDouble() ?? 0;
                      }
                      if (t > 0) mealTotal = CurrencyHelper.format(t, cur);
                    }
                    if (mealTotal.isEmpty) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.monetization_on_outlined, color: Colors.white54, size: 12),
                          const SizedBox(width: 4),
                          Text(mealTotal, style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600,
                          )),
                        ],
                      ),
                    );
                  }
                ),
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
            children: isLocked ? [] : alimentos.asMap().entries.map((foodEntry) {
              final foodIndex = foodEntry.key;
              final a = foodEntry.value as Map<String, dynamic>;
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
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showSubstitutionModal(a, index, foodIndex),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.sync_alt, color: Color(0xFF2ED573), size: 16),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetSummary() {
    final api = Provider.of<ApiService>(context, listen: false);
    final userBudget = api.currentUser?['orcamento_dieta']?.toDouble() ?? 0.0;
    
    if (userBudget == 0) return const SizedBox.shrink();

    // Estimativa bruta de custo mensal (simulada baseada no orçamento e calorias)
    final estimatedDailyCost = (_dieta!['calorias_totais'] as num).toDouble() / 200 * 2.5; // Heurística
    final estimatedMonthlyCost = estimatedDailyCost * 30;
    final percent = (estimatedMonthlyCost / userBudget).clamp(0.0, 1.2);
    final currency = api.currentUser?['moeda'] ?? 'BRL';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: percent > 1.0 ? Colors.redAccent : const Color(0xFF2A2A4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Color(0xFF2ED573), size: 20),
              const SizedBox(width: 10),
              Text(
                'Controle de Orçamento', // TODO: Add to ARB if needed, or keep for now
                style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.white10,
            color: percent > 1.0 ? Colors.redAccent : const Color(0xFF2ED573),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimado: ${CurrencyHelper.format(estimatedMonthlyCost, currency)}',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
              ),
              Text(
                'Meta: ${CurrencyHelper.format(userBudget, currency)}',
                style: GoogleFonts.inter(
                  color: percent > 1.0 ? Colors.redAccent : Colors.white38, 
                  fontSize: 13,
                  fontWeight: percent > 1.0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          if (percent > 1.0) ...[
            const SizedBox(height: 8),
            const Text(
              '⚠️ Dieta acima do orçamento! Tente gerar uma versão "Econômica".',
              style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

}
