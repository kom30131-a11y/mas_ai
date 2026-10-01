import 'package:flutter/material.dart';

void main() {
  runApp(const MasAiApp());
}

class MasAiApp extends StatelessWidget {
  const MasAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MAS AI',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('MAS AI'),
        ),
        body: const Center(
          child: Text('MAS AI'),
        ),
      ),
    );
  }
}
