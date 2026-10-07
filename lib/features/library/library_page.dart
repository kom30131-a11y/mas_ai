import 'package:flutter/material.dart';

import '../../core/database/database_repository.dart';
import '../../core/storage/library_storage_service.dart';
import 'actions/library_actions.dart' as actions;
import 'search/library_search_page.dart';
import 'settings/settings_page.dart';
import 'subject_page.dart';

final _repo = DatabaseRepository.instance;
final _storage = LibraryStorageService.instance;

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
    try {
      if (await _storage.ensureReady(requestPermission: false)) {
        await _storage.syncFolders();
      }
    } catch (_) {}

    try {
      final data = await _repo.getSubjects();
      if (!mounted) return;
      setState(() {
        subjects = data;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        subjects = [];
        loading = false;
      });
    }
  }

  Future<void> openSearch() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LibrarySearchPage()),
    );
    if (mounted) await load();
  }

  Future<void> openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
    if (mounted) await load();
  }

  Future<void> openSubject(Map<String, dynamic> item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubjectPage(
          subjectId: item['id'] as int,
          subjectName: item['name']?.toString() ?? 'Subject',
        ),
      ),
    );
    if (mounted) await load();
  }

  void showSubjectMenu(Map<String, dynamic> item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  actions.renameSubject(context, item, load);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  actions.removeSubject(context, item, load);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? const Color(0xFFF5F9F8)
          : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.auto_stories_outlined,
                color: scheme.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Library',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Search',
            onPressed: openSearch,
            icon: const Icon(Icons.search_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton.filled(
              tooltip: 'Add Subject',
              onPressed: () => actions.addSubject(context, load),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: subjects.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      children: [
                        const SizedBox(height: 120),
                        Container(
                          width: 76,
                          height: 76,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: .10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.library_books_outlined,
                            size: 36,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'No subjects yet',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a subject to start organizing your study materials.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: FilledButton.icon(
                            onPressed: () => actions.addSubject(context, load),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Subject'),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      children: [
                        Text(
                          'Subjects',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...subjects.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: theme.brightness == Brightness.light
                                  ? Colors.white
                                  : scheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => openSubject(item),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 14, 8, 14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: scheme.primary
                                              .withValues(alpha: .10),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: Icon(
                                          Icons.menu_book_rounded,
                                          color: scheme.primary,
                                          size: 25,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          (item['name']
                                                      ?.toString()
                                                      .trim()
                                                      .isEmpty ??
                                                  true)
                                              ? 'Untitled'
                                              : item['name'].toString(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'More',
                                        onPressed: () => showSubjectMenu(item),
                                        icon:
                                            const Icon(Icons.more_vert_rounded),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}
