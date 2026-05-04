import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_fonts/google_fonts.dart';
import 'neon_pose_painter.dart';

class OverlayGuide extends StatefulWidget {
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
  State<OverlayGuide> createState() => _OverlayGuideState();
}

class _OverlayGuideState extends State<OverlayGuide> with SingleTickerProviderStateMixin {
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calcular deslocamento horizontal da silhueta para seguir o usuário
    double horizontalOffset = 0;
    if (widget.currentPose != null && widget.imageSize.width > 0) {
      final lm = widget.currentPose!.landmarks;
      final leftShoulder = lm[PoseLandmarkType.leftShoulder];
      final rightShoulder = lm[PoseLandmarkType.rightShoulder];
      
      if (leftShoulder != null && rightShoulder != null) {
        final bodyCenterX = (leftShoulder.x + rightShoulder.x) / 2;
        final imageCenterX = widget.imageSize.width / 2;
        
        // Normalizar o deslocamento (-1 a 1)
        horizontalOffset = (bodyCenterX - imageCenterX) / (widget.imageSize.width / 2);
        
        // Inverter se for câmera frontal (espelhado)
        if (widget.isFrontCamera) horizontalOffset = -horizontalOffset;
      }
    }

    return Stack(
      children: [
        // Silhouette & Trace Painter
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _scanController,
            builder: (context, child) {
              return CustomPaint(
                painter: SilhouettePainter(
                  isValid: widget.isValid,
                  poseType: widget.poseType,
                  hasBody: widget.currentPose != null,
                  alignmentPercentage: widget.alignmentPercentage,
                  horizontalOffset: horizontalOffset,
                  scanProgress: _scanController.value,
                ),
              );
            }
          ),
        ),
        
        // Exibir métricas e marcações neon maravilhosas ao vivo
        Positioned.fill(
          child: CustomPaint(
            painter: NeonPosePainter(
              pose: widget.currentPose,
              imageSize: widget.imageSize,
              metrics: widget.realtimeMetrics,
              isFrontCamera: widget.isFrontCamera,
            ),
          ),
        ),
        
        // Alignment Percentage Badge
        if (widget.currentPose != null)
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
                    "Alinhamento: ${widget.alignmentPercentage}%",
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
                widget.statusMessage,
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
    if (widget.isValid) return const Color(0xFF2ED573); // Green
    if (widget.currentPose != null) {
      if (widget.alignmentPercentage < 50) return Colors.redAccent;
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
  final double horizontalOffset;
  final double scanProgress;

  SilhouettePainter({
    required this.isValid,
    required this.poseType,
    this.hasBody = false,
    this.alignmentPercentage = 0,
    this.horizontalOffset = 0,
    this.scanProgress = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBrackets(canvas, size);
    
    // Calcular deslocamento em pixels
    final double pixelOffset = horizontalOffset * (size.width * 0.15); // Limite de 15% da largura
    
    Color silhouetteColor = Colors.white.withValues(alpha: 0.3);
    if (isValid) {
      silhouetteColor = const Color(0xFF00FF88).withValues(alpha: 0.6);
    } else if (hasBody) {
      silhouetteColor = (alignmentPercentage < 50) 
          ? Colors.redAccent.withValues(alpha: 0.5) 
          : Colors.amber.withValues(alpha: 0.5);
    }

    final paint = Paint()
      ..color = silhouetteColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.save();
    canvas.translate(pixelOffset, 0);

    final path = Path();
    if (poseType == 'side') {
      _drawSideSilhouette(path, size);
    } else {
      _drawFrontSilhouette(path, size);
    }

    // Desenhar sombra neon
    canvas.drawPath(path, paint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawPath(path, paint..maskFilter = null..strokeWidth = 1.5);

    // Efeito de Scanline Neon
    if (hasBody) {
      final scanLineY = size.height * 0.1 + (size.height * 0.8 * scanProgress);
      final scanPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            silhouetteColor.withValues(alpha: 0),
            silhouetteColor.withValues(alpha: 0.8),
            silhouetteColor.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, scanLineY - 20, size.width, 40))
        ..strokeWidth = 2.0;

      canvas.drawLine(
        Offset(size.width * 0.2, scanLineY),
        Offset(size.width * 0.8, scanLineY),
        scanPaint,
      );
    }

    canvas.restore();
  }

  void _drawBrackets(Canvas canvas, Size size) {
    Color bracketColor = Colors.white30;
    if (isValid) {
      bracketColor = const Color(0xFF00FF88);
    } else if (hasBody) {
      bracketColor = (alignmentPercentage < 50) ? Colors.redAccent : Colors.amber;
    }

    final bracketPaint = Paint()
      ..color = bracketColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    const double bLen = 30.0;
    const double margin = 40.0;

    // Cantos com brilho
    final glowPaint = Paint()
      ..color = bracketColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    void drawCorner(Path path) {
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, bracketPaint);
    }

    // Top Left
    drawCorner(Path()..moveTo(margin, margin + bLen)..lineTo(margin, margin)..lineTo(margin + bLen, margin));
    // Top Right
    drawCorner(Path()..moveTo(size.width - margin - bLen, margin)..lineTo(size.width - margin, margin)..lineTo(size.width - margin, margin + bLen));
    // Bottom Left
    drawCorner(Path()..moveTo(margin, size.height - margin - bLen)..lineTo(margin, size.height - margin)..lineTo(margin + bLen, size.height - margin));
    // Bottom Right
    drawCorner(Path()..moveTo(size.width - margin - bLen, size.height - margin)..lineTo(size.width - margin, size.height - margin)..lineTo(size.width - margin, size.height - margin - bLen));
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
