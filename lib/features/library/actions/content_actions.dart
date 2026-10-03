import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/database_repository.dart';
import '../widgets/library_helpers.dart';

final _repo = DatabaseRepository.instance;

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

    final file = result.files.first;
    final path = file.path;

    if (path == null || path.isEmpty) return;

    final now = DateTime.now().toIso8601String();

    final id = await _repo.insertContent({
      'subject_id': subjectId,
      'topic_id': null,
      'folder_id': folderId,
      'title': p.basenameWithoutExtension(path),
      'type': typeName(type),
      'content': '',
      'file_path': path,
      'original_file_name': file.name,
      'created_at': now,
    });

    await _repo.insertFile({
      'content_id': id,
      'file_name': file.name,
      'file_path': path,
      'mime_type': mimeType(type),
      'file_size': file.size,
      'extracted_text': null,
      'created_at': now,
    });
  } catch (_) {}
}

Future<void> editContent(
  BuildContext context,
  Map<String, dynamic> item,
  VoidCallback refresh,
) async {
  final controller = TextEditingController(
    text: item['title']?.toString(),
  );

  final name = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Rename'),
      content: TextField(
        controller: controller,
        autofocus: true,
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

  if (name == null) return;

  await _repo.updateContent(
    contentId: item['id'],
    title: name,
  );

  refresh();
}

Future<void> removeContent(
  BuildContext context,
  Map<String, dynamic> item,
  VoidCallback refresh,
) async {
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete content?'),
          content: const Text(
            'This item will be deleted.',
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

  if (!confirmed) return;

  await _repo.deleteContent(item['id']);
  refresh();
}
