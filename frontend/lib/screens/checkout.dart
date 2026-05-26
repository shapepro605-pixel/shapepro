import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shapepro/l10n/app_localizations.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  final TextEditingController _promoController = TextEditingController();

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _loadPlans();
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadPlans() async {
    final api = Provider.of<ApiService>(context, listen: false);
    await api.fetchProducts();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _assinar(ProductDetails product) async {
    final api = Provider.of<ApiService>(context, listen: false);
    await api.buyProduct(product);
    // The purchase result is handled by the listener in ApiService
    if (mounted) Navigator.pop(context);
  }

  Future<void> _aplicarCupom() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;
    
    setState(() => _isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    
    final result = await api.applyVipCoupon(code);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Cupom Aplicado!'),
            backgroundColor: const Color(0xFF2ED573),
          ),
        );
        Navigator.pop(context); // Return home with premium
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erro ao aplicar cupom'),
            backgroundColor: const Color(0xFFFD4556),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Provider.of<ApiService>(context).isDarkMode;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.premiumTitle),
        actions: [
          TextButton(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.restoringPurchases)),
              );
              await Provider.of<ApiService>(context, listen: false).restorePurchases();
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
                  const SizedBox(height: 32),
                  // Store Products or Mock Plans for testing
                  ...(_loadPlansList(Provider.of<ApiService>(context).products)),

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
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _promoController,
                                enabled: !_isLoading,
                                textCapitalization: TextCapitalization.characters,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(context)!.promoCodeHint,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF2A2A4A) : const Color(0xFF1E1E38),
                                  hintStyle: const TextStyle(color: Colors.white30),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 1.5),
                                  ),
                                ),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _aplicarCupom,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C5CE7), // Brand Purple
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.activateBtn,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
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
                      GestureDetector(
                        onTap: () async {
                          const url = 'https://play.google.com/store/account/subscriptions';
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Text(
                          AppLocalizations.of(context)!.manageSubscription,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF00D2FF),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/privacy'),
                        child: Text(
                          AppLocalizations.of(context)!.privacy,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white38,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _loadPlansList(List<ProductDetails> products) {
    if (products.isNotEmpty) {
      return products.map((p) => _buildProductCard(p)).toList();
    }
    
    return [
      Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.white24, size: 48),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.plansNotLoaded,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      )
    ];
  }



  Widget _buildProductCard(ProductDetails product) {
    final bool isBest = product.id == 'shapepro_anual';

    String title = product.title.split('(')[0].trim();
    String description = product.description;

    if (product.id == 'shapepro_mensal') {
      title = AppLocalizations.of(context)!.monthlyPlanTitle;
      description = AppLocalizations.of(context)!.monthlyPlanDesc;
    } else if (product.id == 'shapepro_anual') {
      title = AppLocalizations.of(context)!.annualPlanTitle;
      description = AppLocalizations.of(context)!.annualPlanDesc;
    }

    final isMonthly = product.id == 'shapepro_mensal';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return GestureDetector(
              onTap: () => _assinar(product),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16162A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isMonthly 
                        ? Colors.white.withValues(alpha: _glowAnimation.value) 
                        : (isBest ? const Color(0xFF6C5CE7) : const Color(0xFF2A2A4A)),
                    width: isMonthly ? 2 : (isBest ? 2 : 1),
                  ),
                  boxShadow: isMonthly ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: _glowAnimation.value * 0.4),
                      blurRadius: 15 * _glowAnimation.value,
                      spreadRadius: 2 * _glowAnimation.value,
                    )
                  ] : null,
                ),
                child: child,
              ),
            );
          },
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 14,
                            color: Color(0xFF00D2FF),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.cancelAnytime,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF00D2FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.price,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isBest ? const Color(0xFF6C5CE7) : Colors.white,
                      ),
                    ),
                    if (isBest) ...[
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.bestValue,
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
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
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
        if (product.id == 'shapepro_mensal')
          Positioned(
            top: -10,
            right: 20,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: _glowAnimation.value * 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: child,
                );
              },
              child: Text(
                AppLocalizations.of(context)!.recommendedPlan,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E103A),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
