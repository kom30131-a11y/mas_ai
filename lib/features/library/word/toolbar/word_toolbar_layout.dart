import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarLayout extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarLayout({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Page up',
          onPressed: controller.visiblePageIndex > 0
              ? () => controller.revealPage(
                    controller.visiblePageIndex - 1,
                  )
              : null,
          icon: const Icon(Icons.keyboard_arrow_up),
        ),
        IconButton(
          tooltip: 'Page down',
          onPressed: controller.visiblePageIndex <
                  controller.pageCount - 1
              ? () => controller.revealPage(
                    controller.visiblePageIndex + 1,
                  )
              : null,
          icon: const Icon(Icons.keyboard_arrow_down),
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
