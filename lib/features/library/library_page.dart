import 'package:flutter/material.dart';

import '../../core/database/database_repository.dart';
import 'actions/library_actions.dart' as actions;
import 'search/library_search_page.dart';
import 'subject_page.dart';

final _repo = DatabaseRepository.instance;

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryState();
}

class _LibraryState extends State<LibraryPage> {
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

  Future<void> openSearch() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LibrarySearchPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: openSearch,
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () =>
                actions.addSubject(context, load),
            icon: const Icon(Icons.add),
          ),
        ],
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
                            'No subjects yet',
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: subjects.length,
                      itemBuilder: (_, i) {
                        final item = subjects[i];

                        return ListTile(
                          leading: const Icon(
                            Icons.menu_book_outlined,
                          ),
                          title: Text(
                            item['name']?.toString() ??
                                'Untitled',
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SubjectPage(
                                  subjectId:
                                      item['id'],
                                  subjectName:
                                      item['name']
                                              ?.toString() ??
                                          'Subject',
                                ),
                              ),
                            );

                            if (mounted) {
                              await load();
                            }
                          },
                          trailing:
                              PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'r') {
                                actions.renameSubject(
                                  context,
                                  item,
                                  load,
                                );
                              } else {
                                actions.removeSubject(
                                  context,
                                  item,
                                  load,
                                );
                              }
                            },
                            itemBuilder: (_) =>
                                const [
                              PopupMenuItem(
                                value: 'r',
                                child: Text('Rename'),
                              ),
                              PopupMenuItem(
                                value: 'd',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
