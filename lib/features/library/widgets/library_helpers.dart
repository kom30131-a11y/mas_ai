import 'package:flutter/material.dart';

IconData contentIcon(String? type) =>
    switch (type) {
      'PDF' =>
        Icons.picture_as_pdf_outlined,
      'Word' =>
        Icons.description_outlined,
      'PowerPoint' =>
        Icons.slideshow_outlined,
      'Image' =>
        Icons.image_outlined,
      'EPUB' =>
        Icons.menu_book_outlined,
      'Text file' =>
        Icons.article_outlined,
      'HTML' =>
        Icons.language_outlined,
      'FB2' =>
        Icons.book_outlined,
      'FB2 ZIP' =>
        Icons.archive_outlined,
      'DJVU' =>
        Icons.picture_as_pdf_outlined,
      'MOBI' =>
        Icons.book_online_outlined,
      'Code' =>
        Icons.code_rounded,
      'Text' =>
        Icons.article_outlined,
      _ =>
        Icons.insert_drive_file_outlined,
    };

IconData typeIcon(String type) =>
    contentIcon(type);

String typeLabel(String type) =>
    {
      'Image': 'Images',
      'Code': 'Code',
    }[type] ??
    type;

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

Future<String?> choose(
  BuildContext context,
) {
  final items = const [
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
      'Code',
      'code',
      Icons.code_rounded,
    ],
    [
      'EPUB',
      'epub',
      Icons.menu_book_outlined,
    ],
    [
      'TXT',
      'textfile',
      Icons.article_outlined,
    ],
    [
      'HTML',
      'html',
      Icons.language_outlined,
    ],
    [
      'FB2',
      'fb2',
      Icons.book_outlined,
    ],
    [
      'FB2 ZIP',
      'fb2zip',
      Icons.archive_outlined,
    ],
    [
      'DJVU',
      'djvu',
      Icons.picture_as_pdf_outlined,
    ],
    [
      'MOBI',
      'mobi',
      Icons.book_online_outlined,
    ],
    [
      'Image',
      'image',
      Icons.image_outlined,
    ],
    [
      'Text editor',
      'text',
      Icons.edit_note_outlined,
    ],
  ];

  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: items.length,
        itemBuilder: (_, index) {
          final item =
              items[index];

          return ListTile(
            leading: Icon(
              item[2] as IconData,
            ),
            title: Text(
              item[0] as String,
            ),
            onTap: () =>
                Navigator.pop(
              context,
              item[1] as String,
            ),
          );
        },
      ),
    ),
  );
}
