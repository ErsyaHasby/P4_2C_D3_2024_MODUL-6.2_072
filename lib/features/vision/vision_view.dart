import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logbook_app_modul5/features/vision/vision_controller.dart';
import 'package:logbook_app_modul5/features/vision/damage_painter.dart';

class VisionView extends StatefulWidget {
  const VisionView({super.key});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  late final VisionController _visionController;

  @override
  void initState() {
    super.initState();
    _visionController = VisionController();
  }

  @override
  void dispose() {
    _visionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart-Patrol Vision'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: _visionController,
        builder: (context, child) {
          if (_visionController.isInitializing &&
              !_visionController.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_visionController.errorMessage != null) {
            return _buildErrorState();
          }

          if (!_visionController.isInitialized ||
              _visionController.cameraController == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return _buildCameraPreview(_visionController.cameraController!);
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              _visionController.errorMessage ?? 'Gagal memuat kamera',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _visionController.initCamera,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview(CameraController controller) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              // Camera sensor preview is landscape-native, so width/height are swapped on portrait UI.
              width: previewSize.height,
              height: previewSize.width,
              child: CameraPreview(controller),
            ),
          ),
        ),
        Positioned.fill(
          child: AnimatedDetectionOverlay(
            detectionListenable: _visionController.detectionNotifier,
          ),
        ),
      ],
    );
  }
}

class AnimatedDetectionOverlay extends StatefulWidget {
  final ValueListenable<DetectionOverlayData> detectionListenable;

  const AnimatedDetectionOverlay({
    super.key,
    required this.detectionListenable,
  });

  @override
  State<AnimatedDetectionOverlay> createState() =>
      _AnimatedDetectionOverlayState();
}

class _AnimatedDetectionOverlayState extends State<AnimatedDetectionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late DetectionOverlayData _displayedDetection;
  late DetectionOverlayData _targetDetection;
  late Animation<DetectionOverlayData> _detectionAnimation;

  @override
  void initState() {
    super.initState();
    _displayedDetection = widget.detectionListenable.value;
    _targetDetection = _displayedDetection;

    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 900),
        )..addListener(() {
          setState(() {
            _displayedDetection = _detectionAnimation.value;
          });
        });

    _detectionAnimation =
        DetectionOverlayTween(
          begin: _displayedDetection,
          end: _displayedDetection,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOutCubic,
          ),
        );

    widget.detectionListenable.addListener(_onDetectionChanged);
  }

  @override
  void didUpdateWidget(covariant AnimatedDetectionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detectionListenable != widget.detectionListenable) {
      oldWidget.detectionListenable.removeListener(_onDetectionChanged);
      widget.detectionListenable.addListener(_onDetectionChanged);
    }
  }

  void _onDetectionChanged() {
    final nextDetection = widget.detectionListenable.value;
    if (nextDetection == _targetDetection) {
      return;
    }

    _targetDetection = nextDetection;
    _detectionAnimation =
        DetectionOverlayTween(
          begin: _displayedDetection,
          end: _targetDetection,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOutCubic,
          ),
        );

    _animationController
      ..stop()
      ..forward(from: 0);
  }

  @override
  void dispose() {
    widget.detectionListenable.removeListener(_onDetectionChanged);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: DamagePainter(detection: _displayedDetection));
  }
}
