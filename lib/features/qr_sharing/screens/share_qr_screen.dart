import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:muni_app/core/services/api_exception.dart';
import 'package:muni_app/features/qr_sharing/providers/share_controller.dart';
import 'package:muni_app/features/qr_sharing/widgets/share_demo_banner.dart';
import 'package:muni_app/models/share_session.dart';
import 'package:muni_app/shared/widgets/muni_ui.dart';

class ShareQrScreen extends StatelessWidget {
  const ShareQrScreen({super.key, this.embedded = false});

  /// True when shown as a tab in HomeScreen: no app bar, no back button.
  final bool embedded;

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
      if (!embedded) navigator.pop();
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.userMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ShareController>();
    final session = controller.activeShare;

    return Scaffold(
      backgroundColor: MuniColors.mint,
      appBar: embedded
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: MuniColors.forest,
            ),
      body: SafeArea(
        child: session == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Nothing shared yet. Finish a check-in, then choose '
                    'Share my result on your result screen. If you shared '
                    'before, it may have expired or been stopped.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: MuniColors.muted,
                    ),
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
    final localizations = MaterialLocalizations.of(context);
    final remaining = session.expiresAt.difference(DateTime.now());
    final int daysLeft =
        (remaining.inMinutes / Duration.minutesPerDay).ceil().clamp(1, 15);

    return ListView(
      padding: EdgeInsets.fromLTRB(20, embedded ? 24 : 0, 20, 24),
      children: [
        if (session.isDemo) ...[
          const ShareDemoBanner(),
          const SizedBox(height: 16),
        ],
        MuniCard(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
          child: Column(
            children: [
              Semantics(
                label: 'QR code for your shared assessment',
                excludeSemantics: true,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: MuniColors.off,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: QrImageView(
                        data: session.shareUrl,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: MuniColors.off,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: MuniColors.forest,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: MuniColors.forest,
                        ),
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
                            color: MuniColors.crisis.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Valid for $daysLeft ${daysLeft == 1 ? 'day' : 'days'}',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: MuniColors.forest,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Expires '
                '${localizations.formatMediumDate(session.expiresAt.toLocal())}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MuniColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Show this code to a registered mental health professional. The '
          'code holds a private link, never your answers.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            fontWeight: FontWeight.w600,
            color: MuniColors.muted,
          ),
        ),
        const SizedBox(height: 20),
        MuniButton(
          label: controller.isBusy ? 'Stopping...' : 'Stop sharing',
          variant: MuniButtonVariant.outline,
          onPressed: controller.isBusy ? null : () => _stop(context),
        ),
      ],
    );
  }
}