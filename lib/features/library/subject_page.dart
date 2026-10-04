import 'package:flutter/material.dart';

import '../../core/database/database_repository.dart';
import 'topic_page.dart';

final _repo = DatabaseRepository.instance;

class StudyPage extends StatefulWidget {
  const StudyPage({
    super.key,
  });

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  List<Map<String, dynamic>> subjects = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await _repo.getSubjects();

    if (!mounted) return;

    setState(() {
      subjects = data;
      loading = false;
    });
  }

  Future<void> openSubject(
    Map<String, dynamic> subject,
  ) async {
    final id = subject['id'];

    if (id is! int) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopicPage(
          subjectId: id,
          subjectName:
              subject['name']?.toString() ??
                  'Subject',
        ),
      ),
    );

    if (!mounted) return;

    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: subjects.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(
                          child: Text(
                            'No subjects yet.',
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: subjects.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final subject =
                            subjects[index];

                        return Card(
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading:
                                const CircleAvatar(
                              child: Icon(
                                Icons.menu_book_outlined,
                              ),
                            ),
                            title: Text(
                              subject['name']
                                      ?.toString() ??
                                  'Subject',
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              'Topics and learning materials',
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                            ),
                            onTap: () =>
                                openSubject(subject),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
