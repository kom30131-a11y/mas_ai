import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarColor extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarColor({
    super.key,
    required this.controller,
  });

  void _applyTextColor(Color color) {
    controller.applyRunFormat(
      WmlRunProps(
        color: _hex(color),
      ),
    );
    controller.refresh();
  }

  void _applyHighlight(Color color) {
    controller.applyRunFormat(
      WmlRunProps(
        highlight: _hex(color),
      ),
    );
    controller.refresh();
  }

  String _hex(Color color) {
    return color.value.toRadixString(16).substring(2).toUpperCase();
  }

  Future<void> _pick(
    BuildContext context, {
    required bool highlight,
  }) async {
    final color = await showDialog<Color>(
      context: context,
      builder: (context) {
        const colors = [
          Colors.black,
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.orange,
          Colors.purple,
          Colors.brown,
          Colors.grey,
          Colors.white,
          Colors.yellow,
          Colors.cyan,
          Colors.pink,
        ];

        return AlertDialog(
          title: Text(
            highlight ? 'Highlight color' : 'Text color',
          ),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final color in colors)
                InkWell(
                  onTap: () => Navigator.pop(context, color),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (color == null) return;

    if (highlight) {
      _applyHighlight(color);
    } else {
      _applyTextColor(color);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Text color',
          onPressed: () => _pick(
            context,
            highlight: false,
          ),
          icon: const Icon(Icons.format_color_text),
        ),
        IconButton(
          tooltip: 'Highlight',
          onPressed: () => _pick(
            context,
            highlight: true,
          ),
          icon: const Icon(Icons.highlight),
        ),
      ],
    );
  }
}
