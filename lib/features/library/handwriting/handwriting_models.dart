import 'package:flutter/material.dart';

class StrokePoint {
  final double x;
  final double y;

  const StrokePoint({
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
      };

  factory StrokePoint.fromJson(Map<String, dynamic> json) {
    return StrokePoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }

  Offset get offset => Offset(x, y);
}

class InkStroke {
  final List<StrokePoint> points;
  final int color;
  final double width;
  final bool eraser;

  const InkStroke({
    required this.points,
    required this.color,
    required this.width,
    required this.eraser,
  });

  Map<String, dynamic> toJson() => {
        'points': points.map((e) => e.toJson()).toList(),
        'color': color,
        'width': width,
        'eraser': eraser,
      };

  factory InkStroke.fromJson(Map<String, dynamic> json) {
    return InkStroke(
      points: (json['points'] as List)
          .map(
            (e) => StrokePoint.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      color: json['color'] as int,
      width: (json['width'] as num).toDouble(),
      eraser: json['eraser'] as bool? ?? false,
    );
  }
}
