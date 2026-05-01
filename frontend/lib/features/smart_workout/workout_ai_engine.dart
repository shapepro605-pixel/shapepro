import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum AIExerciseType {
  squat,
  pushup,
  crunch,
  plank
}

enum WorkoutState {
  up,
  down,
}

class WorkoutAIEngine {
  int repCount = 0;
  WorkoutState currentState = WorkoutState.up;
  
  // Form Validation
  bool isFormCorrect = true;
  String feedbackMessage = "Posicione-se para começar";
  double accuracyScore = 100.0; // 0-100 score
  List<double> historyAccuracy = [];

  // Plank specifics
  int plankSeconds = 0;
  DateTime? lastPlankTick;

  AIExerciseType currentExercise = AIExerciseType.squat;

  void setExercise(AIExerciseType type) {
    currentExercise = type;
    reset();
  }

  void reset() {
    repCount = 0;
    plankSeconds = 0;
    currentState = WorkoutState.up;
    isFormCorrect = true;
    feedbackMessage = "Pronto para começar";
    accuracyScore = 100.0;
    historyAccuracy.clear();
    lastPlankTick = null;
  }

  double _calculateAngle(PoseLandmark first, PoseLandmark middle, PoseLandmark last) {
    double radians = math.atan2(last.y - middle.y, last.x - middle.x) -
                     math.atan2(first.y - middle.y, first.x - middle.x);
    
    double angle = (radians * 180.0 / math.pi).abs();
    
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    
    return angle;
  }

  void processPose(Pose pose) {
    if (pose.landmarks.isEmpty) {
      isFormCorrect = true;
      feedbackMessage = "Nenhum corpo detectado";
      return;
    }

    switch (currentExercise) {
      case AIExerciseType.squat:
        _processSquat(pose);
        break;
      case AIExerciseType.pushup:
        _processPushup(pose);
        break;
      case AIExerciseType.crunch:
        _processCrunch(pose);
        break;
      case AIExerciseType.plank:
        _processPlank(pose);
        break;
    }
  }

  // ==========================================
  // SQUAT (Agachamento)
  // ==========================================
  void _processSquat(Pose pose) {
    final landmarks = pose.landmarks;
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];

    if (leftHip == null || leftKnee == null || leftAnkle == null || leftShoulder == null) return;
    if (leftHip.likelihood < 0.5 || leftKnee.likelihood < 0.5) return;

    double kneeAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
    
    // Form Check: Postura das costas (não inclinar muito pra frente)
    // Avaliamos o ângulo Ombro-Quadril-Joelho ou a posição X
    double backAngle = _calculateAngle(leftShoulder, leftHip, leftKnee);
    
    if (backAngle < 60) {
      isFormCorrect = false;
      feedbackMessage = "Mantenha as costas retas!";
      accuracyScore = math.max(0, accuracyScore - 2);
    } else {
      isFormCorrect = true;
      feedbackMessage = currentState == WorkoutState.down ? "Suba!" : "Desça!";
      accuracyScore = math.min(100, accuracyScore + 0.5);
    }
    historyAccuracy.add(accuracyScore);

    // Rep Counting Logic
    if (kneeAngle > 160) {
      if (currentState == WorkoutState.down) {
        if (isFormCorrect) repCount++;
        currentState = WorkoutState.up;
      }
    } else if (kneeAngle < 100) {
      currentState = WorkoutState.down;
    }
  }

  // ==========================================
  // PUSHUP (Flexão)
  // ==========================================
  void _processPushup(Pose pose) {
    final landmarks = pose.landmarks;
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];

    if (leftShoulder == null || leftElbow == null || leftWrist == null || leftHip == null || leftAnkle == null) return;
    if (leftShoulder.likelihood < 0.5 || leftElbow.likelihood < 0.5) return;

    double elbowAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
    double bodyAngle = _calculateAngle(leftShoulder, leftHip, leftAnkle);

    // Form check: Body should be straight
    if (bodyAngle < 150) {
      isFormCorrect = false;
      feedbackMessage = "Não deixe o quadril cair!";
      accuracyScore = math.max(0, accuracyScore - 2);
    } else {
      isFormCorrect = true;
      feedbackMessage = currentState == WorkoutState.down ? "Empurre!" : "Desça!";
      accuracyScore = math.min(100, accuracyScore + 0.5);
    }
    historyAccuracy.add(accuracyScore);

    if (elbowAngle > 160) {
      if (currentState == WorkoutState.down) {
        if (isFormCorrect) repCount++;
        currentState = WorkoutState.up;
      }
    } else if (elbowAngle < 90) {
      currentState = WorkoutState.down;
    }
  }

  // ==========================================
  // CRUNCH (Abdominal)
  // ==========================================
  void _processCrunch(Pose pose) {
    final landmarks = pose.landmarks;
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];

    if (leftShoulder == null || leftHip == null || leftKnee == null) return;
    if (leftShoulder.likelihood < 0.5 || leftHip.likelihood < 0.5) return;

    double crunchAngle = _calculateAngle(leftShoulder, leftHip, leftKnee);

    isFormCorrect = true;
    feedbackMessage = currentState == WorkoutState.down ? "Contraia!" : "Desça controlando";
    accuracyScore = math.min(100, accuracyScore + 0.2);
    historyAccuracy.add(accuracyScore);

    // When lying down, angle is around 120-140 (because knees are bent)
    // When crunching up, angle decreases below 90
    if (crunchAngle > 110) {
      if (currentState == WorkoutState.down) {
        repCount++;
        currentState = WorkoutState.up;
      }
    } else if (crunchAngle < 85) {
      currentState = WorkoutState.down;
    }
  }

  // ==========================================
  // PLANK (Prancha)
  // ==========================================
  void _processPlank(Pose pose) {
    final landmarks = pose.landmarks;
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final leftAnkle = landmarks[PoseLandmarkType.leftAnkle];

    if (leftShoulder == null || leftHip == null || leftAnkle == null) return;
    if (leftShoulder.likelihood < 0.5 || leftHip.likelihood < 0.5) return;

    double bodyAngle = _calculateAngle(leftShoulder, leftHip, leftAnkle);

    if (bodyAngle < 160) {
      isFormCorrect = false;
      feedbackMessage = "Alinhe o quadril!";
      accuracyScore = math.max(0, accuracyScore - 1);
      lastPlankTick = null; // Pause timer
    } else {
      isFormCorrect = true;
      feedbackMessage = "Segure firme!";
      accuracyScore = math.min(100, accuracyScore + 0.3);
      
      final now = DateTime.now();
      if (lastPlankTick == null) {
        lastPlankTick = now;
      } else {
        if (now.difference(lastPlankTick!).inSeconds >= 1) {
          plankSeconds++;
          lastPlankTick = now;
        }
      }
    }
    historyAccuracy.add(accuracyScore);
  }
}
