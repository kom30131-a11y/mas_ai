import 'package:flutter/material.dart';

class StudyProgress extends StatelessWidget {
  final int current;
  final int total;

  const StudyProgress({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : current / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        8,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: value),
          const SizedBox(height: 6),
          Text('$current / $total'),
        ],
      ),
    );
  }
}
