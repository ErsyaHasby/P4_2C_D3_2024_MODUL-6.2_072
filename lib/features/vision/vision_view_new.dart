import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logbook_app_modul5/features/vision/vision_controller.dart';
import 'package:logbook_app_modul5/features/vision/damage_painter.dart';
import 'package:logbook_app_modul5/features/vision/image_processor.dart';
import 'package:permission_handler/permission_handler.dart';

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
    return ListenableBuilder(
      listenable: _visionController,
      builder: (context, child) {
        // Show result view if image is captured
        if (_visionController.capturedImageData != null) {
          return _buildResultView();
        }

        // Show loading state
        if (_visionController.isInitializing &&
            !_visionController.isInitialized) {
          return _buildLoadingState();
        }

        // Show error state
        if (_visionController.errorMessage != null) {
          return _buildErrorState();
        }

        // Show camera preview
        if (!_visionController.isInitialized ||
            _visionController.cameraController == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return _buildCameraPreview(_visionController.cameraController!);
      },
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart-Patrol Vision'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.blue.shade300,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Menghubungkan Sensor Visual...',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart-Patrol Vision'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 56,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  _visionController.errorMessage ?? 'Gagal Memuat Kamera',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blue.shade900, fontSize: 14),
                ),
                const SizedBox(height: 20),
                if ((_visionController.errorMessage ?? '').contains(
                  'No Camera Access',
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton.icon(
                      onPressed: openAppSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text('Buka Pengaturan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _visionController.initCamera,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Jepretan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _visionController.clearCapturedImage();
          },
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.black87,
                child: Center(
                  child: Image.memory(
                    _visionController.capturedImageData!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Text(
                    'Filter: ${_visionController.selectedFilter.label}',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      _visionController.clearCapturedImage();
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Kembali'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart-Patrol Vision'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: previewSize.height,
                height: previewSize.width,
                child: CameraPreview(controller),
              ),
            ),
          ),

          // Overlay (if enabled)
          if (_visionController.isOverlayEnabled)
            Positioned.fill(
              child: AnimatedDetectionOverlay(
                detectionListenable: _visionController.detectionNotifier,
              ),
            ),

          // Top controls: Torch + Overlay toggle
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _buildIconButton(
                  icon: _visionController.isTorchOn
                      ? Icons.flash_on
                      : Icons.flash_off,
                  onPressed: _visionController.isTorchAvailable
                      ? _visionController.toggleTorch
                      : null,
                  tooltip: _visionController.isTorchOn
                      ? 'Matikan Lampu'
                      : 'Nyalakan Lampu',
                  isActive: _visionController.isTorchOn,
                ),
                const SizedBox(width: 10),
                _buildIconButton(
                  icon: _visionController.isOverlayEnabled
                      ? Icons.layers
                      : Icons.layers_clear,
                  onPressed: _visionController.toggleOverlay,
                  tooltip: _visionController.isOverlayEnabled
                      ? 'Matikan Overlay'
                      : 'Nyalakan Overlay',
                  isActive: _visionController.isOverlayEnabled,
                ),
              ],
            ),
          ),

          // Filter selection: Horizontal scroll strip
          Positioned(top: 60, left: 0, right: 0, child: _buildFilterStrip()),

          // Bottom: Capture button
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(child: _buildCaptureButton()),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    required bool isActive,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                icon,
                color: isActive ? Colors.white : Colors.blue,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterStrip() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: ImageFilter.values
            .map(
              (filter) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(filter),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFilterChip(ImageFilter filter) {
    final isSelected = _visionController.selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        _visionController.setImageFilter(filter);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          filter.label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blue.shade900,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _visionController.isCapturing
              ? null
              : _visionController.capturePhoto,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(32),
              ),
              child: _visionController.isCapturing
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    )
                  : Icon(Icons.camera_alt, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
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
  void dispose() {
    widget.detectionListenable.removeListener(_onDetectionChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onDetectionChanged() {
    _targetDetection = widget.detectionListenable.value;

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

    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DamagePainter(detection: _displayedDetection),
      child: Container(),
    );
  }
}
