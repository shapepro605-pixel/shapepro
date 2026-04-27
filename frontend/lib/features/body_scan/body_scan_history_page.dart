import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shapepro/l10n/app_localizations.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api.dart';
import '../../utils/body_utils.dart';
import 'body_comparison_page.dart';
import 'body_scan_service.dart';

class BodyScanHistoryPage extends StatefulWidget {
  const BodyScanHistoryPage({super.key});

  @override
  State<BodyScanHistoryPage> createState() => _BodyScanHistoryPageState();
}

class _BodyScanHistoryPageState extends State<BodyScanHistoryPage> {
  late BodyScanService _scanService;
  bool _isLoading = true;
  List<Map<String, List<dynamic>>> _groupedScans = [];
  int _daysRemaining = 30;
  Map<String, dynamic>? _latestMetrics;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scanService = BodyScanService(Provider.of<ApiService>(context, listen: false));
    _loadHistory();
    _loadLatestUserMetrics();
  }

  Future<void> _loadLatestUserMetrics() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final baseUrl = ApiService.baseUrl;
    final token = api.accessToken;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tracking/metrics/history'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final history = data['history'] as List;
        if (history.isNotEmpty && mounted) {
          setState(() => _latestMetrics = history.first);
        }
      }
    } catch (e) {
      debugPrint("Erro ao carregar métricas: $e");
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _scanService.getHistory();
      
      // Group by day
      Map<String, List<dynamic>> groups = {};
      for (var scan in history) {
        String dateKey = '';
        if (scan['created_at'] != null) {
          DateTime dt = DateTime.parse(scan['created_at']);
          dateKey = DateFormat('yyyy-MM-dd').format(dt);
        }
        
        if (!groups.containsKey(dateKey)) {
          groups[dateKey] = [];
        }
        groups[dateKey]!.add(scan);
      }

      // Sort dates desc
      var sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
      
      _groupedScans = sortedKeys.map((key) => {key: groups[key]!}).toList();

      // Calculate countdown from the most recent scan
      if (sortedKeys.isNotEmpty) {
        DateTime lastScanDate = DateTime.parse(sortedKeys.first);
        final difference = DateTime.now().difference(lastScanDate).inDays;
        _daysRemaining = math.max(0, 30 - difference);
      } else {
        _daysRemaining = 30; 
      }

    } catch (e) {
      debugPrint("Error loading history: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myEvolution, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF6C5CE7)),
            onPressed: () => _showDisclaimerModal(context),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
        : RefreshIndicator(
            onRefresh: () async {
              await _loadHistory();
              await _loadLatestUserMetrics();
            },
            color: const Color(0xFF6C5CE7),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildCountdownHeader(),
                const SizedBox(height: 30),
                Text(
                  AppLocalizations.of(context)!.scansHistory,
                  style: GoogleFonts.inter(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white
                  ),
                ),
                const SizedBox(height: 16),
                if (_groupedScans.isEmpty)
                  _buildEmptyState()
                else
                  ..._groupedScans.map((group) => _buildSessionCard(group.keys.first, group.values.first)),
                const SizedBox(height: 20),
                _buildUserProfileDetailCard(),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildCountdownHeader() {
    double progress = (30 - _daysRemaining) / 30;
    bool isExpired = _daysRemaining == 0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpired 
            ? [const Color(0xFF2ED573), const Color(0xFF1ABC9C)]
            : [const Color(0xFF6C5CE7), const Color(0xFF8E78FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isExpired ? const Color(0xFF2ED573) : const Color(0xFF6C5CE7)).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$_daysRemaining",
                        style: GoogleFonts.inter(
                          fontSize: 24, 
                          fontWeight: FontWeight.w900, 
                          color: Colors.white
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.days,
                        style: GoogleFonts.inter(
                          fontSize: 10, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white70
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isExpired 
                        ? "HORA DA EVOLUÇÃO!" 
                        : AppLocalizations.of(context)!.nextCheckin,
                      style: GoogleFonts.inter(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isExpired
                        ? "Seu ciclo de 30 dias terminou. Tire uma nova foto agora!"
                        : AppLocalizations.of(context)!.daysRemainingDesc(_daysRemaining),
                      style: GoogleFonts.inter(
                        fontSize: 13, 
                        color: Colors.white.withOpacity(0.8)
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_groupedScans.length >= 2) ...[
            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _navigateToComparison,
              icon: const Icon(Icons.compare, size: 18),
              label: const Text("VER COMPARAÇÃO DE ANTES E DEPOIS"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: isExpired ? const Color(0xFF2ED573) : const Color(0xFF6C5CE7),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ]
        ],
      ),
    );
  }

  void _navigateToComparison() {
    if (_groupedScans.length < 2) return;
    
    // Pegamos a sessão mais recente (after) e a mais antiga (before)
    // Cada grupo é Map<String, List<dynamic>>
    final afterSession = _groupedScans.first.values.first;
    final beforeSession = _groupedScans.last.values.first;
    
    // Pegamos os scans do tipo 'front' de cada sessão, se existirem
    final afterFront = afterSession.firstWhere((s) => s['type'] == 'front', orElse: () => afterSession.first);
    final beforeFront = beforeSession.firstWhere((s) => s['type'] == 'front', orElse: () => beforeSession.first);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BodyComparisonPage(
          beforeScan: beforeFront,
          afterScan: afterFront,
        ),
      ),
    );
  }

  Widget _buildSessionCard(String dateKey, List<dynamic> scans) {
    DateTime date = DateTime.parse(dateKey);
    String formattedDate = DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(date);
    
    // Tentamos pegar as métricas do primeiro scan que tiver (geralmente frente)
    Map<String, dynamic>? metrics;
    for (var s in scans) {
      if (s['metrics'] != null) {
        metrics = s['metrics'];
        break;
      }
    }

    final api = Provider.of<ApiService>(context, listen: false);
    final user = api.currentUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: GoogleFonts.inter(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.photosAttached(scans.length),
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.session,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6C5CE7), 
                      fontWeight: FontWeight.bold,
                      fontSize: 10
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Photos Row - Refactored to avoid touch absorption issues
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: scans.map<Widget>((scan) {
                final scanId = int.tryParse(scan['id'].toString()) ?? 0;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        debugPrint(">>> FOTO CLICADA PARA EXCLUSÃO: ID $scanId");
                        _confirmDeletion(scanId, scan['image_url']);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              image: DecorationImage(
                                image: NetworkImage(scan['image_url']),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black54, Colors.transparent],
                                ),
                              ),
                              alignment: Alignment.bottomCenter,
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                _translateType(context, scan['type']),
                                style: GoogleFonts.inter(
                                  color: Colors.white, 
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          ),
                          // Ícone de lixeira apenas como guia visual agora, o clique é na foto toda
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          if (metrics != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      const Icon(Icons.analytics, color: Color(0xFF6C5CE7), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.iaMeasures,
                        style: GoogleFonts.inter(color: const Color(0xFF6C5CE7), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        // Principais
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMetricItem(AppLocalizations.of(context)!.neck, _formatMeasure(metrics['neck'])),
                            _buildMetricDivider(),
                            _buildMetricItem(AppLocalizations.of(context)!.shoulders, _formatMeasure(metrics['shoulders'])),
                            _buildMetricDivider(),
                            _buildMetricItem(AppLocalizations.of(context)!.chest, _formatMeasure(metrics['chest'])),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          child: Divider(color: Colors.white10, height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMetricItem(AppLocalizations.of(context)!.waist, _formatMeasure(metrics['waist'])),
                            _buildMetricDivider(),
                            _buildMetricItem(AppLocalizations.of(context)!.hips, _formatMeasure(metrics['hips'])),
                          ],
                        ),
                        
                        // Braços e Pernas (Se disponíveis)
                        if (metrics['left_arm'] != null || metrics['left_thigh'] != null) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            child: Divider(color: Colors.white10, height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetricItem(AppLocalizations.of(context)!.leftArm, _formatMeasure(metrics['left_arm'])),
                              _buildMetricDivider(),
                              _buildMetricItem(AppLocalizations.of(context)!.rightArm, _formatMeasure(metrics['right_arm'])),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            child: Divider(color: Colors.white10, height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetricItem(AppLocalizations.of(context)!.leftThigh, _formatMeasure(metrics['left_thigh'])),
                              _buildMetricDivider(),
                              _buildMetricItem(AppLocalizations.of(context)!.rightThigh, _formatMeasure(metrics['right_thigh'])),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            child: Divider(color: Colors.white10, height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetricItem(AppLocalizations.of(context)!.leftCalf, _formatMeasure(metrics['left_calf'])),
                              _buildMetricDivider(),
                              _buildMetricItem(AppLocalizations.of(context)!.rightCalf, _formatMeasure(metrics['right_calf'])),
                            ],
                          ),
                        ],
                        
                        // Saúde (Se disponíveis)
                        if (metrics['waist_hip_ratio'] != null || metrics['v_shape'] != null) ...[
                           const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            child: Divider(color: Colors.white10, height: 1),
                          ),
                           Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              if (metrics['waist_hip_ratio'] != null)
                                _buildMetricItem("C/Q", "${metrics['waist_hip_ratio']}", unit: ""),
                              if (metrics['waist_hip_ratio'] != null && metrics['v_shape'] != null)
                                _buildMetricDivider(),
                              if (metrics['v_shape'] != null)
                                _buildMetricItem("V-Shape", "${metrics['v_shape']}", unit: ""),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // User info at session time (approximate based on current)
                  if (user != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniInfo(AppLocalizations.of(context)!.currentWeight, _formatWeight(user['peso'])),
                        _buildMiniInfo(AppLocalizations.of(context)!.height, _formatMeasure(user['altura'], isHeight: true)),
                        _buildMiniInfo(AppLocalizations.of(context)!.bmi, _calculateIMC(user['peso'], user['altura'])),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _confirmDeletion(int scanId, String imageUrl) {
    debugPrint(">>> SOLICITANDO DIÁLOGO DE EXCLUSÃO PARA ID: $scanId");
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: const Color(0xFF16162A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            l10n.deletePhotoTitle, 
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)
          ),
          content: Text(
            l10n.deletePhotoDesc,
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel.toUpperCase(), style: GoogleFonts.inter(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteScan(scanId, imageUrl);
              },
              child: Text(l10n.delete.toUpperCase(), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteScan(int scanId, String imageUrl) async {
    debugPrint(">>> EXECUTANDO EXCLUSÃO NO SERVIDOR PARA ID: $scanId");
    final api = Provider.of<ApiService>(context, listen: false);
    final bodyScanService = BodyScanService(api);
    
    setState(() => _isLoading = true);
    
    try {
      final result = await bodyScanService.deleteScan(scanId, imageUrl);
      final bool success = result['success'] ?? false;
      debugPrint(">>> SUCESSO DO SERVIDOR: $success");
      
      if (success) {
        if (mounted) {
          // Sincroniza perfeitamente o estado buscando os dados atualizados do servidor novamente
          await _loadHistory();
          await _loadLatestUserMetrics();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.photoRemoved),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['error'] ?? "O servidor não confirmou a exclusão.");
      }
    } catch (e) {
      debugPrint(">>> ERRO NA EXCLUSÃO: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorDeleting(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatWeight(dynamic valueInKg) {
    return BodyUtils.formatWeight(context, valueInKg);
  }

  String _formatMeasure(dynamic valueInCm, {bool isHeight = false, bool isPercentage = false}) {
    return BodyUtils.formatMeasure(context, valueInCm, isHeight: isHeight, isPercentage: isPercentage);
  }

  String _calculateIMC(dynamic peso, dynamic altura) {
    return BodyUtils.calculateIMC(peso, altura);
  }

  Widget _buildMiniInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 9)),
        Text(value, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildUserProfileDetailCard() {
    final api = Provider.of<ApiService>(context, listen: false);
    final user = api.currentUser;
    if (user == null) return const SizedBox.shrink();

    // Extrair medidas da IA do scan mais recente
    Map<String, dynamic>? aiMetrics;
    if (_groupedScans.isNotEmpty) {
      final latestSession = _groupedScans.first.values.first;
      if (latestSession.isNotEmpty) {
        aiMetrics = latestSession.first['metrics'];
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_pin, color: Color(0xFF6C5CE7), size: 24),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.healthProfile,
                style: GoogleFonts.inter(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 18
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 3,
            children: [
              _buildDetailItem(AppLocalizations.of(context)!.fullName, user['nome'] ?? '--'),
              _buildDetailItem(AppLocalizations.of(context)!.currentWeight, _formatWeight(user['peso'])),
              _buildDetailItem(AppLocalizations.of(context)!.height, _formatMeasure(user['altura'], isHeight: true)),
              _buildDetailItem(AppLocalizations.of(context)!.yourObjective, _translateObjective(user['objetivo'])),
            ],
          ),
          
          if (aiMetrics != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: Colors.white10),
            ),
            Row(
              children: [
                const Icon(Icons.bolt, color: Colors.cyanAccent, size: 18),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.bodyMeasurements,
                  style: GoogleFonts.inter(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 16,
              childAspectRatio: 3.2,
              children: [
                if (aiMetrics['neck'] != null)
                  _buildDetailItem(AppLocalizations.of(context)!.neck, _formatMeasure(aiMetrics['neck'])),
                _buildDetailItem(AppLocalizations.of(context)!.shoulders, _formatMeasure(aiMetrics['shoulders'])),
                _buildDetailItem(AppLocalizations.of(context)!.chest, _formatMeasure(aiMetrics['chest'])),
                _buildDetailItem(AppLocalizations.of(context)!.waist, _formatMeasure(aiMetrics['waist'])),
                _buildDetailItem(AppLocalizations.of(context)!.hips, _formatMeasure(aiMetrics['hips'])),
                if (aiMetrics['left_arm'] != null)
                  _buildDetailItem(AppLocalizations.of(context)!.leftArm, _formatMeasure(aiMetrics['left_arm'])),
                if (aiMetrics['right_arm'] != null)
                  _buildDetailItem(AppLocalizations.of(context)!.rightArm, _formatMeasure(aiMetrics['right_arm'])),
                if (aiMetrics['left_forearm'] != null)
                  _buildDetailItem(AppLocalizations.of(context)!.leftForearm, _formatMeasure(aiMetrics['left_forearm'])),
                if (aiMetrics['right_forearm'] != null)
                  _buildDetailItem(AppLocalizations.of(context)!.rightForearm, _formatMeasure(aiMetrics['right_forearm'])),
                if (aiMetrics['left_thigh'] != null)
                  _buildDetailItem(AppLocalizations.of(context)!.leftThigh, _formatMeasure(aiMetrics['left_thigh'])),
                if (aiMetrics['right_thigh'] != null)
                  _buildDetailItem(AppLocalizations.of(context)!.rightThigh, _formatMeasure(aiMetrics['right_thigh'])),
                if (aiMetrics['left_calf'] != null)
                  _buildDetailItem(AppLocalizations.of(context)!.leftCalf, _formatMeasure(aiMetrics['left_calf'])),
                if (aiMetrics['right_calf'] != null)
                  _buildDetailItem(AppLocalizations.of(context)!.rightCalf, _formatMeasure(aiMetrics['right_calf'])),
              ],
            ),

            // === Indicadores de Saúde ===
            if (aiMetrics['waist_hip_ratio'] != null || aiMetrics['v_shape'] != null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: Colors.white10),
              ),
              Row(
                children: [
                  const Icon(Icons.monitor_heart, color: Color(0xFF00E676), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.healthIndicators,
                    style: GoogleFonts.inter(color: const Color(0xFF00E676), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 16,
                childAspectRatio: 3.2,
                children: [
                  if (aiMetrics['waist_hip_ratio'] != null)
                    _buildDetailItem(AppLocalizations.of(context)!.waistHipRatio, "${aiMetrics['waist_hip_ratio']}"),
                  if (aiMetrics['waist_height_ratio'] != null)
                    _buildDetailItem(AppLocalizations.of(context)!.waistHeightRatio, "${aiMetrics['waist_height_ratio']}"),
                  if (aiMetrics['v_shape'] != null)
                    _buildDetailItem(AppLocalizations.of(context)!.vShape, "${aiMetrics['v_shape']}"),
                ],
              ),
            ],
          ],

          if (_latestMetrics != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: Colors.white10),
            ),
            Text(
              AppLocalizations.of(context)!.recentManualMeasures,
              style: GoogleFonts.inter(color: const Color(0xFF6C5CE7), fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 3,
              children: [
                _buildDetailItem(AppLocalizations.of(context)!.waist, _formatMeasure(_latestMetrics!['cintura'])),
                _buildDetailItem(AppLocalizations.of(context)!.chest, _formatMeasure(_latestMetrics!['peito'])),
                _buildDetailItem(AppLocalizations.of(context)!.leftArm, _formatMeasure(_latestMetrics!['braco_esq'])),
                _buildDetailItem(AppLocalizations.of(context)!.rightArm, _formatMeasure(_latestMetrics!['braco_dir'])),
                _buildDetailItem(AppLocalizations.of(context)!.leftThigh, _formatMeasure(_latestMetrics!['coxa_esq'])),
                _buildDetailItem(AppLocalizations.of(context)!.rightThigh, _formatMeasure(_latestMetrics!['coxa_dir'])),
                _buildDetailItem(AppLocalizations.of(context)!.fatPercentage, _formatMeasure(_latestMetrics!['percentual_gordura'], isPercentage: true)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _translateObjective(String? obj) {
    if (obj == null) return '--';
    final normalized = obj.toLowerCase();
    
    // Mapeia tanto os slugs quanto os valores brutos que podem vir do banco
    if (normalized.contains('perder') || normalized.contains('emagrecer')) {
      return AppLocalizations.of(context)!.loseWeight;
    }
    if (normalized.contains('ganhar') || normalized.contains('hipertrofia') || normalized.contains('massa')) {
      return AppLocalizations.of(context)!.gainMass;
    }
    if (normalized.contains('manter')) {
      return AppLocalizations.of(context)!.maintainWeight;
    }
    
    return obj;
  }

  String _translateActivity(String? level) {
    switch (level) {
      case 'sedentario': return AppLocalizations.of(context)!.sedentary;
      case 'leve': return AppLocalizations.of(context)!.healthy;
      case 'moderado': return AppLocalizations.of(context)!.standard;
      case 'intenso': return AppLocalizations.of(context)!.extreme;
      default: return level ?? '--';
    }
  }

  void _showDisclaimerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF16162A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.gavel_rounded, color: Color(0xFF6C5CE7), size: 24),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.legalDisclaimer,
                  style: GoogleFonts.inter(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 20
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildModalSection(
              AppLocalizations.of(context)!.informativePurposeTitle,
              AppLocalizations.of(context)!.informativePurposeDesc
            ),
            const SizedBox(height: 16),
            _buildModalSection(
              AppLocalizations.of(context)!.notAMedicalDeviceTitle,
              AppLocalizations.of(context)!.notAMedicalDeviceDesc
            ),
            const SizedBox(height: 16),
            _buildModalSection(
              AppLocalizations.of(context)!.consultProfessionalsTitle,
              AppLocalizations.of(context)!.consultProfessionalsDesc
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(AppLocalizations.of(context)!.understood, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildModalSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(color: const Color(0xFF6C5CE7), fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  String _translateType(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'front': return l10n.frontType;
      case 'side': return l10n.sideType;
      case 'back': return l10n.backType;
      default: return type;
    }
  }

  Widget _buildMetricItem(String label, String value, {String unit = ""}) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
        ),
        Text(
          "$value$unit",
          style: GoogleFonts.inter(
            color: Colors.white, 
            fontSize: 14, 
            fontWeight: FontWeight.bold
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      height: 20,
      width: 1,
      color: Colors.white10,
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Icon(Icons.camera_enhance_outlined, size: 80, color: Colors.white.withOpacity(0.1)),
        const SizedBox(height: 20),
        Text(
          AppLocalizations.of(context)!.noScansPerformed,
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.scansWillAppearHere,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
        ),
      ],
    );
  }
}
