import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/storage/library_storage_service.dart';
import '../code/code_editor_page.dart';
import '../content_viewer_page.dart';
import '../move/move_content_page.dart';
import '../text/text_editor_page.dart';
import '../word/word_viewer_page.dart';

Future<void> openContent(
  BuildContext context,
  Map<String, dynamic> item,
  int subjectId,
  int? folderId,
) async {
  final type =
      item['type']?.toString() ?? '';

  if (type == 'Text') {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TextEditorPage(
          subjectId: subjectId,
          folderId: folderId,
          item: item,
        ),
      ),
    );

    return;
  }

  final path =
      item['file_path']?.toString();

  if (path == null ||
      path.isEmpty ||
      !File(path).existsSync()) {
    _showMissingFile(context);
    return;
  }

  if (type == 'Code') {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CodeEditorPage(
          title:
              item['title']
                      ?.toString() ??
                  'Code',
          path: path,
          contentId:
              item['id'] as int,
        ),
      ),
    );

    return;
  }

  if (type == 'Word') {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            WordViewerPage(
          title:
              item['title']
                      ?.toString() ??
                  'Word',
          path: path,
          contentId:
              item['id'] as int?,
        ),
      ),
    );

    return;
  }

  if (type == 'PDF' ||
      type == 'Image' ||
      type == 'PowerPoint') {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ContentViewerPage(
          title:
              item['title']
                      ?.toString() ??
                  'Content',
          path: path,
          type: type,
          extractedText:
              item['content']
                  ?.toString(),
        ),
      ),
    );

    return;
  }

  _showUnsupportedFile(context);
}

void _showMissingFile(
  BuildContext context,
) {
  ScaffoldMessenger.of(context)
      .showSnackBar(
    const SnackBar(
      content: Text(
        'File is no longer available.',
      ),
    ),
  );
}

void _showUnsupportedFile(
  BuildContext context,
) {
  ScaffoldMessenger.of(context)
      .showSnackBar(
    const SnackBar(
      content: Text(
        'Preview is not available for this file.',
      ),
    ),
  );
}

Future<bool> moveContent(
  BuildContext context,
  Map<String, dynamic> item,
  int subjectId,
  int? folderId,
) async {
  final changed =
      await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) =>
          MoveContentPage(
        content: item,
        currentFolderId:
            folderId,
        subjectId:
            subjectId,
      ),
    ),
  );

  return changed == true;
}

Future<void> shareContent(
  Map<String, dynamic> item,
) async {
  final path =
      item['file_path']?.toString();

  if (path == null ||
      path.isEmpty) {
    return;
  }

  await LibraryStorageService
      .instance
      .shareFile(path);
}
