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
  String _userName = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load User Name
    final String? userData = prefs.getString('user_data');
    if (userData != null) {
      final user = jsonDecode(userData);
      _userName = user['nome'] ?? "";
    }

    // Load Notifications
    final String? notificationsJson = prefs.getString('notification_history');
    if (notificationsJson != null) {
      final List<dynamic> decoded = jsonDecode(notificationsJson);
      setState(() {
        _notifications = decoded.cast<Map<String, dynamic>>().reversed.toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _notifications = [
          {
            'title': 'Hora de brilhar, $_userName! 🍎',
            'body': 'Está na hora do seu Almoço. Mantenha o foco no seu objetivo!',
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
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          _isLoading 
            ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))))
            : _notifications.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildPremiumCard(_notifications[index], index),
                      childCount: _notifications.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0A0A1A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
        title: Text(
          "Notificações",
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 80, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 20),
          Text(
            "Tudo em ordem por aqui!",
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(Map<String, dynamic> item, int index) {
    final bool isFaith = item['type'] == 'faith';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isFaith 
            ? [const Color(0xFF1E1E38), const Color(0xFF16162A)]
            : [const Color(0xFF16162A), const Color(0xFF0D0D1F)],
        ),
        border: Border.all(
          color: isFaith 
            ? const Color(0xFF6C5CE7).withValues(alpha: 0.4) 
            : const Color(0xFF2A2A4A).withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          if (isFaith)
            BoxShadow(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: -5,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative light effect for Faith cards
            if (isFaith)
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00D2FF).withValues(alpha: 0.05),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isFaith 
                          ? [const Color(0xFF6C5CE7), const Color(0xFF00D2FF)]
                          : [const Color(0xFF2A2A4A), const Color(0xFF16162A)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isFaith ? Icons.auto_awesome_rounded : Icons.restaurant_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item['title'],
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontSize: 16,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            Text(
                              _formatTime(item['time']),
                              style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['body'],
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            fontStyle: isFaith ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                        if (isFaith) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D2FF).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Reflexão de Hoje",
                              style: GoogleFonts.inter(
                                color: const Color(0xFF00D2FF),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack);
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
