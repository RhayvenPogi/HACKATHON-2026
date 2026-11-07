import 'package:flutter/material.dart';
import 'package:muni_app/core/constants/app_strings.dart';
import 'package:muni_app/core/theme/app_colors.dart';

/// Original text-based FLOW identity. Replace with a real logo later.
class FlowLogo extends StatelessWidget {
  const FlowLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'FLOW logo',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(size * 0.3),
            ),
            child: ExcludeSemantics(
              child: Icon(
                Icons.waves_rounded,
                color: Colors.white,
                size: size * 0.55,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}