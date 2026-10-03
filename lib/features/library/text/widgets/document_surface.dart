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
  @override
  Widget build(BuildContext context) {
    final direction =
        widget.rtl ? TextDirection.rtl : TextDirection.ltr;

    return ClipRect(
      child: InteractiveViewer(
        minScale: .75,
        maxScale: 3,
        scaleEnabled: true,
        panEnabled: true,
        constrained: true,
        boundaryMargin: const EdgeInsets.all(120),
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  10,
                ),
                child: TextField(
                  controller: widget.titleController,
                  textDirection: direction,
                  textAlign: widget.rtl
                      ? TextAlign.right
                      : TextAlign.left,
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall,
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: 600,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Directionality(
                        textDirection: direction,
                        child: QuillEditor.basic(
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          scrollController:
                              widget.scrollController,
                          config: const QuillEditorConfig(
                            placeholder: 'Start writing...',
                            padding: EdgeInsets.zero,
                            expands: false,
                            autoFocus: false,
                            enableInteractiveSelection: true,
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
            ],
          ),
        ),
      ),
    );
  }
}
