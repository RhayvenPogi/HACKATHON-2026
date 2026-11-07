import 'package:flutter/material.dart';
import 'package:muni_app/core/constants/app_routes.dart';
import 'package:muni_app/core/constants/app_strings.dart';
import 'package:muni_app/shared/widgets/app_button.dart';
import 'package:muni_app/shared/widgets/disclaimer_banner.dart';
import 'package:muni_app/shared/widgets/info_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About & privacy',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.about),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Welcome to FLOW', style: textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'How have you been feeling lately? Take a few minutes to '
              'check in with yourself.',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            InfoCard(
              icon: Icons.assignment_outlined,
              title: 'Mental health check-in',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Answer the 42-item DASS questionnaire and receive '
                    'preliminary screening results with general guidance.',
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Start assessment',
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.assessment),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            InfoCard(
              icon: Icons.location_on_outlined,
              title: 'Find a facility',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Locate mental health facilities and support services '
                    'in the City of San Fernando.',
                  ),
                  const SizedBox(height: 16),
                  AppButton.secondary(
                    label: 'Open facility locator',
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.facilities),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            InfoCard(
              icon: Icons.support_agent,
              title: 'Need to talk to someone now?',
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.crisisSupport),
              child: const Text(
                'Free, 24/7 crisis hotline from the National Center for '
                'Mental Health. Tap to see the numbers.',
              ),
            ),
            const SizedBox(height: 16),
            const DisclaimerBanner(),
          ],
        ),
      ),
    );
  }
}