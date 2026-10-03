import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class TextEditorPage extends StatefulWidget {
  final String? title;
  final String? initialText;

  const TextEditorPage({
    super.key,
    this.title,
    this.initialText,
  });

  @override
  State<TextEditorPage> createState() => _TextEditorPageState();
}

class _TextEditorPageState extends State<TextEditorPage> {
  late final QuillController controller;
  final titleController = TextEditingController();

  bool rtl = false;

  @override
  void initState() {
    super.initState();

    titleController.text = widget.title ?? '';

    controller = QuillController.basic();

    final text = widget.initialText?.trim() ?? '';
    if (text.isNotEmpty) {
      controller.document.insert(0, text);
    }

    rtl = _detectArabic(
      widget.initialText ?? '',
    );

    controller.addListener(_onTextChanged);
  }

  bool _detectArabic(String text) {
    final match = RegExp(
      r'[A-Za-z\u0600-\u06FF]',
    ).firstMatch(text);

    if (match == null) return false;

    return RegExp(
      r'[\u0600-\u06FF]',
    ).hasMatch(match.group(0)!);
  }

  void _onTextChanged() {
    final text = controller.document.toPlainText();

    if (text.trim().isEmpty) return;

    final detected = _detectArabic(text);

    if (detected != rtl) {
      setState(() => rtl = detected);
    }
  }

  void _toggleDirection() {
    setState(() => rtl = !rtl);
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
    final direction = rtl
        ? TextDirection.rtl
        : TextDirection.ltr;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title == null
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
                  ? Icons.format_textdirection_r_to_l
                  : Icons.format_textdirection_l_to_r,
            ),
          ),
          IconButton(
            tooltip: 'Save',
            onPressed: () {
              Navigator.pop(
                context,
                controller.document.toPlainText(),
              );
            },
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
              textAlign: rtl
                  ? TextAlign.right
                  : TextAlign.left,
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
              config: QuillSimpleToolbarConfig(
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
                  config: QuillEditorConfig(
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
