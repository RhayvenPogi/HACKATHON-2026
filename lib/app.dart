import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muni_app/core/constants/app_routes.dart';
import 'package:muni_app/core/constants/app_strings.dart';
import 'package:muni_app/core/services/api_service.dart';
import 'package:muni_app/core/services/consent_storage.dart';
import 'package:muni_app/core/theme/app_theme.dart';
import 'package:muni_app/features/about/screens/about_screen.dart';
import 'package:muni_app/features/assessment/data/dass42_items.dart';
import 'package:muni_app/features/assessment/providers/assessment_provider.dart';
import 'package:muni_app/features/assessment/screens/assessment_screen.dart';
import 'package:muni_app/features/home/screens/home_screen.dart';
import 'package:muni_app/features/onboarding/screens/consent_screen.dart';
import 'package:muni_app/features/onboarding/screens/onboarding_screen.dart';
import 'package:muni_app/features/onboarding/screens/welcome_screen.dart';
import 'package:muni_app/features/support/screens/crisis_support_screen.dart';
import 'package:muni_app/shared/widgets/planned_feature_screen.dart';

class MuniApp extends StatelessWidget {
  const MuniApp({super.key, required this.consentStorage});

  final ConsentStorage consentStorage;


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ConsentStorage>.value(value: consentStorage),
        Provider<ApiService>(
          create: (_) => ApiService(),
          dispose: (_, api) => api.close(),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        home: consentStorage.hasValidConsent
            ? const HomeScreen()
            : const WelcomeScreen(),
        routes: {
          AppRoutes.welcome: (_) => const WelcomeScreen(),
          AppRoutes.onboarding: (_) => const OnboardingScreen(),
          AppRoutes.consent: (_) => const ConsentScreen(),
          AppRoutes.home: (_) => const HomeScreen(),
          AppRoutes.crisisSupport: (_) => const CrisisSupportScreen(),
          AppRoutes.about: (_) => const AboutScreen(),
          AppRoutes.assessment: (_) => ChangeNotifierProvider(
                create: (_) =>
                    AssessmentProvider(itemCount: dass42Items.length),
                child: const AssessmentScreen(),
              ),
          AppRoutes.facilities: (_) => const PlannedFeatureScreen(
                title: 'Facility locator',
                phase: 'Phase 6',
                description: 'The map will show verified mental health '
                    'facilities once facility data is available.',
              ),
        },
      ),
    );
  }
}