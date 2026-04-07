import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:shapepro/l10n/app_localizations.dart';
import '../services/api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPhoneMode = false;

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _hasBiometricToken = false;

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.2, 1, curve: Curves.easeOut)),
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.2, 1, curve: Curves.easeOutCubic)),
    );
    _checkBiometrics();
    _animController.forward();

    _emailController.addListener(_onIdentifierChanged);
  }

  void _onIdentifierChanged() {
    final text = _emailController.text.trim();
    final isPhone = text.isNotEmpty && (RegExp(r'^[+0-9]').hasMatch(text));
    if (isPhone != _isPhoneMode) {
      setState(() => _isPhoneMode = isPhone);
    }
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      final api = Provider.of<ApiService>(context, listen: false);
      final hasToken = await api.hasBiometricAuth();
      if (mounted) {
        setState(() {
          _canCheckBiometrics = canCheck;
          _hasBiometricToken = hasToken;
        });
      }
    } catch (e) {
      debugPrint('Biometrics err: $e');
    }
  }

  Future<void> _loginWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Autentique-se para acessar o ShapePro',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
      if (authenticated) {
        setState(() => _isLoading = true);
        if (!mounted) return;
        final api = Provider.of<ApiService>(context, listen: false);
        final success = await api.loginWithBiometricToken();
        if (mounted) {
          setState(() => _isLoading = false);
          if (success) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            setState(() => _errorMessage = 'Sessão expirada. Faça login com senha.');
            await api.disableBiometric();
            setState(() => _hasBiometricToken = false);
          }
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _showBiometricPrompt(ApiService api) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        title: Text('Face ID / Digital', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Deseja habilitar o login rápido por biometria?', style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: Text('Agora Não', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
            onPressed: () async {
              await api.enableBiometric();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
            child: Text('Habilitar', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    final api = Provider.of<ApiService>(context, listen: false);
    final result = await api.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        if (_canCheckBiometrics && !_hasBiometricToken) {
          _showBiometricPrompt(api);
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        setState(() => _errorMessage = result['error'] ?? 'Erro ao fazer login');
      }
    }
  }

  Future<void> _handlePhoneSignIn() async {
    final phone = _emailController.text.trim();
    if (phone.isEmpty) return;
    setState(() => _isLoading = true);
    
    String normalizedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (!normalizedPhone.startsWith('+')) {
      normalizedPhone = normalizedPhone.startsWith('55') ? '+$normalizedPhone' : '+55$normalizedPhone';
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        verificationCompleted: (credential) async {
          final userToken = await FirebaseAuth.instance.signInWithCredential(credential);
          final idToken = await userToken.user?.getIdToken();
          if (idToken != null) {
            final api = Provider.of<ApiService>(context, listen: false);
            final result = await api.verifyPhoneWithFirebase(idToken);
            if (mounted && result['success'] == true) Navigator.pushReplacementNamed(context, '/home');
          }
        },
        verificationFailed: (e) => setState(() { _isLoading = false; _errorMessage = 'Erro SMS: ${e.message}'; }),
        codeSent: (id, token) {
          setState(() => _isLoading = false);
          Navigator.pushNamed(context, '/verify_sms', arguments: {'verificationId': id, 'phone': normalizedPhone});
        },
        codeAutoRetrievalTimeout: (id) {},
      );
    } catch (e) {
      setState(() { _isLoading = false; _errorMessage = 'Falha: $e'; });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) { setState(() => _isLoading = false); return; }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        final api = Provider.of<ApiService>(context, listen: false);
        final result = await api.loginWithGoogle(idToken);
        if (mounted) {
          setState(() => _isLoading = false);
          if (result['success'] == true) Navigator.pushReplacementNamed(context, '/home');
          else setState(() => _errorMessage = result['error'] ?? 'Erro Google');
        }
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = 'Erro Google: $e'; });
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF16162A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Redefinir Senha', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Informe seu email cadastrado.', style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 15),
              TextFormField(
                controller: resetEmailController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: const InputDecoration(hintText: 'email@exemplo.com'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: isSending ? null : () async {
                setDialogState(() => isSending = true);
                final api = Provider.of<ApiService>(context, listen: false);
                await api.resetPassword(resetEmailController.text);
                if (mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A1A), Color(0xFF12122A), Color(0xFF0A0A1A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    Center(
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF00D2FF)]),
                        ),
                        child: const Icon(Icons.fitness_center_rounded, size: 40, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: Text(
                        AppLocalizations.of(context)!.welcomeBack,
                        style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 45),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFD4556).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFD4556).withValues(alpha: 0.3)),
                        ),
                        child: Text(_errorMessage!, style: GoogleFonts.inter(color: const Color(0xFFFD4556), fontSize: 13)),
                      ),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_isPhoneMode ? 'Número de Telefone' : 'E-mail', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: _isPhoneMode ? TextInputType.phone : TextInputType.emailAddress,
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: _isPhoneMode ? '(00) 00000-0000' : 'seu@email.com',
                              prefixIcon: Icon(_isPhoneMode ? Icons.phone_android_outlined : Icons.email_outlined),
                            ),
                          ),
                          if (!_isPhoneMode) ...[
                            const SizedBox(height: 22),
                            Text('Senha', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.inter(color: Colors.white),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (!_isPhoneMode)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(onPressed: _showForgotPasswordDialog, child: const Text('Esqueceu a senha?')),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : (_isPhoneMode ? _handlePhoneSignIn : _login),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isPhoneMode ? 'Enviar SMS' : 'Entrar'),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('ou', style: TextStyle(color: Colors.white30))),
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                      ],
                    ),
                    const SizedBox(height: 30),
                    if (_canCheckBiometrics && _hasBiometricToken) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _loginWithBiometrics,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('Entrar com Biometria'),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 32),
                        label: const Text('Continuar com Google'),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        child: const Text('Não tem conta? Criar conta grátis'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
