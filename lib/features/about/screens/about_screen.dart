import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muni_app/core/constants/app_routes.dart';
import 'package:muni_app/core/services/consent_storage.dart';
import 'package:muni_app/shared/widgets/app_button.dart';
import 'package:muni_app/features/professional/professional_navigation.dart';
import 'package:muni_app/shared/widgets/disclaimer_banner.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _withdraw(BuildContext context) async {
    final storage = context.read<ConsentStorage>();
    final navigator = Navigator.of(context);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Withdraw consent?'),
        content: const Text(
          'You will need to review and accept the consent again before '
          'using FLOW.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Withdraw'),
          ),
          const SizedBox(height: 12),
            TextButton(
            onPressed: () => openProfessionalArea(context),
            child: const Text("I'm a mental health professional"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await storage.withdrawConsent();
    navigator.pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About & privacy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('About FLOW', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'FLOW is a mental health early detection and referral support '
              'app for citizens of the City of San Fernando. It is a student '
              'capstone project.',
            ),
            const SizedBox(height: 16),
            const DisclaimerBanner(),
            const SizedBox(height: 24),
            Text('Your privacy', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Your questionnaire answers are sent to the FLOW server only to '
              'calculate your results. Sharing your results with a mental '
              'health professional will always require your explicit '
              'permission.',
            ),
            const SizedBox(height: 16),
            const Text(
              'This is a development build. Do not enter real personal '
              'information.',
            ),
            const SizedBox(height: 32),
            AppButton.secondary(
              label: 'Withdraw consent',
              icon: Icons.undo,
              onPressed: () => _withdraw(context),
            ),
          ],
        ),
      ),
    );
  }
}