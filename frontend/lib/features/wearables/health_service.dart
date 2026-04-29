import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final Health _health = Health();
  
  bool _isAuthorized = false;
  bool get isAuthorized => _isAuthorized;

  Future<bool> requestPermissions() async {
    // Determine the types of health data we want to read
    final types = [
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.HEART_RATE,
    ];

    // Request permissions for ACTIVITY_RECOGNITION on Android
    if (Platform.isAndroid) {
      final activityRecognitionStatus = await Permission.activityRecognition.request();
      if (!activityRecognitionStatus.isGranted) {
        return false;
      }
    }

    try {
      // Request access to health data
      bool authorized = await _health.requestAuthorization(
        types,
        permissions: types.map((e) => HealthDataAccess.READ).toList(),
      );
      
      _isAuthorized = authorized;
      return authorized;
    } catch (error) {
      print("Error requesting health permissions: $error");
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchDailySummary() async {
    if (!_isAuthorized) {
      bool authorized = await requestPermissions();
      if (!authorized) {
        return {
          'steps': 0,
          'calories': 0,
          'heartRate': 0,
          'error': 'Permission denied'
        };
      }
    }

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    
    int totalSteps = 0;
    int totalCalories = 0;
    int avgHeartRate = 0;

    try {
      // Steps
      final stepsData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: midnight,
        endTime: now,
      );
      
      for (var data in stepsData) {
        if (data.value is NumericHealthValue) {
          totalSteps += (data.value as NumericHealthValue).numericValue.toInt();
        }
      }

      // Calories
      final calData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: midnight,
        endTime: now,
      );
      
      for (var data in calData) {
        if (data.value is NumericHealthValue) {
          totalCalories += (data.value as NumericHealthValue).numericValue.toInt();
        }
      }

      // Heart Rate (get last 24h average or latest)
      final hrData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: midnight,
        endTime: now,
      );
      
      if (hrData.isNotEmpty) {
        double sum = 0;
        int count = 0;
        for (var data in hrData) {
          if (data.value is NumericHealthValue) {
            sum += (data.value as NumericHealthValue).numericValue.toDouble();
            count++;
          }
        }
        if (count > 0) {
          avgHeartRate = (sum / count).round();
        }
      }

      return {
        'steps': totalSteps,
        'calories': totalCalories,
        'heartRate': avgHeartRate,
      };
    } catch (e) {
      print("Error fetching health data: $e");
      return {
        'steps': 0,
        'calories': 0,
        'heartRate': 0,
        'error': e.toString()
      };
    }
  }
}
