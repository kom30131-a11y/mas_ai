import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/storage/library_storage_service.dart';
import '../content_viewer_page.dart';
import '../move/move_content_page.dart';
import '../text/text_editor_page.dart';

Future<void> openContent(
  BuildContext context,
  Map<String, dynamic> item,
  int subjectId,
  int? folderId,
) async {
  if (item['type'] == 'Text') {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TextEditorPage(
          subjectId: subjectId,
          folderId: folderId,
          item: item,
        ),
      ),
    );
    return;
  }

  final path = item['file_path']?.toString();
  if (path == null || path.isEmpty || !File(path).existsSync()) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File is no longer available.')),
      );
    }
    return;
  }

  final type = item['type']?.toString() ?? '';
  final internal = {
    'PDF',
    'Word',
    'PowerPoint',
    'Image',
  };

  if (internal.contains(type)) {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContentViewerPage(
          title: item['title']?.toString() ?? 'Content',
          path: path,
          type: type,
          extractedText: item['content']?.toString(),
        ),
      ),
    );
    return;
  }

  await OpenFilex.open(path);
}

Future<bool> moveContent(
  BuildContext context,
  Map<String, dynamic> item,
  int subjectId,
  int? folderId,
) async {
  final changed = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => MoveContentPage(
        content: item,
        currentFolderId: folderId,
        subjectId: subjectId,
      ),
    ),
  );
  return changed == true;
}

Future<void> shareContent(Map<String, dynamic> item) async {
  final path = item['file_path']?.toString();
  if (path == null || path.isEmpty) return;
  await LibraryStorageService.instance.shareFile(path);
}
