import 'dart:convert';

import 'package:flutter/material.dart';

import 'handwriting_models.dart';
import 'handwriting_painter.dart';

class HandwritingOverlay extends StatefulWidget {
  final String? initialData;
  final ValueChanged<String>? onChanged;

  const HandwritingOverlay({
    super.key,
    this.initialData,
    this.onChanged,
  });

  @override
  State<HandwritingOverlay> createState() =>
      _HandwritingOverlayState();
}

class _HandwritingOverlayState
    extends State<HandwritingOverlay> {
  final List<InkStroke> strokes = [];
  final List<InkStroke> redoStack = [];

  List<StrokePoint> currentPoints = [];

  Color penColor = Colors.red;
  double penWidth = 4;
  bool eraser = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final raw = widget.initialData;
    if (raw == null || raw.isEmpty) return;

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

  void _notify() {
    widget.onChanged?.call(
      jsonEncode(
        strokes.map((e) => e.toJson()).toList(),
      ),
    );
  }

  void _start(Offset p) {
    setState(() {
      currentPoints = [
        StrokePoint(x: p.dx, y: p.dy),
      ];
    });
  }

  void _move(Offset p) {
    setState(() {
      currentPoints.add(
        StrokePoint(x: p.dx, y: p.dy),
      );
    });
  }

  void _end() {
    if (currentPoints.isEmpty) return;

    setState(() {
      strokes.add(
        InkStroke(
          points: List.from(currentPoints),
          color: penColor.toARGB32(),
          width: penWidth,
          eraser: eraser,
        ),
      );
      currentPoints.clear();
      redoStack.clear();
    });

    _notify();
  }

  void _undo() {
    if (strokes.isEmpty) return;

    setState(() {
      redoStack.add(strokes.removeLast());
    });

    _notify();
  }

  void _redo() {
    if (redoStack.isEmpty) return;

    setState(() {
      strokes.add(redoStack.removeLast());
    });

    _notify();
  }

  void _clear() {
    if (strokes.isEmpty) return;

    setState(() {
      redoStack.addAll(strokes);
      strokes.clear();
    });

    _notify();
  }

  void _color() {
    const colors = [
      Colors.red,
      Colors.black,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
    ];

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: colors.map((c) {
              return InkWell(
                onTap: () {
                  setState(() {
                    penColor = c;
                    eraser = false;
                  });
                  Navigator.pop(context);
                },
                child: CircleAvatar(
                  radius: 23,
                  backgroundColor: c,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _width() {
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, update) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pen size',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  min: 1,
                  max: 16,
                  value: penWidth,
                  onChanged: (v) {
                    setState(() => penWidth = v);
                    update(() {});
                  },
                ),
                Text('${penWidth.round()} px'),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) => _start(d.localPosition),
          onPanUpdate: (d) => _move(d.localPosition),
          onPanEnd: (_) => _end(),
          child: CustomPaint(
            painter: HandwritingPainter([
              ...strokes,
              if (currentPoints.isNotEmpty)
                InkStroke(
                  points: currentPoints,
                  color: penColor.toARGB32(),
                  width: penWidth,
                  eraser: eraser,
                ),
            ]),
          ),
        ),
        Positioned(
          left: 8,
          right: 8,
          bottom: 8,
          child: Material(
            elevation: 5,
            borderRadius: BorderRadius.circular(18),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Pen',
                    onPressed: () {
                      setState(() => eraser = false);
                    },
                    icon: Icon(
                      Icons.edit,
                      color: eraser
                          ? null
                          : Theme.of(context)
                              .colorScheme
                              .primary,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Highlighter',
                    onPressed: () {
                      setState(() {
                        eraser = false;
                        penColor = penColor.withValues(
                          alpha: .35,
                        );
                        penWidth = 14;
                      });
                    },
                    icon: const Icon(
                      Icons.highlight,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Eraser',
                    onPressed: () {
                      setState(() => eraser = true);
                    },
                    icon: const Icon(
                      Icons.auto_fix_normal,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Color',
                    onPressed: _color,
                    icon: Icon(
                      Icons.palette_outlined,
                      color: penColor,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Size',
                    onPressed: _width,
                    icon: const Icon(
                      Icons.line_weight,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Undo',
                    onPressed:
                        strokes.isEmpty ? null : _undo,
                    icon: const Icon(Icons.undo),
                  ),
                  IconButton(
                    tooltip: 'Redo',
                    onPressed:
                        redoStack.isEmpty ? null : _redo,
                    icon: const Icon(Icons.redo),
                  ),
                  IconButton(
                    tooltip: 'Clear',
                    onPressed:
                        strokes.isEmpty ? null : _clear,
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
