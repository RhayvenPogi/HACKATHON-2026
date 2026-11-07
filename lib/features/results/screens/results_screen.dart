import 'package:flutter/material.dart';
import 'package:muni_app/core/theme/app_colors.dart';
import 'package:muni_app/features/results/widgets/subscale_result_card.dart';
import 'package:muni_app/features/results/widgets/support_prompt_card.dart';
import 'package:muni_app/models/assessment_response.dart';
import 'package:muni_app/models/severity.dart';
import 'package:muni_app/shared/widgets/app_button.dart';
import 'package:muni_app/shared/widgets/disclaimer_banner.dart';
import 'package:muni_app/features/qr_sharing/screens/share_consent_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.result,
    required this.responses,
  });

  final AssessmentResponse result;

  /// In memory only, needed so the server can re-score a shared copy.
  final List<int> responses;

  Severity get _highestSeverity => Subscale.values
      .map((s) => result[s].score.severity)
      .reduce((a, b) => a.index >= b.index ? a : b);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final bool leave = await _confirmLeave(context);
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Your results')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Your screening results', style: textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'These are preliminary screening results based on your '
                'answers. They are not a diagnosis.',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              SupportPromptCard(highest: _highestSeverity),
              const SizedBox(height: 16),
              for (final subscale in Subscale.values) ...[
                SubscaleResultCard(result: result[subscale]),
                const SizedBox(height: 12),
              ],
              DisclaimerBanner(message: result.notice),
              const SizedBox(height: 12),
              Text(
                'Your results are not saved on this device. Once you leave '
                'this screen, they will be cleared.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              AppButton.secondary(
                label: 'Share with a professional',
                icon: Icons.qr_code_2,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ShareConsentScreen(responses: responses),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Back to home',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> _confirmLeave(BuildContext context) async {
  final bool? leave = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Leave your results?'),
      content: const Text(
        'Your results are not saved. If you leave, you will need to take '
        'the assessment again to see them.',
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