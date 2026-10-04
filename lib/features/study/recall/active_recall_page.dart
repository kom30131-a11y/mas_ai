import 'package:flutter/material.dart';

import '../../../ai/ai_models.dart';
import '../../../core/database/database_repository.dart';
import '../services/answer_evaluation_service.dart';
import '../services/performance_analysis_service.dart';
import '../services/question_generation_service.dart';
import '../services/review_planning_service.dart';

class ActiveRecallPage extends StatefulWidget {
  final String title;
  final int? materialId;
  final String sourceContent;
  final List<int> selectedTopicIds;

  const ActiveRecallPage({
    super.key,
    required this.title,
    this.materialId,
    required this.sourceContent,
    required this.selectedTopicIds,
  });

  @override
  State<ActiveRecallPage> createState() => _ActiveRecallPageState();
}

class _ActiveRecallPageState
    extends State<ActiveRecallPage> {
  final repo = DatabaseRepository.instance;
  final generator = QuestionGenerationService.instance;
  final evaluator = AnswerEvaluationService.instance;
  final performance = PerformanceAnalysisService.instance;
  final reviewPlanner = ReviewPlanningService.instance;

  final answerController = TextEditingController();

  List<GeneratedQuestion> questions = [];
  AnswerEvaluation? currentEvaluation;

  PerformanceAnalysis? analysis;
  PerformanceAnalysis? reviewAnalysis;

  int currentIndex = 0;
  int correctAnswers = 0;

  bool loading = true;
  bool submitted = false;
  bool finished = false;

  String error = '';

  GeneratedQuestion? get currentQuestion {
    if (questions.isEmpty) return null;
    if (currentIndex >= questions.length) return null;

    return questions[currentIndex];
  }

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    answerController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final generated =
          await generator.generateFromContent(
        sourceContent: widget.sourceContent,
        contentId: widget.materialId ?? 0,
        topicIds: widget.selectedTopicIds,
        count: 5,
        language: 'same_as_content',
      );

      if (!mounted) return;

      if (generated.isEmpty) {
        setState(() {
          loading = false;
          error = 'AI did not return any questions.';
        });
        return;
      }

      setState(() {
        questions = generated;
        currentIndex = 0;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _submit() async {
    final question = currentQuestion;
    final answer = answerController.text.trim();

    if (question == null ||
        answer.isEmpty ||
        loading ||
        submitted) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final questionData =
          Map<String, dynamic>.from(
        question.toMap(),
      );

      questionData['content_id'] =
          widget.materialId;

      questionData['topic_id'] =
          question.topicId ??
              (widget.selectedTopicIds.length == 1
                  ? widget.selectedTopicIds.first
                  : null);

      questionData['created_at'] =
          DateTime.now().toIso8601String();

      final questionId =
          await repo.insertQuestion(
        questionData,
      );

      final evaluation =
          await evaluator.evaluate(
        question: questionData,
        studentAnswer: answer,
        language: 'same_as_content',
        studyContent: widget.sourceContent,
      );

      await repo.insertAttempt({
        'question_id': questionId,
        'answer': answer,
        'is_correct': evaluation.isCorrect ? 1 : 0,
        'error_reason': [
          evaluation.errorReason,
          evaluation.knowledgeGap,
        ].where((text) => text.trim().isNotEmpty).join('\n'),
        'answered_at':
            DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      setState(() {
        currentEvaluation = evaluation;
        submitted = true;
        loading = false;

        if (evaluation.isCorrect) {
          correctAnswers++;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _next() async {
    if (currentIndex >= questions.length - 1) {
      await _finish();
      return;
    }

    answerController.clear();

    setState(() {
      currentIndex++;
      currentEvaluation = null;
      submitted = false;
      error = '';
    });
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
        review = await reviewPlanner.plan(
          language: 'same_as_content',
        );
      } catch (_) {}

      await _applyAdaptiveResults(
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

  Future<void> _applyAdaptiveResults(
    PerformanceAnalysis perf,
    PerformanceAnalysis? review,
  ) async {
    final topicIds = widget.selectedTopicIds.toSet();

    if (topicIds.isNotEmpty) {
      for (final topic in perf.topics) {
        if (!topicIds.contains(topic.topicId)) {
          continue;
        }

        await repo.updateTopicMastery(
          topicId: topic.topicId,
          mastery: topic.mastery,
        );
      }
    }

    final plans =
        review?.reviewPlans ?? perf.reviewPlans;

    for (final plan in plans) {
      if (topicIds.isNotEmpty &&
          !topicIds.contains(plan.topicId)) {
        continue;
      }

      final dueAt = DateTime.now().add(
        Duration(days: plan.intervalDays),
      );

      await repo.insertReview({
        'topic_id': plan.topicId,
        'due_at': dueAt.toIso8601String(),
        'interval_days': plan.intervalDays,
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
        title: const Text('Active Recall'),
      ),
      body: loading && questions.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (error.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(error),
                    ),
                  ),
                if (questions.isNotEmpty) ...[
                  Text(
                    '${currentIndex + 1} / ${questions.length}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        currentQuestion?.question ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: answerController,
                    enabled:
                        !submitted && !loading,
                    minLines: 8,
                    maxLines: 16,
                    decoration:
                        const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText:
                          'Answer from memory...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!submitted)
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed:
                            loading ? null : _submit,
                        child: const Text(
                          'Submit',
                        ),
                      ),
                    ),
                  if (submitted &&
                      currentEvaluation != null)
                    _feedbackCard(
                      currentEvaluation!,
                    ),
                ],
              ],
            ),
    );
  }

  Widget _feedbackCard(
    AnswerEvaluation evaluation,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              evaluation.isCorrect
                  ? 'Correct'
                  : 'Needs Review',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
            if (evaluation.explanation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(evaluation.explanation),
            ],
            if (evaluation.errorReason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Error: ${evaluation.errorReason}',
              ),
            ],
            if (evaluation.knowledgeGap.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Knowledge gap: '
                '${evaluation.knowledgeGap}',
              ),
            ],
            if (evaluation
                .recommendedAction
                .isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Next: '
                '${evaluation.recommendedAction}',
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _next,
                child: Text(
                  currentIndex ==
                          questions.length - 1
                      ? 'View Results'
                      : 'Next',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _results() {
    final perf = analysis;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recall Results'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '$correctAnswers / ${questions.length}',
            style: Theme.of(context)
                .textTheme
                .headlineMedium,
          ),
          const SizedBox(height: 20),
          _resultCard(
            'Strengths',
            perf?.strengths.join('\n') ??
                'No data available.',
          ),
          _resultCard(
            'Weaknesses',
            perf?.weaknesses.join('\n') ??
                'No data available.',
          ),
          _resultCard(
            'Summary',
            perf?.summary.isNotEmpty == true
                ? perf!.summary
                : 'No summary available.',
          ),
          if (reviewAnalysis?.reviewPlans
                  .isNotEmpty ==
              true)
            _resultCard(
              'Next reviews',
              reviewAnalysis!.reviewPlans
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
              onPressed: _returnToStudy,
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
          const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
