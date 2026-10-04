import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../ai/ai_client.dart';

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
  final ai = AiClient.instance;

  String question = '';
  String feedback = '';
  String strengths = '';
  String weaknesses = '';
  String recommendation = '';

  int questionIndex = 0;
  int score = 0;

  bool loading = true;
  bool submitted = false;
  bool finished = false;

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  @override
  void dispose() {
    answerController.dispose();
    super.dispose();
  }

  Future<void> _generateQuestion() async {
    setState(() {
      loading = true;
      submitted = false;
      feedback = '';
    });

    try {
      final result = await ai.send(
        request: {
          'task': 'generate_active_recall_question',
          'content': widget.sourceContent,
          'question_number': questionIndex + 1,
          'selected_topic_ids': widget.selectedTopicIds,
          'language': 'same_as_content',
          'instructions': {
            'use_only_source_content': true,
            'avoid_repetition': true,
            'vary_question_style': true,
            'test_retrieval_not_recognition': true,
          },
        },
      );

      final parsed = _parse(result);

      if (!mounted) return;

      setState(() {
        question = parsed['question']?.toString() ?? result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        question = 'AI could not generate the question.';
        feedback = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _submit() async {
    final answer = answerController.text.trim();

    if (answer.isEmpty || loading) return;

    setState(() {
      loading = true;
    });

    try {
      final result = await ai.send(
        request: {
          'task': 'evaluate_active_recall_answer',
          'content': widget.sourceContent,
          'selected_topic_ids': widget.selectedTopicIds,
          'question': question,
          'student_answer': answer,
          'language': 'same_as_content',
          'instructions': {
            'evaluate_against_source': true,
            'identify_correct_points': true,
            'identify_missing_points': true,
            'explain_errors': true,
            'give_actionable_feedback': true,
            'return_json': true,
          },
        },
      );

      final parsed = _parse(result);
      final value = parsed['score'];

      if (value is num && value >= 70) {
        score++;
      } else if (parsed['correct'] == true) {
        score++;
      }

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

  Future<void> _next() async {
    if (questionIndex >= 4) {
      await _finish();
      return;
    }

    answerController.clear();

    setState(() {
      questionIndex++;
    });

    await _generateQuestion();
  }

  Future<void> _finish() async {
    setState(() {
      loading = true;
    });

    try {
      final result = await ai.send(
        request: {
          'task': 'analyze_active_recall_session',
          'content': widget.sourceContent,
          'selected_topic_ids': widget.selectedTopicIds,
          'questions_answered': questionIndex + 1,
          'score': score,
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
      return _buildResults();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Recall'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Question ${questionIndex + 1} of 5',
          ),
          const SizedBox(height: 20),
          if (loading && question.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  question,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: answerController,
              enabled: !submitted && !loading,
              minLines: 8,
              maxLines: 16,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Answer from memory...',
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
                      : const Text('Submit'),
                ),
              ),
            if (submitted)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                          onPressed: _next,
                          child: Text(
                            questionIndex >= 4
                                ? 'View Results'
                                : 'Next',
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
    );
  }

  Widget _buildResults() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recall Results'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Session Results',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(text),
          ],
        ),
      ),
    );
  }
}
