import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../ai/ai_client.dart';

class ExplainStage extends StatefulWidget {
  final String title;
  final String content;
  final List<int> selectedTopicIds;

  const ExplainStage({
    super.key,
    required this.title,
    required this.content,
    required this.selectedTopicIds,
  });

  @override
  State<ExplainStage> createState() => _ExplainStageState();
}

class _ExplainStageState extends State<ExplainStage> {
  final controller = TextEditingController();
  final ai = AiClient.instance;

  bool loading = false;
  bool submitted = false;
  bool finished = false;

  String feedback = '';
  String strengths = '';
  String weaknesses = '';
  String recommendation = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final answer = controller.text.trim();

    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Write your explanation first.'),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final result = await ai.send(
        request: {
          'task': 'evaluate_explanation',
          'content': widget.content,
          'selected_topic_ids': widget.selectedTopicIds,
          'student_explanation': answer,
          'language': 'same_as_content',
          'instructions': {
            'check_accuracy': true,
            'check_completeness': true,
            'identify_missing_concepts': true,
            'identify_misconceptions': true,
            'give_corrective_feedback': true,
            'return_json': true,
          },
        },
      );

      final parsed = _parse(result);

      if (!mounted) return;

      setState(() {
        feedback = parsed['feedback']?.toString() ?? result;
        submitted = true;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        feedback = e.toString();
        submitted = true;
        loading = false;
      });
    }
  }

  Future<void> _finish() async {
    setState(() {
      loading = true;
    });

    try {
      final result = await ai.send(
        request: {
          'task': 'analyze_explanation_session',
          'content': widget.content,
          'selected_topic_ids': widget.selectedTopicIds,
          'student_explanation': controller.text.trim(),
          'language': 'same_as_content',
          'instructions': {
            'identify_strengths': true,
            'identify_weaknesses': true,
            'recommend_next_review': true,
            'recommend_study_action': true,
            'return_json': true,
          },
        },
      );

      final parsed = _parse(result);

      if (!mounted) return;

      setState(() {
        strengths = parsed['strengths']?.toString() ?? '';
        weaknesses = parsed['weaknesses']?.toString() ?? '';
        recommendation =
            parsed['recommendation']?.toString() ?? result;
        finished = true;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        recommendation = e.toString();
        finished = true;
        loading = false;
      });
    }
  }

  Map<String, dynamic> _parse(String value) {
    try {
      final decoded = jsonDecode(value);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    return {
      'feedback': value,
    };
  }

  void _returnToStudy() {
    Navigator.popUntil(
      context,
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (finished) {
      return _results();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Explain in your own words',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            enabled: !submitted && !loading,
            minLines: 10,
            maxLines: 18,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Explain what you learned...',
            ),
          ),
          const SizedBox(height: 16),
          if (!submitted)
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: loading ? null : _submit,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text('Submit Explanation'),
              ),
            ),
          if (submitted)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Feedback',
                      style:
                          Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(feedback),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: loading ? null : _finish,
                        child: const Text('View Results'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _results() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explain Results'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _resultCard(
            'Strengths',
            strengths.isEmpty
                ? 'No strength data returned.'
                : strengths,
          ),
          _resultCard(
            'Weaknesses',
            weaknesses.isEmpty
                ? 'No weakness data returned.'
                : weaknesses,
          ),
          _resultCard(
            'Recommended next step',
            recommendation.isEmpty
                ? 'Continue reviewing this material.'
                : recommendation,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _returnToStudy,
              child: const Text('Return to Study'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(String title, String text) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:
                  Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(text),
          ],
        ),
      ),
    );
  }
}
