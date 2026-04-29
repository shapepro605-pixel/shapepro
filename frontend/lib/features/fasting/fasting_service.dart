import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

enum FastingState {
  notStarted,
  fasting,
  eatingWindow,
}

class FastingService {
  static const String _keyStartTime = 'fasting_start_time';
  static const String _keyTargetHours = 'fasting_target_hours';
  static const String _keyState = 'fasting_state';

  // Singleton
  static final FastingService _instance = FastingService._internal();
  factory FastingService() => _instance;
  FastingService._internal();

  DateTime? startTime;
  int targetHours = 16;
  FastingState currentState = FastingState.notStarted;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    final stateIdx = prefs.getInt(_keyState) ?? 0;
    currentState = FastingState.values[stateIdx];
    
    targetHours = prefs.getInt(_keyTargetHours) ?? 16;
    
    final timeStr = prefs.getString(_keyStartTime);
    if (timeStr != null) {
      startTime = DateTime.parse(timeStr);
    }
    
    _checkStatus();
  }

  void _checkStatus() {
    if (currentState == FastingState.fasting && startTime != null) {
      final elapsedHours = DateTime.now().difference(startTime!).inHours;
      if (elapsedHours >= targetHours) {
        // Fasting completed automatically transitioning to eating window is a choice,
        // but normally the user stops it. We'll leave it fasting until user stops.
      }
    }
  }

  Future<void> startFasting(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    targetHours = hours;
    startTime = DateTime.now();
    currentState = FastingState.fasting;

    await prefs.setInt(_keyTargetHours, targetHours);
    await prefs.setString(_keyStartTime, startTime!.toIso8601String());
    await prefs.setInt(_keyState, currentState.index);
  }

  Future<void> stopFasting() async {
    final prefs = await SharedPreferences.getInstance();
    // Move to eating window
    currentState = FastingState.eatingWindow;
    startTime = DateTime.now(); // Eating window starts now
    
    await prefs.setString(_keyStartTime, startTime!.toIso8601String());
    await prefs.setInt(_keyState, currentState.index);
  }
  
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    currentState = FastingState.notStarted;
    startTime = null;
    
    await prefs.remove(_keyStartTime);
    await prefs.setInt(_keyState, currentState.index);
  }

  Duration get elapsedTime {
    if (startTime == null) return Duration.zero;
    return DateTime.now().difference(startTime!);
  }
  
  Duration get remainingTime {
    if (startTime == null || currentState != FastingState.fasting) return Duration.zero;
    final targetDuration = Duration(hours: targetHours);
    final elapsed = elapsedTime;
    if (elapsed > targetDuration) return Duration.zero;
    return targetDuration - elapsed;
  }
  
  double get progress {
    if (startTime == null || currentState != FastingState.fasting) return 0.0;
    final targetDurationMs = Duration(hours: targetHours).inMilliseconds;
    final elapsedMs = elapsedTime.inMilliseconds;
    return (elapsedMs / targetDurationMs).clamp(0.0, 1.0);
  }
}
