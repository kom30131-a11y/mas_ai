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
  bool saving = false;
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
    final content = await repo.getContent(
      topicId: widget.topicId,
    );

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

  Future<void> _finish() async {
    if (saving) return;

    setState(() {
      saving = true;
    });

    try {
      final topics = await repo.getTopics(
        subjectId: widget.subjectId,
      );

      Map<String, dynamic>? topic;

      for (final item in topics) {
        if (item['id'] == widget.topicId) {
          topic = item;
          break;
        }
      }

      final currentMastery =
          (topic?['mastery'] as num?)?.toDouble() ?? 0.0;

      final newMastery =
          (currentMastery + 10.0).clamp(0.0, 100.0);

      await repo.updateTopicMastery(
        topicId: widget.topicId,
        mastery: newMastery,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save study progress.',
          ),
        ),
      );
    }
  }

  void _next() {
    if (stage < stages.length - 1) {
      setState(() {
        stage++;
      });
      return;
    }

    _finish();
  }

  void _back() {
    if (saving) return;

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
              const Icon(
                Icons.quiz_outlined,
                size: 42,
              ),
              const SizedBox(height: 12),
              const Text(
                'The test engine will be connected '
                'to this study session.',
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
                  onPressed: saving ? null : _back,
                  child: const Text('Back'),
                ),
              ),
            if (stage > 0)
              const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: saving ? null : _next,
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        stage ==
                                stages.length - 1
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
