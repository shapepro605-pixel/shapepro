import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final Health _health = Health();
  
  bool _isAuthorized = false;
  bool get isAuthorized => _isAuthorized;

  // Modern types for Health Connect
  final List<HealthDataType> _dataTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.WORKOUT,
  ];

  Future<bool> isHealthConnectInstalled() async {
    if (Platform.isAndroid) {
      final status = await _health.getHealthConnectSdkStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    }
    return true; // iOS doesn't use Health Connect
  }

  Future<void> openHealthConnectInPlayStore() async {
    const url = 'market://details?id=com.google.android.apps.healthdata';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> openHealthConnectSettings() async {
    if (Platform.isAndroid) {
      try {
        await _health.openHealthConnectSettings();
      } catch (e) {
        print("Error opening Health Connect settings: $e");
      }
    }
  }

  Future<bool> requestPermissions() async {
    // Request permissions for ACTIVITY_RECOGNITION and BODY_SENSORS on Android
    if (Platform.isAndroid) {
      final activityRecognitionStatus = await Permission.activityRecognition.request();
      final bodySensorsStatus = await Permission.sensors.request();
      
      if (!activityRecognitionStatus.isGranted || !bodySensorsStatus.isGranted) {
        // Log or handle denial
      }
    }

    try {
      // Request access to health data
      bool authorized = await _health.requestAuthorization(
        _dataTypes,
        permissions: _dataTypes.map((e) => HealthDataAccess.READ).toList(),
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
          'distance': 0.0,
          'sleep': 0,
          'workouts': [],
          'error': 'Permission denied'
        };
      }
    }

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    
    int totalSteps = 0;
    int totalCalories = 0;
    int avgHeartRate = 0;
    double totalDistance = 0.0;
    int sleepMinutes = 0;
    List<Map<String, dynamic>> workouts = [];

    try {
      // Fetch all data in parallel or sequence
      final healthData = await _health.getHealthDataFromTypes(
        types: _dataTypes,
        startTime: midnight,
        endTime: now,
      );

      for (var data in healthData) {
        if (data.value is NumericHealthValue) {
          final val = (data.value as NumericHealthValue).numericValue;
          switch (data.type) {
            case HealthDataType.STEPS:
              totalSteps += val.toInt();
              break;
            case HealthDataType.ACTIVE_ENERGY_BURNED:
              totalCalories += val.toInt();
              break;
            case HealthDataType.DISTANCE_DELTA:
              totalDistance += val.toDouble();
              break;
            case HealthDataType.HEART_RATE:
              // We'll calculate average later if needed, for now just keep track
              break;
            default:
              break;
          }
        } else if (data.type == HealthDataType.SLEEP_SESSION) {
          final duration = data.dateTo.difference(data.dateFrom).inMinutes;
          sleepMinutes += duration;
        } else if (data.type == HealthDataType.WORKOUT) {
          final workoutValue = data.value as WorkoutHealthValue;
          workouts.add({
            'type': workoutValue.workoutActivityType.name,
            'duration': data.dateTo.difference(data.dateFrom).inMinutes,
            'calories': workoutValue.totalEnergyBurned ?? 0,
            'distance': workoutValue.totalDistance ?? 0,
            'startTime': data.dateFrom,
          });
        }
      }

      // Special handling for average heart rate
      final hrData = healthData.where((d) => d.type == HealthDataType.HEART_RATE).toList();
      if (hrData.isNotEmpty) {
        double sum = 0;
        int count = 0;
        for (var d in hrData) {
          if (d.value is NumericHealthValue) {
            sum += (d.value as NumericHealthValue).numericValue.toDouble();
            count++;
          }
        }
        if (count > 0) avgHeartRate = (sum / count).round();
      }

      return {
        'steps': totalSteps,
        'calories': totalCalories,
        'heartRate': avgHeartRate,
        'distance': totalDistance / 1000, // Convert to km
        'sleep': sleepMinutes,
        'workouts': workouts,
      };
    } catch (e) {
      print("Error fetching health data: $e");
      return {
        'steps': 0,
        'calories': 0,
        'heartRate': 0,
        'distance': 0.0,
        'sleep': 0,
        'workouts': [],
        'error': e.toString()
      };
    }
  }
}
