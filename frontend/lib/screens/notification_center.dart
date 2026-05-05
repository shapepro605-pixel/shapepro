import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notificationsJson = prefs.getString('notification_history');
    
    if (notificationsJson != null) {
      final List<dynamic> decoded = jsonDecode(notificationsJson);
      setState(() {
        _notifications = decoded.cast<Map<String, dynamic>>().reversed.toList();
        _isLoading = false;
      });
    } else {
      // Mock some initial notifications if empty to show the UI
      setState(() {
        _notifications = [
          {
            'title': 'Bom dia com Deus! ✨',
            'body': 'O Senhor é o meu pastor, nada me faltará. (Salmos 23:1)',
            'type': 'faith',
            'time': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          },
          {
            'title': 'Hora da sua refeição 🍎',
            'body': 'Lembre-se de comer seu Almoço agora para manter o foco!',
            'type': 'diet',
            'time': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
          }
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Notificações",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 20),
          Text(
            "Tudo limpo por aqui!",
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final item = _notifications[index];
        final bool isFaith = item['type'] == 'faith';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isFaith ? const Color(0xFF1E1E38) : const Color(0xFF16162A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isFaith ? const Color(0xFF6C5CE7).withValues(alpha: 0.3) : const Color(0xFF2A2A4A),
            ),
            boxShadow: isFaith ? [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isFaith ? const Color(0xFF6C5CE7).withValues(alpha: 0.2) : Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFaith ? Icons.auto_awesome : Icons.restaurant,
                  color: isFaith ? const Color(0xFF00D2FF) : Colors.white54,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['title'],
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          _formatTime(item['time']),
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['body'],
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                        fontStyle: isFaith ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1, end: 0);
      },
    );
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return "";
    final date = DateTime.parse(timeStr);
    final now = DateTime.now();
    if (date.day == now.day) {
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    }
    return "${date.day}/${date.month}";
  }
}
