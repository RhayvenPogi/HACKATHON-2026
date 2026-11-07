import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:muni_app/core/services/api_exception.dart';
import 'package:muni_app/core/theme/app_colors.dart';
import 'package:muni_app/features/qr_sharing/providers/share_controller.dart';
import 'package:muni_app/features/qr_sharing/widgets/share_demo_banner.dart';
import 'package:muni_app/models/share_session.dart';
import 'package:muni_app/shared/widgets/app_button.dart';
import 'package:muni_app/shared/widgets/info_card.dart';

class ShareQrScreen extends StatelessWidget {
  const ShareQrScreen({super.key});

  Future<void> _stop(BuildContext context) async {
    final controller = context.read<ShareController>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Stop sharing?'),
        content: const Text(
          'The QR code will stop working immediately. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Stop sharing'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await controller.revoke();
      navigator.pop();
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.userMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ShareController>();
    final session = controller.activeShare;

    return Scaffold(
      appBar: AppBar(title: const Text('Shared assessment')),
      body: SafeArea(
        child: session == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'You have no active shared assessment. It may have '
                    'expired or been stopped.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : _content(context, controller, session),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    ShareController controller,
    ShareSession session,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final localizations = MaterialLocalizations.of(context);
    final remaining = session.expiresAt.difference(DateTime.now());
    final int daysLeft =
        (remaining.inMinutes / Duration.minutesPerDay).ceil().clamp(1, 15);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (session.isDemo) ...[
          const ShareDemoBanner(),
          const SizedBox(height: 16),
        ],
        Center(
          child: Semantics(
            label: 'QR code for your shared assessment',
            excludeSemantics: true,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: QrImageView(
                    data: session.shareUrl,
                    version: QrVersions.auto,
                    size: 240,
                    backgroundColor: Colors.white,
                  ),
                ),
                if (session.isDemo)
                  Transform.rotate(
                    angle: -0.5,
                    child: Text(
                      'DEMO',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: AppColors.error.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Show this code to a registered mental health professional.',
          style: textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Valid until '
          '${localizations.formatMediumDate(session.expiresAt.toLocal())} '
          '($daysLeft ${daysLeft == 1 ? 'day' : 'days'} left)',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const InfoCard(
          icon: Icons.lock_outline,
          title: 'What the code contains',
          child: Text(
            'Only a random link. It does not contain your answers, scores, '
            'or name.',
          ),
        ),
        const SizedBox(height: 24),
        AppButton.secondary(
          label: 'Stop sharing',
          icon: Icons.block,
          isLoading: controller.isBusy,
          onPressed: () => _stop(context),
        ),
      ],
    );
  }
}