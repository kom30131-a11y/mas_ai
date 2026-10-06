import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/database_repository.dart';
import '../../../core/storage/library_storage_service.dart';

final repo = DatabaseRepository.instance;
final storage = LibraryStorageService.instance;

Future<void> pickFile(
  String type,
  int subjectId,
  int? folderId,
) async {
  final extensions = <String>[
    if (type == 'pdf') 'pdf',
    if (type == 'word') ...[
      'doc',
      'docx',
    ],
    if (type == 'ppt') ...[
      'ppt',
      'pptx',
    ],
    if (type == 'image') ...[
      'jpg',
      'jpeg',
      'png',
      'webp',
      'heic',
    ],
    if (type == 'epub') 'epub',
    if (type == 'textfile') 'txt',
    if (type == 'html') ...[
      'html',
      'htm',
    ],
    if (type == 'fb2') 'fb2',
    if (type == 'fb2zip') 'zip',
    if (type == 'djvu') ...[
      'djvu',
      'djv',
    ],
    if (type == 'mobi') 'mobi',
    if (type == 'code') ...[
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
  ];

  if (extensions.isEmpty) return;

  try {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );

    if (result == null ||
        result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    final sourcePath = file.path;

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
      subjectId: subjectId,
      folderId: folderId,
      originalName: file.name,
    );

    final storedFile =
        File(storedPath);

    final now =
        DateTime.now().toIso8601String();

    final contentId =
        await repo.insertContent({
      'subject_id': subjectId,
      'topic_id': null,
      'folder_id': folderId,
      'title':
          p.basenameWithoutExtension(
        file.name,
      ),
      'type': typeName(type),
      'content': '',
      'file_path': storedPath,
      'original_file_name': file.name,
      'created_at': now,
    });

    await repo.insertFile({
      'content_id': contentId,
      'file_name': file.name,
      'file_path': storedPath,
      'mime_type': mimeType(type),
      'file_size':
          await storedFile.length(),
      'extracted_text': null,
      'file_hash':
          await storage.hashFile(
        storedPath,
      ),
      'created_at': now,
    });
  } catch (_) {}
}

Future<void> editContent(
  BuildContext context,
  Map<String, dynamic> item,
  VoidCallback refresh,
) async {
  final controller =
      TextEditingController(
    text: item['title']?.toString() ?? '',
  );

  final name =
      await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Rename'),
      content: TextField(
        controller: controller,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context),
          child: const Text('Cancel'),
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

  if (name == null) return;

  await storage.renameContentFile(
    content: item,
    newTitle: name,
  );

  await repo.updateContent(
    contentId: item['id'] as int,
    title: name,
  );

  refresh();
}

Future<void> removeContent(
  BuildContext context,
  Map<String, dynamic> item,
  VoidCallback refresh,
) async {
  final confirmed =
      await showDialog<bool>(
            context: context,
            builder: (_) =>
                AlertDialog(
              title: const Text(
                'Delete content?',
              ),
              content: const Text(
                'The material and its stored file will be deleted.',
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

  if (!confirmed) return;

  await storage.deleteContentFile(
    item,
  );

  await repo.deleteContent(
    item['id'] as int,
  );

  refresh();
}

Future<void> shareContent(
  BuildContext context,
  Map<String, dynamic> item,
) async {
  final path =
      item['file_path']?.toString();

  if (path == null ||
      path.isEmpty ||
      !await File(path).exists()) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'File is no longer available.',
          ),
        ),
      );
    }

    return;
  }

  await storage.shareFile(path);
}

String typeName(String type) =>
    {
      'pdf': 'PDF',
      'word': 'Word',
      'ppt': 'PowerPoint',
      'image': 'Image',
      'epub': 'EPUB',
      'textfile': 'Text file',
      'html': 'HTML',
      'fb2': 'FB2',
      'fb2zip': 'FB2 ZIP',
      'djvu': 'DJVU',
      'mobi': 'MOBI',
      'code': 'Code',
    }[type] ??
    'Text';

String? mimeType(String type) =>
    {
      'pdf': 'application/pdf',
      'word':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'ppt':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'image': 'image/*',
      'epub':
          'application/epub+zip',
      'textfile': 'text/plain',
      'html': 'text/html',
      'fb2':
          'application/x-fictionbook+xml',
      'fb2zip':
          'application/zip',
      'djvu':
          'image/vnd.djvu',
      'mobi':
          'application/x-mobipocket-ebook',
      'code': 'text/plain',
    }[type];
