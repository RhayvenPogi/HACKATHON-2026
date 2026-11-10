import 'package:flutter/material.dart';
import 'package:muni_app/features/assessment/data/dass21_items.dart';
import 'package:muni_app/features/professional/screens/scan_share_screen.dart';
import 'package:muni_app/features/professional/widgets/pro_colors.dart';
import 'package:muni_app/features/professional/widgets/rise_in.dart';
import 'package:muni_app/features/results/widgets/subscale_result_card.dart';
import 'package:muni_app/models/assessment_response.dart';
import 'package:muni_app/models/shared_assessment_view.dart';
import 'package:muni_app/shared/widgets/disclaimer_banner.dart';

/// Read-only. Data lives only in this widget; nothing is persisted.
class SharedAssessmentScreen extends StatefulWidget {
  const SharedAssessmentScreen({super.key, required this.view});

  final SharedAssessmentView view;

  @override
  State<SharedAssessmentScreen> createState() => _SharedAssessmentScreenState();
}

class _SharedAssessmentScreenState extends State<SharedAssessmentScreen> {
  bool _showAll = false;

  static const _small = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: ProColors.muted,
  );

  Widget _card({
    required Widget child,
    Color color = Colors.white,
    EdgeInsets padding =
        const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  }) =>
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 14),
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
        ),
        child: child,
      );

  Widget _answerRow(int index) {
    final value = widget.view.responses[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: ProColors.muted,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              dass21Items[index],
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ProColors.muted,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: Text(
              dass21ResponseOptions[value].label,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: ProColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final localizations = MaterialLocalizations.of(context);

    // Highest answers first; ties keep questionnaire order.
    final order = List<int>.generate(view.responses.length, (i) => i)
      ..sort((a, b) {
        final byValue = view.responses[b].compareTo(view.responses[a]);
        return byValue != 0 ? byValue : a.compareTo(b);
      });
    final top = order.take(3).toList();
    final rest = order.skip(3).toList();

    return Scaffold(
      backgroundColor: ProColors.mint,
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 30, 22, 120),
              children: [
                const Text('Shared with you', style: _small),
                const SizedBox(height: 4),
                const Text(
                  'Check-in summary',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: ProColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Shared on '
                  '${localizations.formatMediumDate(view.sharedAt.toLocal())}'
                  ' · Code ends '
                  '${localizations.formatMediumDate(view.expiresAt.toLocal())}',
                  style: _small,
                ),

                // How they may be feeling (real DASS-42 subscale results)
                RiseIn(
                  delay: const Duration(milliseconds: 100),
                  child: _card(
                    color: ProColors.lav,
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 10),
                          child: Text(
                            'How they may be feeling',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: ProColors.ink,
                            ),
                          ),
                        ),
                        for (final subscale in Subscale.values) ...[
                          SubscaleResultCard(result: view.result[subscale]),
                          if (subscale != Subscale.values.last)
                            const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ),

                // Their answers
                RiseIn(
                  delay: const Duration(milliseconds: 260),
                  child: _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Their answers',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: ProColors.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final i in top) _answerRow(i),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 550),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: _showAll
                              ? Column(children: [
                                  for (final i in rest) _answerRow(i),
                                ])
                              : const SizedBox(width: double.infinity),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () =>
                              setState(() => _showAll = !_showAll),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: ProColors.forest,
                          ),
                          child: Text(
                            _showAll ? 'Show fewer answers' : 'See all answers',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Muni's first suggestions
                RiseIn(
                  delay: const Duration(milliseconds: 360),
                  child: _card(
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/img/muni-calm.png',
                          width: 40,
                          errorBuilder: (_, _, _) =>
                              const SizedBox(width: 40),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Muni's first suggestions",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: ProColors.ink,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Check in with them about how they feel '
                                "today, and follow your clinic's usual steps.",
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                  color: ProColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const Text(
                  "Shared with the person's consent. Not saved on this phone.",
                  textAlign: TextAlign.center,
                  style: _small,
                ),
                const SizedBox(height: 12),
                DisclaimerBanner(message: view.result.notice),
              ],
            ),
          ),

          // Dock
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                22,
                26,
                22,
                MediaQuery.paddingOf(context).bottom + 22,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [0.62, 1],
                  colors: [ProColors.mint, Color(0x00EAF4EC)],
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const ScanShareScreen(),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: ProColors.leaf,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Scan another code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}