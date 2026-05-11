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

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = true;
  final TextEditingController _promoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlans();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.premiumTitle),
        actions: [
          TextButton(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Buscando compras anteriores...')),
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
                                  'Ativar', // Changed to "Ativar" as requested
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
                'Planos não carregados.\nVerifique sua conexão ou a Google Play Store.',
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => _assinar(product),
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
                      product.title.split('(')[0].trim(),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
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
                      product.price,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isBest ? const Color(0xFF6C5CE7) : Colors.white,
                      ),
                    ),
                    if (isBest) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Melhor valor',
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
      ],
    );
  }
}
