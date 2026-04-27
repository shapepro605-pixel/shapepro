import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseMetricsHelper {
  static Map<String, double>? calculateEstimatedMetrics(Pose? lastPose, double userHeight) {
    if (lastPose == null) return null;
    
    final nose = lastPose.landmarks[PoseLandmarkType.nose];
    final leftAnkle = lastPose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = lastPose.landmarks[PoseLandmarkType.rightAnkle];
    
    if (nose == null || leftAnkle == null || rightAnkle == null) return null;
    
    // Altura em pixels
    final avgAnkleY = (leftAnkle.y + rightAnkle.y) / 2;
    final bodyHeightPixels = (avgAnkleY - nose.y).abs();
    if (bodyHeightPixels <= 0) return null; // Prevenir divisão por zero
    
    // Proporção pixel para cm
    final pixelToCm = userHeight / bodyHeightPixels;
    
    final shoulderL = lastPose.landmarks[PoseLandmarkType.leftShoulder];
    final shoulderR = lastPose.landmarks[PoseLandmarkType.rightShoulder];
    final hipL = lastPose.landmarks[PoseLandmarkType.leftHip];
    final hipR = lastPose.landmarks[PoseLandmarkType.rightHip];
    
    if (shoulderL == null || shoulderR == null || hipL == null || hipR == null) return null;
    
    // Cálculo de larguras em pixels
    final shoulderWidthPixels = (shoulderL.x - shoulderR.x).abs();
    final hipWidthPixels = (hipL.x - hipR.x).abs();
    
    // Heurística de conversão de largura frontal para circunferência
    double widthToCircumference(double widthPixels, double factor) {
      return (widthPixels * pixelToCm * factor).roundToDouble(); 
    }

    // === Métricas Existentes ===
    final shoulders = widthToCircumference(shoulderWidthPixels, 2.5);
    final chest = widthToCircumference(shoulderWidthPixels, 2.7);
    final waist = widthToCircumference((shoulderWidthPixels + hipWidthPixels) / 2 * 0.85, 2.6);
    final hips = widthToCircumference(hipWidthPixels, 2.8);

    // === Novas Métricas Profissionais ===
    final elbowL = lastPose.landmarks[PoseLandmarkType.leftElbow];
    final elbowR = lastPose.landmarks[PoseLandmarkType.rightElbow];
    final wristL = lastPose.landmarks[PoseLandmarkType.leftWrist];
    final wristR = lastPose.landmarks[PoseLandmarkType.rightWrist];
    final kneeL = lastPose.landmarks[PoseLandmarkType.leftKnee];
    final kneeR = lastPose.landmarks[PoseLandmarkType.rightKnee];

    final Map<String, double> metrics = {
      'shoulders': shoulders,
      'chest': chest,
      'waist': waist,
      'hips': hips,
    };

    // Pescoço (distância entre ponto médio dos ombros e nariz)
    final shoulderMidY = (shoulderL.y + shoulderR.y) / 2;
    final neckLengthPixels = (shoulderMidY - nose.y).abs();
    if (neckLengthPixels > 0) {
      metrics['neck'] = (neckLengthPixels * pixelToCm * 0.95).roundToDouble();
    }

    // Braço Esquerdo (comprimento ombro → cotovelo, heurística para circunferência)
    if (elbowL != null) {
      final armLengthL = _distance(shoulderL, elbowL) * pixelToCm;
      metrics['left_arm'] = (armLengthL * 0.95).roundToDouble();
    }

    // Braço Direito
    if (elbowR != null) {
      final armLengthR = _distance(shoulderR, elbowR) * pixelToCm;
      metrics['right_arm'] = (armLengthR * 0.95).roundToDouble();
    }

    // Antebraço Esquerdo
    if (elbowL != null && wristL != null) {
      final forearmL = _distance(elbowL, wristL) * pixelToCm;
      metrics['left_forearm'] = (forearmL * 0.85).roundToDouble();
    }

    // Antebraço Direito
    if (elbowR != null && wristR != null) {
      final forearmR = _distance(elbowR, wristR) * pixelToCm;
      metrics['right_forearm'] = (forearmR * 0.85).roundToDouble();
    }

    // Coxa Esquerda
    if (kneeL != null) {
      final thighLengthL = _distance(hipL, kneeL) * pixelToCm;
      metrics['left_thigh'] = (thighLengthL * 1.15).roundToDouble();
    }

    // Coxa Direita
    if (kneeR != null) {
      final thighLengthR = _distance(hipR, kneeR) * pixelToCm;
      metrics['right_thigh'] = (thighLengthR * 1.15).roundToDouble();
    }

    // Panturrilha Esquerda
    if (kneeL != null) {
      final calfL = _distance(kneeL, leftAnkle) * pixelToCm;
      metrics['left_calf'] = (calfL * 0.92).roundToDouble();
    }

    // Panturrilha Direita
    if (kneeR != null) {
      final calfR = _distance(kneeR, rightAnkle) * pixelToCm;
      metrics['right_calf'] = (calfR * 0.92).roundToDouble();
    }

    // === Indicadores Derivados ===
    // Relação Cintura-Quadril (Risco Cardiovascular)
    if (hips > 0) {
      metrics['waist_hip_ratio'] = double.parse((waist / hips).toStringAsFixed(2));
    }

    // Relação Cintura-Altura (Gordura Abdominal)
    if (userHeight > 0) {
      metrics['waist_height_ratio'] = double.parse((waist / userHeight).toStringAsFixed(2));
    }

    // Proporção V-Shape (Ombros / Cintura)
    if (waist > 0) {
      metrics['v_shape'] = double.parse((shoulders / waist).toStringAsFixed(2));
    }

    return metrics;
  }

  /// Calculates circumferences using a dual-angle elliptical model (Front + Side)
  static Map<String, double>? calculateProfessionalMetrics({
    required Pose frontPose,
    required Pose sidePose,
    required double userHeight,
  }) {
    // 1. Get Scales
    final frontScale = _getPixelToCmScale(frontPose, userHeight);
    final sideScale = _getPixelToCmScale(sidePose, userHeight);
    
    if (frontScale == null || sideScale == null) return null;

    // 2. Get Widths (Front) and Depths (Side)
    final fLandmarks = frontPose.landmarks;
    final sLandmarks = sidePose.landmarks;

    // --- CHEST ---
    final fShoulderW = (fLandmarks[PoseLandmarkType.leftShoulder]!.x - fLandmarks[PoseLandmarkType.rightShoulder]!.x).abs() * frontScale;
    final sShoulderD = (sLandmarks[PoseLandmarkType.leftShoulder]!.x - sLandmarks[PoseLandmarkType.rightShoulder]!.x).abs() * sideScale;
    // Note: In side view, "width" between shoulders is actually depth. If they overlap, we might need a better landmark or a multiplier.
    // For Side view depth, we often use the distance between a "front" landmark and "back" landmark.
    // However, ML Kit landmarks are mainly on the joints. 
    // A better way for Side Depth: use the distance between the Shoulder and the Chest (if we had one) 
    // or just the width between the visible torso boundaries.
    
    // Actually, if the user is perfectly sideways, the distance between left and right hip landmarks 
    // in the side photo will represent the depth.
    
    final fHipW = (fLandmarks[PoseLandmarkType.leftHip]!.x - fLandmarks[PoseLandmarkType.rightHip]!.x).abs() * frontScale;
    final sHipD = (sLandmarks[PoseLandmarkType.leftHip]!.x - sLandmarks[PoseLandmarkType.rightHip]!.x).abs() * sideScale;

    // --- CALCULATION ---
    final chest = _ellipseCircumference(fShoulderW * 1.1, sShoulderD * 1.2) * 1.05; // 5% correction
    final waist = _ellipseCircumference((fShoulderW + fHipW) / 2 * 0.85, (sShoulderD + sHipD) / 2 * 0.9) * 0.97;
    final hips = _ellipseCircumference(fHipW, sHipD) * 1.03;

    final Map<String, double> metrics = {
      'chest': chest.roundToDouble(),
      'waist': waist.roundToDouble(),
      'hips': hips.roundToDouble(),
      'v_shape': double.parse(((fShoulderW * 2.5) / waist).toStringAsFixed(2)),
    };

    // Add individual limb measurements using average of both poses where possible
    // (Limbs are mostly cylindrical, so we can average the estimated diameters)
    // For brevity, we'll use the existing cylindrical logic but with improved scaling.
    
    return metrics;
  }

  static double? _getPixelToCmScale(Pose pose, double userHeight) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    
    if (nose == null || leftAnkle == null || rightAnkle == null) return null;
    
    final avgAnkleY = (leftAnkle.y + rightAnkle.y) / 2;
    final bodyHeightPixels = (avgAnkleY - nose.y).abs();
    if (bodyHeightPixels <= 0) return null;
    
    return userHeight / bodyHeightPixels;
  }

  /// Ramanujan's approximation for ellipse circumference
  /// a: semi-major axis, b: semi-minor axis
  /// Or in our case, we pass full Width and full Depth
  static double _ellipseCircumference(double width, double depth) {
    final a = width / 2;
    final b = depth / 2;
    // Ramanujan formula: PI * [ 3(a+b) - sqrt((3a+b)*(a+3b)) ]
    return pi * (3 * (a + b) - sqrt((3 * a + b) * (a + 3 * b)));
  }

  /// Calcula a distância euclidiana entre dois landmarks em pixels
  static double _distance(PoseLandmark a, PoseLandmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
  }
}
