import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class NeonPosePainter extends CustomPainter {
  final Pose? pose;
  final Size imageSize;
  final Map<String, double>? metrics;
  final bool isFrontCamera;

  NeonPosePainter({
    required this.pose, 
    required this.imageSize, 
    this.metrics, 
    this.isFrontCamera = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pose == null) return;

    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;
    final double scale = scaleX > scaleY ? scaleX : scaleY;
    final double offsetX = (size.width - imageSize.width * scale) / 2;
    final double offsetY = (size.height - imageSize.height * scale) / 2;

    double tx(double x) {
      double scaledX = x * scale + offsetX;
      return isFrontCamera ? size.width - scaledX : scaledX;
    }
    double ty(double y) => y * scale + offsetY;

    final lm = pose!.landmarks;

    final shoulderL = lm[PoseLandmarkType.leftShoulder];
    final shoulderR = lm[PoseLandmarkType.rightShoulder];
    final hipL = lm[PoseLandmarkType.leftHip];
    final hipR = lm[PoseLandmarkType.rightHip];
    final elbowL = lm[PoseLandmarkType.leftElbow];
    final elbowR = lm[PoseLandmarkType.rightElbow];
    final wristL = lm[PoseLandmarkType.leftWrist];
    final wristR = lm[PoseLandmarkType.rightWrist];
    final kneeL = lm[PoseLandmarkType.leftKnee];
    final kneeR = lm[PoseLandmarkType.rightKnee];
    final ankleL = lm[PoseLandmarkType.leftAnkle];
    final ankleR = lm[PoseLandmarkType.rightAnkle];
    final nose = lm[PoseLandmarkType.nose];

    if (shoulderL == null || shoulderR == null || hipL == null || hipR == null) return;

    // === TINTAS NEON PROFISSIONAIS ===
    final neonGreen = const Color(0xFF00FF88);
    final neonCyan = const Color(0xFF00E5FF);

    // Efeito Bloom: Camada de brilho intenso externo
    final outerGlowPaint = Paint()
      ..color = neonGreen.withValues(alpha: 0.15)
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // Efeito Bloom: Camada de brilho médio
    final innerGlowPaint = Paint()
      ..color = neonGreen.withValues(alpha: 0.4)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Linha central sólida
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = neonCyan
      ..style = PaintingStyle.fill;

    final dotGlowPaint = Paint()
      ..color = neonCyan.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // === DESENHAR PONTOS NOS LANDMARKS ===
    void drawDot(PoseLandmark? point) {
      if (point == null) return;
      canvas.drawCircle(Offset(tx(point.x), ty(point.y)), 6, dotGlowPaint);
      canvas.drawCircle(Offset(tx(point.x), ty(point.y)), 3, dotPaint);
    }

    // Todos os pontos de referência
    for (var p in [shoulderL, shoulderR, hipL, hipR, elbowL, elbowR, 
                   wristL, wristR, kneeL, kneeR, ankleL, ankleR, nose]) {
      drawDot(p);
    }

    // === CONECTAR CORPO COM LINHAS NEON ===
    void drawLine(PoseLandmark? a, PoseLandmark? b) {
      if (a == null || b == null) return;
      final start = Offset(tx(a.x), ty(a.y));
      final end = Offset(tx(b.x), ty(b.y));
      
      canvas.drawLine(start, end, outerGlowPaint);
      canvas.drawLine(start, end, innerGlowPaint);
      canvas.drawLine(start, end, linePaint);
    }

    // Esqueleto corporal
    drawLine(shoulderL, shoulderR);
    drawLine(shoulderL, elbowL);
    drawLine(elbowL, wristL);
    drawLine(shoulderR, elbowR);
    drawLine(elbowR, wristR);
    drawLine(shoulderL, hipL);
    drawLine(shoulderR, hipR);
    drawLine(hipL, hipR);
    drawLine(hipL, kneeL);
    drawLine(hipR, kneeR);
    drawLine(kneeL, ankleL);
    drawLine(kneeR, ankleR);

    // Linha central (pescoço)
    if (nose != null) {
      final neckX = (shoulderL.x + shoulderR.x) / 2;
      final neckY = (shoulderL.y + shoulderR.y) / 2;
      drawLine(nose, PoseLandmark(type: PoseLandmarkType.nose, x: neckX, y: neckY, z: 0, likelihood: 1));
    }

    // === LABELS DE MÉTRICAS AO LADO DO CORPO ===
    if (metrics == null) return;

    void drawMetricLabel(double x, double y, String label, String value, {bool leftSide = true}) {
      const double labelWidth = 100.0;
      final double screenWidth = size.width;
      final double screenHeight = size.height;
      
      // Calcular a posição X final baseada no lado
      double finalX = tx(x);
      double finalY = ty(y);
      double labelOffset = leftSide ? -(labelWidth + 20) : 20.0;
      
      // Lógica de Prevenção de Transbordamento Horizontal (Overflow protection)
      if (finalX + labelOffset < 10) {
        labelOffset = 20.0; // Joga pra direita se sair na esquerda
      } else if (finalX + labelOffset + labelWidth > screenWidth - 10) {
        labelOffset = -(labelWidth + 20); // Joga pra esquerda se sair na direita
      }

      // Lógica de Prevenção de Transbordamento Vertical
      double adjustedY = finalY;
      if (finalY - 16 < 80) adjustedY = 96; // Não sobe demais (barras de status)
      if (finalY + 16 > screenHeight - 150) adjustedY = screenHeight - 166; // Não desce demais (botões)

      final lineEnd = labelOffset > 0 ? 20.0 : -20.0;

      // Linha conectora elegante
      final connectorPaint = Paint()
        ..color = neonGreen.withValues(alpha: 0.6)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(finalX, finalY),
        Offset(finalX + lineEnd, adjustedY),
        connectorPaint,
      );

      // Background do label (Glassmorphism / Blur Manual)
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          finalX + labelOffset, adjustedY - 18,
          labelWidth, 36,
        ),
        const Radius.circular(10),
      );

      final bgPaint = Paint()
        ..color = const Color(0xFF0A0A1A).withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = neonGreen.withValues(alpha: 0.4)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(bgRect, bgPaint);
      canvas.drawRRect(bgRect, borderPaint);

      // Texto do label com tipografia superior
      final labelPainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$label\n",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            TextSpan(
              text: "$value cm",
              style: TextStyle(
                color: neonGreen,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: neonGreen.withValues(alpha: 0.5), blurRadius: 4),
                ],
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      labelPainter.layout(minWidth: labelWidth);
      labelPainter.paint(canvas, Offset(finalX + labelOffset, adjustedY - 15));
    }

    // === POSICIONAR MÉTRICAS NOS PONTOS CORRETOS ===

    // Peito - entre os ombros
    final chestY = (shoulderL.y + shoulderR.y) / 2 + 10;
    drawMetricLabel(shoulderL.x, chestY, "PEITO", "${metrics!['chest']?.toInt() ?? '--'}", leftSide: false);

    // Cintura - entre ombros e quadril
    final waistY = (shoulderL.y + hipL.y) / 2;
    drawMetricLabel(shoulderR.x, waistY, "CINTURA", "${metrics!['waist']?.toInt() ?? '--'}");

    // Quadril - nos quadris
    final hipY = (hipL.y + hipR.y) / 2;
    drawMetricLabel(hipL.x, hipY, "QUADRIL", "${metrics!['hips']?.toInt() ?? '--'}", leftSide: false);

    // Braço Esquerdo - no cotovelo esquerdo
    if (elbowL != null && metrics!['left_arm'] != null) {
      drawMetricLabel(elbowL.x, elbowL.y, "BRAÇO E.", "${metrics!['left_arm']!.toInt()}", leftSide: false);
    }

    // Braço Direito - no cotovelo direito
    if (elbowR != null && metrics!['right_arm'] != null) {
      drawMetricLabel(elbowR.x, elbowR.y, "BRAÇO D.", "${metrics!['right_arm']!.toInt()}");
    }

    // Coxa Esquerda - entre quadril e joelho esquerdo
    if (kneeL != null && metrics!['left_thigh'] != null) {
      final thighY = (hipL.y + kneeL.y) / 2;
      drawMetricLabel(hipL.x, thighY, "COXA E.", "${metrics!['left_thigh']!.toInt()}", leftSide: false);
    }

    // Coxa Direita - entre quadril e joelho direito
    if (kneeR != null && metrics!['right_thigh'] != null) {
      final thighY = (hipR.y + kneeR.y) / 2;
      drawMetricLabel(hipR.x, thighY, "COXA D.", "${metrics!['right_thigh']!.toInt()}");
    }

    // Panturrilha Esquerda - entre joelho e tornozelo esquerdo
    if (kneeL != null && ankleL != null && metrics!['left_calf'] != null) {
      final calfY = (kneeL.y + ankleL.y) / 2;
      drawMetricLabel(kneeL.x, calfY, "PANT. E.", "${metrics!['left_calf']!.toInt()}", leftSide: false);
    }

    // Panturrilha Direita
    if (kneeR != null && ankleR != null && metrics!['right_calf'] != null) {
      final calfY = (kneeR.y + ankleR.y) / 2;
      drawMetricLabel(kneeR.x, calfY, "PANT. D.", "${metrics!['right_calf']!.toInt()}");
    }
  }

  @override
  bool shouldRepaint(covariant NeonPosePainter oldDelegate) => true;
}
