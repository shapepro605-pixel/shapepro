import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shapepro/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.privacy),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '1. ${l10n.privacyIntroTitle}',
              l10n.privacyIntroDesc,
            ),
            _buildSection(
              '2. ${l10n.privacyDataTitle}',
              l10n.privacyDataDesc,
            ),
            _buildSection(
              '3. ${l10n.medicalDisclaimerTitle}',
              l10n.medicalDisclaimerDesc,
            ),
            _buildSection(
              '4. ${l10n.privacyPaymentTitle}',
              l10n.privacyPaymentDesc,
            ),
            _buildSection(
              '5. ${l10n.privacyDeleteTitle}',
              l10n.privacyDeleteDesc,
            ),
            _buildSection(
              '6. ${l10n.privacyContactTitle}',
              l10n.privacyContactDesc,
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                '${l10n.version} 1.0.1 - ${l10n.lastUpdate}: April 2026',
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
