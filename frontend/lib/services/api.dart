import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService extends ChangeNotifier {
  // Base URL for the API.
  // In production, pass via: flutter build --dart-define=API_URL=https://xxx.up.railway.app
  static String get baseUrl {
    const prodUrl = String.fromEnvironment('API_URL', defaultValue: '');
    if (prodUrl.isNotEmpty) return '$prodUrl/api';
    
    if (kIsWeb) {
      return 'http://localhost:5000/api'; // Chrome / Web
    }
    return 'http://10.0.2.2:5000/api'; // Emulador Android
  }
  
  // Current version must match configuration
  static const String currentAppVersion = "1.0.0";
  
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  Locale _locale = const Locale('pt', 'BR');
  bool _isDarkMode = true; // Default to dark

  String? get accessToken => _accessToken;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _accessToken != null;
  Locale get locale => _locale;
  bool get isDarkMode => _isDarkMode;

  // ── Auth Headers ─────────────────────────────────────────────────────

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept-Language': _locale.languageCode,
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  // ── Init: Load saved token ───────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    final userJson = prefs.getString('current_user');
    if (userJson != null) {
      _currentUser = jsonDecode(userJson);
    }
    
    final lang = prefs.getString('language_code') ?? 'pt';
    final country = prefs.getString('country_code') ?? 'BR';
    _locale = Locale(lang, country);
    
    _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
    
    notifyListeners();
  }

  Future<void> _saveTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  Future<void> _saveUser(Map<String, dynamic> user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(user));
    notifyListeners();
  }

  // ── Generic Request Handler ──────────────────────────────────────────

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: _headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: _headers);
          break;
        default:
          throw Exception('Método HTTP não suportado: $method');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, ...data};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Erro desconhecido',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro de conexão. Verifique sua internet.',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── AUTH ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String nome,
    int? idade,
    double? altura,
    double? peso,
    String? sexo,
    String? objetivo,
    String? nivelAtividade,
    String? ritmoMeta,
  }) async {
    final result = await _request('POST', '/auth/register', body: {
      'email': email,
      'password': password,
      'nome': nome,
      if (idade != null) 'idade': idade,
      if (altura != null) 'altura': altura,
      if (peso != null) 'peso': peso,
      if (sexo != null) 'sexo': sexo,
      if (objetivo != null) 'objetivo': objetivo,
      if (nivelAtividade != null) 'nivel_atividade': nivelAtividade,
      if (ritmoMeta != null) 'ritmo_meta': ritmoMeta,
    });

    if (result['success'] == true) {
      await _saveTokens(result['access_token'], result['refresh_token']);
      await _saveUser(result['user']);
    }
    return result;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final result = await _request('POST', '/auth/login', body: {
      'email': email,
      'password': password,
    });

    if (result['success'] == true) {
      await _saveTokens(result['access_token'], result['refresh_token']);
      await _saveUser(result['user']);
    }
    return result;
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<Map<String, dynamic>> getProfile() async {
    final result = await _request('GET', '/auth/profile');
    if (result['success'] == true && result['user'] != null) {
      await _saveUser(result['user']);
    }
    return result;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final result = await _request('PUT', '/auth/profile', body: data);
    if (result['success'] == true && result['user'] != null) {
      await _saveUser(result['user']);
    }
    return result;
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    return await _request('DELETE', '/auth/profile');
  }

  // ── WEIGHT ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> logWeight(double peso) async {
    return await _request('POST', '/auth/weight', body: {'peso': peso});
  }

  Future<Map<String, dynamic>> getWeightHistory() async {
    return await _request('GET', '/auth/weight');
  }

  // ── DIET ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> gerarDieta({String orcamento = 'padrao'}) async {
    return await _request('POST', '/plan/dieta', body: {'orcamento': orcamento});
  }

  Future<Map<String, dynamic>> getDietaAtiva() async {
    return await _request('GET', '/plan/dieta');
  }

  Future<Map<String, dynamic>> getDietaHistorico() async {
    return await _request('GET', '/plan/dieta/historico');
  }

  // ── TRAINING ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTreinos() async {
    return await _request('GET', '/plan/treino');
  }

  Future<Map<String, dynamic>> getTreinoPorTipo(String tipo) async {
    return await _request('GET', '/plan/treino/$tipo');
  }

  Future<Map<String, dynamic>> getExercicios({String? grupo}) async {
    final endpoint = grupo != null
        ? '/plan/exercicios?grupo=$grupo'
        : '/plan/exercicios';
    return await _request('GET', endpoint);
  }

  Future<Map<String, dynamic>> concluirTreino() async {
    return await _request('POST', '/plan/treino/concluir');
  }

  // ── PROGRESS ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProgresso() async {
    return await _request('GET', '/plan/progresso');
  }

  // ── CHALLENGES ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getChallenges() async {
    return await _request('GET', '/challenges');
  }

  Future<Map<String, dynamic>> joinChallenge(int challengeId) async {
    return await _request('POST', '/challenges/join/$challengeId');
  }

  Future<Map<String, dynamic>> getActiveChallenges() async {
    return await _request('GET', '/challenges/active');
  }

  // ── ASSINATURA ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> updateAssinatura(String plano) async {
    return await _request('POST', '/plan/assinatura', body: {'plano': plano});
  }

  // ── SUBSCRIPTION & PAYMENT ───────────────────────────────────────────

  Future<Map<String, dynamic>> getPaymentPlans() async {
    return await _request('GET', '/payment/plans');
  }

  Future<Map<String, dynamic>> checkout(String planCode, String promoCode) async {
    final result = await _request('POST', '/payment/checkout', body: {
      'plan_code': planCode,
      'promo_code': promoCode,
    });
    if (result['success'] == true && result['user'] != null) {
      await _saveUser(result['user']);
    }
    return result;
  }

  // ── BIOMETRICS ───────────────────────────────────────────────────────

  Future<void> enableBiometric() async {
    if (_accessToken != null && _currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('biometric_token', _accessToken!);
      await prefs.setString('biometric_user', jsonEncode(_currentUser));
    }
  }

  Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('biometric_token');
    await prefs.remove('biometric_user');
  }

  Future<bool> hasBiometricAuth() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('biometric_token') != null;
  }

  Future<bool> loginWithBiometricToken() async {
    final prefs = await SharedPreferences.getInstance();
    final bToken = prefs.getString('biometric_token');
    final bUserJson = prefs.getString('biometric_user');
    
    if (bToken != null && bUserJson != null) {
      _accessToken = bToken;
      _currentUser = jsonDecode(bUserJson);
      await _saveTokens(bToken, prefs.getString('refresh_token') ?? '');
      await _saveUser(_currentUser!);
      return true;
    }
    return false;
  }

  // ── LOCALE ──────────────────────────────────────────────────────────

  Future<void> setLocale(Locale newLocale) async {
    _locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLocale.languageCode);
    await prefs.setString('country_code', newLocale.countryCode ?? '');
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    notifyListeners();
  }

  Future<Map<String, dynamic>> checkVersion() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/app/config'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'version': data['version'],
          'min_version': data['min_version'],
          'update_url': data['update_url'],
          'is_outdated': currentAppVersion != data['version'],
          'is_mandatory': _compareVersions(currentAppVersion, data['min_version']) < 0,
        };
      }
    } catch (e) {
      print('Erro ao checar versão: $e');
    }
    return {'success': false};
  }

  int _compareVersions(String v1, String v2) {
    List<int> nums1 = v1.split('.').map(int.parse).toList();
    List<int> nums2 = v2.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      if (nums1[i] < nums2[i]) return -1;
      if (nums1[i] > nums2[i]) return 1;
    }
    return 0;
  }
}
