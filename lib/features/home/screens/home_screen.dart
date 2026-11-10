import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muni_app/core/constants/app_routes.dart';
import 'package:muni_app/features/assessment/data/dass21_items.dart';
import 'package:muni_app/features/assessment/providers/assessment_provider.dart';
import 'package:muni_app/features/assessment/screens/assessment_screen.dart';
import 'package:muni_app/features/facilities/screens/facilities_screen.dart';
import 'package:muni_app/features/home/screens/user_home_screen.dart';
import 'package:muni_app/features/qr_sharing/providers/share_controller.dart';
import 'package:muni_app/features/qr_sharing/screens/share_qr_screen.dart';
import 'package:muni_app/shared/widgets/muni_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  /// Tabs are built on first visit, so the map doesn't load at startup.
  final Set<int> _opened = {0};

  /// Changing this gives the quiz tab a fresh AssessmentProvider.
  int _quizRun = 0;

  void _go(int i) => setState(() {
        _index = i;
        _opened.add(i);
      });

  /// Called when the person returns from the result screen.
  void _checkInFinished() => setState(() {
        _quizRun++;
        _index = 0;
      });

  Widget _home(BuildContext context) {
    final activeShare = context.watch<ShareController>().activeShare;
    final localizations = MaterialLocalizations.of(context);

    return Stack(
      children: [
        UserHomeScreen(
          onStartCheckIn: () => _go(1),
          onFindHelp: () => _go(2),
          onShare: () => _go(3),
          latestLabel: activeShare == null ? null : 'Shared assessment',
          latestSub: activeShare == null
              ? null
              : 'Active until ${localizations.formatMediumDate(activeShare.expiresAt.toLocal())}',
          onViewLatest: () => _go(3),
        ),
        Positioned(
          top: 4,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.info_outline, color: MuniColors.muted),
            tooltip: 'About & privacy',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.about),
          ),
        ),
      ],
    );
  }

  Widget _tab(int i) {
    if (!_opened.contains(i)) return const SizedBox.shrink();
    return switch (i) {
      0 => _home(context),
      1 => KeyedSubtree(
          key: ValueKey(_quizRun),
          child: ChangeNotifierProvider(
            create: (_) => AssessmentProvider(itemCount: dass21Items.length),
            child: AssessmentScreen(onFinished: _checkInFinished),
          ),
        ),
      2 => const FacilitiesScreen(embedded: true),
      _ => const ShareQrScreen(embedded: true),
    };
  }

  @override
  Widget build(BuildContext context) {
    final bool keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return PopScope(
      // Back on any other tab goes to Home; back on Home exits the app.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(0);
      },
      child: Scaffold(
        backgroundColor: MuniColors.mint,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _index,
            children: [for (var i = 0; i < 4; i++) _tab(i)],
          ),
        ),
        bottomNavigationBar: keyboardOpen
            ? null
            : MuniBottomNav(index: _index, onTap: _go),
      ),
    );
  }
}