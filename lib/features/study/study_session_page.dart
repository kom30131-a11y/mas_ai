import 'package:flutter/material.dart';

import '../../core/database/database_repository.dart';

final _repo = DatabaseRepository.instance;

class StudySessionPage extends StatefulWidget {
  final int subjectId;
  final int topicId;
  final int contentId;

  const StudySessionPage({
    super.key,
    required this.subjectId,
    required this.topicId,
    required this.contentId,
  });

  @override
  State<StudySessionPage> createState() => _StudySessionPageState();
}

class _StudySessionPageState extends State<StudySessionPage> {
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
    final items = await _repo.getContent(
      topicId: widget.topicId,
    );

    if (!mounted) return;

    Map<String, dynamic>? found;

    for (final item in items) {
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
    if (stage >= stages.length - 1) return;

    setState(() {
      stage++;
    });
  }

  void _previous() {
    if (stage <= 0) return;

    setState(() {
      stage--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          material?['title']?.toString() ?? 'Study',
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : material == null
              ? const Center(
                  child: Text('Material not found.'),
                )
              : Column(
                  children: [
                    _progress(),
                    Expanded(
                      child: _stage(),
                    ),
                    _navigation(),
                  ],
                ),
    );
  }

  Widget _progress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stages[stage],
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (stage + 1) / stages.length,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < stages.length; i++)
                Text(
                  stages[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: i == stage
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stage() {
    switch (stage) {
      case 0:
        return _learn();
      case 1:
        return _recall();
      case 2:
        return _explain();
      case 3:
        return _quickTest();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _learn() {
    final title =
        material!['title']?.toString() ?? 'Untitled';

    final content =
        material!['content']?.toString() ?? '';

    return _page(
      title,
      content.isEmpty
          ? 'No study text is available for this material.'
          : content,
    );
  }

  Widget _recall() {
    return _page(
      'Recall',
      'Close the material and recall the important information from memory.',
    );
  }

  Widget _explain() {
    return _page(
      'Explain',
      'Explain the material in your own words as if you were teaching another student.',
    );
  }

  Widget _quickTest() {
    return _page(
      'Quick Test',
      'The AI-generated test will be connected here after the study-session foundation is complete.',
    );
  }

  Widget _page(
    String title,
    String text,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall,
              ),
              const SizedBox(height: 20),
              SelectableText(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navigation() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16,
        ),
        child: Row(
          children: [
            if (stage > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previous,
                  child: const Text('Back'),
                ),
              ),
            if (stage > 0)
              const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed:
                    stage < stages.length - 1
                        ? _next
                        : () =>
                            Navigator.pop(context),
                child: Text(
                  stage < stages.length - 1
                      ? 'Continue'
                      : 'Finish',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
