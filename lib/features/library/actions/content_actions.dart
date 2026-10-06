import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/database_repository.dart';
import '../../../core/storage/library_storage_service.dart';
import '../widgets/library_helpers.dart';

final repo =
    DatabaseRepository.instance;

final storage =
    LibraryStorageService.instance;

Future<void> pickFile(
  String type,
  int subjectId,
  int? folderId,
) async {
  final ext = {
    'pdf': ['pdf'],
    'word': ['doc', 'docx'],
    'ppt': ['ppt', 'pptx'],
    'image': [
      'jpg',
      'jpeg',
      'png',
      'webp',
      'heic',
    ],
    'epub': ['epub'],
    'textfile': ['txt'],
    'html': ['html', 'htm'],
    'fb2': ['fb2'],
    'fb2zip': ['zip'],
    'djvu': ['djvu', 'djv'],
    'mobi': ['mobi'],
    'code': [
      'dart',
      'py',
      'js',
      'ts',
      'java',
      'kt',
      'kts',
      'c',
      'h',
      'cpp',
      'hpp',
      'cs',
      'go',
      'rs',
      'php',
      'swift',
      'rb',
      'sh',
      'bash',
      'sql',
      'json',
      'xml',
      'yaml',
      'yml',
      'css',
      'scss',
      'html',
      'md',
      'vue',
      'jsx',
      'tsx',
    ],
  }[type];

  if (ext == null) return;

  try {
    final result =
        await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ext,
    );

    if (result == null ||
        result.files.isEmpty) {
      return;
    }

    final f = result.files.first;

    final sourcePath = f.path;

    if (sourcePath == null ||
        sourcePath.isEmpty) {
      return;
    }

    final ready =
        await storage.ensureReady(
      requestPermission: true,
    );

    if (!ready) return;

    final storedPath =
        await storage.copyImportedFile(
      sourcePath: sourcePath,
      folderId: folderId,
      originalName: f.name,
    );

    final now =
        DateTime.now()
            .toIso8601String();

    final title =
        f.name.replaceFirst(
      RegExp(r'\.[^.]+$'),
      '',
    );

    final id =
        await repo.insertContent({
      'subject_id': subjectId,
      'topic_id': null,
      'folder_id': folderId,
      'title': title,
      'type': typeName(type),
      'content': '',
      'file_path': storedPath,
      'original_file_name':
          f.name,
      'created_at': now,
    });

    final hash =
        await storage.hashFile(
      storedPath,
    );

    final file =
        File(storedPath);

    await repo.insertFile({
      'content_id': id,
      'file_name': f.name,
      'file_path': storedPath,
      'mime_type':
          mimeType(type),
      'file_size':
          await file.length(),
      'extracted_text': null,
      'file_hash': hash,
      'created_at': now,
    });
  } catch (_) {}
}

Future<void> editContent(
  BuildContext c,
  Map<String, dynamic> x,
  VoidCallback refresh,
) async {
  final controller =
      TextEditingController(
    text:
        x['title']?.toString() ??
            '',
  );

  final name =
      await showDialog<String>(
    context: c,
    builder: (_) => AlertDialog(
      title:
          const Text('Rename'),
      content: TextField(
        controller: controller,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(c),
          child:
              const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value =
                controller.text
                    .trim();

            if (value.isNotEmpty) {
              Navigator.pop(
                c,
                value,
              );
            }
          },
          child:
              const Text('Save'),
        ),
      ],
    ),
  );

  controller.dispose();

  if (name == null) return;

  await repo.updateContent(
    contentId: x['id'] as int,
    title: name,
  );

  refresh();
}

Future<void> removeContent(
  BuildContext c,
  Map<String, dynamic> x,
  VoidCallback refresh,
) async {
  final confirmed =
      await showDialog<bool>(
            context: c,
            builder: (_) =>
                AlertDialog(
              title: const Text(
                'Delete content?',
              ),
              content:
                  const Text(
                'The file and its library entry will be deleted.',
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                    c,
                    false,
                  ),
                  child:
                      const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(
                    c,
                    true,
                  ),
                  child:
                      const Text('Delete'),
                ),
              ],
            ),
          ) ??
          false;

  if (!confirmed) return;

  final path =
      x['file_path']?.toString();

  if (path != null &&
      path.isNotEmpty) {
    final file = File(path);

    if (await file.exists()) {
      await file.delete();
    }
  }

  await repo.deleteContent(
    x['id'] as int,
  );

  refresh();
}
