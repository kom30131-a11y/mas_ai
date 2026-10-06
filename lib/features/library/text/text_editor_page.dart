import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/database/database_repository.dart';
import '../../../core/storage/library_storage_service.dart';

class TextEditorPage extends StatefulWidget {
  const TextEditorPage({
    super.key,
    required this.subjectId,
    this.folderId,
    this.item,
  });

  final int subjectId;
  final int? folderId;
  final Map<String, dynamic>? item;

  @override
  State<TextEditorPage> createState() => _TextEditorPageState();
}

class _TextEditorPageState extends State<TextEditorPage> {
  final repo = DatabaseRepository.instance;

  late final QuillController _controller;
  late final TextEditingController _titleController;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;

  bool _rtl = true;
  bool _dirty = false;
  bool _saving = false;

  static const _toolbarHeight = 48.0;

  bool get _isNew => widget.item == null;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    final document = _documentFromContent(
      item?['content']?.toString(),
    );

    _titleController = TextEditingController(
      text: item?['title']?.toString() ?? '',
    );

    _focusNode = FocusNode();
    _scrollController = ScrollController();

    _controller = QuillController(
      document: document,
      selection: TextSelection.collapsed(
        offset: document.length > 0 ? document.length - 1 : 0,
      ),
    );

    _controller.addListener(_onDocumentChanged);
    _detectDirection();
  }

  Document _documentFromContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return Document();
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is List) {
        return Document.fromJson(decoded);
      }
    } catch (_) {}

    final document = Document();
    document.insert(0, value);
    return document;
  }

  void _onDocumentChanged() {
    if (!mounted) return;

    final detected = _detectDirectionFromText(
      _controller.document.toPlainText(),
    );

    if (detected != _rtl || !_dirty) {
      setState(() {
        _rtl = detected;
        _dirty = true;
      });
    }
  }

  bool _detectDirectionFromText(String text) {
    final arabic =
        RegExp(r'[\u0600-\u06FF]').allMatches(text).length;

    final latin =
        RegExp(r'[A-Za-z]').allMatches(text).length;

    if (arabic == 0 && latin == 0) {
      return _rtl;
    }

    return arabic >= latin;
  }

  void _detectDirection() {
    _rtl = _detectDirectionFromText(
      _controller.document.toPlainText(),
    );
  }

  Future<void> _save() async {
    if (_saving) return;

    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل عنوان المحتوى.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final content = jsonEncode(
        _controller.document.toDelta().toJson(),
      );

      if (_isNew) {
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
          contentId: widget.item!['id'] as int,
          title: title,
          content: content,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر حفظ المحتوى.'),
        ),
      );
    }
  }

  void _applyDirection(bool rtl) {
    setState(() => _rtl = rtl);

    _controller.formatSelection(
      DirectionAttribute(rtl ? 'rtl' : 'ltr'),
    );
  }

  String _quillColor(Color color) {
    final value = color.toARGB32();
    final rgb = value & 0x00FFFFFF;

    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }

  void _setBackgroundColor(Color color) {
    _controller.formatSelection(
      color == Colors.transparent
          ? const BackgroundAttribute(null)
          : BackgroundAttribute(_quillColor(color)),
    );
  }

  void _setTextColor(Color color) {
    _controller.formatSelection(
      color == Colors.transparent
          ? const ColorAttribute(null)
          : ColorAttribute(_quillColor(color)),
    );
  }

  Future<void> _pickColor({
    required bool background,
  }) async {
    final colors = background
        ? const [
            Color(0xFFFFFF8D),
            Color(0xFFC6FF00),
            Color(0xFFFFC1E3),
            Color(0xFF80DEEA),
            Color(0xFFFFCC80),
            Color(0xFFB3E5FC),
            Color(0xFFD1C4E9),
            Colors.transparent,
          ]
        : const [
            Color(0xFF111827),
            Color(0xFFDC2626),
            Color(0xFFEA580C),
            Color(0xFFCA8A04),
            Color(0xFF16A34A),
            Color(0xFF0891B2),
            Color(0xFF2563EB),
            Color(0xFF7C3AED),
            Color(0xFFDB2777),
            Colors.white,
          ];

    final selected = await showModalBottomSheet<Color?>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final color in colors)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(
                      context,
                      color,
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color == Colors.transparent
                            ? Theme.of(context)
                                .colorScheme
                                .surface
                            : color,
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: .35),
                        ),
                      ),
                      child: color == Colors.transparent
                          ? const Icon(
                              Icons.format_color_reset,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    if (background) {
      _setBackgroundColor(selected);
    } else {
      _setTextColor(selected);
    }
  }

  Widget _toolButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return SizedBox(
      width: _toolbarHeight,
      height: _toolbarHeight,
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, size: 21),
        onPressed: onPressed,
      ),
    );
  }

  Widget _toolbar(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        height: 58,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
          ),
          children: [
            _toolButton(
              icon: Icons.undo,
              tooltip: 'تراجع',
              onPressed: _controller.undo,
            ),
            _toolButton(
              icon: Icons.redo,
              tooltip: 'إعادة',
              onPressed: _controller.redo,
            ),
            const VerticalDivider(
              width: 12,
              indent: 10,
              endIndent: 10,
            ),
            _toolButton(
              icon: Icons.format_bold,
              tooltip: 'عريض',
              onPressed: () => _controller.formatSelection(
                Attribute.bold,
              ),
            ),
            _toolButton(
              icon: Icons.format_italic,
              tooltip: 'مائل',
              onPressed: () => _controller.formatSelection(
                Attribute.italic,
              ),
            ),
            _toolButton(
              icon: Icons.format_underlined,
              tooltip: 'تحته خط',
              onPressed: () => _controller.formatSelection(
                Attribute.underline,
              ),
            ),
            _toolButton(
              icon: Icons.strikethrough_s,
              tooltip: 'شطب',
              onPressed: () => _controller.formatSelection(
                Attribute.strikeThrough,
              ),
            ),
            const VerticalDivider(
              width: 12,
              indent: 10,
              endIndent: 10,
            ),
            _toolButton(
              icon: Icons.format_color_text,
              tooltip: 'لون النص',
              onPressed: () =>
                  _pickColor(background: false),
            ),
            _toolButton(
              icon: Icons.format_color_fill,
              tooltip: 'تظليل',
              onPressed: () =>
                  _pickColor(background: true),
            ),
            const VerticalDivider(
              width: 12,
              indent: 10,
              endIndent: 10,
            ),
            _toolButton(
              icon: Icons.format_list_bulleted,
              tooltip: 'قائمة نقطية',
              onPressed: () => _controller.formatSelection(
                Attribute.ul,
              ),
            ),
            _toolButton(
              icon: Icons.format_list_numbered,
              tooltip: 'قائمة رقمية',
              onPressed: () => _controller.formatSelection(
                Attribute.ol,
              ),
            ),
            const VerticalDivider(
              width: 12,
              indent: 10,
              endIndent: 10,
            ),
            PopupMenuButton<Attribute<dynamic>>(
              tooltip: 'العناوين',
              icon: const Icon(Icons.title),
              onSelected: (value) =>
                  _controller.formatSelection(value),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: Attribute.h1,
                  child: Text('Heading 1'),
                ),
                PopupMenuItem(
                  value: Attribute.h2,
                  child: Text('Heading 2'),
                ),
                PopupMenuItem(
                  value: Attribute.h3,
                  child: Text('Heading 3'),
                ),
              ],
            ),
            _toolButton(
              icon: Icons.format_align_right,
              tooltip: 'يمين',
              onPressed: () => _controller.formatSelection(
                Attribute.rightAlignment,
              ),
            ),
            _toolButton(
              icon: Icons.format_align_center,
              tooltip: 'وسط',
              onPressed: () => _controller.formatSelection(
                Attribute.centerAlignment,
              ),
            ),
            _toolButton(
              icon: Icons.format_align_left,
              tooltip: 'يسار',
              onPressed: () => _controller.formatSelection(
                Attribute.leftAlignment,
              ),
            ),
            _toolButton(
              icon: Icons.format_align_justify,
              tooltip: 'ضبط',
              onPressed: () => _controller.formatSelection(
                Attribute.justifyAlignment,
              ),
            ),
            const VerticalDivider(
              width: 12,
              indent: 10,
              endIndent: 10,
            ),
            _toolButton(
              icon: Icons.format_textdirection_r_to_l,
              tooltip: 'العربية RTL',
              onPressed: () => _applyDirection(true),
            ),
            _toolButton(
              icon: Icons.format_textdirection_l_to_r,
              tooltip: 'English LTR',
              onPressed: () => _applyDirection(false),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final direction =
        _rtl ? TextDirection.rtl : TextDirection.ltr;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: TextField(
          controller: _titleController,
          textDirection: direction,
          textAlign:
              _rtl ? TextAlign.right : TextAlign.left,
          onChanged: (_) {
            if (!_dirty && mounted) {
              setState(() => _dirty = true);
            }
          },
          decoration: const InputDecoration(
            hintText: 'العنوان',
            border: InputBorder.none,
          ),
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'حفظ',
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    _dirty ? Icons.save : Icons.check,
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          _toolbar(context),
          const Divider(height: 1),
          Expanded(
            child: Directionality(
              textDirection: direction,
              child: QuillEditor(
                controller: _controller,
                focusNode: _focusNode,
                scrollController: _scrollController,
                config: QuillEditorConfig(
                  placeholder: 'ابدأ الكتابة...',
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    24,
                    20,
                    100,
                  ),
                  scrollBottomInset: 120,
                  expands: false,
                  autoFocus: false,
                  enableInteractiveSelection: true,
                  enableSelectionToolbar: true,
                  showCursor: true,
                  scrollable: true,
                  textCapitalization:
                      TextCapitalization.sentences,
                  keyboardAppearance:
                      Theme.of(context).brightness,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onDocumentChanged);
    _controller.dispose();
    _titleController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
