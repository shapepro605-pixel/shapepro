import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/api.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = true;
  List<dynamic> _plans = [];
  final TextEditingController _promoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final res = await api.getPaymentPlans();
    if (mounted) {
      if (res['success'] == true && res['plans'] != null) {
        setState(() {
          _plans = res['plans'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingPlans)),
        );
      }
    }
  }

  void _assinar(String planCode, String planName) async {
    final promoCode = _promoController.text.trim();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
 title: Text(
          promoCode.isNotEmpty
              ? AppLocalizations.of(context)!.confirmPlanActivation(promoCode) // reusing param for promo code display title shorthand if needed, but let's be more precise
              : AppLocalizations.of(context)!.confirmSubscription,
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppLocalizations.of(context)!.confirmPlanActivation(planName),
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7))),
    );

    final api = Provider.of<ApiService>(context, listen: false);
    final res = await api.checkout(planCode, promoCode);
    
    if (!mounted) return;
    Navigator.pop(context); // close loading

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.congrats} ${res['message']}'),
          backgroundColor: const Color(0xFF2ED573),
        ),
      );
      Navigator.pop(context); // return to home/navigation
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'] ?? AppLocalizations.of(context)!.paymentError),
          backgroundColor: const Color(0xFFFD4556),
        ),
      );
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.premiumTitle),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Buscando compras anteriores...')),
              );
            },
            child: Text(
              AppLocalizations.of(context)!.restore,
              style: GoogleFonts.inter(
                color: const Color(0xFF00D2FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.verified, size: 60, color: Color(0xFF6C5CE7)),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.unlockPro,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.premiumDesc,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  ..._plans.map((p) => _buildPlanCard(p)).toList(),

                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16162A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2A2A4A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.havePromoCode,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _promoController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.promoCodeHint,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.insertCodeBefore,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.termsOfUse,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white38,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        AppLocalizations.of(context)!.privacy,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white38,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final meses = plan['duration_months'] as int;
    final preco = (plan['price'] as num).toDouble();
    final bool isBest = meses == 12;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => _assinar(plan['code'], plan['name']),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF16162A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isBest ? const Color(0xFF6C5CE7) : const Color(0xFF2A2A4A),
                width: isBest ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan['name'],
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.accessDuration(meses, meses == 1 ? AppLocalizations.of(context)!.month : AppLocalizations.of(context)!.months),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$ ${preco.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isBest ? const Color(0xFF6C5CE7) : Colors.white,
                      ),
                    ),
                    if (meses > 1) ...[
                      const SizedBox(height: 2),
                      Text(
                        'ou R\$ ${(preco / meses).toStringAsFixed(2)}/mês',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isBest)
          Positioned(
            top: -10,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Text(
                AppLocalizations.of(context)!.bestValue,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
