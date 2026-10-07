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
        top: twips,
        bottom: twips,
        left: twips,
        right: twips,
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
          value: 1080,
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
