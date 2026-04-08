import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shapepro/l10n/app_localizations.dart';
import '../services/api.dart';

class VerifyChoiceScreen extends StatefulWidget {
  const VerifyChoiceScreen({super.key});

  @override
  State<VerifyChoiceScreen> createState() => _VerifyChoiceScreenState();
}

class _VerifyChoiceScreenState extends State<VerifyChoiceScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _sendEmailVerification() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final api = Provider.of<ApiService>(context, listen: false);
    
    try {
      final response = await api.sendVerificationEmail();
      setState(() {
        _isLoading = false;
        if (response['success'] == true) {
          _successMessage = 'E-mail enviado! Clique no link lá na sua caixa de entrada e depois clique aqui em "Já verifiquei".';
        } else {
          _errorMessage = response['error'] ?? 'Erro ao enviar e-mail.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Falha ao se comunicar com o servidor.';
      });
    }
  }

  Future<void> _checkIfEmailVerified() async {
    setState(() {
      _isLoading = true;
    });
    final api = Provider.of<ApiService>(context, listen: false);
    // Refresh user profile to check if email_verificado is true
    final user = await api.getProfile();
    setState(() {
      _isLoading = false;
    });
    
    if (user['email_verificado'] == true) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _errorMessage = 'O e-mail ainda não foi verificado. Confira sua caixa de spam ou lixo eletrônico!';
        _successMessage = null;
      });
    }
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                const Icon(Icons.security_rounded, size: 80, color: Color(0xFF6C5CE7)),
                const SizedBox(height: 30),
                Text(
                  "Segurança da Conta",
                  style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Como você deseja ativar e proteger a sua conta ShapePro?",
                  style: GoogleFonts.inter(fontSize: 16, color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
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
                    child: Text(_errorMessage!, style: GoogleFonts.inter(color: const Color(0xFFFD4556), fontSize: 13)),
                  ),

                if (_successMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B894).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00B894).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(_successMessage!, style: GoogleFonts.inter(color: const Color(0xFF00B894), fontSize: 13), textAlign: TextAlign.center),
                        const SizedBox(height: 15),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _checkIfEmailVerified,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Já verifiquei! Entrar no App'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B894)),
                        )
                      ],
                    ),
                  ),

                if (_successMessage == null) ...[
                  // Opção EMAIL
                  GestureDetector(
                    onTap: _isLoading ? null : _sendEmailVerification,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16162A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.5), width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.email_outlined, color: Color(0xFF6C5CE7), size: 30),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Verificar por E-mail", style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text("Enviamos um link mágico", style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                              ],
                            ),
                          ),
                          if (_isLoading) const CircularProgressIndicator() else const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16)
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Opção SMS
                  GestureDetector(
                    onTap: _isLoading ? null : () {
                      Navigator.pushReplacementNamed(context, '/verify_sms');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16162A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2A2A4A), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A4A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.sms_outlined, color: Colors.white70, size: 30),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Verificar por SMS", style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text("Receba um código de 6 dígitos", style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16)
                        ],
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
}
