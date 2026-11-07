import 'package:flutter/material.dart';
import 'package:muni_app/core/theme/app_colors.dart';
import 'package:muni_app/features/results/widgets/severity_style.dart';
import 'package:muni_app/models/assessment_response.dart';
import 'package:muni_app/shared/widgets/info_card.dart';

class SubscaleResultCard extends StatelessWidget {
  const SubscaleResultCard({super.key, required this.result});

  final SubscaleResult result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final score = result.score;
    final guidance = result.guidance;
    final style = score.severity.style;

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(result.subscale.label, style: textTheme.titleLarge),
              ),
              SeverityChip(severity: score.severity),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${score.score} / ${score.maximumScore}',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score.score / score.maximumScore,
              minHeight: 8,
              color: style.foreground,
              backgroundColor: AppColors.border,
              semanticsLabel: '${result.subscale.label} score'
              '${score.score} of ${score.maximumScore}',
            ),
          ),
          const SizedBox(height: 16),
          Text(guidance.title, style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(guidance.message, style: textTheme.bodyMedium),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What you can do',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(guidance.recommendation, style: textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}