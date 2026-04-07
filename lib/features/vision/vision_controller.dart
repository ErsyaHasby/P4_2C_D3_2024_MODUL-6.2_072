import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _hasCameraPermission = false;
  String? _errorMessage;
  bool _isDisposed = false;

  CameraController? get cameraController => _cameraController;
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  bool get hasCameraPermission => _hasCameraPermission;
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
        _errorMessage = 'Izin kamera belum diberikan.';
        return;
      }

      _hasCameraPermission = true;

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
        ResolutionPreset.medium,
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
    final controller = _cameraController;
    _cameraController = null;
    _isInitialized = false;

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
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }
}
