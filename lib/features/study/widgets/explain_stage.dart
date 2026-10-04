import 'package:flutter/material.dart';

class ExplainStage extends StatefulWidget {
  final String content;

  const ExplainStage({
    super.key,
    this.content = '',
  });

  @override
  State<ExplainStage> createState() => _ExplainStageState();
}

class _ExplainStageState extends State<ExplainStage> {
  final controller = TextEditingController();

  bool submitted = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Write your explanation first.'),
        ),
      );
      return;
    }

    setState(() {
      submitted = true;
    });
  }

  void _finish() {
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Explain the concept in your own words.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            enabled: !submitted,
            minLines: 9,
            maxLines: 16,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'Write your explanation...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (!submitted)
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.school_outlined),
              label: const Text('Submit Explanation'),
            ),
          if (submitted) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Feedback',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your explanation has been recorded for evaluation.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _finish,
                        child: const Text('Finish Explain'),
                      ),
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
}
