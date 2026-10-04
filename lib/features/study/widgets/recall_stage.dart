import 'package:flutter/material.dart';

class RecallStage extends StatefulWidget {
  final String content;

  const RecallStage({
    super.key,
    this.content = '',
  });

  @override
  State<RecallStage> createState() => _RecallStageState();
}

class _RecallStageState extends State<RecallStage> {
  final controller = TextEditingController();

  bool showAnswer = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String get answer {
    final text = widget.content.trim();

    if (text.isEmpty) {
      return 'No source material is available for this recall.';
    }

    if (text.length <= 700) {
      return text;
    }

    return '${text.substring(0, 700)}...';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Recall',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Without looking at the material, '
                    'write everything you remember.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            minLines: 8,
            maxLines: 14,
            textInputAction:
                TextInputAction.newline,
            decoration: const InputDecoration(
              hintText:
                  'Write what you remember...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                showAnswer = true;
              });
            },
            icon: const Icon(
              Icons.visibility_outlined,
            ),
            label: const Text('Reveal Answer'),
          ),
          if (showAnswer) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Source Material',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge,
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      answer,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'How well did you recall it?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _rating('Again', 0),
                _rating('Hard', 1),
                _rating('Good', 2),
                _rating('Easy', 3),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _rating(String label, int value) {
    return OutlinedButton(
      onPressed: () {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Recall rating: $label',
            ),
          ),
        );
      },
      child: Text(label),
    );
  }
}
