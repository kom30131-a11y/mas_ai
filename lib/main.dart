import 'package:flutter/material.dart';

void main() {
  runApp(const MasAiApp());
}

class MasAiApp extends StatefulWidget {
  const MasAiApp({super.key});

  @override
  State<MasAiApp> createState() => _MasAiAppState();
}

class _MasAiAppState extends State<MasAiApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MAS AI',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: MasAiShell(
        themeMode: _themeMode,
        onThemeChanged: _setThemeMode,
      ),
    );
  }
}

class MasAiShell extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const MasAiShell({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<MasAiShell> createState() => _MasAiShellState();
}

class _MasAiShellState extends State<MasAiShell> {
  int _currentIndex = 0;

  final _pages = const [
    HomePage(),
    StudyPage(),
    TestPage(),
    ReviewPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Study',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz),
            label: 'Test',
          ),
          NavigationDestination(
            icon: Icon(Icons.refresh_outlined),
            selectedIcon: Icon(Icons.refresh),
            label: 'Review',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'MAS AI',
      subtitle: 'Master, Apply, Succeed.',
      children: [
        _SectionTitle('Today'),
        _Card(
          icon: Icons.today_outlined,
          title: 'Today’s tasks',
          subtitle: 'Your learning plan will appear here.',
        ),
        _SectionTitle('Review'),
        _Card(
          icon: Icons.schedule_outlined,
          title: 'Due reviews',
          subtitle: 'Spaced reviews based on your mastery.',
        ),
        _SectionTitle('Progress'),
        _Card(
          icon: Icons.trending_up,
          title: 'Learning progress',
          subtitle: 'Your topic mastery will be tracked here.',
        ),
        _SectionTitle('Recommended next step'),
        _Card(
          icon: Icons.auto_awesome,
          title: 'Adaptive learning',
          subtitle: 'MAS AI will recommend what to study next.',
        ),
      ],
    );
  }
}

class StudyPage extends StatelessWidget {
  const StudyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Study',
      subtitle: 'Learn → Recall → Explain → Quick Test',
      children: [
        _ActionCard(
          icon: Icons.upload_file_outlined,
          title: 'Add learning content',
          subtitle: 'PDF, text, notes and lectures',
        ),
        _ActionCard(
          icon: Icons.folder_outlined,
          title: 'Subjects & topics',
          subtitle: 'Organize your learning content',
        ),
        _ActionCard(
          icon: Icons.psychology_outlined,
          title: 'Active Recall',
          subtitle: 'Retrieve information instead of rereading',
        ),
        _ActionCard(
          icon: Icons.record_voice_over_outlined,
          title: 'Explain',
          subtitle: 'Teach back what you learned',
        ),
      ],
    );
  }
}

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Test',
      subtitle: 'Testing is part of learning.',
      children: [
        _ActionCard(
          icon: Icons.auto_awesome,
          title: 'AI Question Generator',
          subtitle: 'Generate questions from your study content',
        ),
        _ActionCard(
          icon: Icons.tune,
          title: 'Test settings',
          subtitle: 'Choose type, number of questions and timer',
        ),
        _ActionCard(
          icon: Icons.quiz_outlined,
          title: 'Question types',
          subtitle: 'MCQ • True/False • Fill in the Blank • More',
        ),
        _ActionCard(
          icon: Icons.analytics_outlined,
          title: 'Performance',
          subtitle: 'Analyze strengths, weaknesses and mistakes',
        ),
      ],
    );
  }
}

class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Review',
      subtitle: 'Remember longer with adaptive review.',
      children: [
        _Card(
          icon: Icons.event_available_outlined,
          title: 'Due now',
          subtitle: 'Topics scheduled for spaced retrieval.',
        ),
        _Card(
          icon: Icons.shuffle,
          title: 'Interleaved Review',
          subtitle: 'Mix related topics to strengthen connections.',
        ),
        _Card(
          icon: Icons.history,
          title: 'Recently learned',
          subtitle: 'Continue strengthening recent topics.',
        ),
        _Card(
          icon: Icons.warning_amber_outlined,
          title: 'Needs attention',
          subtitle: 'Topics requiring additional retrieval practice.',
        ),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Profile',
      subtitle: 'App and learning settings',
      children: [
        _ActionCard(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'Customize MAS AI',
        ),
        _ActionCard(
          icon: Icons.palette_outlined,
          title: 'Appearance',
          subtitle: 'Light, Dark or System',
        ),
        _ActionCard(
          icon: Icons.language_outlined,
          title: 'Language',
          subtitle: 'Application language',
        ),
        _ActionCard(
          icon: Icons.storage_outlined,
          title: 'Data',
          subtitle: 'Local learning data and storage',
        ),
        _ActionCard(
          icon: Icons.info_outline,
          title: 'About MAS AI',
          subtitle: 'Version and application information',
        ),
      ],
    );
  }
}

class _Page extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _Page({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Card({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(subtitle),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                child: Icon(icon),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 5),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
