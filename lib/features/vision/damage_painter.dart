import 'package:flutter/material.dart';

class DamagePainter extends CustomPainter {
  const DamagePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final boxSize = size.width * 0.55;
    final halfBox = boxSize / 2;

    final boxRect = Rect.fromCenter(
      center: center,
      width: boxSize,
      height: boxSize,
    );

    final boxPaint = Paint()
      ..color = Colors.redAccent
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

    final labelStyle = const TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      backgroundColor: Colors.black87,
    );

    final labelPainter = TextPainter(
      text: TextSpan(text: ' Searching for Road Damage... ', style: labelStyle),
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

    labelPainter.paint(canvas, Offset(labelX, labelY));

    final cornerPaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cornerLength = halfBox * 0.18;

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
    return false;
  }
}
