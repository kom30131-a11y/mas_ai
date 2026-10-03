import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/database/database_repository.dart';

final repo = DatabaseRepository.instance;

class TextEditorPage extends StatefulWidget {
  final int subjectId;
  final int? folderId;
  final Map<String, dynamic>? item;

  const TextEditorPage({
    super.key,
    required this.subjectId,
    required this.folderId,
    this.item,
  });

  @override
  State<TextEditorPage> createState() => _TextEditorPageState();
}

class _TextEditorPageState extends State<TextEditorPage> {
  late final QuillController controller;
  late final TextEditingController titleController;

  bool rtl = false;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.item?['title']?.toString() ?? '',
    );

    controller = _createController();

    rtl = _detectArabic(
      controller.document.toPlainText(),
    );

    controller.addListener(_onTextChanged);
  }

  QuillController _createController() {
    final raw = widget.item?['content']?.toString() ?? '';

    if (raw.isNotEmpty) {
      try {
        final data = jsonDecode(raw);

        if (data is List) {
          return QuillController(
            document: Document.fromJson(
              List<Map<String, dynamic>>.from(data),
            ),
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
      } catch (_) {}
    }

    final document = Document();

    if (raw.trim().isNotEmpty) {
      document.insert(0, raw);
    }

    return QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  bool _detectArabic(String text) {
    final arabic = RegExp(r'[\u0600-\u06FF]');
    final latin = RegExp(r'[A-Za-z]');

    final arabicMatch = arabic.firstMatch(text);
    final latinMatch = latin.firstMatch(text);

    if (arabicMatch == null) return false;
    if (latinMatch == null) return true;

    return arabicMatch.start < latinMatch.start;
  }

  void _onTextChanged() {
    final text = controller.document.toPlainText();

    if (text.trim().isEmpty) return;

    final detected = _detectArabic(text);

    if (detected != rtl && mounted) {
      setState(() => rtl = detected);
    }
  }

  void _toggleDirection() {
    setState(() => rtl = !rtl);
  }

  Future<void> save() async {
    final title = titleController.text.trim();
    final plainText = controller.document.toPlainText().trim();

    if (title.isEmpty || plainText.isEmpty) return;

    final delta = jsonEncode(
      controller.document.toDelta().toJson(),
    );

    if (widget.item == null) {
      await repo.insertContent({
        'subject_id': widget.subjectId,
        'topic_id': null,
        'folder_id': widget.folderId,
        'title': title,
        'type': 'Text',
        'content': delta,
        'file_path': null,
        'original_file_name': null,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      await repo.updateContent(
        contentId: widget.item!['id'],
        title: title,
        content: delta,
      );
    }

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    controller.removeListener(_onTextChanged);
    controller.dispose();
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final direction =
        rtl ? TextDirection.rtl : TextDirection.ltr;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'New Note' : 'Edit Note',
        ),
        actions: [
          IconButton(
            tooltip: rtl
                ? 'Left to Right'
                : 'Right to Left',
            onPressed: _toggleDirection,
            icon: Icon(
              rtl
                  ? Icons.format_textdirection_r_to_l
                  : Icons.format_textdirection_l_to_r,
            ),
          ),
          IconButton(
            tooltip: 'Save',
            onPressed: save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              8,
            ),
            child: TextField(
              controller: titleController,
              textDirection: direction,
              textAlign:
                  rtl ? TextAlign.right : TextAlign.left,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: QuillSimpleToolbar(
              controller: controller,
              config: const QuillSimpleToolbarConfig(
                multiRowsDisplay: false,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Directionality(
              textDirection: direction,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: QuillEditor.basic(
                  controller: controller,
                  config: const QuillEditorConfig(
                    placeholder: 'Start writing...',
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
