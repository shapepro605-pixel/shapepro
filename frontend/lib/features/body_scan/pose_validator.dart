import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseValidator {
  static const double minConfidence = 0.6; // Slightly more permissive

  /// Main validation entry point.
  /// Returns a list of error messages. If empty, pose is valid.
  static List<String> validate(Pose pose, String type, double frameWidth, double frameHeight) {
    List<String> errors = [];

    if (!isFullBodyDetected(pose)) {
      errors.add("fullBodyNotDetected");
      return errors; // Early return as other checks depend on these landmarks
    }

    if (!isCentered(pose, frameWidth, frameHeight)) {
      errors.add("centerYourBody");
    }

    if (!isStraight(pose)) {
      errors.add("stayStraight");
    }

    if (!isValidDistance(pose, frameHeight)) {
      errors.add("invalidDistance");
    }

    if (!isCorrectPose(pose, type)) {
      if (type == 'front') errors.add("poseFront");
      if (type == 'side') errors.add("poseSide");
      if (type == 'back') errors.add("poseBack");
    }

    return errors;
  }

  static bool isFullBodyDetected(Pose pose) {
    final landmarks = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];

    for (var type in landmarks) {
      final lm = pose.landmarks[type];
      if (lm == null || lm.likelihood < minConfidence) return false;
    }
    return true;
  }

  static bool isCentered(Pose pose, double frameWidth, double frameHeight) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder]!;
    
    final centerX = (leftShoulder.x + rightShoulder.x) / 2;
    final screenCenter = frameWidth / 2;
    
    // Allow 20% deviation from center (more forgiving for front camera)
    return (centerX - screenCenter).abs() < (frameWidth * 0.20);
  }

  static bool isStraight(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder]!;
    
    // Difference in Y should be minimal
    final diffY = (leftShoulder.y - rightShoulder.y).abs();
    final width = (leftShoulder.x - rightShoulder.x).abs();
    
    // Tilt angle check (must be less than ~5 degrees)
    return diffY < (width * 0.1); 
  }

  static bool isValidDistance(Pose pose, double frameHeight) {
    final nose = pose.landmarks[PoseLandmarkType.nose]!;
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle]!;
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle]!;
    
    final avgAnkleY = (leftAnkle.y + rightAnkle.y) / 2;
    final bodyHeight = (avgAnkleY - nose.y).abs();
    
    // Body should take up between 35% and 80% of screen height
    // 80% forces the user to stand at a distance (apprx 2.5m) to avoid perspective distortion
    return bodyHeight > (frameHeight * 0.35) && bodyHeight < (frameHeight * 0.80);
  }

  static bool isCorrectPose(Pose pose, String type) {
    final nose = pose.landmarks[PoseLandmarkType.nose]!;
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder]!;
    
    if (type == 'front') {
      // Nose must be visible and centered between shoulders
      return nose.likelihood > 0.8 && 
             nose.x > math.min(leftShoulder.x, rightShoulder.x) &&
             nose.x < math.max(leftShoulder.x, rightShoulder.x);
    } else if (type == 'side') {
      // In side profile, distance between shoulders appears smaller
      final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
      final hipWidth = (pose.landmarks[PoseLandmarkType.leftHip]!.x - pose.landmarks[PoseLandmarkType.rightHip]!.x).abs();
      return shoulderWidth < (hipWidth * 0.7); // Heuristic for profile
    } else if (type == 'back') {
      // Nose confidence should be low for back pose
      return nose.likelihood < 0.45; // Increased threshold slightly
    }
    return false;
  }
}
