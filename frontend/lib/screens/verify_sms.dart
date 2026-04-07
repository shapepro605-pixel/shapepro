import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shapepro/l10n/app_localizations.dart';
import '../services/api.dart';

class VerifySmsScreen extends StatefulWidget {
  const VerifySmsScreen({super.key});

  @override
  State<VerifySmsScreen> createState() => _VerifySmsScreenState();
}

class _VerifySmsScreenState extends State<VerifySmsScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  bool _isSendingCode = true; // Firebase sending the initial code
  String? _errorMessage;
  String? _successMessage;

  // Firebase phone auth state
  String? _verificationId;
  int? _resendToken;

  bool _initialized = false;
  String _phoneToVerify = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final api = Provider.of<ApiService>(context, listen: false);
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      _phoneToVerify = args?['phone'] as String? ?? api.currentUser?['telefone'] ?? '';

      if (args != null && args.containsKey('verificationId')) {
         setState(() {
           _verificationId = args['verificationId'];
           _isSendingCode = false;
           _successMessage = 'Código enviado! Verifique seu celular.';
         });
         WidgetsBinding.instance.addPostFrameCallback((_) {
             if (mounted) _focusNodes[0].requestFocus();
         });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startPhoneVerification();
        });
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Start Firebase phone verification flow
  Future<void> _startPhoneVerification() async {
    String phone = _phoneToVerify;
    
    // Normalize phone number for Firebase (Add +55 if missing, ensure + is present)
    if (phone.isNotEmpty) {
      phone = phone.replaceAll(RegExp(r'[^0-9+]'), ''); // Remove spaces, dashes, etc
      if (!phone.startsWith('+')) {
        if (!phone.startsWith('55')) {
          phone = '+55$phone';
        } else {
          phone = '+$phone';
        }
      }
    }
    
    debugPrint('[DEBUG] Starting SMS verification for: $phone');

    if (phone.isEmpty) {
      setState(() {
        _isSendingCode = false;
        _errorMessage = 'Número de telefone não encontrado. Volte e cadastre novamente.';
      });
      return;
    }

    setState(() {
      _isSendingCode = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),

        // Called when Firebase auto-resolves the SMS (Android only)
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('[FIREBASE SUCCESS] Auto-verification completed!');
          await _signInWithCredential(credential);
        },

        // Called when verification fails
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('[FIREBASE ERROR] Code: ${e.code}, Message: ${e.message}, InternalData: ${e.plugin}');
          if (mounted) {
            setState(() {
              _isSendingCode = false;
              _errorMessage = _translateFirebaseError(e.code);
            });
          }
        },

        // Called when SMS is sent — user must enter code manually
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('[FIREBASE SENT] Code sent! ID: $verificationId');
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _resendToken = resendToken;
              _isSendingCode = false;
              _successMessage = 'Código enviado! Verifique seu celular.';
            });
            // Focus first OTP field
            _focusNodes[0].requestFocus();
          }
        },

        // Called on timeout
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('[FIREBASE TIMEOUT] Timeout reached for: $verificationId');
          if (mounted) {
            _verificationId = verificationId;
          }
        },
      );
    } catch (e) {
      debugPrint('[CRITICAL ERROR] Failed to call verifyPhoneNumber: $e');
      if (mounted) {
        setState(() {
          _isSendingCode = false;
          _errorMessage = 'Erro ao enviar SMS: ${e.toString()}';
        });
      }
    }
  }

  /// Sign in with Firebase credential and notify backend
  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken != null && mounted) {
        // Send Firebase ID token to our backend for verification
        final api = Provider.of<ApiService>(context, listen: false);
        final result = await api.verifyPhoneWithFirebase(idToken);

        if (!mounted) return;

        if (result['success'] == true) {
          // Sign out from Firebase (we only use it for phone verification, not auth)
          await FirebaseAuth.instance.signOut();
          
          if (result['needs_registration'] == true) {
            // User found in Firebase but not in our DB -> Send to signup
            Navigator.pushReplacementNamed(context, '/register', arguments: {'phone': result['phone']});
          } else {
            // Success! Go to home
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = result['error'] ?? 'Falha na verificação.';
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _translateFirebaseError(e.code);
        });
        // Clear fields
        for (var c in _controllers) { c.clear(); }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro de conexão. Verifique sua internet.';
        });
      }
    }
  }

  /// Verify the OTP code entered by user
  Future<void> _verify() async {
    String code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() => _errorMessage = 'Digite o código completo de 6 dígitos.');
      return;
    }

    if (_verificationId == null) {
      setState(() => _errorMessage = 'Erro: código de verificação não recebido. Tente reenviar.');
      return;
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: code,
    );

    await _signInWithCredential(credential);
  }

  /// Resend OTP via Firebase
  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    // Clear fields
    for (var c in _controllers) { c.clear(); }

    await _startPhoneVerification();

    if (mounted) {
      setState(() {
        _isResending = false;
      });
    }
  }

  /// Translate Firebase error codes to user-friendly messages
  String _translateFirebaseError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Número de telefone inválido. Verifique o formato.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
      case 'invalid-verification-code':
        return 'Código incorreto. Verifique e tente novamente.';
      case 'session-expired':
        return 'Sessão expirada. Reenvie o código.';
      case 'quota-exceeded':
        return 'Limite de SMS excedido. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Erro de rede. Verifique sua conexão.';
      default:
        return 'Erro na verificação ($code). Tente novamente.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = _phoneToVerify;

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E38),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  AppLocalizations.of(context)!.verifyPhone,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.verifySubtitle(phone),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.white54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                if (_errorMessage != null) _buildError(),
                if (_successMessage != null) _buildSuccess(),

                // Show loading while Firebase sends the code
                if (_isSendingCode)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        const CircularProgressIndicator(color: Color(0xFF6C5CE7)),
                        const SizedBox(height: 16),
                        Text(
                          'Enviando código SMS...',
                          style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // ── OTP Fields ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) => _buildOtpBox(index)),
                  ),
                  
                  const SizedBox(height: 40),
                  _buildVerifyButton(),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: (_isLoading || _isResending) ? null : _resend,
                      child: _isResending
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(color: Color(0xFF6C5CE7), strokeWidth: 2),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Reenviando...',
                                  style: GoogleFonts.inter(color: const Color(0xFF6C5CE7), fontWeight: FontWeight.w600),
                                ),
                              ],
                            )
                          : Text(
                              AppLocalizations.of(context)!.resendCode,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF6C5CE7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          counterText: "",
          fillColor: const Color(0xFF1E1E38),
          filled: true,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A2A4A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (index == 5 && value.isNotEmpty) {
            _verify();
          }
        },
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: const Color(0xFFFD4556).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFD4556).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFD4556), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_errorMessage!, style: GoogleFonts.inter(
              color: const Color(0xFFFD4556), fontSize: 13,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: const Color(0xFF2ED573).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2ED573).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF2ED573), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_successMessage!, style: GoogleFonts.inter(
              color: const Color(0xFF2ED573), fontSize: 13,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _verify,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C5CE7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          disabledBackgroundColor: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                AppLocalizations.of(context)!.verifyBtn,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
      ),
    );
  }
}
