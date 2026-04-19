import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shapepro/l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api.dart';
import '../services/notification_service.dart';
import '../widgets/scale_button.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shapepro/utils/logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  Map<String, dynamic>? _progresso;
  bool _isLoading = true;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
    _loadData();
    _checkUpdate();
    _showMedicalDisclaimer();
  }

  Future<void> _showMedicalDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAccepted = prefs.getBool('medical_disclaimer_accepted') ?? false;
    
    if (!hasAccepted && mounted) {
      // Small delay to let initial UI settle
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF16162A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Row(
              children: [
                const Icon(Icons.medical_services_outlined, color: Color(0xFFFD4556)),
                const SizedBox(width: 12),
                Expanded(child: Text(AppLocalizations.of(context)!.medicalDisclaimerTitle, 
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
              ],
            ),
            content: Text(
              AppLocalizations.of(context)!.medicalDisclaimerDesc,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  await prefs.setBool('medical_disclaimer_accepted', true);
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(AppLocalizations.of(context)!.accept),
              ),
            ],
          ),
        );
      });
    }
  }


  Future<void> _checkUpdate() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final status = await api.checkVersion();
    
    if (status['success'] == true && status['is_outdated'] == true) {
      if (mounted) {
        _showUpdateDialog(status['update_url'], status['is_mandatory']);
      }
    }
  }

  void _showUpdateDialog(String url, bool isMandatory) {
    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.system_update_rounded, color: Color(0xFF6C5CE7)),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.newVersion, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.updateAvailable, 
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 10),
            if (isMandatory)
              Text(AppLocalizations.of(context)!.mandatoryUpdate, 
                style: GoogleFonts.inter(color: const Color(0xFFFD4556), fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          if (!isMandatory)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.later, style: const TextStyle(color: Colors.white54)),
            ),
          ElevatedButton(
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppLocalizations.of(context)!.updateNow),
          ),
        ],
      ),
    );
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    });
  }

  Future<void> _toggleNotifications() async {
    // If turning ON, request permission first
    if (!_notificationsEnabled) {
      final granted = await NotificationService.requestPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)?.notificationDenied ?? 'Notification denied.')),
          );
        }
        return;
      }
    }

    final newState = !_notificationsEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', newState);
    setState(() => _notificationsEnabled = newState);

    if (newState && _progresso?['dieta_ativa'] != null) {
      await NotificationService.scheduleDietNotifications(_progresso!['dieta_ativa']['refeicoes']);
    } else {
      await NotificationService.cancelAllNotifications();
    }
  }

  Future<void> _loadData() async {
    final api = Provider.of<ApiService>(context, listen: false);
    await api.init();
    
    // Check if user is verified (either email or phone)
    if (api.currentUser != null) {
      final user = api.currentUser!;
      final bool phoneVerified = user['telefone_verificado'] == true;
      final bool emailVerified = user['email_verificado'] == true;
      
      if (!phoneVerified && !emailVerified) {
         if (mounted) {
           Navigator.pushReplacementNamed(context, '/verify_choice'); 
           return;
         }
      }
    }

    final result = await api.getProgresso();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _progresso = result['progresso'];
          
          // Re-schedule notifications if enabled on data load
          if (_notificationsEnabled && _progresso?['dieta_ativa'] != null) {
            NotificationService.scheduleDietNotifications(_progresso!['dieta_ativa']['refeicoes']);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading ? _buildLoading() : _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
    );
  }

  Widget _buildBody() {
    return _buildHomeDashboard();
  }

  // ── Dashboard ────────────────────────────────────────────────────────────

  Widget _buildHomeDashboard() {
    final api = Provider.of<ApiService>(context);
    final userFromProgresso = _progresso?['usuario'] as Map<String, dynamic>? ?? {};
    final nome = userFromProgresso['nome'] ?? api.currentUser?['nome'] ?? AppLocalizations.of(context)!.atleta;
    
    final classificacao = _progresso?['classificacao_imc'] ?? '';
    final imc = _progresso?['imc'];
    final user = userFromProgresso;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: Provider.of<ApiService>(context).isDarkMode
              ? [const Color(0xFF0A0A1A), const Color(0xFF12122A)]
              : [const Color(0xFFF7F8FA), const Color(0xFFECEFF5)],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF6C5CE7),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 22),

                // ── Profile Completion Alert (if needed) ──
                if (user['peso'] == null || user['altura'] == null)
                  _buildProfileCompletionBanner(),

                // ── Header ──────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.hello, style: GoogleFonts.inter(
                            fontSize: 14, color: Colors.white54,
                          )),
                          Text(nome, 
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action Buttons Grouped
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeaderButton(
                          _notificationsEnabled ? Icons.notifications_active : Icons.notifications_none,
                          _toggleNotifications,
                          color: _notificationsEnabled ? const Color(0xFF6C5CE7) : Colors.white54,
                        ),
                        _buildHeaderButton(
                          Provider.of<ApiService>(context).isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          () => Provider.of<ApiService>(context, listen: false).toggleTheme(),
                        ),
                        _buildHeaderButton(
                          Icons.language,
                          () {
                            final api = Provider.of<ApiService>(context, listen: false);
                            if (api.locale.languageCode == 'pt') {
                              api.setLocale(const Locale('en', 'US'));
                            } else {
                              api.setLocale(const Locale('pt', 'BR'));
                            }
                          },
                          isEmoji: true,
                          emoji: Provider.of<ApiService>(context).locale.languageCode == 'pt' ? '🇺🇸' : '🇧🇷',
                        ),
                        _buildHeaderButton(
                          Icons.logout,
                          () async {
                             final api = Provider.of<ApiService>(context, listen: false);
                             await api.logout();
                             if (mounted) Navigator.pushReplacementNamed(context, '/login');
                          },
                          color: const Color(0xFFFD4556),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _showProfileMenu,
                      child: Hero(
                        tag: 'avatar',
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: user['foto_perfil'] == null 
                                  ? const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF00D2FF)])
                                  : null,
                                border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.5), width: 2),
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFF6C5CE7).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                                image: (user['foto_perfil'] != null && user['foto_perfil'].toString().startsWith('http'))
                                    ? DecorationImage(
                                        image: NetworkImage(user['foto_perfil']),
                                        fit: BoxFit.cover,
                                        onError: (exception, stackTrace) {
                                          Log.e('Erro ao carregar imagem de perfil: $exception');
                                        },
                                      )
                                    : null,
                              ),
                              child: (user['foto_perfil'] == null || !user['foto_perfil'].toString().startsWith('http'))
                                  ? Center(
                                      child: Text(
                                        nome.isNotEmpty ? nome[0].toUpperCase() : AppLocalizations.of(context)!.atleta[0].toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            if (api.isLoading && _currentIndex == 0)
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── IMC Card ────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(context, '/profile_edit').then((_) => _loadData()),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF6C5CE7), Color(0xFF4834D4)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.favorite, color: Colors.white70, size: 20),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.yourImc, style: GoogleFonts.inter(
                                  fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500,
                                )),
                                const Spacer(),
                                const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  imc != null ? imc.toString() : '--',
                                  style: GoogleFonts.inter(
                                    fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      classificacao,
                                      style: GoogleFonts.inter(
                                        fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${AppLocalizations.of(context)!.peso}: ${userFromProgresso['peso'] ?? '--'} kg  •  ${AppLocalizations.of(context)!.altura}: ${userFromProgresso['altura'] ?? '--'} cm',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms).moveY(begin: 20, end: 0, curve: Curves.easeOutQuad),
                const SizedBox(height: 22),

                // ── Body Scan Banner ───────────────────────────
                _buildBodyScanBanner(),
                const SizedBox(height: 22),

                // ── Quick Actions ───────────────────────────────
                Row(
                  children: [
                    _buildQuickAction(AppLocalizations.of(context)!.treino, Icons.fitness_center_rounded, const Color(0xFF00D2FF), () {
                      final isFree = _progresso?['usuario']?['plano_assinatura'] == 'free';
                      if (isFree) {
                        Navigator.pushNamed(context, '/checkout');
                      } else {
                        Navigator.pushNamed(context, '/treino');
                      }
                    }),
                    const SizedBox(width: 14),
                    _buildQuickAction(AppLocalizations.of(context)!.dieta, Icons.restaurant_menu, const Color(0xFF6C5CE7), () {
                      final isFree = _progresso?['usuario']?['plano_assinatura'] == 'free';
                      if (isFree) {
                        Navigator.pushNamed(context, '/checkout');
                      } else {
                        Navigator.pushNamed(context, '/dieta');
                      }
                    }),
                    const SizedBox(width: 14),
                    _buildQuickAction(AppLocalizations.of(context)!.championshipsTitle, Icons.emoji_events_rounded, const Color(0xFFFFD93D), () {
                      Navigator.pushNamed(context, '/challenges');
                    }),
                    const SizedBox(width: 14),
                    _buildQuickAction(AppLocalizations.of(context)!.resultado, Icons.trending_up, const Color(0xFFFF6B6B), () {
                      Navigator.pushNamed(context, '/resultado');
                    }),
                  ],
                ).animate().fadeIn(delay: 200.ms, duration: 600.ms).moveY(begin: 20, end: 0, curve: Curves.easeOutQuad),
                const SizedBox(height: 28),

                // ── Weight Chart ────────────────────────────────
                Text(AppLocalizations.of(context)!.weightEvolution, style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700, 
                  color: Provider.of<ApiService>(context).isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                )),
                const SizedBox(height: 16),
                _buildWeightChart(),
                const SizedBox(height: 28),

                // ── Diet Summary ────────────────────────────────
                if (_progresso?['dieta_ativa'] != null) ...[
                  Text(AppLocalizations.of(context)!.dietaAtiva, style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
                  )),
                  const SizedBox(height: 16),
                  _buildDietaSummaryCard(),
                  const SizedBox(height: 28),
                ],

                // ── Training Days ───────────────────────────────
                Text(AppLocalizations.of(context)!.treinosSemana, style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
                )),
                const SizedBox(height: 16),
                _buildTrainingDays(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onTap, {bool isEmoji = false, String? emoji, Color? color}) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E38),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: isEmoji 
          ? Text(emoji!, style: const TextStyle(fontSize: 18))
          : Icon(icon, color: color ?? Colors.white54, size: 18),
      ),
    );
  }

  Widget _buildProfileCompletionBanner() {

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B6B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.profileIncomplete, style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white,
                )),
                Text(AppLocalizations.of(context)!.profileIncompleteDesc, style: GoogleFonts.inter(
                  fontSize: 12, color: Colors.white70,
                )),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/profile_edit').then((_) => _loadData()),
            child: Text(AppLocalizations.of(context)!.completeProfile, style: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF16162A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF2A2A4A)),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(label, 
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70, height: 1.1,
                  )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyScanBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.camera_enhance_rounded, color: Color(0xFF6C5CE7), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.bodyScanAI,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.trackBodyEvolution,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          ScaleButton(
            onTap: () => Navigator.pushNamed(context, '/body_scan'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF6C5CE7), width: 1),
              ),
              child: Text(
                AppLocalizations.of(context)!.open, 
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6C5CE7))
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 600.ms).moveY(begin: 20, end: 0, curve: Curves.easeOutQuad);
  }

  Widget _buildWeightChart() {
    final logs = _progresso?['historico_peso'] as List<dynamic>? ?? [];

    if (logs.isEmpty) {
      return Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFF16162A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF2A2A4A)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.show_chart, color: Colors.white24, size: 40),
              const SizedBox(height: 10),
              Text(AppLocalizations.of(context)!.registerWeightToSeeChart, style: GoogleFonts.inter(
                color: Colors.white38, fontSize: 13,
              )),
            ],
          ),
        ),
      );
    }

    final spots = logs.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['peso'] as num).toDouble());
    }).toList();

    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: const Color(0xFF2A2A4A),
              strokeWidth: 1,
            ),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF6C5CE7),
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF6C5CE7),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                    const Color(0xFF6C5CE7).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietaSummaryCard() {
    final dieta = _progresso?['dieta_ativa'];
    if (dieta == null) return const SizedBox();

    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroItem(l10n.calories, '${dieta['calorias_totais']?.toInt() ?? 0}', 'kcal', const Color(0xFFFF6B6B)),
              _buildMacroItem(l10n.proteins, '${dieta['proteinas_g']?.toInt() ?? 0}', 'g', const Color(0xFF00D2FF)),
              _buildMacroItem(l10n.carbs, '${dieta['carboidratos_g']?.toInt() ?? 0}', 'g', const Color(0xFFFFA502)),
              _buildMacroItem(l10n.fats, '${dieta['gorduras_g']?.toInt() ?? 0}', 'g', const Color(0xFF6C5CE7)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w800, color: color,
        )),
        Text(unit, style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(
          fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w500,
        )),
      ],
    );
  }

  Widget _buildTrainingDays() {
    final l10n = AppLocalizations.of(context);
    final days = [
      {'tipo': 'A', 'nome': l10n?.chestTriceps ?? 'Chest & Triceps', 'icon': Icons.fitness_center},
      {'tipo': 'B', 'nome': l10n?.backBiceps ?? 'Back & Biceps', 'icon': Icons.fitness_center},
      {'tipo': 'C', 'nome': l10n?.legsGlutes ?? 'Legs & Glutes', 'icon': Icons.directions_run},
      {'tipo': 'D', 'nome': l10n?.shouldersAbs ?? 'Shoulders & Abs', 'icon': Icons.accessibility_new},
      {'tipo': 'E', 'nome': l10n?.fullBodyFunctional ?? 'Full Body', 'icon': Icons.sports_gymnastics},
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final day = days[i];
          final colors = [
            const Color(0xFF6C5CE7),
            const Color(0xFF00D2FF),
            const Color(0xFFFF6B6B),
            const Color(0xFFFFA502),
            const Color(0xFF2ED573),
          ];
          return ScaleButton(
            onTap: () {
              Navigator.pushNamed(context, '/treino', arguments: day['tipo']);
            },
            child: Container(
              width: 130,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16162A),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors[i].withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors[i].withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(day['icon'] as IconData, color: colors[i], size: 20),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Treino ${day['tipo']}', style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                      )),
                      Text(day['nome'] as String, style: GoogleFonts.inter(
                        fontSize: 10, color: Colors.white54,
                      )),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16162A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 22),
            // Header com Foto e Opção de Trocar
            StatefulBuilder(
              builder: (context, setMenuState) {
                final api = Provider.of<ApiService>(context);
                final curUser = api.currentUser ?? {};
                return Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C5CE7), Color(0xFF00D2FF)],
                            ),
                            image: curUser['foto_perfil'] != null
                                ? DecorationImage(
                                    image: NetworkImage(curUser['foto_perfil']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: curUser['foto_perfil'] == null
                              ? Center(
                                  child: Text(
                                    (curUser['nome'] ?? '')[0].toUpperCase(),
                                    style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                )
                              : null,
                        ),
                        if (api.isLoading)
                          const Positioned.fill(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => _pickPhoto(setMenuState),
                      icon: const Icon(Icons.camera_alt, size: 18, color: Color(0xFF6C5CE7)),
                      label: Text(
                        AppLocalizations.of(context)!.changeProfilePhoto,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF6C5CE7)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: Colors.white10),
                  ],
                );
              },
            ),
            _buildMenuItem(Icons.person_outline, AppLocalizations.of(context)!.myProfile, () {
              Navigator.pushNamed(context, '/profile_edit').then((_) => _loadData());
            }),
            _buildMenuItem(Icons.star_outline, AppLocalizations.of(context)!.subscription, () {}),
            _buildMenuItem(Icons.settings_outlined, AppLocalizations.of(context)!.settings, () {}),
            _buildMenuItem(Icons.delete_forever, AppLocalizations.of(context)!.deleteAccount, () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF16162A),
                  title: Text(AppLocalizations.of(context)!.deleteAccountTitle, style: GoogleFonts.inter(color: Colors.white)),
                  content: Text(AppLocalizations.of(context)!.deleteAccountDesc, style: GoogleFonts.inter(color: Colors.white70)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.white54))),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Color(0xFFFD4556)))),
                  ],
                ),
              );
                if (confirm == true) {
                  if (!mounted) return;
                  final api = Provider.of<ApiService>(context, listen: false);
                  final r = await api.deleteAccount();
                  if (r['success'] == true && mounted) {
                    await api.logout();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(r['error'] ?? 'Erro ao excluir conta')),
                    );
                  }
                }
              }, color: const Color(0xFFFD4556)),
            _buildMenuItem(Icons.help_outline, AppLocalizations.of(context)!.help, () {}),
            _buildMenuItem(Icons.info_outline, AppLocalizations.of(context)!.aboutApp, () {
              showLicensePage(
                context: context,
                applicationName: 'ShapePro',
                applicationVersion: '1.0.1+11',
                applicationIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset('assets/icon.png', width: 44, height: 44),
                ),
              );
            }),
            _buildMenuItem(Icons.privacy_tip_outlined, AppLocalizations.of(context)!.privacyPolicy, () {
              Navigator.pushNamed(context, '/privacy');
            }),
            const SizedBox(height: 8),
            _buildMenuItem(Icons.logout, AppLocalizations.of(context)!.logout, () async {
              if (!mounted) return;
              final api = Provider.of<ApiService>(context, listen: false);
              await api.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            }, color: const Color(0xFFFD4556)),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white70),
      title: Text(label, style: GoogleFonts.inter(
        color: color ?? Colors.white, fontWeight: FontWeight.w500,
      )),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // ── Bottom Navigation ────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F24),
        border: Border(top: BorderSide(color: const Color(0xFF2A2A4A).withValues(alpha: 0.5))),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
        onTap: (i) {
          if (i == 0) {
            if (_currentIndex == 0) {
              Navigator.pushNamed(context, '/profile_edit').then((_) => _loadData());
            } else {
              setState(() => _currentIndex = 0);
            }
            return;
          }

          final api = Provider.of<ApiService>(context, listen: false);
          final user = api.currentUser;
          final isFree = user?['plano_assinatura'] == 'free';

          String route;
          switch (i) {
            case 1: route = '/treino'; break;
            case 2: route = '/dieta'; break;
            case 3: route = '/resultado'; break;
            default: route = '/home';
          }

          if ((route == '/treino' || route == '/dieta') && isFree) {
            Navigator.pushNamed(context, '/checkout').then((_) {
              if (mounted) setState(() => _currentIndex = 0);
            });
          } else {
            Navigator.pushNamed(context, route).then((_) {
              if (mounted) setState(() => _currentIndex = 0);
            });
          }
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: AppLocalizations.of(context)!.home),
          BottomNavigationBarItem(icon: const Icon(Icons.fitness_center_rounded), label: AppLocalizations.of(context)!.treino),
          BottomNavigationBarItem(icon: const Icon(Icons.restaurant_menu), label: AppLocalizations.of(context)!.dieta),
          BottomNavigationBarItem(icon: const Icon(Icons.bar_chart_rounded), label: AppLocalizations.of(context)!.resultado),
        ],
      ),
    );
  }

  Future<void> _pickPhoto(StateSetter setMenuState) async {
    Log.i('[_pickPhoto] Iniciando seletor de foto...');
    final l10n = AppLocalizations.of(context)!;
    final api = Provider.of<ApiService>(context, listen: false);
    
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF16162A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.white),
            title: Text(l10n.takePhoto, style: const TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.white),
            title: Text(l10n.chooseGallery, style: const TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          if (api.currentUser?['foto_perfil'] != null)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFFD4556)),
              title: Text(l10n.remvovePhoto, style: const TextStyle(color: Color(0xFFFD4556))),
              onTap: () async {
                Navigator.pop(ctx);
                await api.updateProfile({'foto_perfil': null});
                _loadData();
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );

    if (source != null) {
      final picker = ImagePicker();
      Log.i('[_pickPhoto] Abrindo seletor para fonte: $source');
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      ).catchError((e) {
        Log.e('[_pickPhoto] ERRO AO ABRIR PICKER: $e');
        return null;
      });

      if (pickedFile != null && mounted) {
        setMenuState(() {}); // Force loading indicator in menu
        final url = await api.uploadFotoPerfil(File(pickedFile.path));
        
        if (url != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.photoUpdated), backgroundColor: Colors.green),
          );
          _loadData();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorPhoto), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
