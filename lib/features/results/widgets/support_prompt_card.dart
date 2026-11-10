import 'package:flutter/material.dart';
import 'package:muni_app/core/constants/app_routes.dart';
import 'package:muni_app/features/results/widgets/severity_style.dart';
import 'package:muni_app/models/severity.dart';
import 'package:muni_app/shared/widgets/muni_ui.dart';

class SupportPromptCard extends StatelessWidget {
  const SupportPromptCard({super.key, required this.highest});

  /// Highest severity across all subscales.
  final Severity highest;

  @override
  Widget build(BuildContext context) {
    final bool elevated = highest.isElevated;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MuniColors.blue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            elevated
                ? 'Talking to someone could help'
                : 'Support is always available',
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: MuniColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            elevated
                ? 'One or more of your results is in the moderate range or '
                    'above. Consider reaching out to a mental health '
                    'professional. If you ever feel unsafe or overwhelmed, '
                    'call the crisis hotline right away.'
                : 'Even when results are in the normal or mild range, you can '
                    'reach out to a professional whenever you feel you need '
                    'support.',
            style: const TextStyle(
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: MuniColors.ink),
          ),
          const SizedBox(height: 16),
          if (elevated) ...[
            MuniButton(
              label: 'Get help now',
              onPressed: () => showCrisisSheet(context),
            ),
            const SizedBox(height: 10),
            MuniButton(
              label: 'Find a facility',
              variant: MuniButtonVariant.outline,
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.facilities),
            ),
          ] else
            Center(
              child: TextButton(
                onPressed: () => showCrisisSheet(context),
                child: const Text('See support options',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: MuniColors.forest)),
              ),
            ),
        ],
      ),
    );
  }
}