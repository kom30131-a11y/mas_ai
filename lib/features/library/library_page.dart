import 'package:flutter/material.dart';
import '../../core/database/database_repository.dart';
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

  Future<void> addSubject() async {
    final c = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New subject'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Subject name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = c.text.trim();
              if (v.isNotEmpty) Navigator.pop(context, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    c.dispose();

    if (!mounted || name == null) return;

    await _repo.insertSubject({
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
    });

    await load();
  }

  Future<void> rename(Map<String, dynamic> x) async {
    final c = TextEditingController(text: x['name']);

    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename subject'),
        content: TextField(
          controller: c,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = c.text.trim();
              if (v.isNotEmpty) Navigator.pop(context, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    c.dispose();

    if (!mounted || name == null) return;

    await _repo.renameSubject(
      subjectId: x['id'],
      name: name,
    );

    await load();
  }

  Future<void> remove(Map<String, dynamic> x) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete subject?'),
            content: const Text('This subject will be deleted.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    await _repo.deleteSubject(x['id']);
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            onPressed: addSubject,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: subjects.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(
                          child: Text('No subjects yet'),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: subjects.length,
                      itemBuilder: (_, i) {
                        final x = subjects[i];

                        return ListTile(
                          leading: const Icon(Icons.menu_book_outlined),
                          title: Text(x['name'] ?? 'Untitled'),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubjectPage(
                                  subjectId: x['id'],
                                  subjectName: x['name'] ?? 'Subject',
                                ),
                              ),
                            );
                            if (mounted) await load();
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'r') {
                                rename(x);
                              } else {
                                remove(x);
                              }
                            },
                            itemBuilder: (_) => const [
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
