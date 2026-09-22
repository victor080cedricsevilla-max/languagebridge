import 'package:flutter/material.dart';

import '../models/module_quiz.dart';
import '../utils/date_format.dart';

class LatestAssessmentCard extends StatelessWidget {
  const LatestAssessmentCard({super.key, required this.result});
  final AssessmentResult? result;

  @override
  Widget build(BuildContext context) {
    final value = result;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.fact_check_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest assessment',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value == null
                        ? 'No assessment yet. Learn, then try the quiz.'
                        : '${value.score} / ${value.total} correct · ${value.percentage}%',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (value?.completedAt != null)
                    Text(
                      DateFormats.longDate(value!.completedAt!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
