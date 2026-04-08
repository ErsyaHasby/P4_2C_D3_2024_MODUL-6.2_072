import 'dart:ui';

import 'package:flutter/material.dart';

class DamagePainter extends CustomPainter {
  final DetectionOverlayData detection;

  const DamagePainter({required this.detection});

  @override
  void paint(Canvas canvas, Size size) {
    final boxRect = Rect.fromLTWH(
      detection.x * size.width,
      detection.y * size.height,
      detection.width * size.width,
      detection.height * size.height,
    );
    final center = boxRect.center;
    final halfBox = boxRect.width / 2;
    final severityColor = detection.isHeavyDamage
        ? const Color(0xFFE53935)
        : const Color(0xFFFDD835);

    final boxPaint = Paint()
      ..color = severityColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawRect(boxRect, boxPaint);

    final crosshairPaint = Paint()
      ..color = Colors.yellowAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const crosshairLength = 22.0;
    canvas.drawLine(
      Offset(center.dx - crosshairLength, center.dy),
      Offset(center.dx + crosshairLength, center.dy),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - crosshairLength),
      Offset(center.dx, center.dy + crosshairLength),
      crosshairPaint,
    );

    final labelStyle = TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      shadows: const [
        Shadow(color: Colors.black, blurRadius: 7, offset: Offset(0, 1)),
      ],
    );

    final labelPainter = TextPainter(
      text: TextSpan(
        text:
            ' ${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}% ',
        style: labelStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelX = center.dx - (labelPainter.width / 2);
    final safeTop = 12.0;
    final preferredLabelY = boxRect.top - labelPainter.height - 10;
    final labelY = preferredLabelY < safeTop
        ? boxRect.bottom + 10
        : preferredLabelY;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          labelX - 6,
          labelY - 4,
          labelPainter.width + 12,
          labelPainter.height + 8,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = Colors.black54,
    );

    final strokePainter = TextPainter(
      text: TextSpan(
        text:
            ' ${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}% ',
        style: labelStyle.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..color = Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    strokePainter.paint(canvas, Offset(labelX, labelY));
    labelPainter.paint(canvas, Offset(labelX, labelY));

    final cornerPaint = Paint()
      ..color = severityColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cornerLength = halfBox * 0.24;

    // Top-left corner
    canvas.drawLine(
      Offset(boxRect.left, boxRect.top),
      Offset(boxRect.left + cornerLength, boxRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(boxRect.left, boxRect.top),
      Offset(boxRect.left, boxRect.top + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(boxRect.right, boxRect.top),
      Offset(boxRect.right - cornerLength, boxRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(boxRect.right, boxRect.top),
      Offset(boxRect.right, boxRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(boxRect.left, boxRect.bottom),
      Offset(boxRect.left + cornerLength, boxRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(boxRect.left, boxRect.bottom),
      Offset(boxRect.left, boxRect.bottom - cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(boxRect.right, boxRect.bottom),
      Offset(boxRect.right - cornerLength, boxRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(boxRect.right, boxRect.bottom),
      Offset(boxRect.right, boxRect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! DamagePainter) {
      return true;
    }
    return oldDelegate.detection != detection;
  }
}

class DetectionOverlayData {
  final double x;
  final double y;
  final double width;
  final double height;
  final String label;
  final double confidence;

  const DetectionOverlayData({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.label,
    required this.confidence,
  });

  bool get isHeavyDamage =>
      label.contains('D40') || label.toLowerCase().contains('pothole');

  static DetectionOverlayData lerp(
    DetectionOverlayData begin,
    DetectionOverlayData end,
    double t,
  ) {
    return DetectionOverlayData(
      x: lerpDouble(begin.x, end.x, t) ?? end.x,
      y: lerpDouble(begin.y, end.y, t) ?? end.y,
      width: lerpDouble(begin.width, end.width, t) ?? end.width,
      height: lerpDouble(begin.height, end.height, t) ?? end.height,
      label: t < 0.5 ? begin.label : end.label,
      confidence:
          lerpDouble(begin.confidence, end.confidence, t) ?? end.confidence,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is DetectionOverlayData &&
        other.x == x &&
        other.y == y &&
        other.width == width &&
        other.height == height &&
        other.label == label &&
        other.confidence == confidence;
  }

  @override
  int get hashCode => Object.hash(x, y, width, height, label, confidence);
}

class DetectionOverlayTween extends Tween<DetectionOverlayData> {
  DetectionOverlayTween({required super.begin, required super.end});

  @override
  DetectionOverlayData lerp(double t) =>
      DetectionOverlayData.lerp(begin!, end!, t);
}
