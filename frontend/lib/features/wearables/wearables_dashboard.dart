import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shapepro/l10n/app_localizations.dart';
import '../../services/api.dart';
import 'health_service.dart';
import 'dart:math' as math;

class WearablesDashboard extends StatefulWidget {
  const WearablesDashboard({super.key});

  @override
  State<WearablesDashboard> createState() => _WearablesDashboardState();
}

class _WearablesDashboardState extends State<WearablesDashboard> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isPremiumLocked = false;
  Map<String, dynamic>? _healthData;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _checkPremiumAccess();
  }

  Future<void> _checkPremiumAccess() async {
    final api = Provider.of<ApiService>(context, listen: false);
    await api.init();
    final user = api.currentUser;
    
    if (user != null) {
      final isInTrial = user['is_trial'] ?? false;
      final isPremium = user['plano_assinatura'] != 'free';
      if (!isInTrial && !isPremium) {
        _isPremiumLocked = true;
      }
    }
    
    if (!_isPremiumLocked) {
      await _syncHealthData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncHealthData() async {
    setState(() => _isLoading = true);
    final data = await HealthService().fetchDailySummary();
    
    setState(() {
      _healthData = data;
      _isLoading = false;
    });
    
    if (_healthData != null && _healthData!['error'] == null) {
      _animController.forward(from: 0);
    }
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
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00D2FF))),
      );
    }

    if (_isPremiumLocked) {
      return _buildLockedView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Wearables", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Color(0xFF00D2FF)),
            onPressed: _syncHealthData,
          )
        ],
      ),
      body: _healthData != null && _healthData!['error'] != null
          ? _buildErrorView(_healthData!['error'])
          : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    int steps = _healthData?['steps'] ?? 0;
    int calories = _healthData?['calories'] ?? 0;
    int hr = _healthData?['heartRate'] ?? 0;

    // Goals for the rings
    double stepsGoal = 10000;
    double calGoal = 500;
    
    double stepsPct = (steps / stepsGoal).clamp(0.0, 1.0);
    double calPct = (calories / calGoal).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Seu Dia em Movimento",
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            "Sincronizado com seu Smartwatch",
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
          ),
          const SizedBox(height: 40),
          
          // Activity Rings
          SizedBox(
            height: 250,
            width: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildRing(250, const Color(0xFFFF2A5F), calPct, "Calorias"),
                _buildRing(190, const Color(0xFF00D2FF), stepsPct, "Passos"),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.watch, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    Text("AO VIVO", style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          
          const SizedBox(height: 50),
          
          // Data Cards
          Row(
            children: [
              Expanded(child: _buildDataCard(Icons.local_fire_department, "Calorias", "$calories kcal", const Color(0xFFFF2A5F))),
              const SizedBox(width: 16),
              Expanded(child: _buildDataCard(Icons.directions_walk, "Passos", "$steps", const Color(0xFF00D2FF))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDataCard(Icons.favorite, "BPM Médio", "$hr bpm", const Color(0xFFFF6B6B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRing(double size, Color color, double percentage, String label) {
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return CustomPaint(
            painter: RingPainter(
              color: color,
              percentage: percentage * _animController.value,
              strokeWidth: 20,
            ),
          );
        }
      ),
    );
  }

  Widget _buildDataCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.watch_off_outlined, size: 80, color: Colors.white54),
            const SizedBox(height: 24),
            Text(
              "Sincronização Falhou",
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              "Não conseguimos acessar os dados do seu relógio. Certifique-se de autorizar o Google Fit / Health Connect.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _syncHealthData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D2FF),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("TENTAR NOVAMENTE", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLockedView() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D2FF), Color(0xFF6C5CE7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D2FF).withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    )
                  ],
                ),
                child: const Icon(Icons.watch, size: 64, color: Colors.white),
              ),
              const SizedBox(height: 40),
              Text(
                "Sincronização Wearables",
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                "Conecte seu Apple Watch, Galaxy Watch ou Garmin para sincronizar calorias e batimentos automaticamente. Assine o ShapePro Premium.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/checkout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D2FF),
                  foregroundColor: Colors.black87,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text("DESBLOQUEAR PREMIUM", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  final Color color;
  final double percentage;
  final double strokeWidth;

  RingPainter({required this.color, required this.percentage, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground ring
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3); // Neon glow

    final sweepAngle = 2 * math.pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at top
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}
