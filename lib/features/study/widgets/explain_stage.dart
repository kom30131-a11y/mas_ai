import 'package:flutter/material.dart';

class ExplainStage extends StatefulWidget {
  final String content;

  const ExplainStage({
    super.key,
    this.content = '',
  });

  @override
  State<ExplainStage> createState() =>
      _ExplainStageState();
}

class _ExplainStageState
    extends State<ExplainStage> {
  final controller = TextEditingController();

  bool submitted = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit() {
    if (controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Write your explanation first.',
          ),
        ),
      );
      return;
    }

    setState(() {
      submitted = true;
    });
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
                    'Explain',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Teach the concept in your own words '
                    'as if you were explaining it to another student.',
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
            minLines: 9,
            maxLines: 16,
            textInputAction:
                TextInputAction.newline,
            decoration: const InputDecoration(
              hintText:
                  'Explain the concept in your own words...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: submit,
            icon: const Icon(
              Icons.school_outlined,
            ),
            label: const Text(
              'Submit Explanation',
            ),
          ),
          if (submitted) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Explanation',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge,
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      controller.text,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Self-check',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _rating('Needs Work'),
                        _rating('Good'),
                        _rating('Strong'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _rating(String label) {
    return OutlinedButton(
      onPressed: () {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Explanation rating: $label',
            ),
          ),
        );
      },
      child: Text(label),
    );
  }
}
