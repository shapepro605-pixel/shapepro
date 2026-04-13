import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api.dart';
import 'package:shapepro/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import 'camera_view.dart';
import 'body_scan_service.dart';

class BodyScanPage extends StatefulWidget {
  const BodyScanPage({super.key});

  @override
  State<BodyScanPage> createState() => _BodyScanPageState();
}

class _BodyScanPageState extends State<BodyScanPage> {
  String _selectedPose = 'front';
  XFile? _capturedImage;
  bool _isUploading = false;
  Map<String, double>? _metrics;
  late BodyScanService _scanService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scanService = BodyScanService(Provider.of<ApiService>(context, listen: false));
  }

  void _onImageCaptured(XFile file, Map<String, double>? metrics) {
    setState(() {
      _capturedImage = file;
      _metrics = metrics;
    });
  }

  Future<void> _processCapture() async {
    if (_capturedImage == null) return;

    setState(() => _isUploading = true);

    final result = await _scanService.uploadScan(
      imageFile: File(_capturedImage!.path),
      type: _selectedPose,
      metrics: _metrics,
    );

    if (mounted) {
      setState(() => _isUploading = false);
      if (result['success']) {
        // Schedule reminder for 30 days
        NotificationService.scheduleComparisonReminder();
        _showSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Erro no upload')),
        );
      }
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16162A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Text(
          AppLocalizations.of(context)!.photoSentSuccess,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: Colors.white),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              setState(() {
                _capturedImage = null; // Prepare for next
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
            child: Text(AppLocalizations.of(context)!.takeAnother),
          ),
          TextButton(
            onPressed: () {
               Navigator.pop(context); // Close dialog
               Navigator.pop(context); // Return home
            },
            child: Text(AppLocalizations.of(context)!.finish, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: _capturedImage == null ? AppBar(
        title: Text("Body Scan", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        elevation: 0,
      ) : null,
      body: _capturedImage == null ? _buildSelection() : _buildPreview(),
    );
  }

  Widget _buildSelection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.evolutionAnalysis,
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.selectPoseType,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
          ),
          const SizedBox(height: 32),
          _buildPoseCard(AppLocalizations.of(context)!.front, "front", Icons.person_outline),
          const SizedBox(height: 16),
          _buildPoseCard(AppLocalizations.of(context)!.side, "side", Icons.hail),
          const SizedBox(height: 16),
          _buildPoseCard(AppLocalizations.of(context)!.back, "back", Icons.person_off_outlined),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CameraView(
                    poseType: _selectedPose,
                    onImageCaptured: _onImageCaptured,
                  ),
                ),
              );
            },
            child: Text(AppLocalizations.of(context)!.open),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPoseCard(String label, String type, IconData icon) {
    bool isSelected = _selectedPose == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedPose = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C5CE7).withValues(alpha: 0.1) : const Color(0xFF16162A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C5CE7) : const Color(0xFF2A2A4A),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF6C5CE7) : Colors.white38, size: 28),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF6C5CE7)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent, Colors.black87],
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildResultsCard(),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(32),
              child: _isUploading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _processCapture,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: Text(AppLocalizations.of(context)!.sendPhoto),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => setState(() => _capturedImage = null),
                        child: Text(AppLocalizations.of(context)!.takeAnother, style: const TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultsCard() {
    final api = Provider.of<ApiService>(context, listen: false);
    final user = api.currentUser;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16162A).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Body Scan Report", style: GoogleFonts.inter(
                    color: const Color(0xFF6C5CE7), fontWeight: FontWeight.w800, fontSize: 18,
                  )),
                  const Icon(Icons.analytics_outlined, color: Color(0xFF6C5CE7), size: 24),
                ],
              ),
              const SizedBox(height: 4),
              Text(dateStr, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
              const Divider(height: 32, color: Colors.white10),
              
              // Measurements
              _buildResultRow("Peito (Estimado)", "${_metrics!['chest']?.toStringAsFixed(1)} cm"),
              const SizedBox(height: 12),
              _buildResultRow("Cintura (Estimada)", "${_metrics!['waist']?.toStringAsFixed(1)} cm"),
              const SizedBox(height: 12),
              _buildResultRow("Quadril (Estimado)", "${_metrics!['hips']?.toStringAsFixed(1)} cm"),
              
              const Divider(height: 32, color: Colors.white10),
              
              // User info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniInfo("Idade", "${user!['idade'] ?? '--'}y"),
                  _buildMiniInfo("Altura", "${user['altura'] ?? '--'}cm"),
                  _buildMiniInfo("Peso", "${user['peso'] ?? '--'}kg"),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "* Valores estimados via IA baseados na pose e altura.",
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
        Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildMiniInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
        Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
