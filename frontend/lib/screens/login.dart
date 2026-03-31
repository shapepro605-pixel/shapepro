import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
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

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
          title: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF6C5CE7), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Redefinir Senha', style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18,
                )),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informe seu email cadastrado. Enviaremos instruções para redefinir sua senha.',
                style: GoogleFonts.inter(color: Colors.white60, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.emailHint,
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF6C5CE7)),
                  filled: true,
                  fillColor: const Color(0xFF1E1E38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF2A2A4A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF2A2A4A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.pop(dialogContext),
              child: Text('Cancelar', style: GoogleFonts.inter(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: isSending ? null : () async {
                final email = resetEmailController.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Informe um email válido')),
                  );
                  return;
                }
                setDialogState(() => isSending = true);
                final api = Provider.of<ApiService>(context, listen: false);
                final result = await api.resetPassword(email);
                setDialogState(() => isSending = false);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Verifique seu email.'),
                      backgroundColor: const Color(0xFF2ED573),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              child: isSending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Enviar', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
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
            colors: [
              Color(0xFF0A0A1A),
              Color(0xFF12122A),
              Color(0xFF0A0A1A),
            ],
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

                    // ── Logo ───────────────────────────────────────
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C5CE7), Color(0xFF00D2FF)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                              blurRadius: 25,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.fitness_center_rounded, size: 40, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ── Title ──────────────────────────────────────
                    Center(
                      child: Text(
                        AppLocalizations.of(context)!.welcomeBack,
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        AppLocalizations.of(context)!.loginSubtitle,
                        style: GoogleFonts.inter(fontSize: 15, color: Colors.white54),
                      ),
                    ),
                    const SizedBox(height: 45),

                    // ── Error message ─────────────────────────────
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFD4556).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFD4556).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFFD4556), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.inter(color: const Color(0xFFFD4556), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Form ──────────────────────────────────────
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.email, style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70,
                          )),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!.emailHint,
                              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF6C5CE7)),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return AppLocalizations.of(context)!.emailRequired;
                              if (!v.contains('@')) return AppLocalizations.of(context)!.emailInvalid;
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),

                          Text(AppLocalizations.of(context)!.password, style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70,
                          )),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6C5CE7)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white38,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Informe sua senha';
                              if (v.length < 6) return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Forgot password ───────────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: Text(
                          AppLocalizations.of(context)!.forgotPassword,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF6C5CE7),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Login button ──────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                AppLocalizations.of(context)!.login,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ── Divider ───────────────────────────────────
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('ou', style: GoogleFonts.inter(color: Colors.white30, fontSize: 13)),
                        ),
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // ── Biometric & Social buttons ────────────────────────────
                    if (_canCheckBiometrics && _hasBiometricToken) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _loginWithBiometrics,
                          icon: const Icon(Icons.fingerprint, size: 28),
                          label: Text(
                            'Entrar com Face ID / Digital',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF6C5CE7)),
                            backgroundColor: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                        label: Text(
                          'Continuar com Google',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Color(0xFF2A2A4A)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // ── Register link ────────────────────────────
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Não tem conta? ',
                            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/register'),
                            child: Text(
                              'Criar conta grátis',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF6C5CE7),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/privacy'),
                            child: Text(
                              'Privacidade',
                              style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, decoration: TextDecoration.underline),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('•', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/privacy'),
                            child: Text(
                              'Termos de Uso',
                              style: GoogleFonts.inter(color: Colors.white38, fontSize: 11, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
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
