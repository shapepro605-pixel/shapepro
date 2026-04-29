import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum WorkoutState {
  up,
  down,
}

class RepCounterHelper {
  int repCount = 0;
  WorkoutState currentState = WorkoutState.up;

  // Calculates the angle between three points (A, B, C) where B is the vertex
  double _calculateAngle(PoseLandmark first, PoseLandmark middle, PoseLandmark last) {
    double radians = math.atan2(last.y - middle.y, last.x - middle.x) -
                     math.atan2(first.y - middle.y, first.x - middle.x);
    
    double angle = (radians * 180.0 / math.pi).abs();
    
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    
    return angle;
  }

  // Analyzes the pose and updates rep count for Squats
  void processSquat(Pose pose) {
    final landmarks = pose.landmarks;

    // Get landmarks for left leg (can also average with right leg)
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];

    final rightHip = landmarks[PoseLandmarkType.rightHip];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip == null || leftKnee == null || leftAnkle == null ||
        rightHip == null || rightKnee == null || rightAnkle == null) {
      return; // Not all points are visible
    }

    // Check visibility score if available (ML Kit usually has likelihood > 0.5 for reliable points)
    if (leftHip.likelihood < 0.5 || leftKnee.likelihood < 0.5 || leftAnkle.likelihood < 0.5) {
        return;
    }

    // Calculate angle for both legs and take the average for better accuracy
    double leftAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
    double rightAngle = _calculateAngle(rightHip, rightKnee, rightAnkle);
    double avgAngle = (leftAngle + rightAngle) / 2;

    // Squat State Machine
    // Standing up is around 170-180 degrees
    // Squatting down is usually < 100 degrees
    if (avgAngle > 160) {
      if (currentState == WorkoutState.down) {
        // Transition from Down to Up = 1 Rep completed
        repCount++;
        currentState = WorkoutState.up;
      }
    } else if (avgAngle < 100) {
      currentState = WorkoutState.down;
    }
  }

  void reset() {
    repCount = 0;
    currentState = WorkoutState.up;
  }
}
