import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarMargin extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarMargin({
    super.key,
    required this.controller,
  });

  void _setMargin(WmlPageMargins margins) {
    controller.setPageMargins(margins);
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<WmlPageMargins>(
      tooltip: 'Margins',
      icon: const Icon(Icons.space_bar),
      onSelected: _setMargin,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: WmlPageMargins.narrow,
          child: Text('Narrow'),
        ),
        PopupMenuItem(
          value: WmlPageMargins.normal,
          child: Text('Normal'),
        ),
        PopupMenuItem(
          value: WmlPageMargins.wide,
          child: Text('Wide'),
        ),
      ],
    );
  }
}
