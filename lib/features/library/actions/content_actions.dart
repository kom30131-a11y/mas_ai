import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/database/database_repository.dart';
import '../widgets/library_helpers.dart';

final repo = DatabaseRepository.instance;

Future<void> pickFile(
  String type,
  int subjectId,
  int? folderId,
) async {
  final ext = {
    'pdf': ['pdf'],
    'word': ['doc', 'docx'],
    'ppt': ['ppt', 'pptx'],
    'image': ['jpg', 'jpeg', 'png', 'webp'],
  }[type];

  if (ext == null) return;

  try {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ext,
    );

    if (result == null || result.files.isEmpty) return;

    final f = result.files.first;
    final path = f.path;

    if (path == null || path.isEmpty) return;

    final now = DateTime.now().toIso8601String();

    final id = await repo.insertContent({
      'subject_id': subjectId,
      'topic_id': null,
      'folder_id': folderId,
      'title': f.name.replaceFirst(
        RegExp(r'\.[^.]+$'),
        '',
      ),
      'type': typeName(type),
      'content': '',
      'file_path': path,
      'original_file_name': f.name,
      'created_at': now,
    });

    await repo.insertFile({
      'content_id': id,
      'file_name': f.name,
      'file_path': path,
      'mime_type': mimeType(type),
      'file_size': f.size,
      'extracted_text': null,
      'created_at': now,
    });
  } catch (_) {}
}

Future<void> editContent(
  BuildContext c,
  Map<String, dynamic> x,
  VoidCallback refresh,
) async {
  final controller = TextEditingController(
    text: x['title']?.toString() ?? '',
  );

  final name = await showDialog<String>(
    context: c,
    builder: (_) => AlertDialog(
      title: const Text('Rename'),
      content: TextField(
        controller: controller,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = controller.text.trim();
            if (value.isNotEmpty) {
              Navigator.pop(c, value);
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );

  controller.dispose();

  if (name == null) return;

  await repo.updateContent(
    contentId: x['id'],
    title: name,
  );

  refresh();
}

Future<void> removeContent(
  BuildContext c,
  Map<String, dynamic> x,
  VoidCallback refresh,
) async {
  final confirmed = await showDialog<bool>(
        context: c,
        builder: (_) => AlertDialog(
          title: const Text('Delete content?'),
          content: const Text('This item will be deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  if (!confirmed) return;

  await repo.deleteContent(x['id']);
  refresh();
}
