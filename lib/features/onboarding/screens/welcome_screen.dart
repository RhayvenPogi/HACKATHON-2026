import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muni_app/core/constants/app_routes.dart';
import 'package:muni_app/core/services/consent_storage.dart';
import 'package:muni_app/features/onboarding/screens/muni_welcome_flow.dart';
import 'package:muni_app/features/onboarding/widgets/terms_sheet.dart';
import 'package:muni_app/features/professional/professional_navigation.dart';
import 'package:muni_app/shared/widgets/muni_ui.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _getStarted(BuildContext context) async {
    final storage = context.read<ConsentStorage>();
    final navigator = Navigator.of(context);

    final agreed = await showTermsSheet(context);
    if (agreed != true) return;

    await storage.recordConsent();
    navigator.pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MuniWelcomeFlow(onGetStarted: () => _getStarted(context)),
        Positioned(
          top: 0,
          right: 8,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: TextButton(
                onPressed: () => openProfessionalArea(context),
                child: const Text(
                  "I'm a mental health professional",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: MuniColors.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}