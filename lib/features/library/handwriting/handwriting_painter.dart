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
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..color = Color(stroke.color);

      if (stroke.eraser) {
        paint
          ..blendMode = BlendMode.clear
          ..strokeWidth = stroke.width * 2.5;
      }

      final path = Path()
        ..moveTo(
          stroke.points.first.x,
          stroke.points.first.y,
        );

      for (final point in stroke.points.skip(1)) {
        path.lineTo(point.x, point.y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(
    covariant HandwritingPainter oldDelegate,
  ) {
    return oldDelegate.strokes != strokes;
  }
}
