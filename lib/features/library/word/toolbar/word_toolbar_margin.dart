import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarMargin extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarMargin({
    super.key,
    required this.controller,
  });

  void _setMargin(int twips) {
    controller.setPageMargins(
      WmlPageMargins(
        topTwips: twips,
        bottomTwips: twips,
        leftTwips: twips,
        rightTwips: twips,
      ),
    );
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Margins',
      icon: const Icon(Icons.space_bar),
      onSelected: _setMargin,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 720,
          child: Text('Narrow'),
        ),
        PopupMenuItem(
          value: 1134,
          child: Text('Normal'),
        ),
        PopupMenuItem(
          value: 1440,
          child: Text('Wide'),
        ),
      ],
    );
  }
}

2. "lib/features/library/word/toolbar/word_toolbar_page.dart"

:::writing{variant="document" id="28591" title="word_toolbar_page.dart"}

import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarPage extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarPage({
    super.key,
    required this.controller,
  });

  Future<void> _pageSize(BuildContext context) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.crop_portrait),
                title: const Text('A4 Portrait'),
                onTap: () => Navigator.pop(context, 'portrait'),
              ),
              ListTile(
                leading: const Icon(Icons.crop_landscape),
                title: const Text('A4 Landscape'),
                onTap: () => Navigator.pop(context, 'landscape'),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || value == null) return;

    controller.setPageSize(
      value == 'portrait'
          ? const WmlPageSize(
              width: 595.28,
              height: 841.89,
            )
          : const WmlPageSize(
              width: 841.89,
              height: 595.28,
            ),
    );

    controller.refresh();
  }

  Future<void> _orientation(BuildContext context) async {
    final value = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.stay_current_portrait),
                title: const Text('Portrait'),
                onTap: () => Navigator.pop(context, false),
              ),
              ListTile(
                leading: const Icon(Icons.stay_current_landscape),
                title: const Text('Landscape'),
                onTap: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || value == null) return;

    controller.setPageLandscape(value);
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Page size',
          onPressed: () => _pageSize(context),
          icon: const Icon(Icons.description_outlined),
        ),
        IconButton(
          tooltip: 'Orientation',
          onPressed: () => _orientation(context),
          icon: const Icon(Icons.screen_rotation),
        ),
        IconButton(
          tooltip: 'Relayout',
          onPressed: () {
            controller.relayout();
            controller.refresh();
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

3. "lib/features/library/word/toolbar/word_toolbar_paragraph.dart"

:::writing{variant="document" id="74216" title="word_toolbar_paragraph.dart"}

import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarParagraph extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarParagraph({
    super.key,
    required this.controller,
  });

  void _align(WmlJustification value) {
    controller.applyParagraphFormat(
      (props) {
        props.justification = value;
      },
    );
    controller.refresh();
  }

  void _indent(double value) {
    controller.setParagraphIndent(
      left: value,
    );
    controller.refresh();
  }

  void _list(bool numbered) {
    controller.toggleList(
      numbered: numbered,
    );
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Align left',
          onPressed: () => _align(WmlJustification.left),
          icon: const Icon(Icons.format_align_left),
        ),
        IconButton(
          tooltip: 'Center',
          onPressed: () => _align(WmlJustification.center),
          icon: const Icon(Icons.format_align_center),
        ),
        IconButton(
          tooltip: 'Align right',
          onPressed: () => _align(WmlJustification.right),
          icon: const Icon(Icons.format_align_right),
        ),
        IconButton(
          tooltip: 'Justify',
          onPressed: () => _align(WmlJustification.both),
          icon: const Icon(Icons.format_align_justify),
        ),
        IconButton(
          tooltip: 'Bulleted list',
          onPressed: () => _list(false),
          icon: const Icon(Icons.format_list_bulleted),
        ),
        IconButton(
          tooltip: 'Numbered list',
          onPressed: () => _list(true),
          icon: const Icon(Icons.format_list_numbered),
        ),
        IconButton(
          tooltip: 'Increase indent',
          onPressed: () => _indent(36),
          icon: const Icon(Icons.format_indent_increase),
        ),
        IconButton(
          tooltip: 'Decrease indent',
          onPressed: () => _indent(0),
          icon: const Icon(Icons.format_indent_decrease),
        ),
      ],
    );
  }
}

4. "lib/features/library/word/toolbar/word_toolbar_paragraph_format.dart"

:::writing{variant="document" id="35184" title="word_toolbar_paragraph_format.dart"}

import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarParagraphFormat extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarParagraphFormat({
    super.key,
    required this.controller,
  });

  void _apply(WmlJustification justification) {
    controller.applyParagraphFormat(
      (props) {
        props.justification = justification;
      },
    );
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<WmlJustification>(
      tooltip: 'Paragraph alignment',
      icon: const Icon(Icons.format_align_left),
      onSelected: _apply,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: WmlJustification.left,
          child: Row(
            children: [
              Icon(Icons.format_align_left),
              SizedBox(width: 12),
              Text('Align left'),
            ],
          ),
        ),
        PopupMenuItem(
          value: WmlJustification.center,
          child: Row(
            children: [
              Icon(Icons.format_align_center),
              SizedBox(width: 12),
              Text('Center'),
            ],
          ),
        ),
        PopupMenuItem(
          value: WmlJustification.right,
          child: Row(
            children: [
              Icon(Icons.format_align_right),
              SizedBox(width: 12),
              Text('Align right'),
            ],
          ),
        ),
        PopupMenuItem(
          value: WmlJustification.both,
          child: Row(
            children: [
              Icon(Icons.format_align_justify),
              SizedBox(width: 12),
              Text('Justify'),
            ],
          ),
        ),
      ],
    );
  }
}

5. "lib/features/library/word/toolbar/word_toolbar_spacing.dart"

:::writing{variant="document" id="80953" title="word_toolbar_spacing.dart"}

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
