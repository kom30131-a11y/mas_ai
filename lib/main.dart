import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'core/settings/app_settings_controller.dart';
import 'features/library/library_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppSettingsController.instance.load();
  } catch (_) {}

  runApp(const MedLibraApp());
}

class MedLibraApp extends StatelessWidget {
  const MedLibraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsController.instance;

    return AnimatedBuilder(
      animation: settings,
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MedLibra',
        locale: settings.locale,
        supportedLocales: const [
          Locale('ar'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultCupertinoLocalizations.delegate,
        ],
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
        builder: (context, child) => Directionality(
          textDirection: settings.isArabic
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const LibraryPage(),
      ),
    );
  }
}
