import 'package:flutter/material.dart';

IconData contentIcon(String? type) => switch (type) {
      'PDF' => Icons.picture_as_pdf_outlined,
      'Word' => Icons.description_outlined,
      'PowerPoint' => Icons.slideshow_outlined,
      'Image' => Icons.image_outlined,
      'Text' => Icons.article_outlined,
      _ => Icons.insert_drive_file_outlined,
    };

IconData typeIcon(String type) => contentIcon(type);

String typeLabel(String type) => {
      'Image': 'Images',
    }[type] ??
    type;

String typeName(String type) => {
      'pdf': 'PDF',
      'word': 'Word',
      'ppt': 'PowerPoint',
      'image': 'Image',
    }[type] ??
    'Text';

String? mimeType(String type) => {
      'pdf': 'application/pdf',
      'word': 'application/msword',
      'ppt': 'application/vnd.ms-powerpoint',
      'image': 'image/*',
    }[type];
