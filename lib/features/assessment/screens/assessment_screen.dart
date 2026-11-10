import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muni_app/core/services/api_exception.dart';
import 'package:muni_app/core/services/api_service.dart';
import 'package:muni_app/features/assessment/data/dass21_items.dart';
import 'package:muni_app/features/assessment/providers/assessment_provider.dart';
import 'package:muni_app/features/assessment/widgets/question_navigator_sheet.dart';
import 'package:muni_app/features/results/screens/check_in_complete_screen.dart';
import 'package:muni_app/shared/widgets/muni_ui.dart';

class AssessmentScreen extends StatelessWidget {
  const AssessmentScreen({super.key, this.onFinished});

  /// Called after the person comes back from the result screen.
  final VoidCallback? onFinished;

  void _select(BuildContext context, AssessmentProvider assessment, int value) {
    final int? previous = assessment.currentAnswer;
    assessment.selectAnswer(value);

    // Offer support (once per change) when item 21 is answered 2 or 3.
    final bool safetyItem = assessment.currentIndex == dass21SafetyItemIndex;
    final bool wasLow = previous == null || previous < 2;
    if (safetyItem && value >= 2 && wasLow) {
      showCrisisSheet(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode && dass21HasPlaceholders) {
      return const _PlaceholderBlockedScreen();
    }

    final assessment = context.watch<AssessmentProvider>();
    final int index = assessment.currentIndex;
    final int total = assessment.itemCount;
    final bool busy = assessment.isSubmitting;

    return Scaffold(
      backgroundColor: MuniColors.mint,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 8, 0),
                  child: Row(
                    children: [
                      const Text(
                        'Mood check-in',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: MuniColors.ink,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Question ${index + 1} of $total',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: MuniColors.ink,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.grid_view_rounded,
                            color: MuniColors.forest),
                        tooltip: 'Jump to question',
                        onPressed:
                            busy ? null : () => showQuestionNavigator(context),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: (index + 1) / total),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 8,
                        backgroundColor: Colors.white,
                        color: MuniColors.forest,
                        semanticsLabel:
                            'Assessment progress: ${assessment.answeredCount} of $total answered',
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      if (dass21HasPlaceholders) ...[
                        const _PlaceholderWarning(),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          Image.asset(
                            'assets/img/muni-calm.png',
                            width: 42,
                            errorBuilder: (_, _, _) =>
                                const SizedBox(width: 42),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Take your time. There are no wrong answers.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: MuniColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        dass21Instructions,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: MuniColors.muted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          dass21Items[index],
                          key: ValueKey(index),
                          style: const TextStyle(
                            fontSize: 22,
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                            color: MuniColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      for (final option in dass21ResponseOptions)
                        _OptionTile(
                          label: option.label,
                          selected: assessment.currentAnswer == option.value,
                          onTap: () =>
                              _select(context, assessment, option.value),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: MuniButton(
                          label: 'Back',
                          variant: MuniButtonVariant.outline,
                          onPressed: assessment.isFirst || busy
                              ? null
                              : assessment.previous,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: assessment.isLast
                            ? MuniButton(
                                label: busy ? 'Please wait...' : 'Finish',
                                onPressed: busy
                                    ? null
                                    : () => _submit(context, onFinished),
                              )
                            : MuniButton(
                                label: 'Next',
                                onPressed: busy ||
                                        assessment.currentAnswer == null
                                    ? null
                                    : assessment.next,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (busy) const _SubmittingOverlay(),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 250),
        scale: selected ? 1.015 : 1,
        child: Semantics(
          button: true,
          selected: selected,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
              decoration: BoxDecoration(
                color: selected ? MuniColors.line : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? MuniColors.leaf : MuniColors.line,
                  width: 2,
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: MuniColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _submit(BuildContext context, VoidCallback? onFinished) async {
  final assessment = context.read<AssessmentProvider>();
  final int? unanswered = assessment.firstUnansweredIndex;

  if (unanswered != null) {
    final int remaining = assessment.itemCount - assessment.answeredCount;
    final bool? goThere = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Some questions are unanswered'),
        content: Text(
          'You have $remaining unanswered '
          '${remaining == 1 ? 'question' : 'questions'}. '
          'Please answer all ${assessment.itemCount} before submitting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay here'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Go to question ${unanswered + 1}'),
          ),
        ],
      ),
    );
    if (goThere == true) assessment.goTo(unanswered);
    return;
  }

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Finish your check-in?'),
      content: const Text(
        'Your answers will be sent to the Muni server to get a general '
        'indicator. They are not saved unless you choose to share them.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Review answers'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Finish'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  await _finish(context, onFinished);
}

Future<void> _finish(BuildContext context, VoidCallback? onFinished) async {
  final assessment = context.read<AssessmentProvider>();
  final api = context.read<ApiService>();
  final navigator = Navigator.of(context);

  try {
    final result = await assessment.checkIn(api);
    final responses = assessment.buildResponses();
    await navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            CheckInCompleteScreen(responses: responses, result: result),
      ),
    );
    onFinished?.call();
  } on ApiException catch (error) {
    if (!context.mounted) return;
    final bool? retry = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Could not finish'),
        content: Text(
          '${error.userMessage}\n\nYour answers have not been lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
    if (retry == true && context.mounted) {
      await _finish(context, onFinished);
    }
  }
}

class _SubmittingOverlay extends StatelessWidget {
  const _SubmittingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.25),
        child: Center(
          child: MuniCard(
            radius: 24,
            padding: const EdgeInsets.all(24),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: MuniColors.leaf),
                SizedBox(height: 16),
                Text(
                  'Getting your result\u2026',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: MuniColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderWarning extends StatelessWidget {
  const _PlaceholderWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MuniColors.crisis.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MuniColors.crisis),
      ),
      child: const Text(
        'DEVELOPMENT ONLY: placeholder questionnaire text. Replace with the '
        'official DASS-21 wording before any real use.',
        style: TextStyle(
          color: MuniColors.crisis,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PlaceholderBlockedScreen extends StatelessWidget {
  const _PlaceholderBlockedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MuniColors.mint,
      appBar: AppBar(
        title: const Text('Assessment unavailable'),
        backgroundColor: Colors.transparent,
        foregroundColor: MuniColors.forest,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'The questionnaire is not available in this build.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}