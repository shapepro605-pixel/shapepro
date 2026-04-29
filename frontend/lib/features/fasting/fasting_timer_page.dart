import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../services/api.dart';
import 'fasting_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FastingTimerPage extends StatefulWidget {
  const FastingTimerPage({super.key});

  @override
  State<FastingTimerPage> createState() => _FastingTimerPageState();
}

class _FastingTimerPageState extends State<FastingTimerPage> with SingleTickerProviderStateMixin {
  final FastingService _fastingService = FastingService();
  Timer? _timer;
  bool _isLoading = true;
  bool _isPremiumLocked = false;
  
  // Animation for the breathing effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initService();
  }

  Future<void> _initService() async {
    await _fastingService.init();
    
    // Check trial/premium status
    final api = Provider.of<ApiService>(context, listen: false);
    final user = api.currentUser;
    if (user != null) {
      final isInTrial = user['is_trial'] ?? false;
      final isPremium = user['plano_assinatura'] != 'free';
      // Se não está no trial e não é premium, bloqueia
      if (!isInTrial && !isPremium) {
        _isPremiumLocked = true;
      }
    }
    
    setState(() {
      _isLoading = false;
    });

    // Start timer to update UI every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
  
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A1A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Jejum Intermitente', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isPremiumLocked ? _buildLockedView() : _buildTimerView(),
    );
  }

  Widget _buildLockedView() {
    return Center(
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
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  )
                ],
              ),
              child: const Icon(Icons.lock_outline_rounded, size: 64, color: Colors.white),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scaleXY(begin: 1.0, end: 1.1, duration: 1.seconds, curve: Curves.easeInOut),
            const SizedBox(height: 40),
            Text(
              "Cronômetro Premium",
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              "Seu período de teste acabou. Desbloqueie o Jejum Intermitente e todas as refeições da dieta com o ShapePro Premium.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/checkout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black87,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text("DESBLOQUEAR PREMIUM", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTimerView() {
    final isFasting = _fastingService.currentState == FastingState.fasting;
    final isEating = _fastingService.currentState == FastingState.eatingWindow;
    
    // Determine colors
    final primaryColor = isFasting ? const Color(0xFF00D2FF) : (isEating ? const Color(0xFF2ED573) : const Color(0xFF6C5CE7));
    final secondaryColor = isFasting ? const Color(0xFF6C5CE7) : (isEating ? const Color(0xFF1ABC9C) : const Color(0xFF4834D4));

    return Column(
      children: [
        const SizedBox(height: 40),
        
        // Timer Circle
        Expanded(
          child: Center(
            child: ScaleTransition(
              scale: isFasting ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: isFasting || isEating ? 0.3 : 0.0),
                      blurRadius: 50,
                      spreadRadius: 10,
                    )
                  ]
                ),
                child: CustomPaint(
                  painter: TimerPainter(
                    progress: _fastingService.progress,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                    isFasting: isFasting,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isFasting ? "JEJUM" : (isEating ? "ALIMENTAÇÃO" : "PRONTO"),
                        style: GoogleFonts.inter(
                          fontSize: 14, 
                          fontWeight: FontWeight.bold, 
                          color: primaryColor,
                          letterSpacing: 2
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isFasting || isEating 
                            ? _formatDuration(_fastingService.elapsedTime)
                            : "16:00:00",
                        style: GoogleFonts.inter(
                          fontSize: 48, 
                          fontWeight: FontWeight.w900, 
                          color: Colors.white,
                          letterSpacing: -1
                        ),
                      ),
                      if (isFasting) ...[
                        const SizedBox(height: 8),
                        Text(
                          "Restante: ${_formatDuration(_fastingService.remainingTime)}",
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          decoration: BoxDecoration(
            color: const Color(0xFF16162A),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              if (!isFasting && !isEating)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildProtocolSelector("14:10", 14),
                    _buildProtocolSelector("16:8", 16),
                    _buildProtocolSelector("18:6", 18),
                  ],
                ),
                
              const SizedBox(height: 30),
              
              if (!isFasting && !isEating)
                ElevatedButton(
                  onPressed: () {
                    _fastingService.startFasting(_fastingService.targetHours);
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text("INICIAR JEJUM", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                )
              else if (isFasting)
                ElevatedButton(
                  onPressed: () {
                    _fastingService.stopFasting();
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ED573), // Green to indicate moving to food
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text("QUEBRAR JEJUM", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                )
              else if (isEating)
                ElevatedButton(
                  onPressed: () {
                    _fastingService.reset();
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFD4556), // Red to indicate ending food window
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text("FINALIZAR JANELA", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildProtocolSelector(String label, int hours) {
    final isSelected = _fastingService.targetHours == hours;
    return GestureDetector(
      onTap: () {
        setState(() {
          _fastingService.targetHours = hours;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C5CE7) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Custom Painter for the beautiful neon ring
class TimerPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isFasting;

  TimerPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isFasting,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - 10;
    
    // Background track
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;
    
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0 && isFasting) {
      // Gradient progress arc
      final gradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: (-math.pi / 2) + (math.pi * 2 * progress),
        colors: [secondaryColor, primaryColor],
      );

      final progressPaint = Paint()
        ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 15;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start at top
        math.pi * 2 * progress,
        false,
        progressPaint,
      );
    } else if (!isFasting && progress == 0) {
      // Solid green if eating window, or primary if just ready
       final progressPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15;
      
      canvas.drawCircle(center, radius, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant TimerPainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.primaryColor != primaryColor ||
           oldDelegate.isFasting != isFasting;
  }
}
