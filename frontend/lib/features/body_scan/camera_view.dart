import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:provider/provider.dart';
import '../../services/api.dart';
import 'package:shapepro/l10n/app_localizations.dart';
import 'pose_validator.dart';
import 'overlay_guide.dart';

class CameraView extends StatefulWidget {
  final String poseType;
  final Function(XFile, Map<String, double>?) onImageCaptured;

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
        
        setState(() {
          _validationErrors = errors;
          _isValid = errors.isEmpty;
          _lastPose = poses.first;
          _lastImageWidth = image.width.toDouble();
          _lastImageHeight = image.height.toDouble();
        });
      } else if (mounted) {
        setState(() {
          _validationErrors = ["noBodyDetected"];
          _lastPose = null;
          _isValid = false;
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

  Future<void> _captureImage() async {
    if (_controller == null || _isCapturing) return;

    if (!_isValid) {
      if (_validationErrors.isEmpty) return; // Prevent crash if errors are not yet populated
      
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
      final metrics = _calculateEstimatedMetrics();
      
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
      
      final file = await _controller!.takePicture();
      widget.onImageCaptured(file, metrics);
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
          isFrontCamera: _cameras.isNotEmpty && _cameras[_cameraIndex].lensDirection == CameraLensDirection.front,
          imageSize: Size(_lastImageWidth, _lastImageHeight),
          statusMessage: _isValid 
            ? AppLocalizations.of(context)!.perfectCapture 
            : (_validationErrors.isNotEmpty ? _getLocalizedError(_validationErrors.first) : ""),
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
      case "startingCamera": return l10n.startingCamera;
      default: return key;
    }
  }

  Map<String, double>? _calculateEstimatedMetrics() {
    if (_lastPose == null) return null;
    
    final api = Provider.of<ApiService>(context, listen: false);
    final userHeight = api.currentUser?['altura']?.toDouble() ?? 170.0;
    
    final nose = _lastPose!.landmarks[PoseLandmarkType.nose];
    final leftAnkle = _lastPose!.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = _lastPose!.landmarks[PoseLandmarkType.rightAnkle];
    
    if (nose == null || leftAnkle == null || rightAnkle == null) return null;
    
    // Altura em pixels
    final avgAnkleY = (leftAnkle.y + rightAnkle.y) / 2;
    final bodyHeightPixels = (avgAnkleY - nose.y).abs();
    
    // Proporção pixel para cm
    final pixelToCm = userHeight / bodyHeightPixels;
    
    final shoulderL = _lastPose!.landmarks[PoseLandmarkType.leftShoulder];
    final shoulderR = _lastPose!.landmarks[PoseLandmarkType.rightShoulder];
    final hipL = _lastPose!.landmarks[PoseLandmarkType.leftHip];
    final hipR = _lastPose!.landmarks[PoseLandmarkType.rightHip];
    
    if (shoulderL == null || shoulderR == null || hipL == null || hipR == null) return null;
    
    // Cálculo de larguras em pixels
    final shoulderWidthPixels = (shoulderL.x - shoulderR.x).abs();
    final hipWidthPixels = (hipL.x - hipR.x).abs();
    
    // Heurística de conversão de largura frontal para circunferência (aprox. 2.6x a 2.8x a largura frontal)
    double widthToCircumference(double widthPixels, double factor) {
      return (widthPixels * pixelToCm * factor).roundToDouble(); 
    }

    return {
      'chest': widthToCircumference(shoulderWidthPixels, 2.7),
      'waist': widthToCircumference((shoulderWidthPixels + hipWidthPixels) / 2 * 0.85, 2.6),
      'hips': widthToCircumference(hipWidthPixels, 2.8),
    };
  }
}
