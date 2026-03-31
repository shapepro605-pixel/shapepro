import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shapepro/l10n/app_localizations.dart';
import '../services/api.dart';

class ResultadoScreen extends StatefulWidget {
  const ResultadoScreen({super.key});

  @override
  State<ResultadoScreen> createState() => _ResultadoScreenState();
}

class _ResultadoScreenState extends State<ResultadoScreen> {
  Map<String, dynamic>? _progresso;
  bool _isLoading = true;
  final _pesoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProgresso();
  }

  @override
  void dispose() {
    _pesoController.dispose();
    super.dispose();
  }

  Future<void> _loadProgresso() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final result = await api.getProgresso();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _progresso = result['progresso'];
        }
      });
    }
  }

  Future<void> _logWeight() async {
    final peso = double.tryParse(_pesoController.text);
    if (peso == null || peso <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.invalidWeight),
        backgroundColor: const Color(0xFFFD4556),
      ));
      return;
    }

    final api = Provider.of<ApiService>(context, listen: false);
    final result = await api.logWeight(peso);
    if (mounted) {
      if (result['success'] == true) {
        _pesoController.clear();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.weightLogged(peso.toString())),
          backgroundColor: const Color(0xFF2ED573),
        ));
        _loadProgresso();
      }
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
                      child: Text(AppLocalizations.of(context)!.results, style: GoogleFonts.inter(
                        fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white,
                      )),
                    ),
                  ],
                ),
              ),

              // ── Content ─────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final user = _progresso?['usuario'] ?? {};
    final imc = _progresso?['imc'];
    final classificacao = _progresso?['classificacao_imc'] ?? '';
    final historico = _progresso?['historico_peso'] as List<dynamic>? ?? [];
    final totalDietas = _progresso?['total_dietas_geradas'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadProgresso,
      color: const Color(0xFF6C5CE7),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stats Cards ─────────────────────────────
            Row(
              children: [
                _buildStatCard(AppLocalizations.of(context)!.peso, '${user['peso'] ?? '--'}', 'kg', const Color(0xFF6C5CE7), Icons.monitor_weight_outlined),
                const SizedBox(width: 12),
                _buildStatCard('IMC', imc?.toString() ?? '--', classificacao, const Color(0xFF00D2FF), Icons.favorite_outline),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard(AppLocalizations.of(context)!.treinos, '${user['treinos_concluidos'] ?? 0}', AppLocalizations.of(context)!.completed, const Color(0xFFFD4556), Icons.local_fire_department),
                const SizedBox(width: 12),
                _buildStatCard(AppLocalizations.of(context)!.dieta, '$totalDietas', AppLocalizations.of(context)!.generated, const Color(0xFF2ED573), Icons.restaurant_menu),
              ],
            ),
            const SizedBox(height: 28),

            // ── Log Weight ──────────────────────────────
            Text(AppLocalizations.of(context)!.logWeight, style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
            )),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF16162A),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF2A2A4A)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pesoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 18),
                      decoration: InputDecoration(
                        hintText: '75.0',
                        suffixText: 'kg',
                        suffixStyle: GoogleFonts.inter(color: Colors.white38),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2A2A4A)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: _logWeight,
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFF00D2FF)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Weight Evolution Chart ──────────────────
            Text(AppLocalizations.of(context)!.weightEvolution, style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
            )),
            const SizedBox(height: 14),
            _buildEvolutionChart(historico),
            const SizedBox(height: 28),

            // ── Weight History ──────────────────────────
            if (historico.isNotEmpty) ...[
              Text(AppLocalizations.of(context)!.history, style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
              )),
              const SizedBox(height: 14),
              ...historico.take(10).map((log) {
                final data = log['data'] ?? '';
                final peso = log['peso'] ?? 0;
                final dateStr = data.length >= 10 ? data.substring(0, 10) : data;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16162A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2A2A4A)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6C5CE7),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(dateStr, style: GoogleFonts.inter(
                          color: Colors.white60, fontSize: 14,
                        )),
                      ),
                      Text('$peso kg', style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16,
                      )),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 30),
            ],

            // ── IMC Classification ─────────────────────
            Text(AppLocalizations.of(context)!.imcClassification, style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
            )),
            const SizedBox(height: 14),
            _buildIMCScale(imc?.toDouble()),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String unit, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF16162A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 14),
            Text(value, style: GoogleFonts.inter(
              fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white,
            )),
            Text(unit, style: GoogleFonts.inter(
              fontSize: 12, color: Colors.white54,
            )),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(
              fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w500,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionChart(List<dynamic> historico) {
    if (historico.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF16162A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF2A2A4A)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.show_chart, color: Colors.white24, size: 40),
              const SizedBox(height: 10),
              Text(AppLocalizations.of(context)!.logWeightToTrack, style: GoogleFonts.inter(
                color: Colors.white38, fontSize: 13,
              ), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final spots = historico.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['peso'] as num).toDouble());
    }).toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) => FlLine(
              color: const Color(0xFF2A2A4A), strokeWidth: 1,
            ),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF00D2FF)],
              ),
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF00D2FF),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                    const Color(0xFF00D2FF).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIMCScale(double? imc) {
    final categories = [
      {'label': AppLocalizations.of(context)!.underweight, 'range': '< 18.5', 'color': const Color(0xFF00D2FF)},
      {'label': AppLocalizations.of(context)!.normalWeight, 'range': '18.5 - 24.9', 'color': const Color(0xFF2ED573)},
      {'label': AppLocalizations.of(context)!.overweight, 'range': '25 - 29.9', 'color': const Color(0xFFFFA502)},
      {'label': AppLocalizations.of(context)!.obesity1, 'range': '30 - 34.9', 'color': const Color(0xFFFF6B6B)},
      {'label': AppLocalizations.of(context)!.obesity2, 'range': '35 - 39.9', 'color': const Color(0xFFFD4556)},
      {'label': AppLocalizations.of(context)!.obesity3, 'range': '≥ 40', 'color': const Color(0xFFD63031)},
    ];

    int activeIndex = -1;
    if (imc != null) {
      if (imc < 18.5) {
        activeIndex = 0;
      } else if (imc < 25) {
        activeIndex = 1;
      } else if (imc < 30) {
        activeIndex = 2;
      } else if (imc < 35) {
        activeIndex = 3;
      } else if (imc < 40) {
        activeIndex = 4;
      } else {
        activeIndex = 5;
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Column(
        children: categories.asMap().entries.map((entry) {
          final i = entry.key;
          final cat = entry.value;
          final isActive = i == activeIndex;
          final color = cat['color'] as Color;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive ? Border.all(color: color.withValues(alpha: 0.4)) : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(cat['label'] as String, style: GoogleFonts.inter(
                    color: isActive ? Colors.white : Colors.white54,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 13,
                  )),
                ),
                Text(cat['range'] as String, style: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 12,
                )),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_back_ios, color: color, size: 12),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
