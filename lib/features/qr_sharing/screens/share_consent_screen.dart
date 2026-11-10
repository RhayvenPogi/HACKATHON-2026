import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muni_app/core/services/api_exception.dart';
import 'package:muni_app/features/qr_sharing/providers/share_controller.dart';
import 'package:muni_app/features/qr_sharing/screens/share_qr_screen.dart';
import 'package:muni_app/features/qr_sharing/widgets/share_demo_banner.dart';
import 'package:muni_app/shared/widgets/muni_ui.dart';

class ShareConsentScreen extends StatefulWidget {
  const ShareConsentScreen({super.key, required this.responses});

  /// In-memory answers from the just-completed assessment.
  final List<int> responses;

  @override
  State<ShareConsentScreen> createState() => _ShareConsentScreenState();
}

class _ShareConsentScreenState extends State<ShareConsentScreen> {
  bool _wantsToShare = false;
  bool _understandsContent = false;
  bool _understandsExpiry = false;

  bool get _allChecked =>
      _wantsToShare && _understandsContent && _understandsExpiry;

  Future<void> _create() async {
    final controller = context.read<ShareController>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await controller.createShare(widget.responses);
      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ShareQrScreen()),
      );
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.userMessage)));
    }
  }

  Widget _switch(String text, bool value, ValueChanged<bool> set) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MuniCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Switch(
              value: value,
              activeTrackColor: MuniColors.leaf,
              activeThumbColor: Colors.white,
              onChanged: (v) => setState(() => set(v)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: MuniColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ShareController>();

    return Scaffold(
      backgroundColor: MuniColors.mint,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: MuniColors.forest,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.isDemo) ...[
                const ShareDemoBanner(),
                const SizedBox(height: 16),
              ],
              const Text(
                'Share my result',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: MuniColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Show a code to a registered professional so they can see '
                'your check-in. Nothing is shared until you agree.',
                style: TextStyle(
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: MuniColors.muted,
                ),
              ),
              const SizedBox(height: 16),
              _switch(
                'I want to share this assessment with a registered mental '
                'health professional.',
                _wantsToShare,
                (v) => _wantsToShare = v,
              ),
              _switch(
                'I understand the professional will see my 21 answers and '
                'the scores calculated from them. Muni does not show these '
                'scores in the app.',
                _understandsContent,
                (v) => _understandsContent = v,
              ),
              _switch(
                'I understand the QR code works for 15 days, and I can stop '
                'sharing at any time.',
                _understandsExpiry,
                (v) => _understandsExpiry = v,
              ),
              const SizedBox(height: 4),
              const MuniCard(
                color: MuniColors.lav,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, color: MuniColors.forest),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'The QR code contains only a random link, not your '
                        'answers, scores, or name. Only registered '
                        'professionals who sign in can open it. '
                        'Administrators cannot see shared assessments.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          color: MuniColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.activeShare != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'You already have an active shared assessment. Creating a '
                  'new QR code will stop the old one from working.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MuniColors.muted,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              MuniButton(
                label: controller.isBusy ? 'Creating...' : 'Create my code',
                onPressed: _allChecked && !controller.isBusy ? _create : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}