import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../handwriting/handwriting_overlay.dart';

class DocumentSurface extends StatefulWidget {
  final TextEditingController titleController;
  final QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final bool rtl;
  final bool penMode;
  final String handwritingData;
  final ValueChanged<String> onHandwritingChanged;

  const DocumentSurface({
    super.key,
    required this.titleController,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.rtl,
    required this.penMode,
    required this.handwritingData,
    required this.onHandwritingChanged,
  });

  @override
  State<DocumentSurface> createState() => _DocumentSurfaceState();
}

class _DocumentSurfaceState extends State<DocumentSurface> {
  final TransformationController _zoom = TransformationController();

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final direction =
        widget.rtl ? TextDirection.rtl : TextDirection.ltr;

    return Column(
      children: [
        Container(
          color: theme.scaffoldBackgroundColor,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: TextField(
            controller: widget.titleController,
            textDirection: direction,
            textAlign:
                widget.rtl ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: dark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: 'Title',
              hintStyle: TextStyle(
                color: dark ? Colors.white54 : Colors.black45,
              ),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: InteractiveViewer(
            transformationController: _zoom,
            minScale: .7,
            maxScale: 4,
            panEnabled: true,
            scaleEnabled: true,
            boundaryMargin: const EdgeInsets.all(200),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 900,
              ),
              color: theme.scaffoldBackgroundColor,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      18,
                      20,
                      80,
                    ),
                    child: Directionality(
                      textDirection: direction,
                      child: QuillEditor.basic(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        scrollController:
                            widget.scrollController,
                        config: QuillEditorConfig(
                          placeholder: 'Start writing...',
                          padding: EdgeInsets.zero,
                          autoFocus: false,
                          expands: false,
                          enableInteractiveSelection: true,
                          customStyles: DefaultStyles(
                            paragraph: DefaultTextBlockStyle(
                              TextStyle(
                                color: dark
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 17,
                              ),
                              const HorizontalSpacing(0, 0),
                              const VerticalSpacing(0, 8),
                              const VerticalSpacing(0, 0),
                              null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.penMode)
                    Positioned.fill(
                      child: HandwritingOverlay(
                        initialData: widget.handwritingData,
                        onChanged:
                            widget.onHandwritingChanged,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
