import 'package:flutter/material.dart';

class ActiveRecallPage extends StatefulWidget {
  final String title;
  final String sourceContent;
  final List<int> selectedTopicIds;

  const ActiveRecallPage({
    super.key,
    required this.title,
    required this.sourceContent,
    required this.selectedTopicIds,
  });

  @override
  State<ActiveRecallPage> createState() =>
      _ActiveRecallPageState();
}

class _ActiveRecallPageState
    extends State<ActiveRecallPage> {
  final answerController = TextEditingController();

  bool submitted = false;

  @override
  void dispose() {
    answerController.dispose();
    super.dispose();
  }

  void _submit() {
    if (answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Write your recall answer first.',
          ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Recall'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              widget.selectedTopicIds.isEmpty
                  ? 'Recall the material from memory.'
                  : 'Recall the selected topics from memory.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recall',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Without looking at the material, '
                      'write everything you can remember.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: answerController,
                      minLines: 8,
                      maxLines: 16,
                      textInputAction:
                          TextInputAction.newline,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText:
                            'Write your answer from memory...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed:
                            submitted ? null : _submit,
                        child: Text(
                          submitted
                              ? 'Answer Submitted'
                              : 'Submit Recall',
                        ),
                      ),
                    ),
                  ],
                ),
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
                        'Recall recorded',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your response is ready for the '
                        'evaluation stage. AI evaluation '
                        'will be connected here later.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _finish,
                          child: const Text(
                            'Finish Recall',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
