import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarColumns extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarColumns({
    super.key,
    required this.controller,
  });

  void _setColumns(int count) {
    controller.setSectionColumns(count);
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Columns',
      icon: const Icon(Icons.view_column),
      onSelected: _setColumns,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 1,
          child: Text('One column'),
        ),
        PopupMenuItem(
          value: 2,
          child: Text('Two columns'),
        ),
        PopupMenuItem(
          value: 3,
          child: Text('Three columns'),
        ),
      ],
    );
  }
}
