import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
        final errorBody = response.body;
        debugPrint(">>> FALHA AO SALVAR NO BANCO: HTTP ${response.statusCode}");
        debugPrint(">>> RESPOSTA DO SERVIDOR: $errorBody");
        
        String errorMessage = 'Erro ao salvar no banco de dados';
        try {
          final decoded = jsonDecode(errorBody);
          if (decoded['details'] != null) {
            errorMessage = "${decoded['error'] ?? 'Erro'}: ${decoded['details']}";
            if (decoded['suggestion'] != null) {
              errorMessage += "\n\nDica: ${decoded['suggestion']}";
            }
          }
        } catch (_) {}
        
        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão com servidor'};
    }
  }

  Future<Map<String, dynamic>> deleteScan(int scanId, String imageUrl) async {
    final baseUrl = ApiService.baseUrl;
    final token = _api.accessToken;
    bool backendDeleted = false;

    // 1. Try to delete from Backend
    try {
      final deleteUrl = '$baseUrl/body-scan/$scanId';
      
      final response = await http.delete(
        Uri.parse(deleteUrl),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        backendDeleted = true;
      } else {
        // If 404, the DELETE route may not be deployed yet - continue to Firebase
      }
    } catch (e) {
      debugPrint(">>> BACKEND: Erro de conexão: $e");
    }

    // 2. Always try to delete from Firebase Storage
    try {
      if (imageUrl.isNotEmpty) {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      }
      // If Firebase deletion worked, consider it a success even if backend failed
      return {'success': true};
    } catch (e) {
      debugPrint(">>> FIREBASE: Erro ao deletar imagem: $e");
      // If file already doesn't exist in Firebase, that's fine — consider it deleted
      if (e.toString().contains('object-not-found')) {
        debugPrint(">>> FIREBASE: Arquivo já não existe, considerando exclusão bem-sucedida");
        return {'success': true};
      }
      if (backendDeleted) {
        return {'success': true};
      }
      return {'success': false, 'error': 'Erro ao excluir: não foi possível remover do servidor nem do storage'};
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
