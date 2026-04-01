import 'package:flutter/material.dart';
 
class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF6C5CE7);
  static const Color secondary = Color(0xFF00D2FF);
  static const Color accent = Color(0xFFFD4556);
  
  // Neutral Colors
  static const Color background = Color(0xFF0A0A1A);
  static const Color surface = Color(0xFF16162A);
  static const Color card = Color(0xFF1E1E38);
  static const Color border = Color(0xFF2A2A4A);
  
  // Status Colors
  static const Color success = Color(0xFF2ED573);
  static const Color warning = Color(0xFFFFA502);
  static const Color error = Color(0xFFFD4556);
  static const Color premium = Color(0xFFFFD700);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
