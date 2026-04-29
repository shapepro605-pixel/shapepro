import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api.dart';
import '../../services/wearable_service.dart';
import '../../widgets/fitness_widgets.dart';
import 'health_service.dart';

class WearablesDashboard extends StatefulWidget {
  const WearablesDashboard({super.key});

  @override
  State<WearablesDashboard> createState() => _WearablesDashboardState();
}

class _WearablesDashboardState extends State<WearablesDashboard> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isPremiumLocked = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final user = api.currentUser;
    
    if (user != null) {
      final isPremium = user['plano_assinatura'] != 'free' || (user['is_trial'] ?? false);
      if (!isPremium) {
        setState(() {
          _isPremiumLocked = true;
          _isLoading = false;
        });
        return;
      }
    }

    final wearableService = Provider.of<WearableService>(context, listen: false);
    if (wearableService.currentData.isEmpty) {
      await wearableService.syncData(api: api);
    }
    
    setState(() => _isLoading = false);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A1A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))),
      );
    }

    if (_isPremiumLocked) {
      return _buildLockedView();
    }

    final wearableService = context.watch<WearableService>();
    final data = wearableService.currentData;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Wearables",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.sync,
              color: wearableService.isSyncing ? Colors.white30 : const Color(0xFF00D2FF),
            ),
            onPressed: wearableService.isSyncing ? null : () => wearableService.syncData(api: context.read<ApiService>()),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => wearableService.syncData(api: context.read<ApiService>()),
        color: const Color(0xFF6C5CE7),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSyncStatus(wearableService),
              const SizedBox(height: 32),
              
              if (wearableService.isSyncing)
                const FitnessSkeleton()
              else if (data['error'] != null)
                _buildErrorCard(data['error'])
              else
                _buildMainDashboard(wearableService),
                
              const SizedBox(height: 32),
              _buildWorkoutsSection(data['workouts'] ?? []),
              const SizedBox(height: 32),
              _buildManualEntryButton(),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatus(WearableService service) {
    final lastSync = service.lastSync;
    final timeStr = lastSync != null 
        ? DateFormat('HH:mm').format(lastSync) 
        : "--:--";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(
            service.isSyncing ? Icons.autorenew : Icons.check_circle_outline,
            color: service.isSyncing ? const Color(0xFF00D2FF) : Colors.greenAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            service.isSyncing ? "Sincronizando..." : "Conectado",
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const Spacer(),
          Text(
            "Última sync: $timeStr",
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMainDashboard(WearableService service) {
    final data = service.currentData;
    final score = service.fitnessScore;

    return Column(
      children: [
        Center(
          child: DailyProgressRing(
            percentage: score / 100,
            color: const Color(0xFF6C5CE7),
            centerWidget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  score.round().toString(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Fitness Score",
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            FitnessDataCard(
              icon: Icons.directions_walk,
              title: "Passos",
              value: "${data['steps'] ?? 0}",
              unit: "/ ${service.stepGoal}",
              color: const Color(0xFF00D2FF),
            ),
            FitnessDataCard(
              icon: Icons.local_fire_department,
              title: "Calorias",
              value: "${data['calories'] ?? 0}",
              unit: "kcal",
              color: const Color(0xFFFF2A5F),
            ),
            FitnessDataCard(
              icon: Icons.favorite,
              title: "BPM Médio",
              value: "${data['heartRate'] ?? 0}",
              unit: "bpm",
              color: const Color(0xFFFF6B6B),
            ),
            FitnessDataCard(
              icon: Icons.nightlight_round,
              title: "Sono",
              value: "${(data['sleep'] ?? 0) ~/ 60}h ${(data['sleep'] ?? 0) % 60}m",
              unit: "",
              color: const Color(0xFF6C5CE7),
            ),
            FitnessDataCard(
              icon: Icons.straighten,
              title: "Distância",
              value: (data['distance'] ?? 0.0).toStringAsFixed(1),
              unit: "km",
              color: const Color(0xFF2ED573),
            ),
            FitnessDataCard(
              icon: Icons.bolt,
              title: "Meta Diária",
              value: "${((data['steps'] ?? 0) / service.stepGoal * 100).round()}%",
              unit: "",
              color: Colors.orangeAccent,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkoutsSection(List workouts) {
    if (workouts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Treinos Detectados",
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        ...workouts.map((w) => _buildWorkoutItem(w)),
      ],
    );
  }

  Widget _buildWorkoutItem(Map<String, dynamic> workout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00D2FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fitness_center, color: Color(0xFF00D2FF), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout['type'] ?? "Atividade",
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${workout['duration']} min • ${workout['calories']} kcal",
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildManualEntryButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(Icons.edit_note, color: Colors.white38, size: 32),
          const SizedBox(height: 12),
          Text(
            "Não tem um Smartwatch?",
            style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            "Adicione seus passos e atividades manualmente.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _showManualEntryDialog,
            child: Text(
              "ADICIONAR MANUALMENTE",
              style: GoogleFonts.inter(color: const Color(0xFF6C5CE7), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog() {
    final stepsController = TextEditingController();
    final calsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Entrada Manual", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stepsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Passos"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: calsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Calorias (kcal)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final steps = int.tryParse(stepsController.text);
              final cals = int.tryParse(calsController.text);
              Provider.of<WearableService>(context, listen: false)
                  .updateManualData(steps: steps, calories: cals, api: context.read<ApiService>());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
            child: const Text("SALVAR"),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A4A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6C5CE7)),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFD4556).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFD4556).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFD4556), size: 48),
          const SizedBox(height: 16),
          Text(
            "Sincronização Falhou",
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            "Certifique-se de que o Health Connect está instalado e autorizado.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => HealthService().openHealthConnectInPlayStore(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6C5CE7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("INSTALAR", style: TextStyle(color: Color(0xFF6C5CE7))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Provider.of<WearableService>(context, listen: false).syncData(api: context.read<ApiService>()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("RETRY"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLockedView() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFF00D2FF), Color(0xFF6C5CE7)]),
              ),
              child: const Icon(Icons.watch, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 40),
            Text(
              "Smartwatch Sync",
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              "Conecte seus dispositivos e acompanhe seu progresso real-time. Disponível para usuários Premium.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/checkout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("DESBLOQUEAR PREMIUM", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
