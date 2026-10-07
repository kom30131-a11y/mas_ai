import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarSpacing extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarSpacing({
    super.key,
    required this.controller,
  });

  void _apply({
    int? before,
    int? after,
    int? line,
  }) {
    controller.applyParagraphFormat(
      WmlParagraphProps(
        spacingBefore: before,
        spacingAfter: after,
        explicitLineSpacing: line,
      ),
    );
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Paragraph spacing',
      icon: const Icon(Icons.format_line_spacing),
      onSelected: (value) {
        switch (value) {
          case 'compact':
            _apply(
              before: 0,
              after: 0,
              line: 240,
            );
            break;
          case 'normal':
            _apply(
              before: 0,
              after: 120,
              line: 276,
            );
            break;
          case 'wide':
            _apply(
              before: 0,
              after: 240,
              line: 360,
            );
            break;
          case 'before':
            _apply(before: 240);
            break;
          case 'after':
            _apply(after: 240);
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'compact',
          child: Text('Compact'),
        ),
        PopupMenuItem(
          value: 'normal',
          child: Text('Normal'),
        ),
        PopupMenuItem(
          value: 'wide',
          child: Text('Wide'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'before',
          child: Text('Add space before'),
        ),
        PopupMenuItem(
          value: 'after',
          child: Text('Add space after'),
        ),
      ],
    );
  }
}
