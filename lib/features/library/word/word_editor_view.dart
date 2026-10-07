import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordEditorView {
  const WordEditorView._();

  static void refresh(
    WordEditorController controller,
  ) {
    controller.relayout();
    controller.refresh();
  }

  static void zoomIn(
    WordEditorController controller,
  ) {
    final value = (controller.viewport.scale * 1.1).clamp(
      controller.viewport.clampMin,
      controller.viewport.clampMax,
    );

    controller.viewport.setScale(value);
    controller.refresh();
  }

  static void zoomOut(
    WordEditorController controller,
  ) {
    final value = (controller.viewport.scale / 1.1).clamp(
      controller.viewport.clampMin,
      controller.viewport.clampMax,
    );

    controller.viewport.setScale(value);
    controller.refresh();
  }

  static void actualSize(
    WordEditorController controller,
  ) {
    final value = 1.0.clamp(
      controller.viewport.clampMin,
      controller.viewport.clampMax,
    );

    controller.viewport.setScale(value);
    controller.refresh();
  }

  static Future<void> showMenu(
    BuildContext context,
    WordEditorController controller,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.zoom_in),
                title: const Text('Zoom In'),
                onTap: () {
                  zoomIn(controller);
                  Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.zoom_out),
                title: const Text('Zoom Out'),
                onTap: () {
                  zoomOut(controller);
                  Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.crop_free),
                title: const Text('Actual Size'),
                onTap: () {
                  actualSize(controller);
                  Navigator.of(sheetContext).pop();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Refresh Layout'),
                onTap: () {
                  refresh(controller);
                  Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
