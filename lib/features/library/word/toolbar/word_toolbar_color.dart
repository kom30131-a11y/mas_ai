import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

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
    const colors = [
            Colors.black,
      Colors.white,
      Colors.red,
      Colors.redAccent,
      Colors.red[50],
      Colors.red[100],
      Colors.red[200],
      Colors.red[300],
      Colors.red[400],
      Colors.red[500],
      Colors.red[600],
      Colors.red[700],
      Colors.red[800],
      Colors.red[900],
      Colors.pink,
      Colors.pinkAccent,
      Colors.pink[50],
      Colors.pink[100],
      Colors.pink[200],
      Colors.pink[300],
      Colors.pink[400],
      Colors.pink[500],
      Colors.pink[600],
      Colors.pink[700],
      Colors.pink[800],
      Colors.pink[900],
      Colors.purple,
      Colors.purpleAccent,
      Colors.purple[50],
      Colors.purple[100],
      Colors.purple[200],
      Colors.purple[300],
      Colors.purple[400],
      Colors.purple[500],
      Colors.purple[600],
      Colors.purple[700],
      Colors.purple[800],
      Colors.purple[900],
      Colors.deepPurple,
      Colors.deepPurpleAccent,
      Colors.deepPurple[50],
      Colors.deepPurple[100],
      Colors.deepPurple[200],
      Colors.deepPurple[300],
      Colors.deepPurple[400],
      Colors.deepPurple[500],
      Colors.deepPurple[600],
      Colors.deepPurple[700],
      Colors.deepPurple[800],
      Colors.deepPurple[900],
      Colors.indigo,
      Colors.indigoAccent,
      Colors.indigo[50],
      Colors.indigo[100],
      Colors.indigo[200],
      Colors.indigo[300],
      Colors.indigo[400],
      Colors.indigo[500],
      Colors.indigo[600],
      Colors.indigo[700],
      Colors.indigo[800],
      Colors.indigo[900],
      Colors.blue,
      Colors.blueAccent,
      Colors.blue[50],
      Colors.blue[100],
      Colors.blue[200],
      Colors.blue[300],
      Colors.blue[400],
      Colors.blue[500],
      Colors.blue[600],
      Colors.blue[700],
      Colors.blue[800],
      Colors.blue[900],
      Colors.lightBlue,
      Colors.lightBlueAccent,
      Colors.lightBlue[50],
      Colors.lightBlue[100],
      Colors.lightBlue[200],
      Colors.lightBlue[300],
      Colors.lightBlue[400],
      Colors.lightBlue[500],
      Colors.lightBlue[600],
      Colors.lightBlue[700],
      Colors.lightBlue[800],
      Colors.lightBlue[900],
      Colors.cyan,
      Colors.cyanAccent,
      Colors.cyan[50],
      Colors.cyan[100],
      Colors.cyan[200],
      Colors.cyan[300],
      Colors.cyan[400],
      Colors.cyan[500],
      Colors.cyan[600],
      Colors.cyan[700],
      Colors.cyan[800],
      Colors.cyan[900],
      Colors.teal,
      Colors.tealAccent,
      Colors.teal[50],
      Colors.teal[100],
      Colors.teal[200],
      Colors.teal[300],
      Colors.teal[400],
      Colors.teal[500],
      Colors.teal[600],
      Colors.teal[700],
      Colors.teal[800],
      Colors.teal[900],
      Colors.green,
      Colors.greenAccent,
      Colors.green[50],
      Colors.green[100],
      Colors.green[200],
      Colors.green[300],
      Colors.green[400],
      Colors.green[500],
      Colors.green[600],
      Colors.green[700],
      Colors.green[800],
      Colors.green[900],
      Colors.lightGreen,
      Colors.lightGreenAccent,
      Colors.lightGreen[50],
      Colors.lightGreen[100],
      Colors.lightGreen[200],
      Colors.lightGreen[300],
      Colors.lightGreen[400],
      Colors.lightGreen[500],
      Colors.lightGreen[600],
      Colors.lightGreen[700],
      Colors.lightGreen[800],
      Colors.lightGreen[900],
      Colors.lime,
      Colors.limeAccent,
      Colors.lime[50],
      Colors.lime[100],
      Colors.lime[200],
      Colors.lime[300],
      Colors.lime[400],
      Colors.lime[500],
      Colors.lime[600],
      Colors.lime[700],
      Colors.lime[800],
      Colors.lime[900],
      Colors.yellow,
      Colors.yellowAccent,
      Colors.yellow[50],
      Colors.yellow[100],
      Colors.yellow[200],
      Colors.yellow[300],
      Colors.yellow[400],
      Colors.yellow[500],
      Colors.yellow[600],
      Colors.yellow[700],
      Colors.yellow[800],
      Colors.yellow[900],
      Colors.amber,
      Colors.amberAccent,
      Colors.amber[50],
      Colors.amber[100],
      Colors.amber[200],
      Colors.amber[300],
      Colors.amber[400],
      Colors.amber[500],
      Colors.amber[600],
      Colors.amber[700],
      Colors.amber[800],
      Colors.amber[900],
      Colors.orange,
      Colors.orangeAccent,
      Colors.orange[50],
      Colors.orange[100],
      Colors.orange[200],
      Colors.orange[300],
      Colors.orange[400],
      Colors.orange[500],
      Colors.orange[600],
      Colors.orange[700],
      Colors.orange[800],
      Colors.orange[900],
      Colors.deepOrange,
      Colors.deepOrangeAccent,
      Colors.deepOrange[50],
      Colors.deepOrange[100],
      Colors.deepOrange[200],
      Colors.deepOrange[300],
      Colors.deepOrange[400],
      Colors.deepOrange[500],
      Colors.deepOrange[600],
      Colors.deepOrange[700],
      Colors.deepOrange[800],
      Colors.deepOrange[900],
      Colors.brown,
      Colors.brown[50],
      Colors.brown[100],
      Colors.brown[200],
      Colors.brown[300],
      Colors.brown[400],
      Colors.brown[500],
      Colors.brown[600],
      Colors.brown[700],
      Colors.brown[800],
      Colors.brown[900],
      Colors.grey,
      Colors.grey[50],
      Colors.grey[100],
      Colors.grey[200],
      Colors.grey[300],
      Colors.grey[400],
      Colors.grey[500],
      Colors.grey[600],
      Colors.grey[700],
      Colors.grey[800],
      Colors.grey[900],
      Colors.blueGrey,
      Colors.blueGrey[50],
      Colors.blueGrey[100],
      Colors.blueGrey[200],
      Colors.blueGrey[300],
      Colors.blueGrey[400],
      Colors.blueGrey[500],
      Colors.blueGrey[600],
      Colors.blueGrey[700],
      Colors.blueGrey[800],
      Colors.blueGrey[900], 
    ];

    final color = await showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            highlight
                ? 'Highlight color'
                : 'Text color',
          ),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final color in colors)
                InkWell(
                  onTap: () => Navigator.pop(
                    context,
                    color,
                  ),
                  borderRadius:
                      BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context)
                            .dividerColor,
                      ),
                    ),
                  ),
                ),
            ],
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
