import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api.dart';
import 'package:shapepro/l10n/app_localizations.dart';
import 'challenge_active.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _allChallenges = [];
  List<dynamic> _activeChallengeIds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    
    final results = await Future.wait([
      api.getChallenges(),
      api.getActiveChallenges(),
    ]);

    if (mounted) {
      setState(() {
        if (results[0]['success'] == true) {
          _allChallenges = results[0]['challenges'];
        }
        if (results[1]['success'] == true) {
          _activeChallengeIds = (results[1]['challenges'] as List)
              .map((c) => c['challenge_id'])
              .toList();
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final api = Provider.of<ApiService>(context);
    final isPremium = api.currentUser?['plano_assinatura'] != 'free';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.championshipsTitle),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: [
            Tab(text: l10n.daily),
            Tab(text: l10n.weekly),
            Tab(text: l10n.monthly),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildChallengeList('diario', isPremium),
                _buildChallengeList('semanal', isPremium),
                _buildChallengeList('mensal', isPremium),
              ],
            ),
    );
  }

  Widget _buildChallengeList(String type, bool isPremium) {
    final filtered = _allChallenges.where((c) => c['tipo'] == type).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          "Nenhum campeonato disponível",
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final challenge = filtered[index];
        final isActive = _activeChallengeIds.contains(challenge['id']);

        return _buildChallengeCard(challenge, isPremium, isActive);
      },
    );
  }

  Widget _buildChallengeCard(dynamic challenge, bool isPremium, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFF00D2FF) : const Color(0xFF2A2A4A),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: const Color(0xFF00D2FF).withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 2,
          )
        ] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E38),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        challenge['icone'] ?? '🏆',
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge['nome'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          challenge['descricao'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              color: const Color(0xFF1E1E38).withValues(alpha: 0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bolt, color: Color(0xFFFFD93D), size: 20),
                      const SizedBox(width: 5),
                      Text(
                        "${challenge['pontos_xp']} XP",
                        style: const TextStyle(
                          color: Color(0xFFFFD93D),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (isActive)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChallengeActiveScreen(challenge: challenge),
                          ),
                        );
                      },
                      icon: const Icon(Icons.flash_on_rounded, size: 16),
                      label: const Text("INICIAR", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D2FF),
                        foregroundColor: Colors.white,
                        elevation: 10,
                        shadowColor: const Color(0xFF00D2FF).withValues(alpha: 0.5),
                        minimumSize: const Size(100, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  else if (!isPremium)
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/checkout'),
                      icon: const Icon(Icons.lock_rounded, size: 16),
                      label: const Text("PREMIUM"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1035),
                        foregroundColor: const Color(0xFF6C5CE7),
                        minimumSize: const Size(100, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => _joinChallenge(challenge['id']),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(100, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text("PARTICIPAR"),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinChallenge(int id) async {
    final api = Provider.of<ApiService>(context, listen: false);
    final result = await api.joinChallenge(id);

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Inscrito com sucesso!"),
            backgroundColor: const Color(0xFF6C5CE7),
          ),
        );
        _loadData(); // Refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? "Erro ao entrar no campeonato"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
