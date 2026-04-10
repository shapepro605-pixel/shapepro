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
            Text('Nova Versão!', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Uma atualização importante para o ShapePro já está disponível. Melhore sua experiência!', 
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 10),
            if (isMandatory)
              Text('Esta atualização é obrigatória para continuar usando o app.', 
                style: GoogleFonts.inter(color: const Color(0xFFFD4556), fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          if (!isMandatory)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('DEPOIS', style: TextStyle(color: Colors.white54)),
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
            child: const Text('ATUALIZAR AGORA'),
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
            const SnackBar(content: Text('Permissão de notificação negada.')),
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
    
    // Check if phone is verified
    if (api.currentUser != null && api.currentUser!['telefone_verificado'] == false) {
       if (mounted) {
         Navigator.pushReplacementNamed(context, '/verify_sms'); 
         return;
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
    final user = _progresso?['usuario'] ?? {};
    final nome = user['nome'] ?? 'Atleta';
    final imc = _progresso?['imc'];
    final classificacao = _progresso?['classificacao_imc'] ?? '';

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
                      ],
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _showProfileMenu,
                      child: Hero(
                        tag: 'avatar',
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C5CE7), Color(0xFF00D2FF)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF6C5CE7).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              nome.isNotEmpty ? nome[0].toUpperCase() : AppLocalizations.of(context)!.atleta[0].toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white,
                              ),
                            ),
                          ),
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
                              '${AppLocalizations.of(context)!.peso}: ${user['peso'] ?? '--'} kg  •  ${AppLocalizations.of(context)!.altura}: ${user['altura'] ?? '--'} cm',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms).moveY(begin: 20, end: 0, curve: Curves.easeOutQuad),
                const SizedBox(height: 22),

                // ── Quick Actions ───────────────────────────────
                Row(
                  children: [
                    _buildQuickAction('Treino', Icons.fitness_center_rounded, const Color(0xFF00D2FF), () {
                      final isFree = _progresso?['usuario']?['plano_assinatura'] == 'free';
                      if (isFree) {
                        Navigator.pushNamed(context, '/checkout');
                      } else {
                        Navigator.pushNamed(context, '/treino');
                      }
                    }),
                    const SizedBox(width: 14),
                    _buildQuickAction('Dieta', Icons.restaurant_menu, const Color(0xFF6C5CE7), () {
                      final isFree = _progresso?['usuario']?['plano_assinatura'] == 'free';
                      if (isFree) {
                        Navigator.pushNamed(context, '/checkout');
                      } else {
                        Navigator.pushNamed(context, '/dieta');
                      }
                    }),
                    _buildQuickAction('Campeonatos', Icons.emoji_events_rounded, const Color(0xFFFFD93D), () {
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
                Text('Evolução do peso', style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700, 
                  color: Provider.of<ApiService>(context).isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                )),
                const SizedBox(height: 16),
                _buildWeightChart(),
                const SizedBox(height: 28),

                // ── Diet Summary ────────────────────────────────
                if (_progresso?['dieta_ativa'] != null) ...[
                  Text('Dieta ativa', style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
                  )),
                  const SizedBox(height: 16),
                  _buildDietaSummaryCard(),
                  const SizedBox(height: 28),
                ],

                // ── Training Days ───────────────────────────────
                Text('Treinos da semana', style: GoogleFonts.inter(
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
              Text(label, style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70,
              )),
            ],
          ),
        ),
      ),
    );
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
              Text('Registre seu peso para ver o gráfico', style: GoogleFonts.inter(
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
    final days = [
      {'tipo': 'A', 'nome': 'Peito e Tríceps', 'icon': Icons.fitness_center},
      {'tipo': 'B', 'nome': 'Costas e Bíceps', 'icon': Icons.fitness_center},
      {'tipo': 'C', 'nome': 'Pernas e Glúteos', 'icon': Icons.directions_run},
      {'tipo': 'D', 'nome': 'Ombros e Abdômen', 'icon': Icons.accessibility_new},
      {'tipo': 'E', 'nome': 'Full Body', 'icon': Icons.sports_gymnastics},
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
          return GestureDetector(
            onTap: () {
              final isFree = _progresso?['usuario']?['plano_assinatura'] == 'free';
              if (isFree) {
                Navigator.pushNamed(context, '/checkout');
              } else {
                Navigator.pushNamed(context, '/treino');
              }
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
            _buildMenuItem(Icons.person_outline, 'Meu perfil', () {
              Navigator.pushNamed(context, '/profile_edit').then((_) => _loadData());
            }),
            _buildMenuItem(Icons.star_outline, 'Assinatura', () {}),
            _buildMenuItem(Icons.settings_outlined, 'Configurações', () {}),
            _buildMenuItem(Icons.delete_forever, 'Excluir Conta', () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF16162A),
                  title: Text('Excluir Conta?', style: GoogleFonts.inter(color: Colors.white)),
                  content: Text('Isso apagará permanentemente todos os seus dados. Deseja continuar?', style: GoogleFonts.inter(color: Colors.white70)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir', style: TextStyle(color: Color(0xFFFD4556)))),
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
            _buildMenuItem(Icons.help_outline, 'Ajuda', () {}),
            _buildMenuItem(Icons.info_outline, 'Sobre o App', () {
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
            _buildMenuItem(Icons.privacy_tip_outlined, 'Política de Privacidade', () {
              Navigator.pushNamed(context, '/privacy');
            }),
            const SizedBox(height: 8),
            _buildMenuItem(Icons.logout, 'Sair', () async {
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center_rounded), label: 'Treino'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Dieta'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Resultado'),
        ],
      ),
    );
  }
}
