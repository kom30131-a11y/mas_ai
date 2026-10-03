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
  bool penEnabled = false;
  bool eraser = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final raw = widget.initialData;

    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) return;

      strokes.addAll(
        decoded.map(
          (e) => InkStroke.fromJson(
            Map<String, dynamic>.from(e),
          ),
        ),
      );
    } catch (_) {}
  }

  String _serialize() {
    return jsonEncode(
      strokes.map((e) => e.toJson()).toList(),
    );
  }

  void _notify() {
    widget.onChanged?.call(_serialize());
  }

  void _start(Offset position) {
    if (!penEnabled) return;

    setState(() {
      currentPoints = [
        StrokePoint(
          x: position.dx,
          y: position.dy,
        ),
      ];
    });
  }

  void _update(Offset position) {
    if (!penEnabled) return;

    setState(() {
      currentPoints.add(
        StrokePoint(
          x: position.dx,
          y: position.dy,
        ),
      );
    });
  }

  void _end() {
    if (!penEnabled || currentPoints.isEmpty) return;

    setState(() {
      strokes.add(
        InkStroke(
          points: List.from(currentPoints),
          color: penColor.toARGB32(),
          width: penWidth,
          eraser: eraser,
        ),
      );

      currentPoints = [];
      redoStack.clear();
    });

    _notify();
  }

  void undo() {
    if (strokes.isEmpty) return;

    setState(() {
      redoStack.add(strokes.removeLast());
    });

    _notify();
  }

  void redo() {
    if (redoStack.isEmpty) return;

    setState(() {
      strokes.add(redoStack.removeLast());
    });

    _notify();
  }

  void clear() {
    if (strokes.isEmpty) return;

    setState(() {
      redoStack.addAll(strokes);
      strokes.clear();
    });

    _notify();
  }

  void setPen() {
    setState(() {
      penEnabled = true;
      eraser = false;
    });
  }

  void setEraser() {
    setState(() {
      penEnabled = true;
      eraser = true;
    });
  }

  void disablePen() {
    setState(() {
      penEnabled = false;
      eraser = false;
      currentPoints = [];
    });
  }

  void _pickColor() {
    const colors = [
      Colors.red,
      Colors.black,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
    ];

    showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 18,
              runSpacing: 18,
              children: colors.map((color) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      penColor = color;
                      eraser = false;
                      penEnabled = true;
                    });

                    Navigator.pop(context);
                  },
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: color,
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _pickWidth() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
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
                      onChanged: (value) {
                        setState(() {
                          penWidth = value;
                        });

                        setSheetState(() {});
                      },
                    ),
                    Text(
                      '${penWidth.toStringAsFixed(0)} px',
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          ignoring: !penEnabled,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (details) {
              _start(details.localPosition);
            },
            onPanUpdate: (details) {
              _update(details.localPosition);
            },
            onPanEnd: (_) {
              _end();
            },
            child: CustomPaint(
              painter: HandwritingPainter(
                [
                  ...strokes,
                  if (currentPoints.isNotEmpty)
                    InkStroke(
                      points: currentPoints,
                      color: penColor.toARGB32(),
                      width: penWidth,
                      eraser: eraser,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (penEnabled)
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Material(
              elevation: 4,
              borderRadius:
                  BorderRadius.circular(18),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Text mode',
                      onPressed: disablePen,
                      icon: const Icon(
                        Icons.text_fields,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Pen',
                      onPressed: setPen,
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
                      tooltip: 'Eraser',
                      onPressed: setEraser,
                      icon: Icon(
                        Icons.auto_fix_normal,
                        color: eraser
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                            : null,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Color',
                      onPressed: _pickColor,
                      icon: Icon(
                        Icons.palette_outlined,
                        color: penColor,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Pen size',
                      onPressed: _pickWidth,
                      icon: const Icon(
                        Icons.line_weight,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Undo',
                      onPressed: strokes.isEmpty
                          ? null
                          : undo,
                      icon: const Icon(Icons.undo),
                    ),
                    IconButton(
                      tooltip: 'Redo',
                      onPressed: redoStack.isEmpty
                          ? null
                          : redo,
                      icon: const Icon(Icons.redo),
                    ),
                    IconButton(
                      tooltip: 'Clear',
                      onPressed: strokes.isEmpty
                          ? null
                          : clear,
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
