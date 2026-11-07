import 'package:flutter/material.dart';
import 'package:muni_app/models/assessment_response.dart';
import 'package:muni_app/shared/widgets/app_button.dart';
import 'package:muni_app/shared/widgets/disclaimer_banner.dart';
import 'package:muni_app/shared/widgets/info_card.dart';

/// PHASE 4 VERSION: proves end-to-end parsing. Redesigned in Phase 5.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.result});

  final AssessmentResponse result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Your results')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Preliminary screening results',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            for (final r in Subscale.values.map((s) => result[s])) ...[
              InfoCard(
                title: r.subscale.label,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Score: ${r.score.score} / ${r.score.maximumScore}'),
                    Text('Severity: ${r.score.severity.apiValue}'),
                    const SizedBox(height: 8),
                    Text(r.guidance.title, style: textTheme.titleSmall),
                    Text(r.guidance.message),
                    const SizedBox(height: 4),
                    Text(r.guidance.recommendation),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            DisclaimerBanner(message: result.notice),
            const SizedBox(height: 24),
            AppButton(
              label: 'Back to home',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}