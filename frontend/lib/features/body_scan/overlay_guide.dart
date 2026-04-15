import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_fonts/google_fonts.dart';
import 'neon_pose_painter.dart';

class OverlayGuide extends StatelessWidget {
  final bool isValid;
  final String statusMessage;
  final String poseType;
  final Pose? currentPose;
  final Map<String, double>? realtimeMetrics;
  final bool isFrontCamera;
  final Size imageSize;

  const OverlayGuide({
    super.key,
    required this.isValid,
    required this.statusMessage,
    required this.poseType,
    this.currentPose,
    this.realtimeMetrics,
    this.isFrontCamera = false,
    required this.imageSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Silhouette & Trace Painter
        Positioned.fill(
          child: CustomPaint(
            painter: SilhouettePainter(
              isValid: isValid,
              poseType: poseType,
            ),
          ),
        ),
        
        // Exibir métricas e marcações neon maravilhosas ao vivo
        if (currentPose != null && realtimeMetrics != null)
          Positioned.fill(
            child: CustomPaint(
              painter: NeonPosePainter(
                pose: currentPose,
                imageSize: imageSize,
                metrics: realtimeMetrics,
                isFrontCamera: isFrontCamera,
              ),
            ),
          ),

        
        // Status Text
        Positioned(
          bottom: 125,
          left: 40,
          right: 40,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: 0.9,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              decoration: BoxDecoration(
                color: isValid 
                    ? const Color(0xFF2ED573).withValues(alpha: 0.9) 
                    : const Color(0xFF16162A).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  if (isValid)
                    BoxShadow(
                      color: const Color(0xFF2ED573).withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SilhouettePainter extends CustomPainter {
  final bool isValid;
  final String poseType;

  SilhouettePainter({
    required this.isValid,
    required this.poseType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBrackets(canvas, size);
    
    final paint = Paint()
      ..color = isValid 
        ? const Color(0xFF2ED573).withValues(alpha: 0.6) 
        : Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = Path();
    
    if (poseType == 'side') {
      _drawSideSilhouette(path, size);
    } else if (poseType == 'back') {
      _drawBackSilhouette(path, size);
    } else {
      _drawFrontSilhouette(path, size);
    }

    canvas.drawPath(path, paint);
  }

  void _drawBrackets(Canvas canvas, Size size) {
    final bracketPaint = Paint()
      ..color = isValid ? const Color(0xFF2ED573) : Colors.white30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    const double bLen = 30.0;
    const double margin = 40.0;

    // Top Left
    canvas.drawPath(Path()..moveTo(margin, margin + bLen)..lineTo(margin, margin)..lineTo(margin + bLen, margin), bracketPaint);
    // Top Right
    canvas.drawPath(Path()..moveTo(size.width - margin - bLen, margin)..lineTo(size.width - margin, margin)..lineTo(size.width - margin, margin + bLen), bracketPaint);
    // Bottom Left
    canvas.drawPath(Path()..moveTo(margin, size.height - margin - bLen)..lineTo(margin, size.height - margin)..lineTo(margin + bLen, size.height - margin), bracketPaint);
    // Bottom Right
    canvas.drawPath(Path()..moveTo(size.width - margin - bLen, size.height - margin)..lineTo(size.width - margin, size.height - margin)..lineTo(size.width - margin, size.height - margin - bLen), bracketPaint);
  }

  void _drawFrontSilhouette(Path path, Size size) {
    path.addOval(Rect.fromLTWH(size.width * 0.4, size.height * 0.1, size.width * 0.2, size.width * 0.25));
    path.moveTo(size.width * 0.25, size.height * 0.3);
    path.lineTo(size.width * 0.75, size.height * 0.3);
    path.lineTo(size.width * 0.65, size.height * 0.6);
    path.lineTo(size.width * 0.35, size.height * 0.6);
    path.close();
    path.moveTo(size.width * 0.35, size.height * 0.6);
    path.lineTo(size.width * 0.35, size.height * 0.9);
    path.moveTo(size.width * 0.65, size.height * 0.6);
    path.lineTo(size.width * 0.65, size.height * 0.9);
  }

  void _drawSideSilhouette(Path path, Size size) {
    path.addOval(Rect.fromLTWH(size.width * 0.42, size.height * 0.1, size.width * 0.16, size.width * 0.25));
    path.moveTo(size.width * 0.5, size.height * 0.25);
    path.quadraticBezierTo(size.width * 0.4, size.height * 0.45, size.width * 0.5, size.height * 0.6);
    path.lineTo(size.width * 0.45, size.height * 0.9);
    path.lineTo(size.width * 0.55, size.height * 0.9);
    path.lineTo(size.width * 0.55, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.45, size.width * 0.5, size.height * 0.25);
  }

  void _drawBackSilhouette(Path path, Size size) {
    _drawFrontSilhouette(path, size);
    path.moveTo(size.width * 0.4, size.height * 0.35);
    path.lineTo(size.width * 0.45, size.height * 0.45);
    path.moveTo(size.width * 0.6, size.height * 0.35);
    path.lineTo(size.width * 0.55, size.height * 0.45);
  }

  @override
  bool shouldRepaint(covariant SilhouettePainter oldDelegate) => true; 
}
