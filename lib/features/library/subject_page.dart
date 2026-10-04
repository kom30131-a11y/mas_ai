import 'package:flutter/material.dart';

import '../../core/database/database_repository.dart';
import 'topic_page.dart';

class SubjectPage extends StatefulWidget {
  final int subjectId;
  final String subjectName;

  const SubjectPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  final repo = DatabaseRepository.instance;

  List<Map<String, dynamic>> topics = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await repo.getTopics(
      subjectId: widget.subjectId,
    );

    if (!mounted) return;

    setState(() {
      topics = data;
      loading = false;
    });
  }

  Future<void> openTopic() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopicPage(
          subjectId: widget.subjectId,
          subjectName: widget.subjectName,
        ),
      ),
    );

    if (mounted) {
      await load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: topics.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(
                          child: Text(
                            'No topics yet.',
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: topics.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final topic = topics[index];

                        final mastery =
                            (topic['mastery'] as num?)
                                    ?.toDouble() ??
                                0.0;

                        return Card(
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            leading: const CircleAvatar(
                              child: Icon(
                                Icons.topic_outlined,
                              ),
                            ),
                            title: Text(
                              topic['name']?.toString() ??
                                  'Topic',
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            subtitle: Padding(
                              padding:
                                  const EdgeInsets.only(
                                top: 6,
                              ),
                              child: Text(
                                'Mastery ${mastery.toStringAsFixed(0)}%',
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                            ),
                            onTap: openTopic,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
