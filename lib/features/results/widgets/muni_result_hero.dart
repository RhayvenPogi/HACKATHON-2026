import 'package:flutter/material.dart';
import 'package:muni_app/models/severity.dart';
import 'package:muni_app/shared/widgets/muni_ui.dart';

class MuniResultHero extends StatelessWidget {
  const MuniResultHero({super.key, required this.highest});

  /// Highest severity across all subscales.
  final Severity highest;

  static (String, String, int) _copy(Severity s) => switch (s) {
        Severity.normal => (
            'Doing okay',
            'Your answers are in the normal range right now.',
            1
          ),
        Severity.mild => (
            'Mild signs',
            'A few things are weighing on you a little.',
            1
          ),
        Severity.moderate => (
            'Moderate signs',
            'Some things are feeling heavy. Support could help.',
            2
          ),
        Severity.severe => (
            'Strong signs',
            'You may be carrying a lot right now. You don\'t have to do it alone.',
            3
          ),
        Severity.extremelySevere => (
            'Very strong signs',
            'Please consider reaching out to someone soon.',
            3
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (title, sub, lit) = _copy(highest);
    return MuniCard(
      color: MuniColors.leaf,
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your check-in result',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          const SizedBox(height: 6),
          Text(sub,
              style: const TextStyle(
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(height: 16),
          Semantics(
            label: 'Level $lit of 3',
            child: Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: i < lit ? 1.0 : 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}