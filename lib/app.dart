import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muni_app/core/constants/app_routes.dart';
import 'package:muni_app/core/constants/app_strings.dart';
import 'package:muni_app/core/services/api_service.dart';
import 'package:muni_app/core/services/consent_storage.dart';
import 'package:muni_app/core/theme/app_theme.dart';
import 'package:muni_app/features/about/screens/about_screen.dart';
import 'package:muni_app/features/home/screens/home_screen.dart';
import 'package:muni_app/features/onboarding/screens/consent_screen.dart';
import 'package:muni_app/features/onboarding/screens/onboarding_screen.dart';
import 'package:muni_app/features/onboarding/screens/welcome_screen.dart';
import 'package:muni_app/features/support/screens/crisis_support_screen.dart';
import 'package:muni_app/features/facilities/screens/facilities_screen.dart';
import 'package:muni_app/core/config/app_config.dart';
import 'package:muni_app/features/professional/data/professional_session_store.dart';
import 'package:muni_app/features/professional/providers/professional_controller.dart';
import 'package:muni_app/features/qr_sharing/data/share_repository.dart';
import 'package:muni_app/features/qr_sharing/data/share_storage.dart';
import 'package:muni_app/features/qr_sharing/providers/share_controller.dart';

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
        ChangeNotifierProvider<ShareController>(
          create: (context) => ShareController(
            repository: AppConfig.shareApiEnabled
                ? ApiShareRepository(context.read<ApiService>())
                : DemoShareRepository(),
            storage: SecureShareStorage(),
          )..load(),
        ),
        ChangeNotifierProvider<ProfessionalController>(
          create: (context) => ProfessionalController(
            api: context.read<ApiService>(),
            store: SecureProfessionalSessionStore(),
          )..load(),
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
          AppRoutes.facilities: (_) => const FacilitiesScreen(),
        },
      ),
    );
  }
}