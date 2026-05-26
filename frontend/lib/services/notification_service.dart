import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final String timezone = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timezone));
    } catch (e) {
      // Ignorar e manter UTC caso falhe
    }
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle click
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'shapepro_notifications',
      'Notificações ShapePro',
      description: 'Lembretes de dieta e reflexões diárias.',
      importance: Importance.max,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<String> _getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString('user_data');
    if (userData != null) {
      final user = jsonDecode(userData);
      return user['nome'] ?? "Atleta";
    }
    return "Atleta";
  }

  static Future<bool> requestPermissions() async {
    final bool? result = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return result ?? false;
  }



  static Future<void> scheduleDietNotifications(List<dynamic> refeicoes, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool enabled = prefs.getBool('notifications_enabled') ?? false;
    
    if (!enabled) {
      await cancelAllNotifications();
      return;
    }

    final name = await _getUserName();

    for (int i = 0; i < refeicoes.length; i++) {
      final refeicao = refeicoes[i];
      final String? horario = refeicao['horario'];
      if (horario == null) continue;

      final parts = horario.split(':');
      if (parts.length != 2) continue;

      final int hour = int.parse(parts[0]);
      final int minute = int.parse(parts[1]);

      await _scheduleDailyNotification(
        i,
        "$name, hora da sua dieta! 🍎",
        'Está na hora do seu ${refeicao['nome']}. Não esqueça de registrar!',
        hour,
        minute,
        type: 'diet',
      );
    }
    

  }

  static Future<void> _scheduleDailyNotification(
      int id, String title, String body, int hour, int minute, {String type = 'diet'}) async {
    
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'shapepro_notifications',
          'Notificações ShapePro',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    
    // Note: We don't save to history here anymore because this is a future schedule.
    // The history should represent delivered or "today's current" notifications.
  }

  static Future<void> _scheduleExactNotification(
      int id, String title, String body, tz.TZDateTime scheduledDate, {String type = 'faith'}) async {
    
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'shapepro_notifications',
          'Notificações ShapePro',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> scheduleComparisonReminder() async {
    final name = await _getUserName();
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(const Duration(days: 7)); // Weekly check-in

    await _notificationsPlugin.zonedSchedule(
      id: 999,
      title: "$name, hora do check-in semanal! 📸",
      body: 'Sua foto semanal da evolução está te esperando. Mantenha o foco!',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'shapepro_notifications',
          'Notificações ShapePro',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> _saveToHistory(String title, String body, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('notification_history');
    List<dynamic> history = historyJson != null ? jsonDecode(historyJson) : [];
    
    history.add({
      'title': title,
      'body': body,
      'type': type,
      'time': DateTime.now().toIso8601String(),
    });

    if (history.length > 50) history.removeAt(0);
    await prefs.setString('notification_history', jsonEncode(history));
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> playNotificationSound() async {
    try {
      await _notificationsPlugin.show(
        id: 888, // ID fixo para o som
        title: null, // Sem título
        body: null, // Sem corpo, apenas som
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'shapepro_notifications',
            'Notificações ShapePro',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
      // Cancela a notificação logo em seguida para não ficar na barra
      // O som já terá sido engatilhado
      Future.delayed(const Duration(milliseconds: 500), () {
        _notificationsPlugin.cancel(id: 888);
      });
    } catch (e) {
      // Falha silenciosa
    }
  }
}
