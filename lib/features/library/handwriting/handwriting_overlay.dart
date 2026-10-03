import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import 'handwriting_models.dart';
import 'handwriting_painter.dart';

enum InkTool { pen, highlighter, eraser }

class HandwritingOverlay extends StatefulWidget {
  final String? initialData;
  final ScrollController scrollController;
  final ValueChanged<String>? onChanged;

  const HandwritingOverlay({
    super.key,
    this.initialData,
    required this.scrollController,
    this.onChanged,
  });

  @override
  State<HandwritingOverlay> createState() =>
      HandwritingOverlayState();
}

class HandwritingOverlayState
    extends State<HandwritingOverlay> {
  final strokes = <InkStroke>[];
  final redoStack = <InkStroke>[];
  final currentPoints = <StrokePoint>[];

  InkTool tool = InkTool.pen;
  Color baseColor = Colors.red;
  double penWidth = 4;
  double highlighterWidth = 18;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final raw = widget.initialData;

    if (raw == null || raw.trim().isEmpty) {
      return;
    }

    try {
      final data = jsonDecode(raw);

      if (data is List) {
        strokes.addAll(
          data.map(
            (e) => InkStroke.fromJson(
              Map<String, dynamic>.from(e),
            ),
          ),
        );
      }
    } catch (_) {}
  }

  Offset _contentOffset(Offset p) {
    final scroll =
        widget.scrollController.hasClients
            ? widget.scrollController.offset
            : 0;

    return Offset(
      p.dx,
      p.dy + scroll,
    );
  }

  Color get _strokeColor {
    if (tool == InkTool.highlighter) {
      return baseColor.withValues(alpha: .30);
    }

    return baseColor;
  }

  double get _strokeWidth {
    return tool == InkTool.highlighter
        ? highlighterWidth
        : penWidth;
  }

  void _notify() {
    widget.onChanged?.call(
      jsonEncode(
        strokes.map((e) => e.toJson()).toList(),
      ),
    );
  }

  void _start(DragStartDetails d) {
    if (tool == InkTool.eraser) {
      _eraseAt(
        _contentOffset(d.localPosition),
      );
      return;
    }

    currentPoints
      ..clear()
      ..add(
        _point(
          _contentOffset(d.localPosition),
        ),
      );

    setState(() {});
  }

  void _move(DragUpdateDetails d) {
    final p = _contentOffset(d.localPosition);

    if (tool == InkTool.eraser) {
      _eraseAt(p);
      return;
    }

    currentPoints.add(_point(p));
    setState(() {});
  }

  void _end(DragEndDetails d) {
    if (tool == InkTool.eraser ||
        currentPoints.isEmpty) {
      return;
    }

    setState(() {
      strokes.add(
        InkStroke(
          points: List.of(currentPoints),
          color: _strokeColor.toARGB32(),
          width: _strokeWidth,
          eraser: false,
        ),
      );

      currentPoints.clear();
      redoStack.clear();
    });

    _notify();
  }

  StrokePoint _point(Offset p) {
    return StrokePoint(
      x: p.dx,
      y: p.dy,
    );
  }

  void _eraseAt(Offset p) {
    final radius = max(12.0, _strokeWidth * 2);

    bool changed = false;

    setState(() {
      strokes.removeWhere((stroke) {
        final hit = stroke.points.any(
          (point) {
            final dx = point.x - p.dx;
            final dy = point.y - p.dy;
            return dx * dx + dy * dy <=
                radius * radius;
          },
        );

        if (hit) {
          changed = true;
        }

        return hit;
      });
    });

    if (changed) {
      _notify();
    }
  }

  void setPen() {
    setState(() => tool = InkTool.pen);
  }

  void setHighlighter() {
    setState(() => tool = InkTool.highlighter);
  }

  void setEraser() {
    setState(() => tool = InkTool.eraser);
  }

  void undo() {
    if (strokes.isEmpty) {
      return;
    }

    setState(() {
      redoStack.add(strokes.removeLast());
    });

    _notify();
  }

  void redo() {
    if (redoStack.isEmpty) {
      return;
    }

    setState(() {
      strokes.add(redoStack.removeLast());
    });

    _notify();
  }

  void clear() {
    if (strokes.isEmpty) {
      return;
    }

    setState(() {
      redoStack.addAll(strokes);
      strokes.clear();
    });

    _notify();
  }

  void showColors() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose color',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onPanDown: (d) {
                    _pickWheelColor(d.localPosition);
                  },
                  onPanUpdate: (d) {
                    _pickWheelColor(d.localPosition);
                  },
                  child: CustomPaint(
                    size: const Size.square(280),
                    painter: _ColorWheelPainter(
                      color: baseColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: baseColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pickWheelColor(Offset p) {
    const size = 280.0;
    final center = Offset(size / 2, size / 2);
    final dx = p.dx - center.dx;
    final dy = p.dy - center.dy;
    final radius = min(center.dx, center.dy);
    final distance = sqrt(dx * dx + dy * dy);

    if (distance > radius) {
      return;
    }

    var hue = atan2(dy, dx) * 180 / pi;
    hue = (hue + 90 + 360) % 360;

    final saturation =
        (distance / radius).clamp(0.0, 1.0);

    setState(() {
      baseColor = HSVColor.fromAHSV(
        1,
        hue,
        saturation,
        1,
      ).toColor();
    });
  }

  void showSize() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, update) {
            final value = tool == InkTool.highlighter
                ? highlighterWidth
                : penWidth;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Size',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Slider(
                      min: 1,
                      max: 30,
                      value: value,
                      onChanged: (v) {
                        setState(() {
                          if (tool ==
                              InkTool.highlighter) {
                            highlighterWidth = v;
                          } else {
                            penWidth = v;
                          }
                        });
                        update(() {});
                      },
                    ),
                    Text(
                      '${value.round()} px',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scroll =
        widget.scrollController.hasClients
            ? widget.scrollController.offset
            : 0.0;

    return AnimatedBuilder(
      animation: widget.scrollController,
      builder: (context, _) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _start,
          onPanUpdate: _move,
          onPanEnd: _end,
          child: CustomPaint(
            painter: HandwritingPainter(
              strokes,
              scrollOffset: scroll,
            ),
          ),
        );
      },
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  final Color color;

  const _ColorWheelPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    final colors = List<Color>.generate(
      13,
      (i) => HSVColor.fromAHSV(
        1,
        i * 30.0,
        1,
        1,
      ).toColor(),
    );

    final wheelPaint = Paint()
      ..shader = SweepGradient(
        colors: colors,
      ).createShader(rect);

    canvas.drawCircle(
      center,
      radius,
      wheelPaint,
    );

    final whitePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(rect);

    canvas.drawCircle(
      center,
      radius,
      whitePaint,
    );

    final hsv = HSVColor.fromColor(color);
    final angle =
        hsv.hue * pi / 180 - pi / 2;
    final pointRadius =
        hsv.saturation * radius;

    final point = Offset(
      center.dx + cos(angle) * pointRadius,
      center.dy + sin(angle) * pointRadius,
    );

    final marker = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white;

    canvas.drawCircle(
      point,
      9,
      marker,
    );

    canvas.drawCircle(
      point,
      5,
      Paint()..color = Colors.black,
    );
  }

  @override
  bool shouldRepaint(
    covariant _ColorWheelPainter oldDelegate,
  ) {
    return oldDelegate.color != color;
  }
}
