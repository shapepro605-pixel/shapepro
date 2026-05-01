import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:camera/camera.dart';

class SmartWorkoutPainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final bool isFormCorrect;
  final AIExerciseType exerciseType;
  final int repCount; // To trigger particle effects on change

  SmartWorkoutPainter(
    this.pose,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection,
    this.isFormCorrect,
    this.exerciseType,
    this.repCount,
  );

  @override
  void paint(Canvas canvas, Size size) {
    _drawGhostForm(canvas, size);
    
    // Pulse animation factor (0.0 to 1.0)
    final double pulse = (DateTime.now().millisecondsSinceEpoch % 1500) / 1500.0;
    final double glowIntensity = 2.0 + (pulse * 3.0);
    
    // Neon style paint
    final paintLine = Paint()
      ..color = isFormCorrect 
          ? const Color(0xFF00D2FF).withValues(alpha: 0.8 + (pulse * 0.2)) 
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
    // Draw a subtle "ghost" silhouette of the perfect form
    final paintGhost = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Define standard "guide" points for a generic human shape or per-exercise
    // For now, let's draw a subtle box or a generic "T-Pose" as a alignment guide
    // Or better: draw the ideal skeleton for the current exercise
    
    // Example: Squat Ghost
    if (exerciseType == AIExerciseType.squat) {
       // Just a simple visual guide for the user to center themselves
       final RRect guideBox = RRect.fromLTRBR(
         size.width * 0.2, 
         size.height * 0.2, 
         size.width * 0.8, 
         size.height * 0.9, 
         const Radius.circular(20)
       );
       canvas.drawRRect(guideBox, paintGhost);
       
       // "AI ALIGNMENT" Text style
       final textPainter = TextPainter(
         text: TextSpan(
           text: "ALINHAMENTO IA",
           style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12, fontWeight: FontWeight.bold),
         ),
         textDirection: TextDirection.ltr,
       );
       textPainter.layout();
       textPainter.paint(canvas, Offset(size.width * 0.5 - textPainter.width / 2, size.height * 0.15));
    }
  }

  @override
  bool shouldRepaint(covariant SmartWorkoutPainter oldDelegate) {
    return oldDelegate.pose != pose ||
           oldDelegate.imageSize != imageSize ||
           oldDelegate.rotation != rotation ||
           oldDelegate.cameraLensDirection != cameraLensDirection ||
           oldDelegate.isFormCorrect != isFormCorrect;
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
