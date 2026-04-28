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
    }

    return errors;
  }

  /// Calculates an alignment score from 0 to 100 based on body visibility and position.
  static double calculateAlignmentScore(Pose pose, String type, double frameWidth, double frameHeight) {
    if (!isFullBodyDetected(pose)) {
      // Base score on how many landmarks are visible
      final landmarks = [
        PoseLandmarkType.nose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
        PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle
      ];
      int visible = 0;
      for (var type in landmarks) {
        if (pose.landmarks[type] != null && pose.landmarks[type]!.likelihood > 0.5) visible++;
      }
      return (visible / landmarks.length) * 40; // Max 40% if body is incomplete
    }

    double score = 40.0; // Base score for full body detection

    // Centering (Max 20%)
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder]!;
    final centerX = (leftShoulder.x + rightShoulder.x) / 2;
    final screenCenter = frameWidth / 2;
    final centerOffset = (centerX - screenCenter).abs() / frameWidth;
    score += math.max(0, 20 * (1 - (centerOffset / 0.3))); // Max 20% if offset < 30%

    // Straightness (Max 20%)
    final diffY = (leftShoulder.y - rightShoulder.y).abs();
    final width = (leftShoulder.x - rightShoulder.x).abs();
    final tilt = diffY / (width + 1);
    score += math.max(0, 20 * (1 - (tilt / 0.15))); // Max 20% if tilt < 15%

    // Distance (Max 20%)
    final nose = pose.landmarks[PoseLandmarkType.nose]!;
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle]!;
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle]!;
    final bodyHeight = (leftAnkle.y - nose.y).abs();
    final heightRatio = bodyHeight / frameHeight;
    // Ideal ratio is between 0.4 and 0.7
    double distanceFactor = 0;
    if (heightRatio >= 0.4 && heightRatio <= 0.7) distanceFactor = 1.0;
    else if (heightRatio < 0.4) distanceFactor = heightRatio / 0.4;
    else distanceFactor = 1.0 - ((heightRatio - 0.7) / 0.3);
    score += math.max(0, 20 * distanceFactor);

    return math.min(100, score);
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
    }
    return false;
  }
}
