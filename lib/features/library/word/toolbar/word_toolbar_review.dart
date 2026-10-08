import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarReview extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarReview({
    super.key,
    required this.controller,
  });

  Future<void> _review(BuildContext context) async {
    final revision = controller.selectedRevision;

    if (revision == null) {
      if (controller.hasTrackedChanges) {
        controller.stepRevision(1);
        controller.refresh();
      }
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check),
                title: const Text('Accept'),
                onTap: () => Navigator.pop(context, 'accept'),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Reject'),
                onTap: () => Navigator.pop(context, 'reject'),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || action == null) return;

    if (action == 'accept') {
      controller.acceptRevision(revision);
    } else {
      controller.rejectRevision(revision);
    }

    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final hasChanges = controller.hasTrackedChanges;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Previous change',
          onPressed: hasChanges
              ? () {
                  controller.stepRevision(-1);
                  controller.refresh();
                }
              : null,
          icon: const Icon(Icons.skip_previous),
        ),
        IconButton(
          tooltip: 'Next change',
          onPressed: hasChanges
              ? () {
                  controller.stepRevision(1);
                  controller.refresh();
                }
              : null,
          icon: const Icon(Icons.skip_next),
        ),
        IconButton(
          tooltip: 'Review change',
          onPressed: hasChanges
              ? () => _review(context)
              : null,
          icon: const Icon(Icons.rate_review),
        ),
        IconButton(
          tooltip: 'Accept all',
          onPressed: hasChanges
              ? () {
                  controller.acceptAllRevisions();
                  controller.refresh();
                }
              : null,
          icon: const Icon(Icons.done_all),
        ),
        IconButton(
          tooltip: 'Reject all',
          onPressed: hasChanges
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
