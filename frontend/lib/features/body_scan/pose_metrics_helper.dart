import 'dart:math';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseMetricsHelper {
  static Map<String, double>? calculateEstimatedMetrics(
      Pose? lastPose, double userHeight) {
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

    if (shoulderL == null || shoulderR == null || hipL == null || hipR == null) {
      return null;
    }

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
    final waist = widthToCircumference(
        (shoulderWidthPixels + hipWidthPixels) / 2 * 0.85, 2.6);
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
      metrics['waist_hip_ratio'] =
          double.parse((waist / hips).toStringAsFixed(2));
    }

    // Relação Cintura-Altura (Gordura Abdominal)
    if (userHeight > 0) {
      metrics['waist_height_ratio'] =
          double.parse((waist / userHeight).toStringAsFixed(2));
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
    required Size frontSize,
    required Pose sidePose,
    required Size sideSize,
    required double userHeight,
  }) {
    // 1. Get Scales (using pixel-based height)
    final frontScale = _getPixelToCmScale(frontPose, frontSize, userHeight);
    final sideScale = _getPixelToCmScale(sidePose, sideSize, userHeight);

    if (frontScale == null || sideScale == null) return null;

    dev.log(">>> AI SCAN DEBUG: Front Scale: $frontScale, Side Scale: $sideScale");

    // 2. Get Widths (Front) and Depths (Side)
    final fLandmarks = frontPose.landmarks;
    final sLandmarks = sidePose.landmarks;

    // --- CHEST ---
    // Extracting pixel-based width and depth
    final fShoulderW = (_getPX(frontPose.landmarks[PoseLandmarkType.leftShoulder]!, frontSize) - 
                        _getPX(frontPose.landmarks[PoseLandmarkType.rightShoulder]!, frontSize)).abs() * frontScale;
    
    final sShoulderD = (_getPX(sidePose.landmarks[PoseLandmarkType.leftShoulder]!, sideSize) - 
                        _getPX(sidePose.landmarks[PoseLandmarkType.rightShoulder]!, sideSize)).abs() * sideScale;

    dev.log(">>> AI SCAN DEBUG: Chest Width: $fShoulderW, Depth: $sShoulderD");

    final fHipW = (_getPX(frontPose.landmarks[PoseLandmarkType.leftHip]!, frontSize) - 
                   _getPX(frontPose.landmarks[PoseLandmarkType.rightHip]!, frontSize)).abs() * frontScale;
    final sHipD = (_getPX(sidePose.landmarks[PoseLandmarkType.leftHip]!, sideSize) - 
                   _getPX(sidePose.landmarks[PoseLandmarkType.rightHip]!, sideSize)).abs() * sideScale;

    dev.log(">>> AI SCAN DEBUG: Hip Width: $fHipW, Depth: $sHipD");

    // --- CALCULATION ---
    // Multipliers increased to account for tissue (skin/muscle) depth beyond the skeletal joints
    final chestDepth = max(sShoulderD * 1.85, fShoulderW * 0.72); // Fallback to 72% of width if depth is too small
    final hipDepth = max(sHipD * 1.95, fHipW * 0.82);   // Fallback to 82% of width (common for hips)
    
    final chest = _ellipseCircumference(fShoulderW * 1.15, chestDepth) * 1.08;
    final waist = _ellipseCircumference((fShoulderW + fHipW) / 2 * 0.9, (chestDepth + hipDepth) / 2 * 0.85) * 0.98;
    final hips = _ellipseCircumference(fHipW * 1.05, hipDepth) * 1.05;

    dev.log(">>> AI SCAN DEBUG: Final - Chest: $chest, Waist: $waist, Hips: $hips");

    final Map<String, double> metrics = {
      'shoulders': (fShoulderW * 2.6).roundToDouble(),
      'chest': chest.roundToDouble(),
      'waist': waist.roundToDouble(),
      'hips': hips.roundToDouble(),
      'v_shape': double.parse(((fShoulderW * 2.6) / waist).toStringAsFixed(2)),
    };

    // Add individual limb measurements using average of both poses where possible
    // (Limbs are mostly cylindrical, so we can average the estimated diameters)
    // For brevity, we'll use the existing cylindrical logic but with improved scaling.

    return metrics;
  }

  static double? _getPixelToCmScale(Pose pose, Size imageSize, double userHeight) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (nose == null || leftAnkle == null || rightAnkle == null) return null;

    // Detect if coordinates are normalized (0..1)
    double noseY = _getPY(nose, imageSize);
    double ankleY = (_getPY(leftAnkle, imageSize) + _getPY(rightAnkle, imageSize)) / 2;

    final bodyHeightPixels = (ankleY - noseY).abs();
    if (bodyHeightPixels <= 10) return null;

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

  static double _getPX(PoseLandmark lm, Size size) => lm.x <= 1.0 ? lm.x * size.width : lm.x;
  static double _getPY(PoseLandmark lm, Size size) => lm.y <= 1.0 ? lm.y * size.height : lm.y;

  /// Calcula a distância euclidiana entre dois landmarks em pixels
  static double _distance(PoseLandmark a, PoseLandmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
  }
}
