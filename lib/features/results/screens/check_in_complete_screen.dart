import 'package:flutter/material.dart';
import 'package:muni_app/core/constants/app_routes.dart';
import 'package:muni_app/features/qr_sharing/screens/share_consent_screen.dart';
import 'package:muni_app/features/results/widgets/tips_card.dart';
import 'package:muni_app/models/check_in_result.dart';
import 'package:muni_app/shared/widgets/muni_ui.dart';

/// Shows ONE overall screening indicator (Low / Moderate / High).
/// Subscale scores and labels are never shown to citizens; only a
/// professional sees them, and only if the person shares.
class CheckInCompleteScreen extends StatelessWidget {
  const CheckInCompleteScreen({
    super.key,
    required this.responses,
    required this.result,
  });

  /// In memory only. Sent for storage only if the person chooses to share.
  final List<int> responses;
  final CheckInResult result;

  static const _signs = [
    (
      'Stress',
      'Finding it hard to relax, feeling tense or on edge, getting easily '
          'irritated.',
    ),
    (
      'Anxiety',
      'Feeling worried or panicky, a racing heart or shaky feeling without '
          'a clear reason.',
    ),
    (
      'Low mood',
      'Feeling down or empty, losing interest in things, finding it hard to '
          'get started.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const heading = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: MuniColors.ink,
    );
    const body = TextStyle(
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w600,
      color: MuniColors.muted,
    );
    final bool high = result.level == ScreeningLevel.high;

    // On "High" the help button uses the default (solid) style.
    final Widget crisisButton = high
        ? MuniButton(
            label: 'Need help now?',
            onPressed: () => showCrisisSheet(context),
          )
        : MuniButton(
            label: 'Need help now?',
            variant: MuniButtonVariant.outline,
            onPressed: () => showCrisisSheet(context),
          );

    return Scaffold(
      backgroundColor: MuniColors.mint,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            const Text(
              'Thank you for checking in.',
              style: TextStyle(
                fontSize: 26,
                height: 1.2,
                fontWeight: FontWeight.w900,
                color: MuniColors.forest,
              ),
            ),
            const SizedBox(height: 16),
            _IndicatorCard(result: result),
            if (high) ...[
              const SizedBox(height: 12),
              crisisButton,
            ],
            const SizedBox(height: 16),
            MuniCard(
              radius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Feelings many people have', style: heading),
                  const SizedBox(height: 12),
                  for (final (title, text) in _signs) ...[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: MuniColors.forest,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(text, style: body),
                    const SizedBox(height: 12),
                  ],
                  const Text(
                    'Everyone feels these sometimes. If they happen often, '
                    'feel strong, or get in the way of daily life, consider '
                    'talking to a mental health professional.',
                    style: body,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const TipsCard(),
            const SizedBox(height: 20),
            MuniButton(
              label: 'Share with a professional',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ShareConsentScreen(responses: responses),
                ),
              ),
            ),
            const SizedBox(height: 10),
            MuniButton(
              label: 'Find a facility',
              variant: MuniButtonVariant.outline,
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.facilities),
            ),
            if (!high) ...[
              const SizedBox(height: 10),
              crisisButton,
            ],
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Back to home',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: MuniColors.forest,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your answers are not saved on this phone or on the server '
              'unless you choose to share them.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: MuniColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard({required this.result});

  final CheckInResult result;

  static const _labels = ['Low', 'Moderate', 'High'];
  // Text-safe (AA) colours; bars use the same hues.
  static const _colors = [
    Color(0xFF2F7048),
    Color(0xFF92400E),
    Color(0xFF9F1239),
  ];
  static const _messages = {
    ScreeningLevel.low:
        'Your answers suggest few signs of distress right now. This does not '
            'rule out a concern, so reach out whenever you feel you need '
            'support.',
    ScreeningLevel.moderate:
        'Your answers suggest some signs of distress. Talking with a mental '
            'health professional could help.',
    ScreeningLevel.high:
        'Your answers suggest a high level of distress. We encourage you to '
            'reach out to a mental health professional soon. If you ever feel '
            'unsafe, tap "Need help now?".',
  };

  @override
  Widget build(BuildContext context) {
    final int active = result.level.index;
    final Color color = _colors[active];

    return Semantics(
      label: 'Overall screening indicator: ${_labels[active]}',
      child: MuniCard(
        radius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall screening indicator',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: MuniColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            ExcludeSemantics(
              child: Text(
                _labels[active],
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: i == active
                                  ? _colors[i]
                                  : _colors[i].withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _labels[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  i == active ? FontWeight.w900 : FontWeight.w600,
                              color: i == active ? _colors[i] : MuniColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _messages[result.level]!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: MuniColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              result.notice,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: MuniColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}