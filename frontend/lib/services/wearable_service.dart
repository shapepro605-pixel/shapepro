import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/wearables/health_service.dart';

class WearableService extends ChangeNotifier {
  static final WearableService _instance = WearableService._internal();
  factory WearableService() => _instance;
  WearableService._internal();

  final HealthService _healthService = HealthService();
  
  Map<String, dynamic> _currentData = {};
  Map<String, dynamic> get currentData => _currentData;
  
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  DateTime? _lastSync;
  DateTime? get lastSync => _lastSync;

  // Goals
  int stepGoal = 10000;
  int calorieGoal = 500;

  Future<void> init() async {
    await _loadCache();
  }

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('wearable_data_cache');
    final lastSyncStr = prefs.getString('wearable_last_sync');

    if (cachedData != null) {
      _currentData = jsonDecode(cachedData);
    }
    if (lastSyncStr != null) {
      _lastSync = DateTime.parse(lastSyncStr);
    }
    notifyListeners();
  }

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wearable_data_cache', jsonEncode(_currentData));
    if (_lastSync != null) {
      await prefs.setString('wearable_last_sync', _lastSync!.toIso8601String());
    }
  }

  Future<bool> syncData({dynamic api}) async {
    _isSyncing = true;
    notifyListeners();

    try {
      final newData = await _healthService.fetchDailySummary();
      
      if (newData['error'] == null) {
        _currentData = newData;
        _lastSync = DateTime.now();
        
        // Push to backend if API is available
        if (api != null) {
          try {
            await api.syncWearableData({
              ...newData,
              'fitnessScore': fitnessScore,
              'source': 'health_connect',
            });
          } catch (e) {
            // Log backend sync error but don't fail local sync
          }
        }

        await _saveCache();
        _isSyncing = false;
        notifyListeners();
        return true;
      } else {
        _isSyncing = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  double get fitnessScore {
    if (_currentData.isEmpty) return 0.0;
    
    int steps = _currentData['steps'] ?? 0;
    int calories = _currentData['calories'] ?? 0;
    int sleep = _currentData['sleep'] ?? 0; // minutes
    
    // Simple calculation logic
    double stepPart = (steps / stepGoal).clamp(0.0, 1.0) * 40;
    double caloriePart = (calories / calorieGoal).clamp(0.0, 1.0) * 30;
    double sleepPart = (sleep / 480).clamp(0.0, 1.0) * 30; // 8 hours goal
    
    return stepPart + caloriePart + sleepPart;
  }

  Future<void> updateManualData({int? steps, int? calories, double? distance, dynamic api}) async {
    if (steps != null) _currentData['steps'] = steps;
    if (calories != null) _currentData['calories'] = calories;
    if (distance != null) _currentData['distance'] = distance;
    
    _lastSync = DateTime.now();

    if (api != null) {
      try {
        await api.syncWearableData({
          ..._currentData,
          'fitnessScore': fitnessScore,
          'source': 'manual',
        });
      } catch (e) {
        // Ignore
      }
    }

    await _saveCache();
    notifyListeners();
  }
}
