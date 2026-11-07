import 'package:flutter/material.dart';
import 'package:muni_app/core/constants/app_routes.dart';
import 'package:muni_app/core/constants/app_strings.dart';
import 'package:muni_app/core/theme/app_colors.dart';
import 'package:muni_app/shared/widgets/app_button.dart';
import 'package:muni_app/shared/widgets/disclaimer_banner.dart';
import 'package:muni_app/shared/widgets/muni_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const padding = 24.0;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(padding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - padding * 2,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(),
                    const FlowLogo(),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.appTagline,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'FLOW helps you check in on how you have been feeling '
                      'through a structured questionnaire, understand your '
                      'results, and find mental health support in the City '
                      'of San Fernando.',
                      style: textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    const DisclaimerBanner(),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Get Started',
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.onboarding),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}