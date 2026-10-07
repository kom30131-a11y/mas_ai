import 'package:flutter/material.dart';

import '../../../core/database/database_repository.dart';
import '../../../core/storage/library_storage_service.dart';

class MoveContentPage extends StatefulWidget {
  final Map<String, dynamic> content;
  final int? currentFolderId;
  final int subjectId;

  const MoveContentPage({
    super.key,
    required this.content,
    required this.currentFolderId,
    required this.subjectId,
  });

  @override
  State<MoveContentPage> createState() =>
      _MoveContentPageState();
}

class _MoveContentPageState
    extends State<MoveContentPage> {
  final repo =
      DatabaseRepository.instance;

  final storage =
      LibraryStorageService.instance;

  List<Map<String, dynamic>>
      subjects = [];

  List<Map<String, dynamic>>
      folders = [];

  bool loading = true;
  bool moving = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final loadedSubjects =
        await repo.getSubjects();

    final loadedFolders =
        await repo.getAllFolders();

    if (!mounted) return;

    setState(() {
      subjects =
          loadedSubjects;

      folders =
          loadedFolders;

      loading = false;
    });
  }

  List<Map<String, dynamic>>
      foldersForSubject(
    int subjectId,
  ) {
    return folders
        .where(
          (item) =>
              item['subject_id'] ==
              subjectId,
        )
        .toList();
  }

  bool isCurrentLocation(
    int subjectId,
    int? folderId,
  ) {
    return subjectId ==
            widget.subjectId &&
        folderId ==
            widget.currentFolderId;
  }

  String folderPath(
    int folderId,
    int subjectId,
  ) {
    final subjectFolders =
        foldersForSubject(
      subjectId,
    );

    final byId =
        <int, Map<String, dynamic>>{
      for (final item
          in subjectFolders)
        item['id'] as int:
            item,
    };

    final names =
        <String>[];

    int? current =
        folderId;

    while (current != null) {
      final folder =
          byId[current];

      if (folder == null) {
        break;
      }

      names.insert(
        0,
        folder['name']
            .toString(),
      );

      current =
          folder['parent_id']
              as int?;
    }

    return names.join(
      ' / ',
    );
  }

  Future<void> moveTo({
    required int subjectId,
    required int? folderId,
  }) async {
    if (isCurrentLocation(
      subjectId,
      folderId,
    )) {
      Navigator.pop(
        context,
        false,
      );

      return;
    }

    setState(
      () => moving = true,
    );

    try {
      await storage.moveContentFile(
        content: widget.content,
        destinationSubjectId:
            subjectId,
        destinationFolderId:
            folderId,
      );

      if (mounted) {
        Navigator.pop(
          context,
          true,
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(
        () => moving = false,
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not move this material: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Move material',
        ),
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ListView(
              children: [
                for (final subject
                    in subjects) ...[
                  ListTile(
                    contentPadding:
                        const EdgeInsets.fromLTRB(
                      20,
                      12,
                      16,
                      4,
                    ),
                    leading:
                        const Icon(
                      Icons
                          .folder_special_outlined,
                    ),
                    title: Text(
                      subject['name']
                          .toString(),
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                  ListTile(
                    contentPadding:
                        const EdgeInsets.only(
                      left: 52,
                      right: 16,
                    ),
                    leading:
                        const Icon(
                      Icons
                          .home_outlined,
                    ),
                    title:
                        const Text(
                      'Subject root',
                    ),
                    subtitle:
                        const Text(
                      'Root of this subject',
                    ),
                    trailing:
                        isCurrentLocation(
                                subject['id']
                                    as int,
                                null)
                            ? const Icon(
                                Icons.check,
                              )
                            : null,
                    onTap:
                        moving
                            ? null
                            : () =>
                                moveTo(
                              subjectId:
                                  subject['id']
                                      as int,
                              folderId:
                                  null,
                            ),
                  ),
                  for (final folder
                      in foldersForSubject(
                    subject['id']
                        as int,
                  ))
                    ListTile(
                      contentPadding:
                          const EdgeInsets.only(
                        left: 52,
                        right: 16,
                      ),
                      leading:
                          const Icon(
                        Icons
                            .folder_outlined,
                      ),
                      title:
                          Text(
                        folder['name']
                            .toString(),
                      ),
                      subtitle:
                          Text(
                        folderPath(
                          folder['id']
                              as int,
                          subject['id']
                              as int,
                        ),
                      ),
                      trailing:
                          isCurrentLocation(
                            subject['id']
                                as int,
                            folder['id']
                                as int,
                          )
                              ? const Icon(
                                  Icons.check,
                                )
                              : null,
                      onTap:
                          moving
                              ? null
                              : () =>
                                  moveTo(
                                    subjectId:
                                        subject['id']
                                            as int,
                                    folderId:
                                        folder['id']
                                            as int,
                                  ),
                    ),
                ],
              ],
            ),
    );
  }
}
