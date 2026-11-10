import 'package:flutter/material.dart';
import 'package:muni_app/features/results/widgets/severity_style.dart';
import 'package:muni_app/models/assessment_response.dart';
import 'package:muni_app/shared/widgets/muni_ui.dart';

class SubscaleResultCard extends StatelessWidget {
  const SubscaleResultCard({super.key, required this.result});

  final SubscaleResult result;

  @override
  Widget build(BuildContext context) {
    final score = result.score;
    final guidance = result.guidance;
    final style = score.severity.style;

    return MuniCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(result.subscale.label,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: MuniColors.ink)),
              ),
              SeverityChip(severity: score.severity),
            ],
          ),
          const SizedBox(height: 12),
          Text('${score.score} / ${score.maximumScore}',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: MuniColors.ink)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score.score / score.maximumScore,
              minHeight: 8,
              color: style.foreground,
              backgroundColor: MuniColors.mint,
              semanticsLabel: '${result.subscale.label} score '
                  '${score.score} of ${score.maximumScore}',
            ),
          ),
          const SizedBox(height: 16),
          Text(guidance.title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: MuniColors.ink)),
          const SizedBox(height: 6),
          Text(guidance.message,
              style: const TextStyle(
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: MuniColors.muted)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MuniColors.mint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 20, color: MuniColors.forest),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('What you can do',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: MuniColors.forest)),
                      const SizedBox(height: 4),
                      Text(guidance.recommendation,
                          style: const TextStyle(
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                              color: MuniColors.ink)),
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