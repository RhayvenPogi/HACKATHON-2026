import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muni_app/core/services/api_exception.dart';
import 'package:muni_app/core/services/api_service.dart';
import 'package:muni_app/core/theme/app_colors.dart';
import 'package:muni_app/features/assessment/data/dass42_items.dart';
import 'package:muni_app/features/assessment/providers/assessment_provider.dart';
import 'package:muni_app/features/assessment/widgets/answer_option_tile.dart';
import 'package:muni_app/features/assessment/widgets/question_navigator_sheet.dart';
import 'package:muni_app/features/results/screens/results_screen.dart';
import 'package:muni_app/shared/widgets/app_button.dart';

class AssessmentScreen extends StatelessWidget {
  const AssessmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode && dass42HasPlaceholders) {
      return const _PlaceholderBlockedScreen();
    }

    final assessment = context.watch<AssessmentProvider>();
    final textTheme = Theme.of(context).textTheme;
    final int index = assessment.currentIndex;
    final int total = assessment.itemCount;
    final bool busy = assessment.isSubmitting;

    return PopScope(
      canPop: assessment.answeredCount == 0 && !busy,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || assessment.isSubmitting) return;
        final bool leave = await _confirmLeave(context);
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Question ${index + 1} of $total'),
          actions: [
            IconButton(
              icon: const Icon(Icons.grid_view_rounded),
              tooltip: 'Jump to question',
              onPressed: busy ? null : () => showQuestionNavigator(context),
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _ProgressHeader(
                    answered: assessment.answeredCount,
                    total: total,
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      children: [
                        if (dass42HasPlaceholders) ...[
                          const _PlaceholderWarning(),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          dass42Instructions,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(dass42Items[index], style: textTheme.titleLarge),
                        const SizedBox(height: 20),
                        for (final option in dass42ResponseOptions)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AnswerOptionTile(
                              value: option.value,
                              label: option.label,
                              selected:
                                  assessment.currentAnswer == option.value,
                              onTap: () =>
                                  assessment.selectAnswer(option.value),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppButton.secondary(
                            label: 'Back',
                            onPressed: assessment.isFirst || busy
                                ? null
                                : assessment.previous,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: assessment.isLast
                              ? AppButton(
                                  label: 'Review & submit',
                                  isLoading: busy,
                                  onPressed: () => _submit(context),
                                )
                              : AppButton(
                                  label: 'Next',
                                  onPressed: busy ? null : assessment.next,
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
      ),
    );
  }
}

Future<void> _submit(BuildContext context) async {
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
      title: const Text('Submit your answers?'),
      content: Text(
        'You have answered all ${assessment.itemCount} questions. Your '
        'answers will be sent to the server to calculate your results.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Review answers'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Submit'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  await _sendAssessment(context);
}

Future<void> _sendAssessment(BuildContext context) async {
  final assessment = context.read<AssessmentProvider>();
  final api = context.read<ApiService>();
  final navigator = Navigator.of(context);

  try {
    final result = await assessment.submit(api);
    navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          result: result,
          responses: assessment.buildResponses(),
        ),
      ),
    );
  } on ApiException catch (error) {
    if (!context.mounted) return;
    final bool? retry = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Could not submit'),
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
    if (retry == true && context.mounted) await _sendAssessment(context);
  }
}

Future<bool> _confirmLeave(BuildContext context) async {
  final bool? leave = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Leave the assessment?'),
      content: const Text(
        'Your answers so far will be discarded. Nothing is saved on this '
        'device.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Stay'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Leave'),
        ),
      ],
    ),
  );
  return leave ?? false;
}

class _SubmittingOverlay extends StatelessWidget {
  const _SubmittingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.25),
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Submitting your answers…',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.answered, required this.total});

  final int answered;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: answered / total,
              minHeight: 8,
              backgroundColor: AppColors.border,
              semanticsLabel: 'Assessment progress: $answered of $total answered',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$answered of $total answered',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
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
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error),
      ),
      child: const Text(
        'DEVELOPMENT ONLY: placeholder questionnaire text. Replace with the '
        'official DASS-42 wording before any real use.',
        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PlaceholderBlockedScreen extends StatelessWidget {
  const _PlaceholderBlockedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assessment unavailable')),
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