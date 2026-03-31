import 'package:flutter/material.dart';
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
  bool _isResending = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // Auto-focus the first OTP field after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes.isNotEmpty && mounted) {
        _focusNodes[0].requestFocus();
      }
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

  /// Verify the OTP code entered by user against the backend
  Future<void> _verify() async {
    String code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() => _errorMessage = 'Digite o código completo de 6 dígitos.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final result = await api.verifySms(code);

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() => _isLoading = false);
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['error'] ?? AppLocalizations.of(context)!.invalidCode;
        });
        // Clear fields on error so user can retry
        for (var c in _controllers) {
          c.clear();
        }
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

  /// Resend OTP via backend
  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final result = await api.resendSms();

      if (!mounted) return;

      for (var c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();

      if (result['success'] == true) {
        setState(() {
          _isResending = false;
          _successMessage = 'Novo código enviado! Verifique seu celular.';
        });
      } else {
        setState(() {
          _isResending = false;
          _errorMessage = result['error'] ?? 'Erro ao reenviar código.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
          _errorMessage = 'Erro de conexão. Tente novamente.';
        });
      }
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
                if (_successMessage != null) _buildSuccess(),

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
