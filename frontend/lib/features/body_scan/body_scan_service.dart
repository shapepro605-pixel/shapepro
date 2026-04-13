import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api.dart';

enum BodyScanType { front, side, back }

class BodyScanService {
  final ApiService _api;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  BodyScanService(this._api);

  /// Uploads image to Firebase Storage and then syncs with the backend.
  Future<Map<String, dynamic>> uploadScan({
    required File imageFile,
    required String type,
    Map<String, double>? metrics,
  }) async {
    try {
      final user = _api.currentUser;
      if (user == null) return {'success': false, 'error': 'Usuário não autenticado'};

      final userId = user['id'].toString();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_$type.jpg';
      
      // Path based on privacy requirements: users/{userId}/body_scan/
      final path = 'users/$userId/body_scan/$fileName';
      final ref = _storage.ref().child(path);

      // Upload
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      if (uploadTask.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL();
        
        // Sync with backend (PostgreSQL)
        return await _syncWithBackend(
          userId: userId,
          type: type,
          imageUrl: downloadUrl,
          metrics: metrics,
        );
      } else {
        return {'success': false, 'error': 'Falha no upload para o storage'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erro no processo: $e'};
    }
  }

  Future<Map<String, dynamic>> _syncWithBackend({
    required String userId,
    required String type,
    required String imageUrl,
    Map<String, double>? metrics,
  }) async {
    final baseUrl = ApiService.baseUrl;
    final token = _api.accessToken;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/body-scan'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'type': type,
          'image_url': imageUrl,
          'metrics': metrics,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Erro ao salvar no banco de dados'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão com servidor'};
    }
  }

  Future<List<dynamic>> getHistory() async {
    final baseUrl = ApiService.baseUrl;
    final token = _api.accessToken;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/body-scan'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['scans'] ?? [];
      }
    } catch (e) {
      // Log error
    }
    return [];
  }
}
