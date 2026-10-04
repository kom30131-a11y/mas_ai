import 'package:flutter/material.dart';

import '../../core/database/database_repository.dart';
import 'widgets/explain_stage.dart';
import 'widgets/learn_stage.dart';
import 'widgets/recall_stage.dart';
import 'widgets/study_progress.dart';

class StudySessionPage extends StatefulWidget {
  final int subjectId;
  final int topicId;
  final int contentId;
  final String title;

  const StudySessionPage({
    super.key,
    required this.subjectId,
    required this.topicId,
    required this.contentId,
    required this.title,
  });

  @override
  State<StudySessionPage> createState() =>
      _StudySessionPageState();
}

class _StudySessionPageState
    extends State<StudySessionPage> {
  final repo = DatabaseRepository.instance;

  Map<String, dynamic>? material;
  bool loading = true;
  int stage = 0;

  static const stages = [
    'Learn',
    'Recall',
    'Explain',
    'Quick Test',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final content = await repo.getContent();

    if (!mounted) return;

    Map<String, dynamic>? found;

    for (final item in content) {
      if (item['id'] == widget.contentId) {
        found = item;
        break;
      }
    }

    setState(() {
      material = found;
      loading = false;
    });
  }

  void _next() {
    if (stage < stages.length - 1) {
      setState(() {
        stage++;
      });
      return;
    }

    Navigator.pop(context);
  }

  void _back() {
    if (stage > 0) {
      setState(() {
        stage--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : material == null
              ? const Center(
                  child: Text(
                    'Material not found.',
                  ),
                )
              : Column(
                  children: [
                    _header(),
                    Expanded(
                      child: _stageContent(),
                    ),
                    _buttons(),
                  ],
                ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            0,
          ),
          child: Text(
            stages[stage],
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),
        ),
        StudyProgress(
          current: stage + 1,
          total: stages.length,
        ),
      ],
    );
  }

  Widget _stageContent() {
    switch (stage) {
      case 0:
        return LearnStage(
          title: widget.title,
          content:
              material!['content']?.toString() ?? '',
        );

      case 1:
        return const RecallStage();

      case 2:
        return const ExplainStage();

      case 3:
        return _quickTest();

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _quickTest() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Test',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall,
              ),
              const SizedBox(height: 16),
              const Text(
                'Questions will be generated from '
                'this material in the Test system.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(
                  Icons.quiz_outlined,
                ),
                label: const Text(
                  'Test engine coming next',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buttons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (stage > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _back,
                  child: const Text('Back'),
                ),
              ),
            if (stage > 0)
              const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _next,
                child: Text(
                  stage == stages.length - 1
                      ? 'Finish'
                      : 'Continue',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
