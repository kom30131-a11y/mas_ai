import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarSection extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarSection({
    super.key,
    required this.controller,
  });

  Future<void> _options(BuildContext context) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.vertical_align_top),
                title: const Text('Different first page'),
                onTap: () => Navigator.pop(
                  context,
                  'first',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.view_week),
                title: const Text('Different odd/even pages'),
                onTap: () => Navigator.pop(
                  context,
                  'odd_even',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Link to previous'),
                onTap: () => Navigator.pop(
                  context,
                  'link',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.view_column),
                title: const Text('Two columns'),
                onTap: () => Navigator.pop(
                  context,
                  'columns',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.watermark),
                title: const Text('Watermark'),
                onTap: () => Navigator.pop(
                  context,
                  'watermark',
                ),
              ),
            ],
          ),
        );
      },
    );

    if (value == null) return;

    switch (value) {
      case 'first':
        controller.setDifferentFirstPage(true);
        break;
      case 'odd_even':
        controller.setDifferentOddEven(true);
        break;
      case 'link':
        controller.setLinkToPrevious(false);
        break;
      case 'columns':
        controller.setSectionColumns(2);
        break;
      case 'watermark':
        controller.setWatermark(
          text: 'MedLibra',
        );
        break;
    }

    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Section',
      onPressed: () => _options(context),
      icon: const Icon(Icons.article_outlined),
    );
  }
}
