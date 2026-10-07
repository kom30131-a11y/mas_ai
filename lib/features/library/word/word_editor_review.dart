import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordEditorReview {
  const WordEditorReview._();

  static void enableTrackChanges(
    WordEditorController c,
    bool enabled,
  ) {
    c.setTrackRevisions(enabled);
    c.refresh();
  }

  static void acceptAll(
    WordEditorController c,
  ) {
    c.acceptAllRevisions();
    c.refresh();
  }

  static void rejectAll(
    WordEditorController c,
  ) {
    c.rejectAllRevisions();
    c.refresh();
  }

  static void acceptSelected(
    WordEditorController c,
  ) {
    final revision = c.selectedRevision;
    if (revision == null) return;

    c.acceptRevision(revision);
    c.refresh();
  }

  static void rejectSelected(
    WordEditorController c,
  ) {
    final revision = c.selectedRevision;
    if (revision == null) return;

    c.rejectRevision(revision);
    c.refresh();
  }

  static void previousRevision(
    WordEditorController c,
  ) {
    if (c.document.revisions.isEmpty) return;
    c.stepRevision(-1);
    c.refresh();
  }

  static void nextRevision(
    WordEditorController c,
  ) {
    if (c.document.revisions.isEmpty) return;
    c.stepRevision(1);
    c.refresh();
  }

  static Future<void> showReviewMenu(
    BuildContext context,
    WordEditorController c,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final tracked = c.hasTrackedChanges;
        final count = c.document.revisions.length;

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.track_changes),
                title: const Text('Track Changes'),
                value: tracked,
                onChanged: (value) {
                  enableTrackChanges(c, value);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.keyboard_arrow_up),
                title: const Text('Previous change'),
                enabled: count > 0,
                onTap: () {
                  previousRevision(c);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.keyboard_arrow_down),
                title: const Text('Next change'),
                enabled: count > 0,
                onTap: () {
                  nextRevision(c);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Accept selected change'),
                enabled: c.selectedRevision != null,
                onTap: () {
                  acceptSelected(c);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined),
                title: const Text('Reject selected change'),
                enabled: c.selectedRevision != null,
                onTap: () {
                  rejectSelected(c);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.done_all),
                title: const Text('Accept all changes'),
                enabled: count > 0,
                onTap: () {
                  acceptAll(c);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear_all),
                title: const Text('Reject all changes'),
                enabled: count > 0,
                onTap: () {
                  rejectAll(c);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
