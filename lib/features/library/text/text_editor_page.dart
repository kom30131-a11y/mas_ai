import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/database/database_repository.dart';
import '../handwriting/handwriting_overlay.dart';

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
  State<TextEditorPage> createState() =>
      _TextEditorPageState();
}

class _TextEditorPageState
    extends State<TextEditorPage> {
  late final QuillController controller;
  late final TextEditingController titleController;
  late final FocusNode editorFocusNode;
  late final ScrollController editorScrollController;

  String handwritingData = '';

  bool rtl = false;
  bool saving = false;
  bool penMode = false;

  final TransformationController
      transformController =
      TransformationController();

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.item?['title']?.toString() ?? '',
    );

    editorFocusNode = FocusNode();
    editorScrollController = ScrollController();

    controller = _createController();

    rtl = _detectArabic(
      controller.document.toPlainText(),
    );
  }

  QuillController _createController() {
    final raw =
        widget.item?['content']?.toString() ?? '';

    if (raw.trim().isEmpty) {
      return QuillController.basic();
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is Map) {
        final textData = decoded['text'];
        final handwriting =
            decoded['handwriting'];

        if (handwriting is List &&
            handwriting.isNotEmpty) {
          handwritingData =
              jsonEncode(handwriting);
        }

        if (textData is List) {
          final document = Document.fromJson(
            List<Map<String, dynamic>>.from(
              textData,
            ),
          );

          return QuillController(
            document: document,
            selection:
                TextSelection.collapsed(
              offset:
                  document.length > 0
                      ? document.length - 1
                      : 0,
            ),
          );
        }
      }

      if (decoded is List) {
        final document = Document.fromJson(
          List<Map<String, dynamic>>.from(
            decoded,
          ),
        );

        return QuillController(
          document: document,
          selection:
              TextSelection.collapsed(
            offset:
                document.length > 0
                    ? document.length - 1
                    : 0,
          ),
        );
      }
    } catch (_) {}

    final document = Document();

    if (raw.isNotEmpty) {
      document.insert(0, raw);
    }

    return QuillController(
      document: document,
      selection: TextSelection.collapsed(
        offset:
            document.length > 0
                ? document.length - 1
                : 0,
      ),
    );
  }

  bool _detectArabic(String text) {
    final arabic =
        RegExp(r'[\u0600-\u06FF]');
    final latin = RegExp(r'[A-Za-z]');

    final arabicMatch =
        arabic.firstMatch(text);
    final latinMatch =
        latin.firstMatch(text);

    if (arabicMatch == null) return false;
    if (latinMatch == null) return true;

    return arabicMatch.start <
        latinMatch.start;
  }

  void _toggleDirection() {
    setState(() {
      rtl = !rtl;
    });
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

  Future<void> save() async {
    if (saving) return;

    final title =
        titleController.text.trim();

    final plainText = controller.document
        .toPlainText()
        .trim();

    if (title.isEmpty) {
      _message('Please enter a title.');
      return;
    }

    if (plainText.isEmpty &&
        handwritingData.trim().isEmpty) {
      _message(
        'Please write something first.',
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final content = jsonEncode({
        'text':
            controller.document.toDelta().toJson(),
        'handwriting':
            handwritingData.isEmpty
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
          'created_at':
              DateTime.now()
                  .toIso8601String(),
        });
      } else {
        await repo.updateContent(
          contentId: widget.item!['id'],
          title: title,
          content: content,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        _message(
          'Could not save the note.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    titleController.dispose();
    editorFocusNode.dispose();
    editorScrollController.dispose();
    transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final direction =
        rtl
            ? TextDirection.rtl
            : TextDirection.ltr;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null
              ? 'New Note'
              : 'Edit Note',
        ),
        actions: [
          IconButton(
            tooltip: rtl
                ? 'Left to Right'
                : 'Right to Left',
            onPressed: _toggleDirection,
            icon: Icon(
              rtl
                  ? Icons
                      .format_textdirection_r_to_l
                  : Icons
                      .format_textdirection_l_to_r,
            ),
          ),
          IconButton(
            tooltip:
                penMode ? 'Text' : 'Pen',
            onPressed: _togglePen,
            icon: Icon(
              penMode
                  ? Icons.text_fields
                  : Icons.draw_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Save',
            onPressed:
                saving ? null : save,
            icon: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.check,
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              8,
            ),
            child: TextField(
              controller: titleController,
              textDirection: direction,
              textAlign: rtl
                  ? TextAlign.right
                  : TextAlign.left,
              textInputAction:
                  TextInputAction.next,
              decoration:
                  const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
          ),

          const Divider(height: 1),

          if (!penMode)
            Container(
              width: double.infinity,
              decoration:
                  BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
              ),
              child:
                  SingleChildScrollView(
                scrollDirection:
                    Axis.horizontal,
                child: QuillSimpleToolbar(
                  controller: controller,
                  config:
                      const QuillSimpleToolbarConfig(
                    multiRowsDisplay: true,
                    showBoldButton: true,
                    showItalicButton: true,
                    showUnderLineButton: true,
                    showStrikeThrough: true,
                    showFontSize: true,
                    showFontFamily: true,
                    showColorButton: true,
                    showBackgroundColorButton:
                        true,
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

          if (!penMode)
            const Divider(height: 1),

          Expanded(
            child: InteractiveViewer(
              transformationController:
                  transformController,
              minScale: 0.7,
              maxScale: 3.0,
              panEnabled: true,
              scaleEnabled: true,
              boundaryMargin:
                  const EdgeInsets.all(200),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Theme.of(context)
                        .colorScheme
                        .surface,
                    padding:
                        const EdgeInsets.all(16),
                    child: Directionality(
                      textDirection:
                          direction,
                      child: QuillEditor.basic(
                        controller:
                            controller,
                        focusNode:
                            editorFocusNode,
                        scrollController:
                            editorScrollController,
                        config:
                            const QuillEditorConfig(
                          placeholder:
                              'Start writing...',
                          padding:
                              EdgeInsets.zero,
                          expands: true,
                          autoFocus: false,
                          enableInteractiveSelection:
                              true,
                        ),
                      ),
                    ),
                  ),

                  HandwritingOverlay(
                    initialData:
                        handwritingData,
                    onChanged: (value) {
                      handwritingData =
                          value;
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
