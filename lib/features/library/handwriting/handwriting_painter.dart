import 'package:flutter/material.dart';

import 'handwriting_models.dart';

class HandwritingPainter extends CustomPainter {
  final List<InkStroke> strokes;

  const HandwritingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.eraser
            ? stroke.width * 2.5
            : stroke.width
        ..color = Color(stroke.color)
        ..blendMode = stroke.eraser
            ? BlendMode.clear
            : BlendMode.srcOver;

      if (!stroke.eraser &&
          stroke.width >= 14) {
        paint.color = Color(stroke.color).withValues(
          alpha: .32,
        );
      }

      final path = Path()
        ..moveTo(
          stroke.points.first.x,
          stroke.points.first.y,
        );

      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.x, p.y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(
    covariant HandwritingPainter oldDelegate,
  ) =>
      true;
}
