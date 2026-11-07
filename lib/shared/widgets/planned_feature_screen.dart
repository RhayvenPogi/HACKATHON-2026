import 'package:flutter/material.dart';
import 'package:muni_app/core/theme/app_colors.dart';

/// Honest placeholder for features not yet implemented.
class PlannedFeatureScreen extends StatelessWidget {
  const PlannedFeatureScreen({
    super.key,
    required this.title,
    required this.phase,
    required this.description,
  });

  final String title;
  final String phase;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction_outlined,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Planned for $phase',
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}