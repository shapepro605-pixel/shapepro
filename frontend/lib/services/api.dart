import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import 'package:shapepro/utils/logger.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:ui' as ui;

class ApiService extends ChangeNotifier {
  // Base URL for the API.
  // In production, pass via: flutter build --dart-define=API_URL=https://xxx.up.railway.app
  static String get baseUrl {
    const prodUrl = String.fromEnvironment('API_URL', defaultValue: 'https://shapepro-production.up.railway.app');
    if (prodUrl.isNotEmpty) return '$prodUrl/api';
    
    if (kIsWeb) {
      return 'http://localhost:5000/api'; // Chrome / Web
    }
    return 'http://10.0.2.2:5000/api'; // Emulador Android
  }
  
  // Current version must match configuration
  static const String currentAppVersion = "1.0.1";
  
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

  // IAP
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

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
    
    String? lang = prefs.getString('language_code');
    String? country = prefs.getString('country_code');

    if (lang == null) {
      // Auto-detect system language
      final systemLocale = ui.PlatformDispatcher.instance.locale;
      lang = systemLocale.languageCode;
      country = systemLocale.countryCode ?? '';
      
      // Default to English for international markets (non-PT)
      if (lang != 'pt' && lang != 'en') {
        lang = 'en';
      }
      
      // Save it once detected to avoid re-detection logic overhead if desired, 
      // but keeping it dynamic as fallback is safer if they change system lang later without having set a preference.
    }
    
    _locale = Locale(lang, country);
    
    _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
    
    // Initialize IAP
    _initializeIAP();
    
    notifyListeners();
  }

  void _initializeIAP() {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription?.cancel();
    }, onError: (error) {
      // Handle error
    });
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show loading if needed
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // Handle error
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          // Verify with backend
          bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            // Deliver product
          }
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    final res = await _request('POST', '/payment/verify', body: {
      'server_verification_data': purchase.verificationData.serverVerificationData,
      'product_id': purchase.productID,
      'purchase_id': purchase.purchaseID,
    });
    if (res['success'] == true && res['user'] != null) {
      _saveUser(res['user']);
      return true;
    }
    return false;
  }

  Future<void> fetchProducts() async {
    const Set<String> ids = {'shapepro_mensal', 'shapepro_anual'};
    final ProductDetailsResponse response = await _iap.queryProductDetails(ids);
    if (response.notFoundIDs.isNotEmpty) {
      // Handle missing IDs
    }
    _products = response.productDetails;
    notifyListeners();
  }

  Future<void> buyProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<Map<String, dynamic>> reportFoodPrice({
    required String foodName,
    required double price,
    required String city,
    String? pais,
    String? moeda,
  }) async {
    return await _request('POST', '/food-prices/report', body: {
      'alimento': foodName,
      'preco': price,
      'cidade': city,
      'pais': pais,
      'moeda': moeda,
    });
  }

  Future<Map<String, dynamic>> getFoodPrices(List<String> alimentos, {String? cidade, String? pais}) async {
    final query = alimentos.map((a) => 'alimentos=$a').join('&');
    final cityParam = cidade != null ? '&cidade=$cidade' : '';
    final countryParam = pais != null ? '&pais=$pais' : '';
    return await _request('GET', '/food-prices/search?$query$cityParam$countryParam');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _saveTokens(String access, {String? refresh}) async {
    _accessToken = access;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    if (refresh != null) {
      _refreshToken = refresh;
      await prefs.setString('refresh_token', refresh);
    }
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;
    try {
      final uri = Uri.parse('$baseUrl/auth/refresh');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_refreshToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access_token'] != null) {
          await _saveTokens(data['access_token']);
          Log.s('Token refreshed successfully');
          return true;
        }
      }
    } catch (e) {
      Log.e('Token refresh failed: $e');
    }
    return false;
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
    bool isRetry = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      Log.i('API REQUEST [$method]: $uri');
      
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(const Duration(seconds: 15));
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(const Duration(seconds: 15));
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: _headers).timeout(const Duration(seconds: 15));
          break;
        default:
          throw Exception('Método HTTP não suportado: $method');
      }

      Log.s('API RESPONSE [$method] ${response.statusCode}: ${response.body}');

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        Log.e('Failed to parse JSON response: ${response.body}');
        return {
          'success': false,
          'error': 'O servidor retornou uma resposta inválida.',
        };
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, ...data};
      } else if (response.statusCode == 401 && !isRetry && _refreshToken != null) {
        Log.i('Token expired, attempting auto-refresh...');
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          return _request(method, endpoint, body: body, isRetry: true);
        }
        Log.e('Auto-refresh failed, session expired');
        await logout();
        return {
          'success': false,
          'error': data['error'] ?? 'Sessão expirada. Faça login novamente.',
        };
      } else {
        Log.e('API ERROR RESPONSE: ${response.body}');
        return {
          'success': false,
          'error': data['error'] ?? 'Erro desconhecido',
        };
      }
    } catch (e) {
      Log.e('CRITICAL API ERROR: $e');
      return {
        'success': false,
        'error': 'Erro de conexão ou tempo de resposta excedido.',
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
    required String telefone,
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
      'telefone': telefone,
      if (idade != null) 'idade': idade,
      if (altura != null) 'altura': altura,
      if (peso != null) 'peso': peso,
      if (sexo != null) 'sexo': sexo,
      if (objetivo != null) 'objetivo': objetivo,
      if (nivelAtividade != null) 'nivel_atividade': nivelAtividade,
      if (ritmoMeta != null) 'ritmo_meta': ritmoMeta,
    });

    if (result['success'] == true) {
      await _saveTokens(result['access_token'], refresh: result['refresh_token']);
      await _saveUser(result['user']);
    }
    return result;
  }

  /// Verify phone via Firebase ID token.
  /// After Firebase phone auth succeeds, send the idToken to our backend.
  Future<Map<String, dynamic>> verifyPhoneWithFirebase(String firebaseIdToken) async {
    final result = await _request('POST', '/auth/verify_sms', body: {
      'firebase_id_token': firebaseIdToken,
    });
    if (result['success'] == true) {
      if (result['access_token'] != null) {
        await _saveTokens(result['access_token'], refresh: result['refresh_token']);
      }
      if (result['user'] != null) {
        await _saveUser(result['user']);
      }
    }
    return result;
  }

  /// TEST MODE ONLY: Simulates a successful Google Play purchase locally.
  Future<Map<String, dynamic>> simulatePurchase(String productId) async {
    final result = await _request('POST', '/payment/verify', body: {
      'product_id': productId,
      'is_test': true,
      'purchase_id': 'MOCK_PURCHASE_${DateTime.now().millisecondsSinceEpoch}',
    });
    
    if (result['success'] == true && result['user'] != null) {
      await _saveUser(result['user']);
    }
    return result;
  }

  /// Applies a promotional or VIP access code.
  Future<Map<String, dynamic>> applyVipCoupon(String code) async {
    final result = await _request('POST', '/payment/apply-coupon', body: {
      'code': code,
    });
    
    if (result['success'] == true && result['user'] != null) {
      await _saveUser(result['user']);
    }
    return result;
  }

  /// Login via Google.
  /// Sends the Google Identity token to our backend for validation and sign-in.
  Future<Map<String, dynamic>> loginWithGoogle(String firebaseIdToken) async {
    final result = await _request('POST', '/auth/google_login', body: {
      'id_token': firebaseIdToken,
    });
    if (result['success'] == true) {
      if (result['access_token'] != null) {
        await _saveTokens(result['access_token'], refresh: result['refresh_token']);
      }
      if (result['user'] != null) {
        await _saveUser(result['user']);
      }
    }
    return result;
  }

  /// Legacy verify SMS (fallback for dev/testing without Firebase)
  Future<Map<String, dynamic>> verifySms(String code) async {
    final result = await _request('POST', '/auth/verify_sms', body: {'code': code});
    if (result['success'] == true && result['user'] != null) {
      await _saveUser(result['user']);
    }
    return result;
  }

  Future<Map<String, dynamic>> resendSms() async {
    return await _request('POST', '/auth/resend_sms');
  }

  Future<Map<String, dynamic>> sendVerificationEmail() async {
    return await _request('POST', '/auth/send_verification_email');
  }

  Future<Map<String, dynamic>> verifyEmailCode(String code) async {
    final result = await _request('POST', '/auth/verify_email_code', body: {'code': code});
    if (result['success'] == true && result['user'] != null) {
      await _saveUser(result['user']);
    }
    return result;
  }

  Future<Map<String, dynamic>> resetPassword(String email) async {
    return await _request('POST', '/auth/reset_password', body: {'email': email});
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
      await _saveTokens(result['access_token'], refresh: result['refresh_token']);
      await _saveUser(result['user']);
    }
    return result;
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('current_user');
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

  /// Uploads a profile photo to Firebase Storage and returns the download URL.
  Future<String?> uploadFotoPerfil(File file) async {
    if (_currentUser == null) {
      Log.e('Erro uploadFotoPerfil: Usuário não logado');
      return null;
    }
    
    try {
      final userId = _currentUser!['id'].toString();
      Log.i('Iniciando upload para Firebase Storage. ID Usuário: $userId');
      
      final storageRef = FirebaseStorage.instance.ref();
      final photoRef = storageRef.child('perfil/$userId.jpg');
      
      Log.i('Reference Path: ${photoRef.fullPath}');
      
      final uploadTask = photoRef.putFile(file);
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        Log.i('Upload progress [$userId]: ${((snapshot.bytesTransferred / snapshot.totalBytes) * 100).toStringAsFixed(2)}%');
      }, onError: (e) => Log.e('Erro durante o stream de upload: $e'));

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      Log.s('Upload concluído com sucesso [$userId]. URL: $downloadUrl');
      
      Log.i('Enviando link para o backend /auth/profile...');
      final result = await updateProfile({'foto_perfil': downloadUrl});
      
      if (result['success'] == true) {
        Log.s('Tudo OK! Foto salva no perfil do banco de dados.');
        return downloadUrl;
      } else {
        Log.e('Backend falhou em salvar a URL: ${result['error']}');
        return null;
      }
    } catch (e) {
      Log.e('!!! ERRO CRÍTICO NO UPLOAD: $e');
      if (e.toString().contains('permission-denied')) {
        Log.e('DICA: Verifique as Regras de Segurança do Firebase Storage no console!');
      }
      return null;
    }
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

  // ── TRACKING (Water & Metrics) ───────────────────────────────────────

  Future<Map<String, dynamic>> logWater(int ml) async {
    return await _request('POST', '/tracking/water', body: {'ml': ml});
  }

  Future<Map<String, dynamic>> getWaterToday() async {
    return await _request('GET', '/tracking/water/today');
  }

  Future<Map<String, dynamic>> logMetrics(Map<String, dynamic> data) async {
    return await _request('POST', '/tracking/metrics', body: data);
  }

  // ── SLEEP ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> logSleep(String horaDormir, String horaAcordar, {int qualidade = 3, String notas = ''}) async {
    return await _request('POST', '/tracking/sleep', body: {
      'hora_dormir': horaDormir,
      'hora_acordar': horaAcordar,
      'qualidade': qualidade,
      'notas': notas,
    });
  }

  Future<Map<String, dynamic>> getSleepHistory() async {
    return await _request('GET', '/tracking/sleep/history');
  }

  Future<Map<String, dynamic>> getSleepStats() async {
    return await _request('GET', '/tracking/sleep/stats');
  }

  // ── JOURNAL ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createJournalEntry(Map<String, dynamic> data) async {
    return await _request('POST', '/journal', body: data);
  }

  Future<Map<String, dynamic>> listJournalEntries({int limit = 10}) async {
    return await _request('GET', '/journal?limit=$limit');
  }

  Future<Map<String, dynamic>> getJournalStats() async {
    return await _request('GET', '/journal/stats');
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
      if (_refreshToken != null) {
        await prefs.setString('biometric_refresh_token', _refreshToken!);
      }
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
    final bRefresh = prefs.getString('biometric_refresh_token');
    
    if (bToken != null && bUserJson != null) {
      _accessToken = bToken;
      _refreshToken = bRefresh;
      _currentUser = jsonDecode(bUserJson);
      await _saveTokens(bToken, refresh: bRefresh);
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
      // Version check failed - ignore for production
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
