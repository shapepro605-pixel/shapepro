import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class Log {
  /// Base logs that only appear in Debug mode
  static void d(Object? message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] ${DateTime.now()}: $message');
    }
  }

  /// Info logs - visible in release via logcat
  static void i(Object? message) {
    developer.log('[INFO] $message', name: 'ShapePro');
    print('[INFO] ${DateTime.now()}: $message');
  }
  
  /// Error logs - visible in release via logcat
  static void e(Object? message, [dynamic error, StackTrace? stackTrace]) {
    developer.log('[ERROR] $message', name: 'ShapePro', error: error, stackTrace: stackTrace);
    print('[ERROR] ${DateTime.now()}: $message');
    if (error != null) print('Error detail: $error');
    if (stackTrace != null) print('StackTrace: $stackTrace');
  }
  
  /// Success logs - visible in release via logcat
  static void s(Object? message) {
    developer.log('[SUCCESS] $message', name: 'ShapePro');
    print('[SUCCESS] ${DateTime.now()}: $message');
  }
}
