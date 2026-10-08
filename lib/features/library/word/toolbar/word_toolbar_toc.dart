import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarToc extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarToc({
    super.key,
    required this.controller,
  });

  void _insert() {
    controller.insertTableOfContents();
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Table of contents',
      onPressed: _insert,
      icon: const Icon(Icons.list_alt),
    );
  }
}
