import 'package:flutter/material.dart';
import 'package:muni_app/core/constants/app_strings.dart';
import 'package:muni_app/core/theme/app_colors.dart';

/// Non-alarming informational banner for the screening disclaimer.
class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({
    super.key,
    this.message = AppStrings.screeningDisclaimer,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}