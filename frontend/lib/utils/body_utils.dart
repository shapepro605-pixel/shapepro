import 'package:flutter/material.dart';

class BodyUtils {
  /// Formata peso para a localidade (kg ou lbs)
  static String formatWeight(BuildContext context, dynamic valueInKg) {
    if (valueInKg == null || valueInKg == '--' || valueInKg == '') return '--';
    double kg = double.tryParse(valueInKg.toString()) ?? 0.0;
    if (kg == 0) return '--';
    
    if (Localizations.localeOf(context).languageCode == 'en') {
      return "${(kg * 2.20462).toStringAsFixed(1)} lbs";
    }
    return "${kg.toStringAsFixed(1)} kg";
  }

  /// Formata medida para a localidade (cm ou inches)
  static String formatMeasure(BuildContext context, dynamic valueInCm, {bool isHeight = false, bool isPercentage = false}) {
    if (valueInCm == null || valueInCm == '--' || valueInCm == '') return '--';
    if (isPercentage) return "$valueInCm %";
    
    double cm = double.tryParse(valueInCm.toString()) ?? 0.0;
    if (cm == 0) return '--';
    
    if (Localizations.localeOf(context).languageCode == 'en') {
      double totalInches = cm / 2.54;
      if (isHeight) {
        int feet = totalInches ~/ 12;
        int inches = (totalInches % 12).round();
        return "$feet'$inches\"";
      } else {
        return "${totalInches.toStringAsFixed(1)}\"";
      }
    }
    return "${cm.toStringAsFixed(1)} cm";
  }

  /// Calcula IMC (BMI)
  static String calculateIMC(dynamic peso, dynamic altura) {
    try {
      double w = double.parse(peso.toString());
      double h = double.parse(altura.toString()) / 100;
      if (h <= 0) return "--";
      return (w / (h * h)).toStringAsFixed(1);
    } catch (e) {
      return "--";
    }
  }

  /// Calcula a diferença entre duas medidas e retorna formatado (ex: +2.1 ou -1.5)
  static String getDeltaString(dynamic newValue, dynamic oldValue) {
    try {
      double n = double.parse(newValue.toString());
      double o = double.parse(oldValue.toString());
      double diff = n - o;
      String sign = diff > 0 ? "+" : "";
      return "$sign${diff.toStringAsFixed(1)}";
    } catch (e) {
      return "--";
    }
  }

  /// Retorna a cor baseada na diferença (positivo/negativo)
  static Color getDeltaColor(dynamic newValue, dynamic oldValue, {bool reverse = false}) {
    try {
      double n = double.parse(newValue.toString());
      double o = double.parse(oldValue.toString());
      double diff = n - o;
      if (diff.abs() < 0.1) return Colors.white54;
      
      bool isPositiveChange = diff > 0;
      if (reverse) isPositiveChange = !isPositiveChange;
      
      return isPositiveChange ? const Color(0xFF2ED573) : const Color(0xFFFD4556);
    } catch (e) {
      return Colors.white54;
    }
  }
}
