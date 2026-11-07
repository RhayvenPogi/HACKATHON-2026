import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muni_app/core/theme/app_colors.dart';
import 'package:muni_app/features/assessment/providers/assessment_provider.dart';

Future<void> showQuestionNavigator(BuildContext context) {
  final assessment = context.read<AssessmentProvider>();

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jump to question',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Filled numbers are answered.',
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(assessment.itemCount, (i) {
                final bool answered = assessment.answerAt(i) != null;
                final bool current = i == assessment.currentIndex;
                final shape = RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: current
                        ? AppColors.secondary
                        : (answered ? AppColors.primary : AppColors.border),
                    width: current ? 3 : 1,
                  ),
                );

                return Semantics(
                  label: 'Question ${i + 1}, '
                      '${answered ? 'answered' : 'not answered'}',
                  button: true,
                  excludeSemantics: true,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Material(
                      color: answered ? AppColors.primary : AppColors.surface,
                      shape: shape,
                      child: InkWell(
                        customBorder: shape,
                        onTap: () {
                          assessment.goTo(i);
                          Navigator.pop(sheetContext);
                        },
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: answered
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    ),
  );
}