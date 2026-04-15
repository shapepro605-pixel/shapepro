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

  /// Calcula a distância euclidiana entre dois landmarks em pixels
  static double _distance(PoseLandmark a, PoseLandmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
  }
}
