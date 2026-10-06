import 'package:flutter/material.dart';

import '../../../core/database/database_repository.dart';

final _repo = DatabaseRepository.instance;

Future<String?> askSubjectName(
  BuildContext context, {
  String? initialValue,
  String title = 'New subject',
}) async {
  final controller = TextEditingController(
    text: initialValue,
  );

  final name = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Subject name',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = controller.text.trim();

            if (value.isNotEmpty) {
              Navigator.pop(context, value);
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );

  controller.dispose();
  return name;
}

Future<void> addSubject(
  BuildContext context,
  VoidCallback refresh,
) async {
  final name = await askSubjectName(context);

  if (name == null) return;

  await _repo.insertSubject({
    'name': name,
    'created_at': DateTime.now().toIso8601String(),
  });

  refresh();
}

Future<void> renameSubject(
  BuildContext context,
  Map<String, dynamic> item,
  VoidCallback refresh,
) async {
  final name = await askSubjectName(
    context,
    initialValue: item['name']?.toString(),
    title: 'Rename subject',
  );

  if (name == null) return;

  await _repo.renameSubject(
    subjectId: item['id'],
    name: name,
  );

  refresh();
}

Future<void> removeSubject(
  BuildContext context,
  Map<String, dynamic> item,
  VoidCallback refresh,
) async {
  final confirmed =
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete subject?'),
          content: const Text(
            'This subject will be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  if (!confirmed) return;

  await _repo.deleteSubject(
    item['id'],
  );

  refresh();
}
