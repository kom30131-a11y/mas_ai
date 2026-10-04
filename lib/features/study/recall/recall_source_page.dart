import 'package:flutter/material.dart';

import '../../../core/database/database_repository.dart';
import 'recall_scope_page.dart';

class RecallSourcePage extends StatefulWidget {
  final int subjectId;
  final String mode;
  final int? folderId;
  final String? folderName;

  const RecallSourcePage({
    super.key,
    required this.subjectId,
    this.mode = 'recall',
    this.folderId,
    this.folderName,
  });

  @override
  State<RecallSourcePage> createState() => _RecallSourcePageState();
}

class _RecallSourcePageState extends State<RecallSourcePage> {
  final repo = DatabaseRepository.instance;

  List<Map<String, dynamic>> folders = [];
  List<Map<String, dynamic>> materials = [];
  bool loading = true;

  bool get isInsideFolder => widget.folderId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (isInsideFolder) {
      materials = await repo.getContent(
        folderId: widget.folderId,
      );
    } else {
      final allFolders = await repo.getFolders();

      folders = allFolders.where((folder) {
        return folder['subject_id'] == widget.subjectId;
      }).toList();
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  void _openFolder(Map<String, dynamic> folder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecallSourcePage(
          subjectId: widget.subjectId,
          mode: widget.mode,
          folderId: folder['id'] as int,
          folderName: folder['name']?.toString(),
        ),
      ),
    );
  }

  void _openMaterial(Map<String, dynamic> material) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecallScopePage(
          subjectId: widget.subjectId,
          folderId: widget.folderId ?? 0,
          materialId: material['id'] as int,
          materialTitle:
              material['title']?.toString() ?? 'Material',
          mode: widget.mode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isInsideFolder
              ? widget.folderName ?? 'Folder'
              : widget.mode == 'explain'
                  ? 'Explain'
                  : 'Active Recall',
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : isInsideFolder
              ? _buildMaterials()
              : _buildFolders(),
    );
  }

  Widget _buildFolders() {
    if (folders.isEmpty) {
      return const Center(
        child: Text('No folders'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: folders.length,
      itemBuilder: (_, index) {
        final folder = folders[index];

        return Card(
          child: ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(
              folder['name']?.toString() ?? 'Folder',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () => _openFolder(folder),
          ),
        );
      },
    );
  }

  Widget _buildMaterials() {
    if (materials.isEmpty) {
      return const Center(
        child: Text('No materials'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: materials.length,
      itemBuilder: (_, index) {
        final material = materials[index];

        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.description_outlined,
            ),
            title: Text(
              material['title']?.toString() ?? 'Material',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () => _openMaterial(material),
          ),
        );
      },
    );
  }
}
