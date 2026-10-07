import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarReview extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarReview({
    super.key,
    required this.controller,
  });

  Future<void> _revisions(BuildContext context) async {
    if (!controller.hasTrackedChanges) return;

    final revision = controller.selectedRevision;

    if (revision == null) {
      controller.stepRevision(forward: true);
      controller.refresh();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check),
                title: const Text('Accept'),
                onTap: () {
                  controller.acceptRevision(revision.id);
                  controller.refresh();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Reject'),
                onTap: () {
                  controller.rejectRevision(revision.id);
                  controller.refresh();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Previous change',
          onPressed: controller.hasTrackedChanges
              ? () {
                  controller.stepRevision(forward: false);
                  controller.refresh();
                }
              : null,
          icon: const Icon(Icons.skip_previous),
        ),
        IconButton(
          tooltip: 'Next change',
          onPressed: controller.hasTrackedChanges
              ? () {
                  controller.stepRevision(forward: true);
                  controller.refresh();
                }
              : null,
          icon: const Icon(Icons.skip_next),
        ),
        IconButton(
          tooltip: 'Accept or reject change',
          onPressed: controller.hasTrackedChanges
              ? () => _revisions(context)
              : null,
          icon: const Icon(Icons.rate_review),
        ),
        IconButton(
          tooltip: 'Accept all changes',
          onPressed: controller.hasTrackedChanges
              ? () {
                  controller.acceptAllRevisions();
                  controller.refresh();
                }
              : null,
          icon: const Icon(Icons.done_all),
        ),
        IconButton(
          tooltip: 'Reject all changes',
          onPressed: controller.hasTrackedChanges
              ? () {
                  controller.rejectAllRevisions();
                  controller.refresh();
                }
              : null,
          icon: const Icon(Icons.clear_all),
        ),
      ],
    );
  }
}
