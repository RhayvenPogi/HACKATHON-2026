import 'package:flutter/material.dart';
import 'package:muni_app/core/constants/app_routes.dart';
import 'package:muni_app/core/theme/app_colors.dart';
import 'package:muni_app/shared/widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: Icons.assignment_outlined,
      title: 'A structured check-in',
      body: 'FLOW uses the DASS-42, a 42-item questionnaire covering three '
          'areas: depression, anxiety, and stress. Most people finish it in '
          '10 to 15 minutes.',
    ),
    _OnboardingPageData(
      icon: Icons.health_and_safety_outlined,
      title: 'Screening, not diagnosis',
      body: 'Your results are preliminary screening information with general '
          'guidance. They are not a diagnosis. Whatever your results say, you '
          'can reach out to a professional whenever you feel you need support.',
    ),
    _OnboardingPageData(
      icon: Icons.lock_outline,
      title: 'Your privacy',
      body: 'Your answers are sent to the FLOW server only to calculate your '
          'results. Sharing your results with a mental health professional '
          'will always require your explicit permission.',
    ),
  ];

  bool get _isLastPage => _page == _pages.length - 1;

  void _goToConsent() => Navigator.pushNamed(context, AppRoutes.consent);

  void _next() {
    if (_isLastPage) {
      _goToConsent();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(onPressed: _goToConsent, child: const Text('Skip')),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) =>
                    _OnboardingPage(data: _pages[index]),
              ),
            ),
            _PageDots(count: _pages.length, current: _page),
            Padding(
              padding: const EdgeInsets.all(24),
              child: AppButton(
                label: _isLastPage ? 'Continue' : 'Next',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.infoBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(data.icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 28),
            Text(
              data.title,
              style: textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              data.body,
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page ${current + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          final bool active = index == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}