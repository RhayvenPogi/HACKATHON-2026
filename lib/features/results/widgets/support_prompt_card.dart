import 'package:flutter/material.dart';
import 'package:muni_app/core/constants/app_routes.dart';
import 'package:muni_app/core/theme/app_colors.dart';
import 'package:muni_app/features/results/widgets/severity_style.dart';
import 'package:muni_app/models/severity.dart';
import 'package:muni_app/shared/widgets/app_button.dart';

class SupportPromptCard extends StatelessWidget {
  const SupportPromptCard({super.key, required this.highest});

  /// Highest severity across all subscales.
  final Severity highest;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool elevated = highest.isElevated;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            elevated
                ? 'Talking to someone could help'
                : 'Support is always available',
            style: textTheme.titleMedium,
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
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (elevated) ...[
            AppButton(
              label: 'Get help now',
              icon: Icons.support_agent,
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.crisisSupport),
            ),
            const SizedBox(height: 10),
            AppButton.secondary(
              label: 'Find a facility',
              icon: Icons.location_on_outlined,
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.facilities),
            ),
          ] else
            TextButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.crisisSupport),
              icon: const Icon(Icons.support_agent),
              label: const Text('See support options'),
            ),
        ],
      ),
    );
  }
}