import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

import 'word_color_palette.dart';

class WordToolbarColor extends StatelessWidget {
final WordEditorController controller;

const WordToolbarColor({
super.key,
required this.controller,
});

String _hex(Color color) {
return color
.toARGB32()
.toRadixString(16)
.padLeft(8, '0')
.substring(2)
.toUpperCase();
}

Future<void> _pick(
BuildContext context, {
required bool highlight,
}) async {
final color = await showDialog<Color>(
context: context,
builder: (dialogContext) {
return AlertDialog(
title: Text(
highlight ? 'Highlight color' : 'Text color',
),
content: WordColorPalette(
selectedColor: null,
onSelected: (value) {
Navigator.pop(dialogContext, value);
},
),
);
},
);

if (!context.mounted || color == null) return;

controller.applyRunFormat(
  (props) {
    if (highlight) {
      props.highlight = _hex(color);
    } else {
      props.color = _hex(color);
    }
  },
);

controller.refresh();

}

@override
Widget build(BuildContext context) {
return Row(
mainAxisSize: MainAxisSize.min,
children: [
IconButton(
tooltip: 'Text color',
onPressed: () => _pick(
context,
highlight: false,
),
icon: const Icon(
Icons.format_color_text,
),
),
IconButton(
tooltip: 'Highlight',
onPressed: () => _pick(
context,
highlight: true,
),
icon: const Icon(Icons.highlight),
),
],
);
}
}
