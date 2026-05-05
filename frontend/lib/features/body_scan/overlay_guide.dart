import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_fonts/google_fonts.dart';

class OverlayGuide extends StatefulWidget {
  final bool isValid;
  final String statusMessage;
  final bool isStabilizing;
  final double stabilityProgress;
  final String poseType;
  final Pose? currentPose;
  final Map<String, double>? realtimeMetrics;
  final int alignmentPercentage;
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
    this.alignmentPercentage = 0,
    this.isStabilizing = false,
    this.stabilityProgress = 0,
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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Calcular deslocamento horizontal da silhueta para seguir o usuário
    double horizontalOffset = 0;
    if (widget.currentPose != null && widget.imageSize.width > 0) {
      final lm = widget.currentPose!.landmarks;
      final leftShoulder = lm[PoseLandmarkType.leftShoulder];
      final rightShoulder = lm[PoseLandmarkType.rightShoulder];
      final leftHip = lm[PoseLandmarkType.leftHip];
      final rightHip = lm[PoseLandmarkType.rightHip];
      
      double? bodyCenterX;
      if (leftShoulder != null && rightShoulder != null) {
        bodyCenterX = (leftShoulder.x + rightShoulder.x) / 2;
      } else if (leftHip != null && rightHip != null) {
        bodyCenterX = (leftHip.x + rightHip.x) / 2;
      }
      
      if (bodyCenterX != null) {
        final imageCenterX = widget.imageSize.width / 2;
        horizontalOffset = (bodyCenterX - imageCenterX) / (widget.imageSize.width / 2);
        if (widget.isFrontCamera) {
          horizontalOffset = -horizontalOffset;
        }
      }
    }

    return Stack(
      children: [
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
                  isStabilizing: widget.isStabilizing,
                  stabilityProgress: widget.stabilityProgress,
                ),
              );
            }
          ),
        ),

        if (widget.statusMessage.isNotEmpty)
          Positioned(
            top: 150,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.isValid).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(widget.isValid).withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Text(
                  widget.statusMessage,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getStatusColor(bool isValid) {
    if (isValid) return const Color(0xFF00FF88);
    return Colors.redAccent;
  }
}

class SilhouettePainter extends CustomPainter {
  final bool isValid;
  final String poseType;
  final bool hasBody;
  final int alignmentPercentage;
  final double horizontalOffset;
  final double scanProgress;
  final bool isStabilizing;
  final double stabilityProgress;

  SilhouettePainter({
    required this.isValid,
    required this.poseType,
    required this.hasBody,
    required this.alignmentPercentage,
    required this.horizontalOffset,
    required this.scanProgress,
    this.isStabilizing = false,
    this.stabilityProgress = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBrackets(canvas, size);
    
    final double pixelOffset = horizontalOffset * (size.width * 0.4); 
    
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

    canvas.drawPath(path, paint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawPath(path, paint..maskFilter = null..strokeWidth = 1.5);
    canvas.restore();

    // Laser Scan VFX
    if (isStabilizing || (isValid && alignmentPercentage > 95)) {
      _drawLaserScan(canvas, size, pixelOffset);
    }
  }

  void _drawLaserScan(Canvas canvas, Size size, double pixelOffset) {
    final double yPos = size.height * (0.1 + (isStabilizing ? stabilityProgress : scanProgress) * 0.8);
    
    final Paint laserPaint = Paint()
      ..color = const Color(0xFF00FF88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final Paint linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double laserWidth = size.width * 0.4;
    final double startX = (size.width - laserWidth) / 2 + pixelOffset;
    final double endX = (size.width + laserWidth) / 2 + pixelOffset;

    canvas.drawLine(Offset(startX - 20, yPos), Offset(endX + 20, yPos), laserPaint);
    canvas.drawLine(Offset(startX, yPos), Offset(endX, yPos), linePaint);
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

    final glowPaint = Paint()
      ..color = bracketColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    void drawCorner(Path path) {
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, bracketPaint);
    }

    drawCorner(Path()..moveTo(margin, margin + bLen)..lineTo(margin, margin)..lineTo(margin + bLen, margin));
    drawCorner(Path()..moveTo(size.width - margin - bLen, margin)..lineTo(size.width - margin, margin)..lineTo(size.width - margin, margin + bLen));
    drawCorner(Path()..moveTo(margin, size.height - margin - bLen)..lineTo(margin, size.height - margin)..lineTo(margin + bLen, size.height - margin));
    drawCorner(Path()..moveTo(size.width - margin - bLen, size.height - margin)..lineTo(size.width - margin, size.height - margin)..lineTo(size.width - margin, size.height - margin - bLen));
  }

  void _drawFrontSilhouette(Path path, Size size) {
    final w = size.width;
    final h = size.height;
    path.addOval(Rect.fromLTWH(w * 0.42, h * 0.08, w * 0.16, h * 0.1));
    path.moveTo(w * 0.3, h * 0.22);
    path.quadraticBezierTo(w * 0.5, h * 0.18, w * 0.7, h * 0.22);
    path.lineTo(w * 0.75, h * 0.45);
    path.lineTo(w * 0.68, h * 0.45);
    path.lineTo(w * 0.65, h * 0.28);
    path.quadraticBezierTo(w * 0.6, h * 0.4, w * 0.62, h * 0.55);
    path.quadraticBezierTo(w * 0.5, h * 0.58, w * 0.38, h * 0.55);
    path.quadraticBezierTo(w * 0.4, h * 0.4, w * 0.35, h * 0.28);
    path.lineTo(w * 0.32, h * 0.45);
    path.lineTo(w * 0.25, h * 0.45);
    path.close();
    path.moveTo(w * 0.4, h * 0.55);
    path.lineTo(w * 0.38, h * 0.9);
    path.lineTo(w * 0.48, h * 0.9);
    path.lineTo(w * 0.5, h * 0.6);
    path.lineTo(w * 0.52, h * 0.9);
    path.lineTo(w * 0.62, h * 0.9);
    path.lineTo(w * 0.6, h * 0.55);
  }

  void _drawSideSilhouette(Path path, Size size) {
    final w = size.width;
    final h = size.height;
    path.addOval(Rect.fromLTWH(w * 0.44, h * 0.08, w * 0.12, h * 0.1));
    path.moveTo(w * 0.5, h * 0.18);
    path.quadraticBezierTo(w * 0.62, h * 0.3, w * 0.58, h * 0.45);
    path.quadraticBezierTo(w * 0.55, h * 0.55, w * 0.55, h * 0.6);
    path.lineTo(w * 0.52, h * 0.9);
    path.lineTo(w * 0.45, h * 0.9);
    path.lineTo(w * 0.45, h * 0.6);
    path.quadraticBezierTo(w * 0.4, h * 0.35, w * 0.5, h * 0.18);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
