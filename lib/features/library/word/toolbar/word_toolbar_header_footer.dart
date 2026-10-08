import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarHeaderFooter extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarHeaderFooter({
    super.key,
    required this.controller,
  });

  void _header() {
    controller.setMode(OfficeEditorMode.header);
    controller.refresh();
  }

  void _footer() {
    controller.setMode(OfficeEditorMode.footer);
    controller.refresh();
  }

  void _close() {
    controller.setMode(OfficeEditorMode.edit);
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Header',
          onPressed: _header,
          icon: const Icon(Icons.vertical_align_top),
        ),
        IconButton(
          tooltip: 'Footer',
          onPressed: _footer,
          icon: const Icon(Icons.vertical_align_bottom),
        ),
        if (controller.isEditingHeaderFooter)
          IconButton(
            tooltip: 'Close header/footer',
            onPressed: _close,
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }
}
