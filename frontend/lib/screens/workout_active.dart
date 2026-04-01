import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shapepro/l10n/app_localizations.dart';
import '../services/api.dart';
import '../widgets/upgrade_sheet.dart';

class WorkoutActiveScreen extends StatefulWidget {
  final Map<String, dynamic> treino;
  final Color accentColor;

  const WorkoutActiveScreen({
    super.key,
    required this.treino,
    required this.accentColor,
  });

  @override
  State<WorkoutActiveScreen> createState() => _WorkoutActiveScreenState();
}

class _WorkoutActiveScreenState extends State<WorkoutActiveScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isResting = false;
  int _restSecondsLeft = 0;
  Timer? _restTimer;
  bool _isCompleting = false;
  bool _isTrial = false;

  List<dynamic> get exercicios => widget.treino['exercicios'] as List<dynamic>? ?? [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _isTrial = Provider.of<ApiService>(context, listen: false).currentUser?['is_trial'] ?? false;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cancelTimer();
    super.dispose();
  }

  void _startRest() {
    _cancelTimer();
    setState(() {
      _isResting = true;
      _restSecondsLeft = 60; // Fixed 60s for simplicity
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsLeft > 0) {
        setState(() => _restSecondsLeft--);
      } else {
        _endRest();
      }
    });
  }

  void _endRest() {
    _cancelTimer();
    setState(() => _isResting = false);
  }

  void _cancelTimer() {
    _restTimer?.cancel();
    _restTimer = null;
  }

  void _nextExercise() {
    _endRest();
    if (_isTrial) {
      showUpgradeSheet(context);
      return;
    }
    if (_currentIndex < exercicios.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _previousExercise() {
    _endRest();
    if (_currentIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _concluirTreino() async {
    setState(() => _isCompleting = true);
    final api = Provider.of<ApiService>(context, listen: false);
    await api.concluirTreino();
    
    if (!mounted) return;
    Navigator.pop(context); // close workout
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context)!.workoutFinished),
      backgroundColor: const Color(0xFF2ED573),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (exercicios.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A1A),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(child: Text(AppLocalizations.of(context)!.noExercisesFound)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgress(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemCount: exercicios.length,
                itemBuilder: (context, index) {
                  return _buildExerciseView(exercicios[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // Ask for confirmation
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E38),
                  title: Text(AppLocalizations.of(context)!.cancelWorkout, style: GoogleFonts.inter(color: Colors.white)),
                  content: Text(AppLocalizations.of(context)!.progressLost, style: GoogleFonts.inter(color: Colors.white70)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c), child: Text(AppLocalizations.of(context)!.continueBtn)),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(c);
                        Navigator.pop(context);
                      },
                      child: Text(AppLocalizations.of(context)!.exit, style: const TextStyle(color: Color(0xFFFD4556))),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E38),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, color: Colors.white70, size: 18),
            ),
          ),
          const Spacer(),
          Text(widget.treino['nome'] ?? AppLocalizations.of(context)!.treino, style: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
          )),
          const Spacer(),
          const SizedBox(width: 40), // Balance app bar
        ],
      ),
    );
  }

  Widget _buildProgress() {
    final progress = (_currentIndex + 1) / exercicios.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      child: Row(
        children: [
          Text('${_currentIndex + 1}/${exercicios.length}', style: GoogleFonts.inter(
            color: widget.accentColor, fontWeight: FontWeight.w800, fontSize: 13,
          )),
          const SizedBox(width: 14),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFF1E1E38),
                valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
                minHeight: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseView(Map<String, dynamic> ex, int index) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual Image Placeholder
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFF16162A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2A2A4A)),
            ),
            child: Icon(Icons.fitness_center, color: widget.accentColor.withValues(alpha: 0.3), size: 100),
          ),
          const SizedBox(height: 30),
          
          Text(ex['nome'] ?? AppLocalizations.of(context)!.exercise, style: GoogleFonts.inter(
            fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white,
          )),
          const SizedBox(height: 14),

          // Tags
          Row(
            children: [
              _buildTag(AppLocalizations.of(context)!.series(ex['series']?.toString() ?? '0'), Icons.repeat),
              const SizedBox(width: 10),
              _buildTag(AppLocalizations.of(context)!.reps(ex['repeticoes']?.toString() ?? '0'), Icons.sync),
              const SizedBox(width: 10),
              _buildTag(ex['descanso'] ?? '90s', Icons.timer),
            ],
          ),
          const SizedBox(height: 24),

          // Tips / Desc
          if (ex['dicas'] != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.1),
                border: Border.all(color: widget.accentColor.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, color: widget.accentColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(ex['dicas'], style: GoogleFonts.inter(
                      color: Colors.white70, fontSize: 13, height: 1.4,
                    )),
                  ),
                ],
              ),
            ),

          const Spacer(),

          // Active Area (Rest Timer or Next button)
          if (_isResting)
            _buildRestArea()
          else
            _buildControls(index),
        ],
      ),
    );
  }

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E38),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white54),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.inter(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12,
          )),
        ],
      ),
    );
  }

  Widget _buildRestArea() {
    return Column(
      children: [
        Text(AppLocalizations.of(context)!.rest, style: GoogleFonts.inter(
          color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: 8),
        Text('00:${_restSecondsLeft.toString().padLeft(2, '0')}', style: GoogleFonts.inter(
          color: widget.accentColor, fontSize: 44, fontWeight: FontWeight.w900,
        )),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() => _restSecondsLeft += 15);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('+15s', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _nextExercise,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(AppLocalizations.of(context)!.skip, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControls(int index) {
    final isLast = index == exercicios.length - 1;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (index > 0)
              IconButton(
                onPressed: _previousExercise,
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white54),
                iconSize: 22,
              ),
            const Spacer(),
            if (!isLast)
              ElevatedButton.icon(
                onPressed: _startRest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.check, color: Colors.white),
                label: Text(AppLocalizations.of(context)!.seriesDone, style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800,
                )),
              )
            else
              ElevatedButton.icon(
                onPressed: _isCompleting ? null : _concluirTreino,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ED573), // green for finish
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isCompleting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Icon(Icons.flag, color: Colors.white),
                label: Text(AppLocalizations.of(context)!.finishWorkout, style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800,
                )),
              ),
            const Spacer(),
            if (!isLast)
              IconButton(
                onPressed: _nextExercise,
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
                iconSize: 22,
              ),
          ],
        ),
      ],
    );
  }
}
