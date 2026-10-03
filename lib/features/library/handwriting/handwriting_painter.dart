import 'package:flutter/material.dart';

import 'handwriting_models.dart';

class HandwritingPainter extends CustomPainter {
  final List<InkStroke> strokes;
  final double scrollOffset;

  const HandwritingPainter(
    this.strokes, {
    this.scrollOffset = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    for (final stroke in strokes) {
      if (stroke.points.isEmpty || stroke.eraser) {
        continue;
      }

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.width
        ..color = Color(stroke.color);

      final first = stroke.points.first;

      final path = Path()
        ..moveTo(
          first.x,
          first.y - scrollOffset,
        );

      for (final point
          in stroke.points.skip(1)) {
        path.lineTo(
          point.x,
          point.y - scrollOffset,
        );
      }

      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant HandwritingPainter oldDelegate,
  ) {
    return true;
  }
}
