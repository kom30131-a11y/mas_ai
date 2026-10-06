import 'package:flutter/material.dart';

import 'core/database/database_service.dart';
import 'core/settings/app_settings_controller.dart';
import 'core/storage/library_storage_service.dart';
import 'features/library/library_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseService.instance.initialize();
  await AppSettingsController.instance.load();
  final storage = LibraryStorageService.instance;
  if (await storage.ensureReady(requestPermission: true)) {
    await storage.syncFolders();
  }

  runApp(const MasAiApp());
}

class MasAiApp extends StatelessWidget {
  const MasAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsController.instance;

    return AnimatedBuilder(
      animation: settings,
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MAS AI',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF0F766E),
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF5F9F8),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF0F766E),
          brightness: Brightness.dark,
        ),
        themeMode: settings.themeMode,
        home: const LibraryPage(),
      ),
    );
  }
}
