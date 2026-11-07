import 'package:flutter/material.dart';
import 'package:muni_app/core/theme/app_colors.dart';
import 'package:muni_app/features/assessment/data/dass42_items.dart';
import 'package:muni_app/features/results/widgets/subscale_result_card.dart';
import 'package:muni_app/models/assessment_response.dart';
import 'package:muni_app/models/shared_assessment_view.dart';
import 'package:muni_app/shared/widgets/disclaimer_banner.dart';

/// Read-only. Data lives only in this widget; nothing is persisted.
class SharedAssessmentScreen extends StatelessWidget {
  const SharedAssessmentScreen({super.key, required this.view});

  final SharedAssessmentView view;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final localizations = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Shared assessment')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Confidential. Shared by the citizen with their consent. Not '
                'saved on this phone.\nShared '
                '${localizations.formatMediumDate(view.sharedAt.toLocal())} '
                '· access until '
                '${localizations.formatMediumDate(view.expiresAt.toLocal())}',
              ),
            ),
            const SizedBox(height: 16),
            for (final subscale in Subscale.values) ...[
              SubscaleResultCard(result: view.result[subscale]),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            Text('Item responses', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            for (var i = 0; i < view.responses.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Text('${i + 1}', style: textTheme.titleMedium),
                title: Text(dass42Items[i]),
                subtitle: Text(
                  dass42ResponseOptions[view.responses[i]].label,
                ),
                trailing: Text(
                  '${view.responses[i]}',
                  style: textTheme.titleMedium,
                ),
              ),
            const SizedBox(height: 16),
            DisclaimerBanner(message: view.result.notice),
          ],
        ),
      ),
    );
  }
}