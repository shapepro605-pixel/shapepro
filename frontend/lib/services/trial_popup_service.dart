import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:shapepro/utils/logger.dart';
import '../widgets/trial_upsell_popup.dart';
import 'api.dart';
import 'notification_service.dart';

class TrialPopupService {
  static const String _prefsKey = 'trial_popup_history';
  static const int _maxPopupsPerDay = 3;
  static const int _minHoursBetweenPopups = 4;

  static Future<void> checkAndShowTrialPopup(BuildContext context) async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final user = api.currentUser;
      
      if (user == null) return;
      
      // Only show to users in trial
      final isTrial = user['is_trial'] == true;
      final isPremium = user['plano_assinatura'] != 'free';
      
      if (!isTrial || isPremium) return;
      
      final shouldShow = await _shouldShowPopup();
      if (shouldShow) {
        await _recordPopupShown();
        // Play the SMS sound using local notifications
        await NotificationService.playNotificationSound();
        
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const TrialUpsellPopup(),
          );
        }
      }
    } catch (e) {
      Log.e('Error checking trial popup: $e');
    }
  }

  static Future<bool> _shouldShowPopup() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_prefsKey);
    
    List<DateTime> history = [];
    if (historyJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(historyJson);
        history = decoded.map((e) => DateTime.parse(e)).toList();
      } catch (e) {
        history = [];
      }
    }
    
    final now = DateTime.now();
    
    // Filter history to keep only today's popups
    history.removeWhere((date) => 
      date.year != now.year || 
      date.month != now.month || 
      date.day != now.day
    );
    
    // Check if we hit the daily limit
    if (history.length >= _maxPopupsPerDay) {
      return false;
    }
    
    // Check if enough time has passed since the last popup
    if (history.isNotEmpty) {
      final lastPopup = history.last;
      final difference = now.difference(lastPopup);
      if (difference.inHours < _minHoursBetweenPopups) {
        return false; // Too soon
      }
    }
    
    return true;
  }

  static Future<void> _recordPopupShown() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_prefsKey);
    
    List<DateTime> history = [];
    if (historyJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(historyJson);
        history = decoded.map((e) => DateTime.parse(e)).toList();
      } catch (e) {
        history = [];
      }
    }
    
    final now = DateTime.now();
    // Filter history to keep only today's popups
    history.removeWhere((date) => 
      date.year != now.year || 
      date.month != now.month || 
      date.day != now.day
    );
    
    history.add(now);
    
    final List<String> encoded = history.map((e) => e.toIso8601String()).toList();
    await prefs.setString(_prefsKey, jsonEncode(encoded));
  }
}
