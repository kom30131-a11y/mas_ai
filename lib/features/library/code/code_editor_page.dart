import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/database/database_repository.dart';
import '../../../core/storage/library_storage_service.dart';

class CodeEditorPage extends StatefulWidget {
  final String title;
  final String path;
  final int contentId;

  const CodeEditorPage({
    super.key,
    required this.title,
    required this.path,
    required this.contentId,
  });

  @override
  State<CodeEditorPage> createState() =>
      _CodeEditorPageState();
}

class _CodeEditorPageState
    extends State<CodeEditorPage> {
  final repo =
      DatabaseRepository.instance;

  final storage =
      LibraryStorageService.instance;

  late final TextEditingController
      _controller;

  bool loading = true;
  bool saving = false;
  bool dirty = false;

  @override
  void initState() {
    super.initState();

    _controller =
        TextEditingController();

    _load();
  }

  Future<void> _load() async {
    try {
      final file = File(widget.path);

      final text =
          await file.readAsString();

      _controller.text = text;

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Could not read this code file.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (saving) return;

    setState(() => saving = true);

    try {
      final file = File(widget.path);

      await file.writeAsString(
        _controller.text,
      );

      final hash =
          await storage.hashFile(
        widget.path,
      );

      final files =
          await repo.getFiles(
        contentId:
            widget.contentId,
      );

      if (files.isNotEmpty) {
        await repo.updateFileHash(
          fileId:
              files.first['id'] as int,
          hash: hash,
        );
      }

      await repo.updateContent(
        contentId:
            widget.contentId,
        content:
            _controller.text,
      );

      if (!mounted) return;

      setState(() {
        dirty = false;
        saving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Saved.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => saving = false);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save the file.',
          ),
        ),
      );
    }
  }

  String get _extension {
    final name =
        widget.path.split('/').last;

    final index = name.lastIndexOf('.');

    if (index == -1) return '';

    return name
        .substring(index + 1)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(
              right: 4,
            ),
            child: Center(
              child: Text(
                _extension,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Save',
            onPressed:
                saving ? null : _save,
            icon: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    dirty
                        ? Icons.save
                        : Icons.check,
                  ),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Code',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(
                          fontWeight:
                              FontWeight.w700,
                        ),
                  ),
                ),
                const Divider(
                  height: 1,
                ),
                Expanded(
                  child: TextField(
                    controller:
                        _controller,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    onChanged: (_) {
                      if (!dirty &&
                          mounted) {
                        setState(
                          () => dirty = true,
                        );
                      }
                    },
                    textAlign:
                        TextAlign.left,
                    textDirection:
                        TextDirection.ltr,
                    keyboardType:
                        TextInputType.multiline,
                    style:
                        const TextStyle(
                      fontFamily:
                          'monospace',
                      fontSize: 14,
                      height: 1.45,
                    ),
                    decoration:
                        const InputDecoration(
                      border:
                          InputBorder.none,
                      contentPadding:
                          EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
