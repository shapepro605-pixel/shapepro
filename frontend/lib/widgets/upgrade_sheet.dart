import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shapepro/l10n/app_localizations.dart';

void showUpgradeSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const _UpgradeSheetContent(),
  );
}

class _UpgradeSheetContent extends StatefulWidget {
  const _UpgradeSheetContent();

  @override
  State<_UpgradeSheetContent> createState() => _UpgradeSheetContentState();
}

class _UpgradeSheetContentState extends State<_UpgradeSheetContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1035), Color(0xFF0F0F24)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50, height: 5,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 35),
          // ── Premium Lock Icon with Glow ──
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFFD700).withValues(alpha: 0.3),
                      const Color(0xFFFFA502).withValues(alpha: 0.15),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: _glowAnimation.value * 0.5),
                      blurRadius: 30 * _glowAnimation.value,
                      spreadRadius: 5 * _glowAnimation.value,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFFA502).withValues(alpha: _glowAnimation.value * 0.3),
                      blurRadius: 50 * _glowAnimation.value,
                      spreadRadius: 15 * _glowAnimation.value,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Color(0xFFFFD700),
                  size: 42,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA502)],
            ).createShader(bounds),
            child: Text(
              AppLocalizations.of(context)!.lockedTrial,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppLocalizations.of(context)!.upgradeToUnlock,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          // ── Feature bullets ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                _buildFeatureRow(Icons.restaurant_menu, 'Todas as refeições desbloqueadas'),
                const SizedBox(height: 10),
                _buildFeatureRow(Icons.fitness_center, 'Todos os exercícios liberados'),
                const SizedBox(height: 10),
                _buildFeatureRow(Icons.emoji_events, 'Acesso a campeonatos'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/checkout');
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: const Color(0xFF6C5CE7).withValues(alpha: 0.5),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF4834D4)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "ASSINAR PREMIUM",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6C5CE7), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: GoogleFonts.inter(
            color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500,
          )),
        ),
        const Icon(Icons.check_circle, color: Color(0xFF2ED573), size: 16),
      ],
    );
  }
}
