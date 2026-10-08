import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarSpacing extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarSpacing({
    super.key,
    required this.controller,
  });

  void _apply({
    double? before,
    double? after,
    bool? explicitLine,
    double? line,
  }) {
    controller.applyParagraphFormat(
      (props) {
        if (before != null) {
          props.spacingBefore = before;
        }

        if (after != null) {
          props.spacingAfter = after;
        }

        if (explicitLine != null) {
          props.explicitLineSpacing = explicitLine;
        }

        if (line != null) {
          props.lineSpacing = line;
        }
      },
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
              explicitLine: true,
              line: 1,
            );
            break;
          case 'normal':
            _apply(
              before: 0,
              after: 8,
              explicitLine: false,
              line: 1.15,
            );
            break;
          case 'wide':
            _apply(
              before: 0,
              after: 16,
              explicitLine: true,
              line: 1.5,
            );
            break;
          case 'before':
            _apply(before: 12);
            break;
          case 'after':
            _apply(after: 12);
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
