import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/database/database_repository.dart';
import 'widgets/document_surface.dart';

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
  late final FocusNode editorFocusNode;
  late final ScrollController editorScrollController;

  String handwritingData = '';
  bool rtl = false;
  bool penMode = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(
      text: widget.item?['title']?.toString() ?? '',
    );
    editorFocusNode = FocusNode();
    editorScrollController = ScrollController();
    controller = _loadDocument();
    rtl = _detectDirection(controller.document.toPlainText());
  }

  QuillController _loadDocument() {
    final raw = widget.item?['content']?.toString() ?? '';

    if (raw.trim().isEmpty) {
      return QuillController.basic();
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is Map) {
        final text = decoded['text'];
        final ink = decoded['handwriting'];

        if (ink is List) {
          handwritingData = jsonEncode(ink);
        }

        if (text is List) {
          return _fromDocument(
            Document.fromJson(
              List<Map<String, dynamic>>.from(text),
            ),
          );
        }
      }

      if (decoded is List) {
        return _fromDocument(
          Document.fromJson(
            List<Map<String, dynamic>>.from(decoded),
          ),
        );
      }
    } catch (_) {}

    return _fromDocument(
      Document()..insert(0, raw),
    );
  }

  QuillController _fromDocument(Document doc) {
    return QuillController(
      document: doc,
      selection: TextSelection.collapsed(
        offset: doc.length > 0 ? doc.length - 1 : 0,
      ),
    );
  }

  bool _detectDirection(String text) {
    final a = RegExp(r'[\u0600-\u06FF]').firstMatch(text);
    final l = RegExp(r'[A-Za-z]').firstMatch(text);

    if (a == null) {
      return false;
    }

    if (l == null) {
      return true;
    }

    return a.start < l.start;
  }

  void _toggleDirection() {
    setState(() => rtl = !rtl);
  }

  void _togglePen() {
    setState(() {
      penMode = !penMode;

      if (penMode) {
        editorFocusNode.unfocus();
      } else {
        editorFocusNode.requestFocus();
      }
    });
  }

  Future<void> _save() async {
    if (saving) {
      return;
    }

    final title = titleController.text.trim();
    final text = controller.document.toPlainText().trim();

    if (title.isEmpty) {
      _msg('Please enter a title.');
      return;
    }

    if (text.isEmpty && handwritingData.isEmpty) {
      _msg('Please write something first.');
      return;
    }

    setState(() => saving = true);

    try {
      final content = jsonEncode({
        'text': controller.document.toDelta().toJson(),
        'handwriting': handwritingData.isEmpty
            ? []
            : jsonDecode(handwritingData),
      });

      if (widget.item == null) {
        await repo.insertContent({
          'subject_id': widget.subjectId,
          'topic_id': null,
          'folder_id': widget.folderId,
          'title': title,
          'type': 'Text',
          'content': content,
          'file_path': null,
          'original_file_name': null,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        await repo.updateContent(
          contentId: widget.item!['id'],
          title: title,
          content: content,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        _msg('Could not save the note.');
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    titleController.dispose();
    editorFocusNode.dispose();
    editorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'New Note' : 'Edit Note',
        ),
        actions: [
          IconButton(
            tooltip: rtl ? 'Left to Right' : 'Right to Left',
            onPressed: _toggleDirection,
            icon: Icon(
              rtl
                  ? Icons.format_textdirection_r_to_l
                  : Icons.format_textdirection_l_to_r,
            ),
          ),
          IconButton(
            tooltip: penMode ? 'Text' : 'Pen',
            onPressed: _togglePen,
            icon: Icon(
              penMode ? Icons.text_fields : Icons.draw_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Save',
            onPressed: saving ? null : _save,
            icon: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!penMode)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: QuillSimpleToolbar(
                  controller: controller,
                  config: const QuillSimpleToolbarConfig(
                    multiRowsDisplay: true,
                    showBoldButton: true,
                    showItalicButton: true,
                    showUnderLineButton: true,
                    showStrikeThrough: true,
                    showFontSize: true,
                    showFontFamily: true,
                    showColorButton: true,
                    showBackgroundColorButton: true,
                    showAlignmentButtons: true,
                    showHeaderStyle: true,
                    showListNumbers: true,
                    showListBullets: true,
                    showListCheck: true,
                    showIndent: true,
                    showQuote: true,
                    showCodeBlock: true,
                    showLink: true,
                    showUndo: true,
                    showRedo: true,
                    showClearFormat: true,
                    showDirection: true,
                    showSearchButton: true,
                  ),
                ),
              ),
            ),
          if (!penMode) const Divider(height: 1),
          Expanded(
            child: DocumentSurface(
              titleController: titleController,
              controller: controller,
              focusNode: editorFocusNode,
              scrollController: editorScrollController,
              rtl: rtl,
              penMode: penMode,
              handwritingData: handwritingData,
              onHandwritingChanged: (value) {
                handwritingData = value;
              },
            ),
          ),
        ],
      ),
    );
  }
}
