import 'package:flutter/material.dart';

import '../../../core/database/database_repository.dart';
import '../../../core/storage/library_storage_service.dart';

final _repo = DatabaseRepository.instance;
final _storage = LibraryStorageService.instance;

Future<bool> _storageReady(BuildContext context) async {
  final ready = await _storage.ensureReady(requestPermission: true);
  if (ready || !context.mounted) return ready;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Storage permission is required.')),
  );
  return false;
}

Future<String?> askSubjectName(
  BuildContext context, {
  String? initialValue,
  String title = 'New subject',
}) async {
  final controller = TextEditingController(text: initialValue);
  final name = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = controller.text.trim();
            if (value.isNotEmpty) Navigator.pop(context, value);
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
  if (name == null || !await _storageReady(context)) return;

  final existing = await _repo.getSubjects();
  final duplicate = existing.any(
    (item) => item['name']?.toString().trim().toLowerCase() ==
        name.trim().toLowerCase(),
  );

  if (duplicate) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A subject with this name already exists.')),
    );
    return;
  }

  final id = await _repo.insertSubject({
    'name': name,
    'created_at': DateTime.now().toIso8601String(),
  });

  await _storage.subjectDirectory(id);
  if (context.mounted) refresh();
}

Future<void> renameSubject(
  BuildContext context,
  Map<String, dynamic> item,
  VoidCallback refresh,
) async {
  final oldName = item['name']?.toString() ?? 'Subject';
  final name = await askSubjectName(
    context,
    initialValue: oldName,
    title: 'Rename subject',
  );
  if (name == null || name == oldName || !await _storageReady(context)) return;

  final existing = await _repo.getSubjects();
  final duplicate = existing.any(
    (other) =>
        other['id'] != item['id'] &&
        other['name']?.toString().trim().toLowerCase() ==
            name.trim().toLowerCase(),
  );

  if (duplicate) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A subject with this name already exists.')),
    );
    return;
  }

  await _storage.renameSubjectDirectory(oldName: oldName, newName: name);
  await _repo.renameSubject(subjectId: item['id'] as int, name: name);
  if (context.mounted) refresh();
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
            'The subject, its database entries, and its stored files will be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  if (!confirmed || !await _storageReady(context)) return;

  await _storage.deleteSubjectDirectory(item['id'] as int);
  await _repo.deleteSubject(item['id'] as int);
  if (context.mounted) refresh();
}
