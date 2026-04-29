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

  SmartWorkoutPainter(
    this.pose,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection,
  );

  @override
  void paint(Canvas canvas, Size size) {
    // Neon style paint
    final paintLine = Paint()
      ..color = const Color(0xFF00D2FF)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3); // Neon glow effect
      
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

  @override
  bool shouldRepaint(covariant SmartWorkoutPainter oldDelegate) {
    return oldDelegate.pose != pose ||
           oldDelegate.imageSize != imageSize ||
           oldDelegate.rotation != rotation ||
           oldDelegate.cameraLensDirection != cameraLensDirection;
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
