import 'dart:io';

import 'package:flutter/material.dart';

import '../content_viewer_page.dart';
import '../text/text_editor_page.dart';

Future<String?> ask(
  BuildContext context,
  String title, [
  String? old,
]) async {
  final controller = TextEditingController(text: old);

  final result = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
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
  return result;
}

Future<bool> sure(
  BuildContext context,
  String title,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
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
}

Future<String?> choose(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        [
          'PDF',
          'pdf',
          Icons.picture_as_pdf_outlined,
        ],
        [
          'Word',
          'word',
          Icons.description_outlined,
        ],
        [
          'PowerPoint',
          'ppt',
          Icons.slideshow_outlined,
        ],
        [
          'Text',
          'text',
          Icons.edit_note_outlined,
        ],
        [
          'Image',
          'image',
          Icons.image_outlined,
        ],
      ]
          .map(
            (item) => ListTile(
              leading: Icon(item[2] as IconData),
              title: Text(item[0] as String),
              onTap: () => Navigator.pop(
                context,
                item[1] as String,
              ),
            ),
          )
          .toList(),
    ),
  );
}

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

  if (path == null ||
      path.isEmpty ||
      !File(path).existsSync()) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'File is no longer available.',
          ),
        ),
      );
    }

    return;
  }

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ContentViewerPage(
        title: item['title']?.toString() ?? 'Content',
        path: path,
        type: item['type']?.toString() ?? '',
        extractedText: item['content']?.toString(),
      ),
    ),
  );
}
