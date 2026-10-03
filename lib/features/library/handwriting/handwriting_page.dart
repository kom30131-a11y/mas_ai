import 'dart:convert';

import 'package:flutter/material.dart';

import 'handwriting_models.dart';
import 'handwriting_painter.dart';

class HandwritingPage extends StatefulWidget {
  final String? initialData;

  const HandwritingPage({
    super.key,
    this.initialData,
  });

  @override
  State<HandwritingPage> createState() =>
      _HandwritingPageState();
}

class _HandwritingPageState
    extends State<HandwritingPage> {
  final List<InkStroke> strokes = [];
  final List<InkStroke> undoStack = [];

  List<StrokePoint> currentPoints = [];

  Color penColor = Colors.black;
  double penWidth = 4;
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
      final data = jsonDecode(raw);

      if (data is! List) return;

      strokes.addAll(
        data.map(
          (e) => InkStroke.fromJson(
            Map<String, dynamic>.from(e),
          ),
        ),
      );
    } catch (_) {}
  }

  void _startStroke(Offset position) {
    setState(() {
      currentPoints = [
        StrokePoint(
          x: position.dx,
          y: position.dy,
        ),
      ];
    });
  }

  void _updateStroke(Offset position) {
    setState(() {
      currentPoints.add(
        StrokePoint(
          x: position.dx,
          y: position.dy,
        ),
      );
    });
  }

  void _endStroke() {
    if (currentPoints.isEmpty) return;

    setState(() {
      strokes.add(
        InkStroke(
          points: List.from(currentPoints),
          color: penColor.value,
          width: penWidth,
          eraser: eraser,
        ),
      );

      undoStack.clear();
      currentPoints = [];
    });
  }

  void _undo() {
    if (strokes.isEmpty) return;

    setState(() {
      undoStack.add(strokes.removeLast());
    });
  }

  void _redo() {
    if (undoStack.isEmpty) return;

    setState(() {
      strokes.add(undoStack.removeLast());
    });
  }

  void _clear() {
    if (strokes.isEmpty) return;

    setState(() {
      undoStack.addAll(strokes);
      strokes.clear();
    });
  }

  void _save() {
    final data = jsonEncode(
      strokes.map((e) => e.toJson()).toList(),
    );

    Navigator.of(context).pop(data);
  }

  void _showWidthPicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
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
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showColors() {
    const colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
    ];

    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Handwriting'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed: strokes.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Redo',
            onPressed:
                undoStack.isEmpty ? null : _redo,
            icon: const Icon(Icons.redo),
          ),
          IconButton(
            tooltip: 'Clear',
            onPressed: strokes.isEmpty ? null : _clear,
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            tooltip: 'Save',
            onPressed: _save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Column(
        children: [
          _toolbar(),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) {
                _startStroke(details.localPosition);
              },
              onPanUpdate: (details) {
                _updateStroke(details.localPosition);
              },
              onPanEnd: (_) {
                _endStroke();
              },
              child: Container(
                color: Colors.white,
                child: CustomPaint(
                  painter: HandwritingPainter(
                    [
                      ...strokes,
                      if (currentPoints.isNotEmpty)
                        InkStroke(
                          points: currentPoints,
                          color: penColor.value,
                          width: penWidth,
                          eraser: eraser,
                        ),
                    ],
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Pen',
              onPressed: () {
                setState(() {
                  eraser = false;
                });
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
              tooltip: 'Eraser',
              onPressed: () {
                setState(() {
                  eraser = true;
                });
              },
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
              onPressed: _showColors,
              icon: Icon(
                Icons.palette_outlined,
                color: penColor,
              ),
            ),
            IconButton(
              tooltip: 'Pen size',
              onPressed: _showWidthPicker,
              icon: const Icon(
                Icons.line_weight,
              ),
            ),
            const Spacer(),
            Text(
              '${penWidth.toStringAsFixed(0)} px',
            ),
          ],
        ),
      ),
    );
  }
}
