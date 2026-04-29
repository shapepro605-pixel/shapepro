import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../services/api.dart';
import 'rep_counter_helper.dart';
import 'smart_workout_painter.dart';
import 'package:shapepro/l10n/app_localizations.dart';

class SmartWorkoutView extends StatefulWidget {
  const SmartWorkoutView({super.key});

  @override
  State<SmartWorkoutView> createState() => _SmartWorkoutViewState();
}

class _SmartWorkoutViewState extends State<SmartWorkoutView> {
  CameraController? _controller;
  PoseDetector? _poseDetector;
  bool _isBusy = false;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 1; // Default to front camera for workouts
  
  Pose? _lastPose;
  double _lastImageWidth = 1.0;
  double _lastImageHeight = 1.0;
  
  final RepCounterHelper _repCounter = RepCounterHelper();
  bool _isPremiumLocked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPremiumAccess();
  }

  Future<void> _checkPremiumAccess() async {
    final api = Provider.of<ApiService>(context, listen: false);
    await api.init();
    final user = api.currentUser;
    
    if (user != null) {
      final isInTrial = user['is_trial'] ?? false;
      final isPremium = user['plano_assinatura'] != 'free';
      if (!isInTrial && !isPremium) {
        _isPremiumLocked = true;
      }
    }
    
    setState(() => _isLoading = false);
    
    if (!_isPremiumLocked) {
      _initializeCamera();
      _initializePoseDetector();
    }
  }

  void _initializePoseDetector() {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    );
    _poseDetector = PoseDetector(options: options);
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    // Try to find front camera
    for (int i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == CameraLensDirection.front) {
        _cameraIndex = i;
        break;
      }
    }

    _startCamera();
  }
  
  Future<void> _startCamera() async {
    if (_controller != null) {
      await _controller!.dispose();
    }
    
    _controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.medium, // Medium is better for fast ML processing
      enableAudio: false,
      imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
    );

    try {
      await _controller!.initialize();
      _controller!.startImageStream(_processImage);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  void _switchCamera() {
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    _startCamera();
  }

  void _processImage(CameraImage image) async {
    if (_isBusy) return;
    _isBusy = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      final poses = await _poseDetector!.processImage(inputImage);
      
      if (poses.isNotEmpty && mounted) {
        final pose = poses.first;
        
        // Count reps
        _repCounter.processSquat(pose);
        
        setState(() {
          _lastPose = pose;
          _lastImageWidth = image.width.toDouble();
          _lastImageHeight = image.height.toDouble();
        });
      } else if (mounted) {
        setState(() {
          _lastPose = null;
        });
      }
    } catch (e) {
      debugPrint("Processing Error: $e");
    } finally {
      _isBusy = false;
    }
  }

  InputImage _inputImageFromCameraImage(CameraImage image) {
    final sensorOrientation = _controller!.description.sensorOrientation;
    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;
    final format = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A1A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00D2FF))),
      );
    }

    if (_isPremiumLocked) {
      return _buildLockedView();
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A1A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00D2FF))),
      );
    }

    final size = MediaQuery.of(context).size;
    final scale = size.aspectRatio * _controller!.value.aspectRatio;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera feed
          Transform.scale(
            scale: scale < 1 ? 1 / scale : scale,
            child: Center(
              child: CameraPreview(_controller!),
            ),
          ),
          
          // Dark overlay for better neon visibility
          Container(
            color: Colors.black.withValues(alpha: 0.3),
          ),

          // ML Pose Painter (Neon Lines)
          if (_lastPose != null)
            CustomPaint(
              painter: SmartWorkoutPainter(
                _lastPose!,
                Size(_lastImageWidth, _lastImageHeight),
                InputImageRotationValue.fromRawValue(_controller!.description.sensorOrientation) ?? InputImageRotation.rotation0deg,
                _controller!.description.lensDirection,
              ),
            ),
            
          // UI Elements
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D2FF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF00D2FF)),
                        ),
                        child: Text(
                          "AGACHAMENTO",
                          style: GoogleFonts.inter(color: const Color(0xFF00D2FF), fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                        onPressed: _switchCamera,
                      ),
                    ],
                  ),
                ),
                
                // Rep Counter Giant Display
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.5),
                    border: Border.all(color: _repCounter.currentState == WorkoutState.down ? const Color(0xFF2ED573) : const Color(0xFF00D2FF), width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: (_repCounter.currentState == WorkoutState.down ? const Color(0xFF2ED573) : const Color(0xFF00D2FF)).withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _repCounter.repCount.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 80,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        "REPS",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bottom Instructions
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _lastPose == null 
                        ? "Posicione o celular no chão" 
                        : (_repCounter.currentState == WorkoutState.down ? "SUBA!" : "DESÇA"),
                      style: GoogleFonts.inter(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        color: _lastPose == null ? Colors.white70 : Colors.white
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedView() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    )
                  ],
                ),
                child: const Icon(Icons.lock_outline_rounded, size: 64, color: Colors.white),
              ),
              const SizedBox(height: 40),
              Text(
                "Treino com IA Premium",
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                "Sua câmera pode contar suas repetições usando Inteligência Artificial. Assine o ShapePro Premium para desbloquear o Treinador Virtual.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/checkout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black87,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text("DESBLOQUEAR PREMIUM", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
