import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/api.dart';
import 'package:shapepro/l10n/app_localizations.dart';
import 'pose_validator.dart';
import 'overlay_guide.dart';
import '../../services/tts_service.dart';
import 'pose_metrics_helper.dart';

class CameraView extends StatefulWidget {
  final String poseType;
  final Function(XFile, Map<String, double>?, Pose?, Size?) onImageCaptured;

  const CameraView({
    super.key,
    required this.poseType,
    required this.onImageCaptured,
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller;
  PoseDetector? _poseDetector;
  bool _isBusy = false;
  List<String> _validationErrors = [];
  bool _isValid = false;
  Map<String, double>? _lastEstimatedMetrics;
  Pose? _lastPose;
  double _lastImageWidth = 1.0;
  double _lastImageHeight = 1.0;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  bool _isCapturing = false;
  int _alignmentPercentage = 0;
  final TtsService _tts = TtsService();
  String _userName = "";
  String _lastSpokenError = "";
  bool _isSpeakingCapture = false;
  bool _showContrastFlash = false;
  double _stabilityProgress = 0.0;
  DateTime? _stableStartTime;
  DateTime _lastVoiceTime = DateTime.now().subtract(const Duration(seconds: 5));
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_validationErrors.isEmpty) {
      _validationErrors = [AppLocalizations.of(context)!.startingCamera];
    }
  }
  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializePoseDetector();
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    await _tts.init();
    final api = Provider.of<ApiService>(context, listen: false);
    _userName = api.currentUser?['nome']?.split(' ').first ?? "";
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


    _controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      await _controller!.initialize();
      _controller!.startImageStream(_processImage);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  void _processImage(CameraImage image) async {
    if (_isBusy) return;
    _isBusy = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      final poses = await _poseDetector!.processImage(inputImage);
      
      if (poses.isNotEmpty && mounted) {
        final errors = PoseValidator.validate(
          poses.first, 
          widget.poseType, 
          image.width.toDouble(), 
          image.height.toDouble()
        );
        
        final alignmentScore = PoseValidator.calculateAlignmentScore(
          poses.first, 
          widget.poseType, 
          image.width.toDouble(), 
          image.height.toDouble()
        );
        
        setState(() {
          _validationErrors = errors;
          _isValid = errors.isEmpty;
          _lastPose = poses.first;
          _alignmentPercentage = alignmentScore.toInt();
          _lastImageWidth = image.width.toDouble();
          _lastImageHeight = image.height.toDouble();
        });

        _handleVoiceGuidance();
      } else if (mounted) {
        setState(() {
          _validationErrors = ["instructions"]; // Use instruction key
          _lastPose = null;
          _isValid = false;
          _alignmentPercentage = 0;
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


  Future<void> _setFlashMode(FlashMode mode) async {
    if (_controller == null) return;
    try {
      await _controller!.setFlashMode(mode);
      setState(() => _flashMode = mode);
    } catch (e) {
      debugPrint("Flash Error: $e");
    }
  }

  Future<void> _captureImage({bool isAuto = false}) async {
    if (_controller == null || (_isCapturing && !isAuto)) return;

    if (!_isValid && !isAuto) {
      if (_validationErrors.isEmpty) return; 
      
      // Provide helpful feedback why capture is blocked
      final errorMessage = _getLocalizedError(_validationErrors.first);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ajuste sua posição: $errorMessage"),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() => _isCapturing = true);

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final userHeight = api.currentUser?['altura']?.toDouble() ?? 170.0;
      final metrics = PoseMetricsHelper.calculateEstimatedMetrics(_lastPose, userHeight);
      
      // Flash effect (UI only)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Capturando... Mantenha a posição"),
            duration: Duration(milliseconds: 500),
            backgroundColor: Color(0xFF6C5CE7),
          ),
        );
      }

      try {
        await _controller!.stopImageStream();
        await Future.delayed(const Duration(milliseconds: 300)); // Increased safety delay
      } catch (e) {
        debugPrint("Error stopping stream: $e");
      }
      
      // Trigger Contrast Flash
      setState(() => _showContrastFlash = true);
      await Future.delayed(const Duration(milliseconds: 100));

      final file = await _controller!.takePicture();
      
      // Hide Flash
      setState(() => _showContrastFlash = false);
      
      // Final Thank You Voice
      final thankYou = _userName.isNotEmpty 
          ? "Já finalizamos sua foto, muito obrigado $_userName."
          : "Já finalizamos sua foto, muito obrigado.";
      await _tts.speak(thankYou);

      if (mounted) {
        Navigator.pop(context); // Close camera view and return to preview
        widget.onImageCaptured(
          file, 
          metrics, 
          _lastPose, 
          Size(_lastImageWidth, _lastImageHeight)
        );
      }
    } catch (e) {
      debugPrint("Capture Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro na captura: $e"), backgroundColor: Colors.red),
        );
        _controller!.startImageStream(_processImage);
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _handleVoiceGuidance() {
    if (_isSpeakingCapture) return;

    // 1. Auto-Capture Trigger (>70% alignment + Stability)
    if (_alignmentPercentage >= 70 && _isValid && !_isCapturing) {
      if (_stableStartTime == null) {
        _stableStartTime = DateTime.now();
      }
      
      final elapsedStable = DateTime.now().difference(_stableStartTime!).inMilliseconds;
      setState(() {
        _stabilityProgress = (elapsedStable / 1500).clamp(0.0, 1.0);
      });

      if (elapsedStable >= 1500) {
        _startAutoCapture();
      }
      return;
    } else {
      if (_stableStartTime != null) {
        setState(() {
          _stableStartTime = null;
          _stabilityProgress = 0.0;
        });
      }
    }

    // 2. Error Guidance (Don't spam, every 3 seconds)
    if (DateTime.now().difference(_lastVoiceTime).inSeconds > 3) {
      if (_validationErrors.isNotEmpty) {
        final error = _validationErrors.first;
        if (error != _lastSpokenError) {
          final message = _getVoiceMessage(error);
          _tts.speak(message);
          _lastSpokenError = error;
          _lastVoiceTime = DateTime.now();
        }
      }
    }
  }

  String _getVoiceMessage(String errorKey) {
    String prefix = _userName.isNotEmpty ? "$_userName, " : "";
    
    // Adicionar um toque de encorajamento se o alinhamento estiver subindo
    String suffix = "";
    if (_alignmentPercentage > 50) {
      suffix = " Você está quase lá, continue se ajustando.";
    }

    switch (errorKey) {
      case "moveRight": return "${prefix}mova só mais um pouco para a sua direita.$suffix";
      case "moveLeft": return "${prefix}mova só mais um pouco para a sua esquerda.$suffix";
      case "moveForward": return "${prefix}chegue um pouco mais para frente.$suffix";
      case "moveBack": return "${prefix}afaste-se só mais um pouco para trás.$suffix";
      case "stayStraight": return "${prefix}alinhe seu corpo, você está inclinado para os lados.";
      case "alignShoulders": return "${prefix}tente deixar seus ombros bem retos e nivelados.";
      case "rotateToCenter": return "${prefix}vire seu corpo um milímetro para o centro, você está um pouco de lado.";
      case "fullBodyNotDetected": return "${prefix}ainda não consigo ver seus pés ou cabeça. Afaste-se um pouco.";
      case "poseFront": return "${prefix}gire seu corpo para ficar totalmente de frente para mim.";
      case "poseSide": return "${prefix}fique de perfil, olhando para o lado.";
      default: return "";
    }
  }

  Future<void> _startAutoCapture() async {
    _isSpeakingCapture = true;
    _isCapturing = true; // Block manual clicks
    
    final message = _userName.isNotEmpty 
        ? "$_userName, mantenha-se parado, não se mova, vou tirar a foto agora."
        : "Mantenha-se parado, não se mova, vou tirar a foto agora.";
    
    await _tts.speak(message);
    
    // Wait for the voice to finish or at least a short buffer
    await Future.delayed(const Duration(milliseconds: 2800));
    
    if (mounted && _isValid && _alignmentPercentage >= 65) {
       await _captureImage(isAuto: true);
    } else {
      _isSpeakingCapture = false;
      _isCapturing = false;
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras.length < 2) return;

    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    
    await _controller?.dispose();
    if (mounted) {
      setState(() {
        _controller = null;
        _isValid = false;
        _validationErrors = [AppLocalizations.of(context)!.startingCamera];
        _lastPose = null;
      });
    }

    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _poseDetector?.close();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera Preview
        CameraPreview(_controller!),
        
        // Silhouette Overlay
        OverlayGuide(
          isValid: _isValid,
          poseType: widget.poseType,
          currentPose: _lastPose,
          realtimeMetrics: _lastEstimatedMetrics,
          alignmentPercentage: _alignmentPercentage,
          isFrontCamera: _cameras.isNotEmpty && _cameras[_cameraIndex].lensDirection == CameraLensDirection.front,
          imageSize: Size(_lastImageWidth, _lastImageHeight),
          isStabilizing: _stableStartTime != null,
          stabilityProgress: _stabilityProgress,
          statusMessage: _isValid 
            ? AppLocalizations.of(context)!.perfectCapture 
            : (_validationErrors.isNotEmpty ? _getLocalizedError(_validationErrors.first) : ""),
        ),

        // Central Spirit Level (Professional Aesthetic)
        if (_alignmentPercentage > 50)
          Center(
            child: Container(
              width: 250,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _isValid ? const Color(0xFF00FF88).withValues(alpha: 0.6) : Colors.redAccent.withValues(alpha: 0.4),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),

        // Distance Instruction Tip
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.straighten, color: Colors.cyanAccent, size: 16),
                  SizedBox(width: 8),
                  Text(
                    "Afaste-se ~1.5m para mais precisão",
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Capture Button (Only active if valid)
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _captureImage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: _isValid ? 1.0 : 0.3),
                  border: Border.all(
                    color: _isValid ? Colors.green : Colors.grey,
                    width: 4,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: _isValid ? Colors.black : Colors.black26,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        
        // Back Button
        Positioned(
          top: 40,
          left: 20,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // Flash Toggle
        Positioned(
          top: 40,
          left: MediaQuery.of(context).size.width / 2 - 24,
          child: IconButton(
            icon: Icon(
              _flashMode == FlashMode.off ? Icons.flash_off : 
              _flashMode == FlashMode.always ? Icons.flash_on : Icons.flash_auto, 
              color: Colors.white, 
              size: 24
            ),
            onPressed: () {
              if (_flashMode == FlashMode.off) {
                _setFlashMode(FlashMode.always);
              } else if (_flashMode == FlashMode.always) {
                _setFlashMode(FlashMode.auto);
              } else {
                _setFlashMode(FlashMode.off);
              }
            },
          ),
        ),

        // Flip Camera Button
        if (_cameras.length > 1)
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.flip_camera_android, color: Colors.white, size: 28),
              onPressed: _toggleCamera,
            ),
          ),
        
        // Stability Progress Bar (Professional AI look)
        if (_stabilityProgress > 0 && _stabilityProgress < 1.0)
          Positioned(
            bottom: 130,
            left: 60,
            right: 60,
            child: Column(
              children: [
                Text(
                  "ESTABILIZANDO...",
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _stabilityProgress,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),

        // Contrast Flash Overlay
        if (_showContrastFlash)
          Positioned.fill(
            child: Container(
              color: Colors.white,
            ),
          ),
      ],
    );
  }
  String _getLocalizedError(String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case "fullBodyNotDetected": return l10n.fullBodyNotDetected;
      case "centerYourBody": return l10n.centerYourBody;
      case "stayStraight": return l10n.stayStraight;
      case "invalidDistance": return l10n.invalidDistance;
      case "poseFront": return l10n.poseFront;
      case "poseSide": return l10n.poseSide;
      case "poseBack": return l10n.poseBack;
      case "noBodyDetected": return l10n.noBodyDetected;
      case "instructions": return "Fique reto, corpo inteiro visível, boa iluminação";
      case "startingCamera": return l10n.startingCamera;
      default: return key;
    }
  }

}
