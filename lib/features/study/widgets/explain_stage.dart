import 'package:flutter/material.dart';

import '../../../ai/ai_models.dart';
import '../../../core/database/database_repository.dart';
import '../services/answer_evaluation_service.dart';
import '../services/performance_analysis_service.dart';
import '../services/review_planning_service.dart';

class ExplainStage extends StatefulWidget {
  final String title;
  final int? materialId;
  final String content;
  final List<int> selectedTopicIds;

  const ExplainStage({
    super.key,
    this.title = 'Explain',
    this.materialId,
    this.content = '',
    this.selectedTopicIds = const [],
  });

  @override
  State<ExplainStage> createState() =>
      _ExplainStageState();
}

class _ExplainStageState
    extends State<ExplainStage> {
  final repo = DatabaseRepository.instance;
  final evaluator = AnswerEvaluationService.instance;
  final performance =
      PerformanceAnalysisService.instance;
  final reviewPlanner =
      ReviewPlanningService.instance;

  final controller = TextEditingController();

  AnswerEvaluation? evaluation;
  PerformanceAnalysis? analysis;
  PerformanceAnalysis? reviewAnalysis;

  bool loading = false;
  bool submitted = false;
  bool finished = false;

  String error = '';

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
          content: Text(
            'Write your explanation first.',
          ),
        ),
      );
      return;
    }

    if (widget.content.trim().isEmpty) {
      setState(() {
        error = 'No study content is available.';
      });
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    try {
      final questionData =
          <String, dynamic>{
        'type': 'explain',
        'question':
            'Explain the selected study material '
            'in your own words.',
        'answer': widget.content,
        'options': '',
        'explanation': '',
        'content_id': widget.materialId,
        'topic_id':
            widget.selectedTopicIds.length == 1
                ? widget.selectedTopicIds.first
                : null,
      };

      final questionId =
          widget.materialId == null
              ? null
              : await repo.insertQuestion({
                  ...questionData,
                  'created_at':
                      DateTime.now()
                          .toIso8601String(),
                });

      final result =
          await evaluator.evaluate(
        question: questionData,
        studentAnswer: answer,
        language: 'same_as_content',
        studyContent: widget.content,
      );

      if (questionId != null) {
        await repo.insertAttempt({
          'question_id': questionId,
          'answer': answer,
          'is_correct':
              result.isCorrect ? 1 : 0,
          'error_reason': [
            result.errorReason,
            result.knowledgeGap,
          ]
              .where(
                (text) =>
                    text.trim().isNotEmpty,
              )
              .join('\n'),
          'answered_at':
              DateTime.now()
                  .toIso8601String(),
        });
      }

      if (!mounted) return;

      setState(() {
        evaluation = result;
        submitted = true;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _finish() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final perf =
          await performance.analyze(
        language: 'same_as_content',
      );

      PerformanceAnalysis? review;

      try {
        review =
            await reviewPlanner.plan(
          language: 'same_as_content',
        );
      } catch (_) {}

      await _applyResults(
        perf,
        review,
      );

      if (!mounted) return;

      setState(() {
        analysis = perf;
        reviewAnalysis = review;
        finished = true;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        finished = true;
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _applyResults(
    PerformanceAnalysis perf,
    PerformanceAnalysis? review,
  ) async {
    final topicIds =
        widget.selectedTopicIds.toSet();

    if (topicIds.isEmpty) return;

    for (final topic in perf.topics) {
      if (!topicIds.contains(topic.topicId)) {
        continue;
      }

      await repo.updateTopicMastery(
        topicId: topic.topicId,
        mastery: topic.mastery,
      );
    }

    final plans =
        review?.reviewPlans ??
            perf.reviewPlans;

    for (final plan in plans) {
      if (!topicIds.contains(plan.topicId)) {
        continue;
      }

      final dueAt =
          DateTime.now().add(
        Duration(
          days: plan.intervalDays,
        ),
      );

      await repo.insertReview({
        'topic_id': plan.topicId,
        'due_at':
            dueAt.toIso8601String(),
        'interval_days':
            plan.intervalDays,
        'ease': 2.5,
        'repetitions': 1,
      });
    }
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
          if (error.isNotEmpty)
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Text(error),
              ),
            ),
          Text(
            'Explain in your own words',
            style: Theme.of(context)
                .textTheme
                .headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            enabled:
                !submitted && !loading,
            minLines: 10,
            maxLines: 18,
            decoration:
                const InputDecoration(
              border:
                  OutlineInputBorder(),
              hintText:
                  'Explain what you learned...',
            ),
          ),
          const SizedBox(height: 16),
          if (!submitted)
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed:
                    loading ? null : _submit,
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Explanation',
                      ),
              ),
            ),
          if (submitted &&
              evaluation != null)
            _feedbackCard(
              evaluation!,
            ),
        ],
      ),
    );
  }

  Widget _feedbackCard(
    AnswerEvaluation result,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              result.isCorrect
                  ? 'Strong explanation'
                  : 'Needs Review',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
            if (result.explanation
                .isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(result.explanation),
            ],
            if (result.errorReason
                .isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Error: '
                '${result.errorReason}',
              ),
            ],
            if (result.knowledgeGap
                .isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Knowledge gap: '
                '${result.knowledgeGap}',
              ),
            ],
            if (result.recommendedAction
                .isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Next: '
                '${result.recommendedAction}',
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed:
                    loading ? null : _finish,
                child: const Text(
                  'View Results',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _results() {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Explain Results'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          _resultCard(
            'Strengths',
            analysis?.strengths
                    .join('\n') ??
                'No data available.',
          ),
          _resultCard(
            'Weaknesses',
            analysis?.weaknesses
                    .join('\n') ??
                'No data available.',
          ),
          _resultCard(
            'Summary',
            analysis?.summary
                    .isNotEmpty ==
                true
                ? analysis!.summary
                : 'No summary available.',
          ),
          if (reviewAnalysis
                  ?.reviewPlans
                  .isNotEmpty ==
              true)
            _resultCard(
              'Next reviews',
              reviewAnalysis!
                  .reviewPlans
                  .map(
                    (plan) =>
                        '${plan.topicName}: '
                        '${plan.intervalDays} day(s) '
                        '— ${plan.reason}',
                  )
                  .join('\n'),
            ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed:
                  _returnToStudy,
              child: const Text(
                'Return to Study',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(
    String title,
    String text,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 8),
            Text(text),
          ],
        ),
      ),
    );
  }
}
