import 'package:flutter/material.dart';

class RecallStage extends StatefulWidget {
  const RecallStage({super.key});

  @override
  State<RecallStage> createState() =>
      _RecallStageState();
}

class _RecallStageState extends State<RecallStage> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Recall',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Without looking at the material, '
                'write what you remember.',
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                minLines: 8,
                maxLines: null,
                textInputAction:
                    TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Write from memory...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
