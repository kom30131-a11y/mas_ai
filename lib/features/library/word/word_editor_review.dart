import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordEditorReview {
  const WordEditorReview._();

  static void trackChanges(
    WordEditorController controller,
    bool enabled,
  ) {
    controller.setTrackRevisions(enabled);
    controller.refresh();
  }

  static void acceptSelected(
    WordEditorController controller,
  ) {
    final revision = controller.selectedRevision;
    if (revision == null) return;

    controller.acceptRevision(revision);
    controller.refresh();
  }

  static void rejectSelected(
    WordEditorController controller,
  ) {
    final revision = controller.selectedRevision;
    if (revision == null) return;

    controller.rejectRevision(revision);
    controller.refresh();
  }

  static void acceptAll(
    WordEditorController controller,
  ) {
    controller.acceptAllRevisions();
    controller.refresh();
  }

  static void rejectAll(
    WordEditorController controller,
  ) {
    controller.rejectAllRevisions();
    controller.refresh();
  }

  static void next(
    WordEditorController controller,
  ) {
    if (!controller.hasTrackedChanges) return;

    controller.stepRevision(1);
    controller.refresh();
  }

  static void previous(
    WordEditorController controller,
  ) {
    if (!controller.hasTrackedChanges) return;

    controller.stepRevision(-1);
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
              SwitchListTile(
                secondary: const Icon(Icons.track_changes),
                title: const Text('Track Changes'),
                value: controller.hasTrackedChanges,
                onChanged: (value) {
                  trackChanges(controller, value);
                  Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.keyboard_arrow_up),
                title: const Text('Previous Change'),
                onTap: () {
                  previous(controller);
                  Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.keyboard_arrow_down),
                title: const Text('Next Change'),
                onTap: () {
                  next(controller);
                  Navigator.of(sheetContext).pop();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.check),
                title: const Text('Accept Selected'),
                enabled: controller.selectedRevision != null,
                onTap: () {
                  acceptSelected(controller);
                  Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Reject Selected'),
                enabled: controller.selectedRevision != null,
                onTap: () {
                  rejectSelected(controller);
                  Navigator.of(sheetContext).pop();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.done_all),
                title: const Text('Accept All'),
                onTap: () {
                  acceptAll(controller);
                  Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear_all),
                title: const Text('Reject All'),
                onTap: () {
                  rejectAll(controller);
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
