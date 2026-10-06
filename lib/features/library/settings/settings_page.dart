import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/settings/app_settings_controller.dart';
import '../../../core/storage/library_storage_service.dart';
import '../duplicates/duplicate_files_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final settings = AppSettingsController.instance;
  final storage = LibraryStorageService.instance;
  bool storageReady = false;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _checkStorage();
  }

  Future<void> _checkStorage() async {
    final ready = await storage.ensureReady();
    if (mounted) setState(() => storageReady = ready);
  }

  Future<void> _enableStorage() async {
    setState(() => busy = true);
    final ready = await storage.ensureReady(requestPermission: true);
    if (ready) await storage.syncFolders();
    if (mounted) {
      setState(() {
        storageReady = ready;
        busy = false;
      });
    }

    if (!ready && mounted) {
      await openAppSettings();
    }
  }

  Future<void> _theme() async {
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _themeTile(ThemeMode.system, 'System', Icons.brightness_auto),
            _themeTile(ThemeMode.light, 'Light', Icons.light_mode_outlined),
            _themeTile(ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
          ],
        ),
      ),
    );

    if (selected != null) await settings.setThemeMode(selected);
  }

  Widget _themeTile(ThemeMode mode, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: settings.themeMode == mode ? const Icon(Icons.check) : null,
      onTap: () => Navigator.pop(context, mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _section('Profile'),
          Card(
            elevation: 0,
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.person_outline),
              ),
              title: const Text('Local profile'),
              subtitle: const Text('Your MAS AI data stays on this device.'),
            ),
          ),
          const SizedBox(height: 16),
          _section('Appearance'),
          _card(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: switch (settings.themeMode) {
              ThemeMode.light => 'Light',
              ThemeMode.dark => 'Dark',
              ThemeMode.system => 'System',
            },
            onTap: _theme,
          ),
          const SizedBox(height: 16),
          _section('Library storage'),
          _card(
            icon: Icons.folder_outlined,
            title: 'MAS AI folder',
            subtitle: storageReady
                ? '/storage/emulated/0/MAS AI'
                : 'Storage access is not enabled',
            trailing: storageReady
                ? const Icon(Icons.check_circle_outline)
                : busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : FilledButton(
                        onPressed: _enableStorage,
                        child: const Text('Enable'),
                      ),
            onTap: storageReady ? null : _enableStorage,
          ),
          const SizedBox(height: 10),
          _card(
            icon: Icons.find_in_page_outlined,
            title: 'Duplicate files',
            subtitle: 'Find identical files and remove copies',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DuplicateFilesPage(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _section('About storage'),
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Imported materials are copied into the MAS AI folder. '
                'Folders created in Library are mirrored there, so files remain '
                'available from the Android file manager.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
