import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        title: const Text('Privacidade e Termos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '1. Introdução',
              'O ShapePro está comprometido em proteger sua privacidade. Esta política descreve como coletamos e usamos seus dados para fornecer planos de treino e dieta personalizados.',
            ),
            _buildSection(
              '2. Coleta de Dados',
              'Coletamos informações como e-mail, telefone, peso, altura, idade e nível de atividade. Esses dados são usados exclusivamente para o cálculo do seu plano e monitoramento de progresso.',
            ),
            _buildSection(
              '3. Aviso Médico (Disclaimer)',
              'IMPORTANTE: O ShapePro fornece orientações informativas. SEMPRE consulte um médico ou nutricionista antes de iniciar qualquer dieta restritiva ou programa de exercícios intensos. Não nos responsabilizamos por lesões resultantes da execução incorreta de exercícios.',
            ),
            _buildSection(
              '4. Assinaturas e Pagamentos',
              'As assinaturas são processadas através da Google Play Store. O cancelamento pode ser feito a qualquer momento nas configurações da sua conta Google.',
            ),
            _buildSection(
              '5. Exclusão de Dados',
              'Você pode solicitar a exclusão permanente de sua conta e todos os dados associados a qualquer momento através do menu Configurações no aplicativo.',
            ),
            _buildSection(
              '6. Contato',
              'Para dúvidas sobre privacidade, entre em contato: suporte@shapepro.com.br',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Versão 1.0.0 - Última atualização: Março 2026',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6C5CE7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
