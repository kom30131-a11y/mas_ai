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
  State<ActiveRecallPage> createState() => _ActiveRecallPageState();
}

class _ActiveRecallPageState extends State<ActiveRecallPage> {
  final answerController = TextEditingController();

  bool submitted = false;
  int questionIndex = 0;

  final questions = const [
    'What are the most important concepts you remember from this material?',
    'Explain the key mechanisms or relationships you remember.',
    'What important facts or details can you recall without looking?',
  ];

  @override
  void dispose() {
    answerController.dispose();
    super.dispose();
  }

  void _submit() {
    if (answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Write your recall answer first.'),
        ),
      );
      return;
    }

    setState(() {
      submitted = true;
    });
  }

  void _next() {
    if (questionIndex < questions.length - 1) {
      setState(() {
        questionIndex++;
        submitted = false;
        answerController.clear();
      });
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Active Recall',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${questionIndex + 1} / ${questions.length}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  questions[questionIndex],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        height: 1.4,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: answerController,
              enabled: !submitted,
              minLines: 8,
              maxLines: 16,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Write your answer from memory...',
              ),
            ),
            const SizedBox(height: 16),
            if (!submitted)
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Submit Recall'),
                ),
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
                        'Your answer has been recorded for evaluation.',
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
                          onPressed: _next,
                          child: Text(
                            questionIndex < questions.length - 1
                                ? 'Next'
                                : 'Finish Recall',
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
