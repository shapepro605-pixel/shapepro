import 'dart:io';
import 'dart:ui';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api.dart';
import 'package:shapepro/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import 'camera_view.dart';
import 'body_scan_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'pose_metrics_helper.dart';
import 'body_scan_history_page.dart';

import 'neon_pose_painter.dart';

class BodyScanPage extends StatefulWidget {
  const BodyScanPage({super.key});

  @override
  State<BodyScanPage> createState() => _BodyScanPageState();
}

class _BodyScanPageState extends State<BodyScanPage> with SingleTickerProviderStateMixin {
  late AnimationController _neonAnimController;

  String _selectedPose = 'front';
  XFile? _frontImage;
  Pose? _frontPose;
  Size? _frontImageSize;
  
  XFile? _sideImage;
  Pose? _sidePose;
  Size? _sideImageSize;
  
  // Static holders to survive Activity recreations during ImagePicker/Camera
  static Pose? _staticFrontPose;
  static Size? _staticFrontSize;
  static Pose? _staticSidePose;
  static Size? _staticSideSize;

  XFile? _capturedImage; // Temporary preview
  bool _isUploading = false;
  Map<String, double>? _metrics;
  late BodyScanService _scanService;
  bool _isEvolutionMode = false;
  int _daysSinceLastScan = 0;

  @override
  void initState() {
    super.initState();
    _neonAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  }

  @override
  void dispose() {
    _neonAnimController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scanService = BodyScanService(Provider.of<ApiService>(context, listen: false));
    _checkEvolutionStatus();
  }

  Future<void> _checkEvolutionStatus() async {
    final history = await _scanService.getHistory();
    if (history.isNotEmpty) {
      final latest = DateTime.parse(history.first['created_at']);
      final diff = DateTime.now().difference(latest).inDays;
      if (mounted) {
        setState(() {
          _daysSinceLastScan = diff;
          _isEvolutionMode = diff >= 30;
        });
      }
    }
  }

  void _onImageCaptured(XFile file, Map<String, double>? metrics, [Pose? pose, Size? size]) {
    log(">>> AI SCAN UI: onImageCaptured called. Pose: $_selectedPose. Pose is null? ${pose == null}");
    setState(() {
      if (_selectedPose == 'front') {
        _frontImage = file;
        _frontPose = pose;
        _frontImageSize = size;
        _staticFrontPose = pose;
        _staticFrontSize = size;
      } else if (_selectedPose == 'side') {
        _sideImage = file;
        _sidePose = pose;
        _sideImageSize = size;
        _staticSidePose = pose;
        _staticSideSize = size;
      }
      
      // Restore from static if local state was lost
      _frontPose ??= _staticFrontPose;
      _frontImageSize ??= _staticFrontSize;
      _sidePose ??= _staticSidePose;
      _sideImageSize ??= _staticSideSize;

      // Automatic calculation if both are present
      log(">>> AI SCAN UI: frontPose exists? ${_frontPose != null}, sidePose exists? ${_sidePose != null}");
      if (_frontPose != null && _sidePose != null) {
        log(">>> AI SCAN UI: Calculating professional metrics");
        final api = Provider.of<ApiService>(context, listen: false);
        final userHeight = api.currentUser?['altura']?.toDouble() ?? 170.0;
        _metrics = PoseMetricsHelper.calculateProfessionalMetrics(
          frontPose: _frontPose!,
          frontSize: _frontImageSize!,
          sidePose: _sidePose!,
          sideSize: _sideImageSize!,
          userHeight: userHeight,
        );
      } else {
        // Fallback or partial metrics if only one is available (optional)
        log(">>> AI SCAN UI: Missing one of the poses. Falling back to single-pose metrics.");
        _metrics = metrics;
      }
      log(">>> AI SCAN UI: Assigned metrics: $_metrics");
      
      _capturedImage = file;
      if (_selectedPose == 'front' && _frontPose != null) {
        _neonAnimController.forward(from: 0.0);
      }
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
          SnackBar(content: Text(AppLocalizations.of(context)!.uploadError(result['error'] ?? 'Network Error'))),
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
        title: Text(AppLocalizations.of(context)!.bodyScannerTitle, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF6C5CE7)),
            onPressed: _showTutorial,
          ),
        ],
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
          if (_isEvolutionMode) _buildEvolutionBanner(),
          const SizedBox(height: 16),
          Text(
            _isEvolutionMode ? "CHECK-IN DE EVOLUÇÃO" : AppLocalizations.of(context)!.evolutionAnalysis,
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.selectPoseType,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
          ),
          const SizedBox(height: 32),
          _buildPoseCard(AppLocalizations.of(context)!.front, "front", Icons.person_outline, _frontPose != null),
          const SizedBox(height: 16),
          _buildPoseCard(AppLocalizations.of(context)!.side, "side", Icons.hail, _sidePose != null),
          const SizedBox(height: 24),
          
          // History Button
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BodyScanHistoryPage()),
                );
              },
              icon: const Icon(Icons.history, color: Color(0xFF6C5CE7)),
              label: Text(
                AppLocalizations.of(context)!.viewEvolutionHistory,
                style: GoogleFonts.inter(
                  color: const Color(0xFF6C5CE7),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
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
                  icon: const Icon(Icons.camera_alt),
                  label: Text(AppLocalizations.of(context)!.camera),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: Text(AppLocalizations.of(context)!.gallery),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A4A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEvolutionBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2ED573), Color(0xFF1ABC9C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2ED573).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "HORA DE VER RESULTADOS!",
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                ),
                Text(
                  "Já faz $_daysSinceLastScan dias desde seu último scan. Vamos ver como você evoluiu?",
                  style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTutorial() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF16162A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(AppLocalizations.of(context)!.howItWorks, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.scannerTutorialSubtitle, 
              textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 20),
            Expanded(
              child: PageView(
                children: [
                  _buildTutorialPage("assets/images/bodyscan_front.png", AppLocalizations.of(context)!.front, AppLocalizations.of(context)!.frontDesc),
                  _buildTutorialPage("assets/images/bodyscan_side.png", AppLocalizations.of(context)!.side, AppLocalizations.of(context)!.sideDesc),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: Text(AppLocalizations.of(context)!.understood.toUpperCase()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialPage(String imagePath, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 20),
          Text(title, style: GoogleFonts.inter(fontSize: 18, color: const Color(0xFF6C5CE7), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(desc, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null || !mounted) return;

    // Show loading
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
    );

    try {
      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final options = PoseDetectorOptions(mode: PoseDetectionMode.single);
      final poseDetector = PoseDetector(options: options);
      
      final poses = await poseDetector.processImage(inputImage);
      poseDetector.close();

      final api = Provider.of<ApiService>(context, listen: false);
      final userHeight = api.currentUser?['altura']?.toDouble() ?? 170.0;
      final metrics = PoseMetricsHelper.calculateEstimatedMetrics(poses.first, userHeight);

      // Get image dimensions
      final data = await pickedFile.readAsBytes();
      final image = await decodeImageFromList(data);
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());

      if (mounted) {
        Navigator.pop(context); // Close loading
        _onImageCaptured(
          XFile(pickedFile.path), 
          metrics, 
          poses.first,
          imageSize,
        );
      }
    } catch (e) {
      if (mounted) {
         Navigator.pop(context); // Close loading
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildPoseCard(String label, String type, IconData icon, bool isCompleted) {
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
            color: isSelected ? const Color(0xFF6C5CE7) : (isCompleted ? Colors.green.withOpacity(0.5) : const Color(0xFF2A2A4A)),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF6C5CE7) : (isCompleted ? Colors.green : Colors.white38), size: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.white60,
                  ),
                ),
                if (isCompleted) 
                  Text("Foto capturada", style: GoogleFonts.inter(fontSize: 10, color: Colors.green)),
              ],
            ),
            const Spacer(),
            if (isCompleted) const Icon(Icons.check_circle, color: Colors.green)
            else if (isSelected) const Icon(Icons.circle_outlined, color: Color(0xFF6C5CE7)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Blur leve no fundo para não poluir visualmente
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                  child: Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
                ),
                if (_selectedPose == 'front' && _frontPose != null)
                  AnimatedBuilder(
                    animation: _neonAnimController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: NeonPosePainter(
                          pose: _frontPose,
                          imageSize: _frontImageSize!,
                          metrics: _metrics,
                          animationProgress: _neonAnimController.value,
                        ),
                      );
                    },
                  )
                else if (_selectedPose == 'side' && _sidePose != null)
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: NeonPosePainter(
                      pose: _sidePose,
                      imageSize: _sideImageSize!,
                      metrics: _metrics,
                    ),
                  ),
              ],
            );
          }
        ),
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

  String _formatMeasure(double? value) {
    if (value == null) return "--";
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    if (isEnglish) {
      final inches = value / 2.54;
      return "${inches.toStringAsFixed(1)} in";
    }
    return "${value.toStringAsFixed(1)} cm";
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
                  Text(AppLocalizations.of(context)!.scannerReport, style: GoogleFonts.inter(
                    color: const Color(0xFF6C5CE7), fontWeight: FontWeight.w800, fontSize: 18,
                  )),
                  const Icon(Icons.analytics_outlined, color: Color(0xFF6C5CE7), size: 24),
                ],
              ),
              const SizedBox(height: 4),
              Text(dateStr, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
              const Divider(height: 32, color: Colors.white10),
              
              // Measurements
              _buildResultRow(AppLocalizations.of(context)!.chestEstimated, _formatMeasure(_metrics!['chest'])),
              const SizedBox(height: 12),
              if (_metrics!.containsKey('shoulders')) ...[
                _buildResultRow("Ombro", _formatMeasure(_metrics!['shoulders'])),
                const SizedBox(height: 12),
              ],
              _buildResultRow(AppLocalizations.of(context)!.waistEstimated, _formatMeasure(_metrics!['waist'])),
              const SizedBox(height: 12),
              _buildResultRow(AppLocalizations.of(context)!.hipsEstimated, _formatMeasure(_metrics!['hips'])),
              
              const Divider(height: 32, color: Colors.white10),
              
              // User info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniInfo(AppLocalizations.of(context)!.age, "${user!['idade'] ?? '--'}y"),
                  _buildMiniInfo(AppLocalizations.of(context)!.height, "${user['altura'] ?? '--'}cm"),
                  _buildMiniInfo(AppLocalizations.of(context)!.currentWeight, "${user['peso'] ?? '--'}kg"),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "Precisão estimada: 85% (Frente + Lado)",
                    style: GoogleFonts.inter(color: Colors.green.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.estimatedIAValues,
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
