import 'package:flutter/material.dart';

class WordViewerPage extends StatelessWidget {
  final String title;
  final String path;
  final VoidCallback onOpen;

  const WordViewerPage({
    super.key,
    required this.title,
    required this.path,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.description_outlined,
                size: 72,
              ),
              const SizedBox(height: 20),
              const Text(
                'Word document',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This file will be opened with a compatible app.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open file'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
