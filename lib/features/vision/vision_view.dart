import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logbook_app_modul5/features/vision/vision_controller.dart';
import 'package:logbook_app_modul5/features/vision/damage_painter.dart';
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
            return _buildLoadingState();
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

  Widget _buildLoadingState() {
    return Container(
      color: const Color(0xFF0A0A0F),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFFFFB74D),
              ),
            ),
            SizedBox(height: 18),
            Text(
              'Menghubungkan ke Sensor Visual...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
            if ((_visionController.errorMessage ?? '').contains(
              'No Camera Access',
            ))
              OutlinedButton.icon(
                onPressed: openAppSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
              ),
            if ((_visionController.errorMessage ?? '').contains(
              'No Camera Access',
            ))
              const SizedBox(height: 10),
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
        if (_visionController.isOverlayEnabled)
          Positioned.fill(
            child: AnimatedDetectionOverlay(
              detectionListenable: _visionController.detectionNotifier,
            ),
          ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 14,
          child: _buildControlPanel(),
        ),
      ],
    );
  }

  Widget _buildControlPanel() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC121218),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildPillButton(
                    icon: _visionController.isTorchOn
                        ? Icons.flash_on
                        : Icons.flash_off,
                    label: _visionController.isTorchOn
                        ? 'Torch ON'
                        : 'Torch OFF',
                    accent: _visionController.isTorchOn
                        ? const Color(0xFFFFCA28)
                        : Colors.white70,
                    enabled: _visionController.isTorchAvailable,
                    onTap: _visionController.isTorchAvailable
                        ? _visionController.toggleTorch
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPillButton(
                    icon: _visionController.isOverlayEnabled
                        ? Icons.layers
                        : Icons.layers_clear,
                    label: _visionController.isOverlayEnabled
                        ? 'Overlay ON'
                        : 'Overlay OFF',
                    accent: _visionController.isOverlayEnabled
                        ? const Color(0xFF66BB6A)
                        : Colors.white70,
                    enabled: true,
                    onTap: _visionController.toggleOverlay,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Resolution',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ResolutionPreset>(
                          value: _visionController.resolutionPreset,
                          dropdownColor: const Color(0xFF1A1A23),
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(
                              value: ResolutionPreset.low,
                              child: Text('Low (lebih ringan)'),
                            ),
                            DropdownMenuItem(
                              value: ResolutionPreset.medium,
                              child: Text('Medium (seimbang)'),
                            ),
                            DropdownMenuItem(
                              value: ResolutionPreset.high,
                              child: Text('High'),
                            ),
                            DropdownMenuItem(
                              value: ResolutionPreset.max,
                              child: Text('Max (latency test)'),
                            ),
                            DropdownMenuItem(
                              value: ResolutionPreset.ultraHigh,
                              child: Text('UltraHigh (latency test)'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            _visionController.setResolutionPreset(value);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    required Color accent,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: enabled ? Colors.white10 : Colors.white12,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? accent.withValues(alpha: 0.7) : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: enabled ? accent : Colors.white54, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.white : Colors.white54,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
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
