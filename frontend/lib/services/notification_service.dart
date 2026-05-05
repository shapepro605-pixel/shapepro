import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static final List<Map<String, String>> _reflections = [
    {'title': 'Bom dia com Deus! ✨', 'body': 'O Senhor é o meu pastor, nada me faltará. (Salmos 23:1)'},
    {'title': 'Reflexão do Dia 🙏', 'body': 'Tudo posso naquele que me fortalece. (Filipenses 4:13)'},
    {'title': 'Pão Diário 🍞', 'body': 'Ainda que eu ande pelo vale da sombra da morte, não temerei mal algum. (Salmos 23:4)'},
    {'title': 'Mensagem de Fé 🕊️', 'body': 'Entrega o teu caminho ao Senhor; confia nele, e ele tudo fará. (Salmos 37:5)'},
    {'title': 'Deus está contigo! ⚡', 'body': 'O meu socorro vem do Senhor, que fez o céu e a terra. (Salmos 121:2)'},
    {'title': 'Força e Coragem 💪', 'body': 'Espera no Senhor, anima-te, e ele fortalecerá o teu coração. (Salmos 27:14)'},
    {'title': 'Amor Incondicional ❤️', 'body': 'Porque Deus amou o mundo de tal maneira que deu o seu Filho unigênito. (João 3:16)'},
    {'title': 'Luz no Caminho 🕯️', 'body': 'Lâmpada para os meus pés é tua palavra e luz para o meu caminho. (Salmos 119:105)'},
  ];

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
        // Handle notification click
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

  static Future<bool> requestPermissions() async {
    final bool? result = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return result ?? false;
  }

  static Future<void> scheduleDailyReflection() async {
    final prefs = await SharedPreferences.getInstance();
    final bool enabled = prefs.getBool('notifications_enabled') ?? false;
    if (!enabled) return;

    final random = Random();
    final reflection = _reflections[random.nextInt(_reflections.length)];

    // Schedule for 7:00 AM every day
    await _scheduleDailyNotification(
      888, // Unique ID for reflections
      reflection['title']!,
      reflection['body']!,
      7,
      0,
      type: 'faith',
    );
  }

  static Future<void> scheduleDietNotifications(List<dynamic> refeicoes) async {
    final prefs = await SharedPreferences.getInstance();
    final bool enabled = prefs.getBool('notifications_enabled') ?? false;
    
    if (!enabled) {
      await cancelAllNotifications();
      return;
    }

    // Schedule diet ones starting from ID 0
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
        'Hora da sua dieta! 🍎',
        'Está na hora do seu ${refeicao['nome']}. Não esqueça de registrar!',
        hour,
        minute,
        type: 'diet',
      );
    }
    
    // Don't forget the daily reflection
    await scheduleDailyReflection();
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

    // Save to history for the Notification Center
    await _saveToHistory(title, body, type);
  }

  static Future<void> _saveToHistory(String title, String body, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('notification_history');
    List<dynamic> history = historyJson != null ? jsonDecode(historyJson) : [];
    
    // Add new notification to history
    history.add({
      'title': title,
      'body': body,
      'type': type,
      'time': DateTime.now().toIso8601String(),
    });

    // Keep only last 50
    if (history.length > 50) history.removeAt(0);
    
    await prefs.setString('notification_history', jsonEncode(history));
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
