import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click if needed
      },
    );

    // Create Notification Channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'diet_reminders',
      'Lembretes de Dieta',
      description: 'Notificações para os horários das suas refeições.',
      importance: Importance.max,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<bool> requestPermissions() async {
    final bool? result = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return result ?? false;
  }

  static Future<void> scheduleDietNotifications(List<dynamic> refeicoes) async {
    final prefs = await SharedPreferences.getInstance();
    final bool enabled = prefs.getBool('notifications_enabled') ?? false;
    
    if (!enabled) {
      await cancelAllNotifications();
      return;
    }

    await cancelAllNotifications(); // Clear existing to avoid duplicates

    for (int i = 0; i < refeicoes.length; i++) {
      final refeicao = refeicoes[i];
      final String? horario = refeicao['horario']; // Format "HH:mm"
      if (horario == null) continue;

      final parts = horario.split(':');
      if (parts.length != 2) continue;

      final int hour = int.parse(parts[0]);
      final int minute = int.parse(parts[1]);

      await _scheduleDailyNotification(
        i,
        'Hora da sua dieta! 🍎',
        'Está na hora do seu ${refeicao['nome']}. Não esqueça de registrar!',
        hour,
        minute,
      );
    }
  }

  static Future<void> _scheduleDailyNotification(
      int id, String title, String body, int hour, int minute) async {
    
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'diet_reminders',
          'Lembretes de Dieta',
          channelDescription: 'Notificações para os horários das suas refeições.',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
