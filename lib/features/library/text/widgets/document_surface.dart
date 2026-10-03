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
  final inkKey = GlobalKey<HandwritingOverlayState>();
  final transform = TransformationController();

  double scale = 1;

  @override
  void initState() {
    super.initState();
    transform.addListener(_transformChanged);
  }

  void _transformChanged() {
    final value = transform.value.getMaxScaleOnAxis();

    if ((value - scale).abs() > .01 && mounted) {
      setState(() => scale = value);
    }
  }

  @override
  void dispose() {
    transform.removeListener(_transformChanged);
    transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final direction =
        widget.rtl ? TextDirection.rtl : TextDirection.ltr;

    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            transformationController: transform,
            minScale: .75,
            maxScale: 4,
            scaleEnabled: true,
            panEnabled: !widget.penMode && scale > 1.02,
            constrained: true,
            boundaryMargin: const EdgeInsets.all(240),
            child: Material(
              color: theme.colorScheme.surface,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      10,
                    ),
                    child: TextField(
                      controller: widget.titleController,
                      textDirection: direction,
                      textAlign: widget.rtl
                          ? TextAlign.right
                          : TextAlign.left,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: .45),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            16,
                            20,
                            20,
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
                                expands: false,
                                autoFocus: false,
                                enableInteractiveSelection: true,
                                customStyles:
                                    DefaultStyles.getInstance(
                                  context,
                                ).merge(
                                  DefaultStyles(
                                    paragraph:
                                        DefaultTextBlockStyle(
                                      TextStyle(
                                        color: theme
                                            .colorScheme
                                            .onSurface,
                                        fontSize: 17,
                                      ),
                                      const HorizontalSpacing(
                                        0,
                                        0,
                                      ),
                                      const VerticalSpacing(
                                        0,
                                        8,
                                      ),
                                      const VerticalSpacing(
                                        0,
                                        0,
                                      ),
                                      null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (widget.penMode)
                          Positioned.fill(
                            child: HandwritingOverlay(
                              key: inkKey,
                              initialData:
                                  widget.handwritingData,
                              scrollController:
                                  widget.scrollController,
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
        ),
        if (widget.penMode)
          _penToolbar(theme),
      ],
    );
  }

  Widget _penToolbar(ThemeData theme) {
    final state = inkKey.currentState;

    return Material(
      elevation: 5,
      color: theme.colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              IconButton(
                tooltip: 'Pen',
                onPressed: state?.setPen,
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                tooltip: 'Highlighter',
                onPressed: state?.setHighlighter,
                icon: const Icon(Icons.highlight),
              ),
              IconButton(
                tooltip: 'Eraser',
                onPressed: state?.setEraser,
                icon: const Icon(Icons.auto_fix_normal),
              ),
              IconButton(
                tooltip: 'Colors',
                onPressed: state?.showColors,
                icon: const Icon(Icons.palette_outlined),
              ),
              IconButton(
                tooltip: 'Size',
                onPressed: state?.showSize,
                icon: const Icon(Icons.line_weight),
              ),
              IconButton(
                tooltip: 'Undo',
                onPressed: state?.undo,
                icon: const Icon(Icons.undo),
              ),
              IconButton(
                tooltip: 'Redo',
                onPressed: state?.redo,
                icon: const Icon(Icons.redo),
              ),
              IconButton(
                tooltip: 'Clear',
                onPressed: state?.clear,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
