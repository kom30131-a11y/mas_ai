import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarPage extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarPage({
    super.key,
    required this.controller,
  });

  Future<void> _pageSize(BuildContext context) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.crop_portrait),
                title: const Text('A4 Portrait'),
                onTap: () => Navigator.pop(context, 'portrait'),
              ),
              ListTile(
                leading: const Icon(Icons.crop_landscape),
                title: const Text('A4 Landscape'),
                onTap: () => Navigator.pop(context, 'landscape'),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || value == null) return;

    controller.setPageSize(
      value == 'portrait'
          ? const WmlPageSize(
              width: 595.28,
              height: 841.89,
            )
          : const WmlPageSize(
              width: 841.89,
              height: 595.28,
            ),
    );

    controller.refresh();
  }

  Future<void> _orientation(BuildContext context) async {
    final value = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.stay_current_portrait),
                title: const Text('Portrait'),
                onTap: () => Navigator.pop(context, false),
              ),
              ListTile(
                leading: const Icon(Icons.stay_current_landscape),
                title: const Text('Landscape'),
                onTap: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || value == null) return;

    controller.setPageLandscape(value);
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Page size',
          onPressed: () => _pageSize(context),
          icon: const Icon(Icons.description_outlined),
        ),
        IconButton(
          tooltip: 'Orientation',
          onPressed: () => _orientation(context),
          icon: const Icon(Icons.screen_rotation),
        ),
        IconButton(
          tooltip: 'Relayout',
          onPressed: () {
            controller.relayout();
            controller.refresh();
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}
