import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
  bool _isSendingSms = false;
  String? _errorMessage;
  String? _verificationId;
  int? _resendToken;

  @override
  void initState() {
    super.initState();
    // Send SMS after build to have access to context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendVerificationSms();
    });
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

  /// Send SMS via Firebase Phone Auth
  Future<void> _sendVerificationSms() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final phone = api.currentUser?['telefone'] ?? '';

    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Número de telefone não encontrado.');
      return;
    }

    // Ensure phone starts with country code
    String formattedPhone = phone.trim();
    if (!formattedPhone.startsWith('+')) {
      // Assume Brazil if no country code
      formattedPhone = '+55$formattedPhone';
    }

    setState(() {
      _isSendingSms = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only — auto-reads SMS)
          if (mounted) {
            setState(() => _isLoading = true);
            await _completeVerification(credential);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() {
              _isSendingSms = false;
              _errorMessage = _getFirebaseErrorMessage(e.code);
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _resendToken = resendToken;
              _isSendingSms = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.resendCode),
                backgroundColor: const Color(0xFF2ED573),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) {
            _verificationId = verificationId;
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingSms = false;
          _errorMessage = 'Erro ao enviar SMS. Tente novamente.';
        });
      }
    }
  }

  /// Verify the OTP code entered by user
  Future<void> _verify() async {
    String code = _controllers.map((c) => c.text).join();
    if (code.length < 6) return;

    if (_verificationId == null) {
      setState(() => _errorMessage = 'Aguarde o envio do SMS...');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await _completeVerification(credential);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getFirebaseErrorMessage(e.code);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context)!.invalidCode;
        });
      }
    }
  }

  /// After Firebase verifies, notify our backend
  Future<void> _completeVerification(PhoneAuthCredential credential) async {
    try {
      // Authenticate with Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Notify our backend that phone is verified
      if (!mounted) return;
      final api = Provider.of<ApiService>(context, listen: false);
      final code = _controllers.map((c) => c.text).join();
      await api.verifySms(code.isNotEmpty ? code : '000000');

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context)!.invalidCode;
        });
      }
    }
  }

  /// Resend SMS
  Future<void> _resend() async {
    for (var c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    await _sendVerificationSms();
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Número de telefone inválido.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos.';
      case 'invalid-verification-code':
        return 'Código inválido. Tente novamente.';
      case 'session-expired':
        return 'Código expirado. Solicite um novo.';
      default:
        return 'Erro na verificação ($code). Tente novamente.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiService>(context);
    final phone = api.currentUser?['telefone'] ?? '';

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
                if (_isSendingSms)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 25),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(color: Color(0xFF6C5CE7), strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text('Enviando SMS...', style: GoogleFonts.inter(
                          color: const Color(0xFF6C5CE7), fontSize: 13,
                        )),
                      ],
                    ),
                  ),
                
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
                    onPressed: (_isLoading || _isSendingSms) ? null : _resend,
                    child: Text(
                      AppLocalizations.of(context)!.resendCode,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6C5CE7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
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
      child: Text(_errorMessage!, style: GoogleFonts.inter(
        color: const Color(0xFFFD4556), fontSize: 13,
      )),
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (_isLoading || _verificationId == null) ? null : _verify,
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
