import 'package:flutter/foundation.dart';

class Log {
  /// Base logs that only appear in Debug mode
  static void d(Object? message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] ${DateTime.now()}: $message');
    }
  }

  /// Info logs
  static void i(Object? message) {
    print('[INFO] ${DateTime.now()}: $message');
  }
  
  /// Error logs
  static void e(Object? message, [dynamic error, StackTrace? stackTrace]) {
    print('[ERROR] ${DateTime.now()}: $message');
    if (error != null) print('Error detail: $error');
    if (stackTrace != null) print('StackTrace: $stackTrace');
  }
  
  /// Success logs
  static void s(Object? message) {
    print('[SUCCESS] ${DateTime.now()}: $message');
  }
}
