import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'workout_ai_engine.dart';

class SmartWorkoutPainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final bool isFormCorrect;
  final AIExerciseType exerciseType;
  final int repCount; // To trigger particle effects on change
  final double flashIntensity;

  SmartWorkoutPainter(
    this.pose,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection,
    this.isFormCorrect,
    this.exerciseType,
    this.repCount, {
    this.flashIntensity = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGhostForm(canvas, size);
    
    // Pulse animation factor (0.0 to 1.0)
    final double pulse = (DateTime.now().millisecondsSinceEpoch % 1500) / 1500.0;
    final double glowIntensity = (2.0 + (pulse * 3.0)) + (flashIntensity * 15.0);
    
    // Neon style paint
    final paintLine = Paint()
      ..color = isFormCorrect 
          ? Color.lerp(const Color(0xFF00D2FF), Colors.white, flashIntensity)!.withValues(alpha: 0.8 + (pulse * 0.2)) 
          : const Color(0xFFFF4757)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.solid, glowIntensity); // Dynamic neon glow
      
    final paintPoint = Paint()
      ..color = const Color(0xFF6C5CE7)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    void paintLineBetween(PoseLandmarkType type1, PoseLandmarkType type2) {
      final landmark1 = pose.landmarks[type1];
      final landmark2 = pose.landmarks[type2];
      
      if (landmark1 != null && landmark2 != null) {
        // Only draw if confidence is high enough
        if (landmark1.likelihood > 0.5 && landmark2.likelihood > 0.5) {
          canvas.drawLine(
              Offset(_translateX(landmark1.x, size, imageSize, rotation, cameraLensDirection), _translateY(landmark1.y, size, imageSize, rotation, cameraLensDirection)),
              Offset(_translateX(landmark2.x, size, imageSize, rotation, cameraLensDirection), _translateY(landmark2.y, size, imageSize, rotation, cameraLensDirection)),
              paintLine);
        }
      }
    }

    void drawPoint(PoseLandmarkType type) {
       final landmark = pose.landmarks[type];
       if (landmark != null && landmark.likelihood > 0.5) {
         canvas.drawPoints(
           PointMode.points,
           [Offset(
             _translateX(landmark.x, size, imageSize, rotation, cameraLensDirection),
             _translateY(landmark.y, size, imageSize, rotation, cameraLensDirection)
           )],
           paintPoint
         );
       }
    }

    // Draw main body segments
    // Arms
    paintLineBetween(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    paintLineBetween(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    paintLineBetween(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    paintLineBetween(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

    // Torso
    paintLineBetween(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    paintLineBetween(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    paintLineBetween(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    paintLineBetween(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);

    // Legs
    paintLineBetween(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    paintLineBetween(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    paintLineBetween(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    paintLineBetween(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);

    // Draw joints
    drawPoint(PoseLandmarkType.leftShoulder);
    drawPoint(PoseLandmarkType.rightShoulder);
    drawPoint(PoseLandmarkType.leftElbow);
    drawPoint(PoseLandmarkType.rightElbow);
    drawPoint(PoseLandmarkType.leftWrist);
    drawPoint(PoseLandmarkType.rightWrist);
    drawPoint(PoseLandmarkType.leftHip);
    drawPoint(PoseLandmarkType.rightHip);
    drawPoint(PoseLandmarkType.leftKnee);
    drawPoint(PoseLandmarkType.rightKnee);
    drawPoint(PoseLandmarkType.leftAnkle);
    drawPoint(PoseLandmarkType.rightAnkle);
  }

  void _drawGhostForm(Canvas canvas, Size size) {
    final paintGhost = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintGhostFill = Paint()
      ..color = const Color(0xFF00D2FF).withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    // Alignment Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: "IA ALIGNMENT GUIDE",
        style: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.2), 
          fontSize: 10, 
          fontWeight: FontWeight.bold,
          letterSpacing: 2
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.5 - textPainter.width / 2, size.height * 0.12));

    switch (exerciseType) {
      case AIExerciseType.squat:
        _drawSquatGhost(canvas, size, paintGhost, paintGhostFill);
        break;
      case AIExerciseType.pushup:
      case AIExerciseType.plank:
        _drawHorizontalGhost(canvas, size, paintGhost, paintGhostFill);
        break;
      case AIExerciseType.crunch:
        _drawCrunchGhost(canvas, size, paintGhost, paintGhostFill);
        break;
    }
  }

  void _drawSquatGhost(Canvas canvas, Size size, Paint paint, Paint fill) {
    // Vertical human silhouette guide
    final path = Path();
    path.moveTo(size.width * 0.4, size.height * 0.2); // Head top
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.15, size.width * 0.6, size.height * 0.2);
    path.lineTo(size.width * 0.7, size.height * 0.4); // Shoulders
    path.lineTo(size.width * 0.65, size.height * 0.7); // Hips
    path.lineTo(size.width * 0.75, size.height * 0.95); // Right Leg
    path.lineTo(size.width * 0.25, size.height * 0.95); // Left Leg
    path.lineTo(size.width * 0.35, size.height * 0.7); // Hips
    path.lineTo(size.width * 0.3, size.height * 0.4); // Shoulders
    path.close();
    
    canvas.drawPath(path, fill);
    canvas.drawPath(path, paint);
  }

  void _drawHorizontalGhost(Canvas canvas, Size size, Paint paint, Paint fill) {
    // Horizontal alignment guide for floor exercises
    final rect = Rect.fromLTWH(
      size.width * 0.1, 
      size.height * 0.65, 
      size.width * 0.8, 
      size.height * 0.15
    );
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(30));
    canvas.drawRRect(rRect, fill);
    canvas.drawRRect(rRect, paint);
    
    // Floor indicator
    canvas.drawLine(
      Offset(size.width * 0.05, size.height * 0.82), 
      Offset(size.width * 0.95, size.height * 0.82), 
      paint..color = Colors.white10
    );
  }

  void _drawCrunchGhost(Canvas canvas, Size size, Paint paint, Paint fill) {
    // Seated/Lying guide
    final rect = Rect.fromLTWH(
      size.width * 0.15, 
      size.height * 0.5, 
      size.width * 0.7, 
      size.height * 0.4
    );
    canvas.drawOval(rect, fill);
    canvas.drawOval(rect, paint);
  }

  @override
  bool shouldRepaint(covariant SmartWorkoutPainter oldDelegate) {
    return true; // Always repaint for animations
  }
}

// Helpers for coordinate translation
double _translateX(double x, Size canvasSize, Size imageSize, InputImageRotation rotation, CameraLensDirection cameraLensDirection) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
      return x * canvasSize.width / (Platform.isIOS ? imageSize.width : imageSize.height);
    case InputImageRotation.rotation270deg:
      return canvasSize.width - x * canvasSize.width / (Platform.isIOS ? imageSize.width : imageSize.height);
    default:
      return x * canvasSize.width / imageSize.width;
  }
}

double _translateY(double y, Size canvasSize, Size imageSize, InputImageRotation rotation, CameraLensDirection cameraLensDirection) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
    case InputImageRotation.rotation270deg:
      return y * canvasSize.height / (Platform.isIOS ? imageSize.height : imageSize.width);
    default:
      return y * canvasSize.height / imageSize.height;
  }
}
