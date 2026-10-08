import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarColor extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarColor({
    super.key,
    required this.controller,
  });

  String _hex(Color color) {
    return color.value
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2)
        .toUpperCase();
  }

  Future<void> _pick(
    BuildContext context, {
    required bool highlight,
  }) async {
    const colors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.cyan,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.brown,
      Colors.grey,
    ];

    final color = await showDialog<Color>(
      context: context,
      builder: (context) {
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
                  onTap: () => Navigator.pop(
                    context,
                    color,
                  ),
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

    if (!context.mounted || color == null) return;

    controller.applyRunFormat(
      WmlRunProps(
        color: highlight ? null : _hex(color),
        highlight: highlight ? _hex(color) : null,
      ),
    );
    controller.refresh();
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
