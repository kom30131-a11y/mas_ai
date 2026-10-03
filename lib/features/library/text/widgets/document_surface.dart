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
  State<DocumentSurface> createState() =>
      _DocumentSurfaceState();
}

class _DocumentSurfaceState
    extends State<DocumentSurface> {
  double scale = 1.0;

  static const double minScale = 0.75;
  static const double maxScale = 3.0;

  @override
  Widget build(BuildContext context) {
    final direction = widget.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return GestureDetector(
          onScaleUpdate: (details) {
            if (details.pointerCount >= 2) {
              setState(() {
                scale = (scale * details.scale)
                    .clamp(minScale, maxScale);
              });
            }
          },
          child: ClipRect(
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: width / scale,
                height: height / scale,
                child: Material(
                  color: Theme.of(context)
                      .colorScheme
                      .surface,
                  child: Column(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          20,
                          18,
                          20,
                          10,
                        ),
                        child: TextField(
                          controller:
                              widget.titleController,
                          textDirection: direction,
                          textAlign: widget.rtl
                              ? TextAlign.right
                              : TextAlign.left,
                          decoration:
                              const InputDecoration(
                            hintText: 'Title',
                            border: InputBorder.none,
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall,
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.all(
                                20,
                              ),
                              child: Directionality(
                                textDirection: direction,
                                child: QuillEditor.basic(
                                  controller:
                                      widget.controller,
                                  focusNode:
                                      widget.focusNode,
                                  scrollController:
                                      widget.scrollController,
                                  config:
                                      const QuillEditorConfig(
                                    placeholder:
                                        'Start writing...',
                                    padding:
                                        EdgeInsets.zero,
                                    autoFocus: false,
                                    expands: false,
                                    enableInteractiveSelection:
                                        true,
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                ignoring: !widget.penMode,
                                child: HandwritingOverlay(
                                  initialData:
                                      widget.handwritingData,
                                  onChanged:
                                      widget.onHandwritingChanged,
                                ),
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
          ),
        );
      },
    );
  }
}
