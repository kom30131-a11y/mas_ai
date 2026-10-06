import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/settings/app_settings_controller.dart';
import '../../../core/storage/library_storage_service.dart';
import '../content/duplicate_files_page.dart';

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

    if (!mounted) return;

    setState(() {
      storageReady = ready;
    });
  }

  Future<void> _enableStorage() async {
    setState(() => busy = true);

    final ready = await storage.ensureReady(
      requestPermission: true,
    );

    if (ready) {
      await storage.syncFolders();
    }

    if (!mounted) return;

    setState(() {
      storageReady = ready;
      busy = false;
    });

    if (!ready) {
      await openAppSettings();
    }
  }

  Future<void> _syncStorage() async {
    setState(() => busy = true);

    try {
      final ready = await storage.ensureReady(
        requestPermission: true,
      );

      if (ready) {
        await storage.syncFolders();
      }

      if (!mounted) return;

      setState(() {
        storageReady = ready;
        busy = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ready
                ? 'تمت مزامنة مجلدات MedLibra.'
                : 'تعذر الوصول إلى التخزين.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => busy = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر مزامنة التخزين.'),
        ),
      );
    }
  }

  Future<void> _selectTheme() async {
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _themeTile(
                ThemeMode.system,
                'System',
                Icons.brightness_auto,
              ),
              _themeTile(
                ThemeMode.light,
                'Light',
                Icons.light_mode_outlined,
              ),
              _themeTile(
                ThemeMode.dark,
                'Dark',
                Icons.dark_mode_outlined,
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    await settings.setThemeMode(selected);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _selectLanguage() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _languageTile(
                'ar',
                'العربية',
                Icons.language,
              ),
              _languageTile(
                'en',
                'English',
                Icons.language,
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    await settings.setLanguage(selected);

    if (mounted) {
      setState(() {});
    }
  }

  Widget _themeTile(
    ThemeMode mode,
    String title,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: settings.themeMode == mode
          ? const Icon(Icons.check)
          : null,
      onTap: () => Navigator.pop(context, mode),
    );
  }

  Widget _languageTile(
    String language,
    String title,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: settings.locale.languageCode == language
          ? const Icon(Icons.check)
          : null,
      onTap: () => Navigator.pop(context, language),
    );
  }

  String _themeName() {
    return switch (settings.themeMode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };
  }

  String _languageName() {
    return settings.isArabic ? 'العربية' : 'English';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          32,
        ),
        children: [
          _section('Profile'),

          Card(
            elevation: 0,
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(
                  Icons.local_library_outlined,
                ),
              ),
              title: const Text('MedLibra'),
              subtitle: const Text(
                'Your library data stays on this device.',
              ),
            ),
          ),

          const SizedBox(height: 18),

          _section('Appearance'),

          _card(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: _themeName(),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: _selectTheme,
          ),

          const SizedBox(height: 10),

          _card(
            icon: Icons.language,
            title: 'Language',
            subtitle: _languageName(),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: _selectLanguage,
          ),

          const SizedBox(height: 18),

          _section('Library storage'),

          _card(
            icon: Icons.folder_outlined,
            title: 'MedLibra folder',
            subtitle: storageReady
                ? 'Internal storage / MedLibra'
                : 'Storage access is not enabled',
            trailing: storageReady
                ? const Icon(
                    Icons.check_circle_outline,
                  )
                : busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : FilledButton(
                        onPressed: _enableStorage,
                        child: const Text('Enable'),
                      ),
            onTap: storageReady
                ? null
                : _enableStorage,
          ),

          const SizedBox(height: 10),

          _card(
            icon: Icons.sync,
            title: 'Sync folders',
            subtitle:
                'Create and synchronize real subject and folder directories',
            trailing: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.chevron_right,
                  ),
            onTap: busy ? null : _syncStorage,
          ),

          const SizedBox(height: 10),

          _card(
            icon: Icons.find_in_page_outlined,
            title: 'Duplicate files',
            subtitle:
                'Find identical files using their file hash',
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const DuplicateFilesPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 18),

          _section('Files'),

          _card(
            icon: Icons.description_outlined,
            title: 'Word & PowerPoint',
            subtitle:
                'Open supported documents inside MedLibra',
            trailing: const Icon(
              Icons.visibility_outlined,
            ),
          ),

          const SizedBox(height: 10),

          _card(
            icon: Icons.picture_as_pdf_outlined,
            title: 'PDF',
            subtitle:
                'Open PDF files inside MedLibra',
            trailing: const Icon(
              Icons.visibility_outlined,
            ),
          ),

          const SizedBox(height: 18),

          _section('Storage information'),

          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Physical storage',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    storageReady
                        ? '/storage/emulated/0/MedLibra'
                        : 'Storage is not currently available.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'MedLibra keeps imported files in real phone storage. '
                    'Subjects, folders and nested folders are mirrored '
                    'as real directories and remain visible in the phone '
                    'file manager.',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          _section('About'),

          Card(
            elevation: 0,
            child: const ListTile(
              leading: Icon(
                Icons.info_outline,
              ),
              title: Text('MedLibra'),
              subtitle: Text(
                'Medical learning and library application',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        4,
        0,
        4,
        8,
      ),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
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
