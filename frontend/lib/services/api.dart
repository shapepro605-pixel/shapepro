import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';

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
    final userJson = prefs.getString('current_user');
    if (userJson != null) {
      _currentUser = jsonDecode(userJson);
    }
    
    final lang = prefs.getString('language_code') ?? 'pt';
    final country = prefs.getString('country_code') ?? 'BR';
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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _saveTokens(String access) async {
    _accessToken = access;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
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
      debugPrint('🚀 API REQUEST [$method]: $uri');
      
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

      debugPrint('✅ API RESPONSE [$method] ${response.statusCode}: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, ...data};
      } else {
        debugPrint('⚠️ API ERROR RESPONSE: ${response.body}');
        return {
          'success': false,
          'error': data['error'] ?? 'Erro desconhecido',
        };
      }
    } catch (e) {
      debugPrint('🔥 CRITICAL API ERROR: $e');
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
      await _saveTokens(result['access_token']);
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
        await _saveTokens(result['access_token']);
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
        await _saveTokens(result['access_token']);
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
      await _saveTokens(result['access_token']);
      await _saveUser(result['user']);
    }
    return result;
  }

  Future<void> logout() async {
    _accessToken = null;
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
      await _saveTokens(bToken);
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
