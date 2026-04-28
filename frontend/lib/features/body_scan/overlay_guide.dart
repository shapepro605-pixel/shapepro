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
  final int alignmentPercentage;

  const OverlayGuide({
    super.key,
    required this.isValid,
    required this.statusMessage,
    required this.poseType,
    this.currentPose,
    this.realtimeMetrics,
    this.isFrontCamera = false,
    required this.imageSize,
    this.alignmentPercentage = 0,
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
              hasBody: currentPose != null,
              alignmentPercentage: alignmentPercentage,
            ),
          ),
        ),
        
        // Exibir métricas e marcações neon maravilhosas ao vivo
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
        
        // Alignment Percentage Badge
        if (currentPose != null)
          Positioned(
            top: 150,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getOverlayColor().withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.align_horizontal_center, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "Alinhamento: $alignmentPercentage%",
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
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
                color: _getOverlayColor().withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _getOverlayColor().withValues(alpha: 0.4),
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

  Color _getOverlayColor() {
    if (isValid) return const Color(0xFF2ED573); // Green
    if (currentPose != null) {
      if (alignmentPercentage < 50) return Colors.redAccent;
      return Colors.amber; // Yellow
    }
    return const Color(0xFF16162A); // Dark
  }
}

class SilhouettePainter extends CustomPainter {
  final bool isValid;
  final String poseType;
  final bool hasBody;
  final int alignmentPercentage;

  SilhouettePainter({
    required this.isValid,
    required this.poseType,
    this.hasBody = false,
    this.alignmentPercentage = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBrackets(canvas, size);
    
    Color silhouetteColor = Colors.white.withValues(alpha: 0.4);
    if (isValid) {
      silhouetteColor = const Color(0xFF2ED573).withValues(alpha: 0.6);
    } else if (hasBody) {
      silhouetteColor = (alignmentPercentage < 50) 
          ? Colors.redAccent.withValues(alpha: 0.6) 
          : Colors.amber.withValues(alpha: 0.6);
    }

    final paint = Paint()
      ..color = silhouetteColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = Path();
    
    if (poseType == 'side') {
      _drawSideSilhouette(path, size);
    } else {
      _drawFrontSilhouette(path, size);
    }

    canvas.drawPath(path, paint);
  }

  void _drawBrackets(Canvas canvas, Size size) {
    Color bracketColor = Colors.white30;
    if (isValid) {
      bracketColor = const Color(0xFF2ED573);
    } else if (hasBody) {
      bracketColor = (alignmentPercentage < 50) ? Colors.redAccent : Colors.amber;
    }

    final bracketPaint = Paint()
      ..color = bracketColor
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


  @override
  bool shouldRepaint(covariant SilhouettePainter oldDelegate) => true; 
}
