import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:logbook_app_modul5/features/vision/damage_painter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math';

class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _hasCameraPermission = false;
  bool _isPermissionPermanentlyDenied = false;
  bool _isOverlayEnabled = true;
  bool _isTorchOn = false;
  bool _isTorchAvailable = false;
  ResolutionPreset _resolutionPreset = ResolutionPreset.medium;
  String? _errorMessage;
  bool _isDisposed = false;
  Timer? _mockTimer;
  final Random _random = Random();

  final ValueNotifier<DetectionOverlayData> detectionNotifier =
      ValueNotifier<DetectionOverlayData>(
        const DetectionOverlayData(
          x: 0.3,
          y: 0.3,
          width: 0.35,
          height: 0.28,
          label: 'Searching for Road Damage...',
          confidence: 0.91,
        ),
      );

  CameraController? get cameraController => _cameraController;
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  bool get hasCameraPermission => _hasCameraPermission;
  bool get isPermissionPermanentlyDenied => _isPermissionPermanentlyDenied;
  bool get isOverlayEnabled => _isOverlayEnabled;
  bool get isTorchOn => _isTorchOn;
  bool get isTorchAvailable => _isTorchAvailable;
  ResolutionPreset get resolutionPreset => _resolutionPreset;
  String? get errorMessage => _errorMessage;

  VisionController() {
    WidgetsBinding.instance.addObserver(this);
    initCamera();
  }

  Future<void> initCamera() async {
    if (_isInitializing || _isDisposed) {
      return;
    }

    _isInitializing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final permissionStatus = await Permission.camera.request();
      if (!permissionStatus.isGranted) {
        _hasCameraPermission = false;
        _isInitialized = false;
        _isPermissionPermanentlyDenied = permissionStatus.isPermanentlyDenied;
        _errorMessage = _isPermissionPermanentlyDenied
            ? 'No Camera Access: akses kamera diblok permanen.'
            : 'No Camera Access: izin kamera belum diberikan.';
        return;
      }

      _hasCameraPermission = true;
      _isPermissionPermanentlyDenied = false;

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _isInitialized = false;
        _errorMessage = 'Tidak ada kamera yang terdeteksi di perangkat.';
        return;
      }

      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      await _disposeCameraController();

      final controller = CameraController(
        selectedCamera,
        _resolutionPreset,
        enableAudio: false,
      );

      _cameraController = controller;
      await controller.initialize();

      if (_isDisposed) {
        await controller.dispose();
        return;
      }

      _isInitialized = true;
      _errorMessage = null;
      _syncTorchAvailability();
      _startMockDetection();
    } on CameraException catch (e) {
      _isInitialized = false;
      _errorMessage = 'Camera error (${e.code}): ${e.description ?? 'Unknown'}';
    } catch (e) {
      _isInitialized = false;
      _errorMessage = 'Gagal menginisialisasi kamera: $e';
    } finally {
      _isInitializing = false;
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  Future<void> _disposeCameraController() async {
    _stopMockDetection();

    final controller = _cameraController;
    _cameraController = null;
    _isInitialized = false;
    _isTorchOn = false;
    _isTorchAvailable = false;

    if (controller != null) {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      await controller.dispose();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _disposeCameraController();
      notifyListeners();
      return;
    }

    if (state == AppLifecycleState.resumed && _hasCameraPermission) {
      initCamera();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopMockDetection();
    detectionNotifier.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }

  void _startMockDetection() {
    _mockTimer?.cancel();

    _updateMockDetection();
    _mockTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _updateMockDetection();
    });
  }

  void _stopMockDetection() {
    _mockTimer?.cancel();
    _mockTimer = null;
  }

  void _updateMockDetection() {
    // Keep mock detection inside the visible canvas using normalized coordinates (0.0 - 1.0).
    final width = 0.2 + (_random.nextDouble() * 0.25);
    final height = 0.15 + (_random.nextDouble() * 0.2);
    final maxX = 1.0 - width;
    final maxY = 1.0 - height;

    final x = _random.nextDouble() * maxX;
    final y = _random.nextDouble() * maxY;
    final confidence = 0.75 + (_random.nextDouble() * 0.24);

    final mockLabels = <String>['D40 Pothole', 'D00 Longitudinal Crack'];
    final label = mockLabels[_random.nextInt(mockLabels.length)];

    detectionNotifier.value = DetectionOverlayData(
      x: x,
      y: y,
      width: width,
      height: height,
      label: label,
      confidence: confidence,
    );
  }

  Future<void> setResolutionPreset(ResolutionPreset preset) async {
    if (_resolutionPreset == preset) {
      return;
    }

    _resolutionPreset = preset;
    notifyListeners();

    await initCamera();
  }

  void toggleOverlay() {
    _isOverlayEnabled = !_isOverlayEnabled;
    notifyListeners();
  }

  Future<void> toggleTorch() async {
    final controller = _cameraController;
    if (controller == null || !_isInitialized) {
      return;
    }

    try {
      if (_isTorchOn) {
        await controller.setFlashMode(FlashMode.off);
        _isTorchOn = false;
      } else {
        await controller.setFlashMode(FlashMode.torch);
        _isTorchOn = true;
      }
    } on CameraException {
      _errorMessage = 'Torch tidak tersedia pada perangkat ini.';
      _isTorchAvailable = false;
    }

    notifyListeners();
  }

  void _syncTorchAvailability() {
    // CameraDescription.hasFlash is not available on all plugin versions.
    // Assume available and fallback to error handling in toggleTorch if unsupported.
    _isTorchAvailable = true;
    _isTorchOn = false;
  }
}
