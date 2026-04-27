import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/body_utils.dart';
import 'package:shapepro/l10n/app_localizations.dart';

class BodyComparisonPage extends StatefulWidget {
  final Map<String, dynamic> beforeScan;
  final Map<String, dynamic> afterScan;

  const BodyComparisonPage({
    super.key,
    required this.beforeScan,
    required this.afterScan,
  });

  @override
  State<BodyComparisonPage> createState() => _BodyComparisonPageState();
}

class _BodyComparisonPageState extends State<BodyComparisonPage> {
  double _sliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Stack(
        children: [
          // ── Background Images & Slider ──────────────────────────
          _buildComparisonSlider(),
          
          // ── Top Bar ───────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      l10n.evolutionAnalysis.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40), // Balance
                ],
              ),
            ),
          ),

          // ── Bottom Panel (Draggable or Fixed) ──────────────────
          _buildEvolutionPanel(l10n),
        ],
      ),
    );
  }

  Widget _buildComparisonSlider() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // AFTER (Newer) - Visible on the left
        Image.network(
          widget.afterScan['image_url'],
          fit: BoxFit.cover,
        ),
        
        // BEFORE (Older) - Clipped to the right
        ClipRect(
          clipper: _SliderClipper(_sliderValue),
          child: Image.network(
            widget.beforeScan['image_url'],
            fit: BoxFit.cover,
          ),
        ),
        
        // Slider Line
        Align(
          alignment: Alignment(lerpDouble(-1, 1, _sliderValue)!, 0),
          child: Container(
            width: 2,
            color: const Color(0xFF6C5CE7),
            height: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C5CE7).withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Icon(Icons.unfold_more, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
        ),
        
        // Interactive Overlay
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _sliderValue += details.primaryDelta! / MediaQuery.of(context).size.width;
              _sliderValue = _sliderValue.clamp(0.0, 1.0);
            });
          },
          child: Container(color: Colors.transparent),
        ),

        // Labels
        Positioned(
          top: 100,
          left: 20,
          child: _buildDateLabel("DEPOIS", widget.afterScan['created_at']),
        ),
        Positioned(
          top: 100,
          right: 20,
          child: _buildDateLabel("ANTES", widget.beforeScan['created_at']),
        ),
      ],
    );
  }

  Widget _buildDateLabel(String title, String dateStr) {
    DateTime date = DateTime.parse(dateStr);
    String formatted = DateFormat('dd/MM/yy').format(date);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
          Text(formatted, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildEvolutionPanel(AppLocalizations l10n) {
    final beforeMetrics = widget.beforeScan['metrics'] as Map<String, dynamic>? ?? {};
    final afterMetrics = widget.afterScan['metrics'] as Map<String, dynamic>? ?? {};
    
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.2,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF16162A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5)],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("SUA EVOLUÇÃO", style: GoogleFonts.inter(color: const Color(0xFF6C5CE7), fontWeight: FontWeight.w900, fontSize: 22)),
                          Text("Comparação detalhada", style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                      _buildSummaryBadge(afterMetrics, beforeMetrics),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  _buildComparisonRow("Peito", afterMetrics['chest'], beforeMetrics['chest']),
                  _buildComparisonRow("Cintura", afterMetrics['waist'], beforeMetrics['waist'], reverse: true),
                  _buildComparisonRow("Quadril", afterMetrics['hips'], beforeMetrics['hips']),
                  _buildComparisonRow("Ombros", afterMetrics['shoulders'], beforeMetrics['shoulders']),
                  
                  if (afterMetrics.containsKey('left_arm') && beforeMetrics.containsKey('left_arm'))
                    _buildComparisonRow("Braço", afterMetrics['left_arm'], beforeMetrics['left_arm']),
                    
                  const SizedBox(height: 32),
                  _buildVictoryCard(afterMetrics, beforeMetrics),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryBadge(Map after, Map before) {
    // Exemplo: Diferença de cintura como destaque
    String delta = BodyUtils.getDeltaString(after['waist'] ?? 0, before['waist'] ?? 0);
    bool isLost = (double.tryParse(delta) ?? 0) < 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLost ? const Color(0xFF2ED573).withOpacity(0.1) : const Color(0xFF6C5CE7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLost ? const Color(0xFF2ED573) : const Color(0xFF6C5CE7), width: 1.5),
      ),
      child: Column(
        children: [
          Text(isLost ? "REDUÇÃO" : "GANHO", style: GoogleFonts.inter(color: isLost ? const Color(0xFF2ED573) : const Color(0xFF6C5CE7), fontSize: 10, fontWeight: FontWeight.bold)),
          Text("$delta cm", style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, dynamic newVal, dynamic oldVal, {bool reverse = false}) {
    if (newVal == null || oldVal == null) return const SizedBox.shrink();
    
    String delta = BodyUtils.getDeltaString(newVal, oldVal);
    Color deltaColor = BodyUtils.getDeltaColor(newVal, oldVal, reverse: reverse);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(BodyUtils.formatMeasure(context, oldVal), style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
          ),
          const Icon(Icons.arrow_forward, color: Colors.white10, size: 14),
          Expanded(
            child: Text(BodyUtils.formatMeasure(context, newVal), textAlign: TextAlign.right, style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: deltaColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(delta, style: GoogleFonts.inter(color: deltaColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildVictoryCard(Map after, Map before) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF4834D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6C5CE7).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          Text(
            "RESULTADO INCRÍVEL!",
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            "Você está mais perto do seu objetivo hoje do que há 30 dias. Continue assim!",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.share, size: 18),
            label: const Text("COMPARTILHAR VITÓRIA"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6C5CE7),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderClipper extends CustomClipper<Rect> {
  final double value;
  _SliderClipper(this.value);

  @override
  Rect getClip(Size size) {
    // We want to show the AFTER (newer) on the LEFT and BEFORE (older) on the RIGHT
    // The BEFORE image is clipped: we show the portion from [value * width] to [width]
    return Rect.fromLTRB(value * size.width, 0, size.width, size.height);
  }

  @override
  bool shouldReclip(_SliderClipper oldClipper) => oldClipper.value != value;
}
