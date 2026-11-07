import 'package:flutter/material.dart';
import 'package:muni_app/core/theme/app_colors.dart';

class ShareDemoBanner extends StatelessWidget {
  const ShareDemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error),
      ),
      child: const Text(
        'DEMO MODE: the sharing server is not available yet. QR codes made '
        'now cannot be opened by anyone, and nothing is sent.',
        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
      ),
    );
  }
}