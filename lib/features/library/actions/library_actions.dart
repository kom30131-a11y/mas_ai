import 'package:flutter/material.dart';

import '../../../core/database/database_repository.dart';
import '../../../core/storage/library_storage_service.dart';

final _repo =
    DatabaseRepository.instance;

final _storage =
    LibraryStorageService.instance;

Future<String?> askSubjectName(
  BuildContext context, {
  String? initialValue,
  String title = 'New subject',
}) async {
  final controller =
      TextEditingController(
    text: initialValue,
  );

  final name =
      await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration:
            const InputDecoration(
          labelText: 'Subject name',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context),
          child:
              const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value =
                controller.text.trim();

            if (value.isNotEmpty) {
              Navigator.pop(
                context,
                value,
              );
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
  final name =
      await askSubjectName(
    context,
  );

  if (name == null) {
    return;
  }

  final id =
      await _repo.insertSubject({
    'name': name,
    'created_at':
        DateTime.now()
            .toIso8601String(),
  });

  try {
    await _storage.subjectDirectory(
      id,
    );
  } catch (_) {
    await _repo.deleteSubject(id);
    rethrow;
  }

  refresh();
}

Future<void> renameSubject(
  BuildContext context,
  Map<String, dynamic> item,
  VoidCallback refresh,
) async {
  final name =
      await askSubjectName(
    context,
    initialValue:
        item['name']?.toString(),
    title: 'Rename subject',
  );

  if (name == null) {
    return;
  }

  final id =
      item['id'] as int;

  await _storage
      .renameSubjectDirectory(
    subjectId: id,
    newName: name,
  );

  await _repo.renameSubject(
    subjectId: id,
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
        builder: (_) =>
            AlertDialog(
          title:
              const Text(
            'Delete subject?',
          ),
          content:
              const Text(
            'This subject, its folders, and stored materials will be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              child:
                  const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  if (!confirmed) {
    return;
  }

  final id =
      item['id'] as int;

  await _storage
      .deleteSubjectDirectory(
    id,
  );

  await _repo.deleteSubject(id);

  refresh();
}
