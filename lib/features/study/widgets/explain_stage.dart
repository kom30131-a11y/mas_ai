import 'package:flutter/material.dart';

class ExplainStage extends StatefulWidget {
  const ExplainStage({super.key});

  @override
  State<ExplainStage> createState() =>
      _ExplainStageState();
}

class _ExplainStageState
    extends State<ExplainStage> {
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
                'Explain',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Explain the material in your own words '
                'as if you were teaching someone else.',
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                minLines: 8,
                maxLines: null,
                textInputAction:
                    TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Explain it...',
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
