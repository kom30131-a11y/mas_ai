import 'dart:convert';

import 'package:flutter/material.dart';

import 'handwriting_models.dart';
import 'handwriting_painter.dart';

enum InkTool { pen, highlighter, eraser }

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

class _HandwritingOverlayState extends State<HandwritingOverlay> {
  final strokes = <InkStroke>[];
  final redo = <InkStroke>[];
  final points = <StrokePoint>[];

  InkTool tool = InkTool.pen;
  Color color = Colors.red;
  double width = 4;

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

  void _changed() {
    widget.onChanged?.call(
      jsonEncode(
        strokes.map((e) => e.toJson()).toList(),
      ),
    );
  }

  void _start(DragStartDetails d) {
    points
      ..clear()
      ..add(
        StrokePoint(
          x: d.localPosition.dx,
          y: d.localPosition.dy,
        ),
      );
    setState(() {});
  }

  void _move(DragUpdateDetails d) {
    points.add(
      StrokePoint(
        x: d.localPosition.dx,
        y: d.localPosition.dy,
      ),
    );
    setState(() {});
  }

  void _end(DragEndDetails d) {
    if (points.isEmpty) return;

    final stroke = InkStroke(
      points: List.of(points),
      color: color.toARGB32(),
      width: width,
      eraser: tool == InkTool.eraser,
    );

    setState(() {
      strokes.add(stroke);
      points.clear();
      redo.clear();
    });

    _changed();
  }

  void _undo() {
    if (strokes.isEmpty) return;
    setState(() => redo.add(strokes.removeLast()));
    _changed();
  }

  void _redo() {
    if (redo.isEmpty) return;
    setState(() => strokes.add(redo.removeLast()));
    _changed();
  }

  void _clear() {
    if (strokes.isEmpty) return;
    setState(() {
      redo.addAll(strokes);
      strokes.clear();
    });
    _changed();
  }

  void _setTool(InkTool value) {
    setState(() {
      tool = value;
      if (value == InkTool.pen) {
        width = width.clamp(1, 10);
      } else if (value == InkTool.highlighter) {
        width = 18;
      }
    });
  }

  void _colors() {
    const colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.yellow,
      Colors.white,
    ];

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: colors.map((c) {
              return InkWell(
                onTap: () {
                  setState(() => color = c);
                  Navigator.pop(context);
                },
                child: CircleAvatar(
                  radius: 23,
                  backgroundColor: c,
                  child: c == Colors.white
                      ? const Icon(
                          Icons.circle_outlined,
                          color: Colors.black26,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _size() {
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
                  'Size',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  min: 1,
                  max: 25,
                  value: width,
                  onChanged: (v) {
                    setState(() => width = v);
                    update(() {});
                  },
                ),
                Text('${width.round()} px'),
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
          onPanStart: _start,
          onPanUpdate: _move,
          onPanEnd: _end,
          child: CustomPaint(
            painter: HandwritingPainter([
              ...strokes,
              if (points.isNotEmpty)
                InkStroke(
                  points: List.of(points),
                  color: color.toARGB32(),
                  width: width,
                  eraser: tool == InkTool.eraser,
                ),
            ]),
          ),
        ),
        Positioned(
          left: 10,
          right: 10,
          bottom: 10,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(22),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Pen',
                    onPressed: () => _setTool(InkTool.pen),
                    icon: Icon(
                      Icons.edit,
                      color: tool == InkTool.pen
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                          : null,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Highlighter',
                    onPressed: () =>
                        _setTool(InkTool.highlighter),
                    icon: Icon(
                      Icons.highlight,
                      color: tool == InkTool.highlighter
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                          : null,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Eraser',
                    onPressed: () =>
                        _setTool(InkTool.eraser),
                    icon: Icon(
                      Icons.auto_fix_normal,
                      color: tool == InkTool.eraser
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                          : null,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Color',
                    onPressed: _colors,
                    icon: Icon(
                      Icons.palette_outlined,
                      color: color,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Size',
                    onPressed: _size,
                    icon: const Icon(Icons.line_weight),
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
                        redo.isEmpty ? null : _redo,
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
