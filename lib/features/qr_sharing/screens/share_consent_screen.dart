import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muni_app/core/services/api_exception.dart';
import 'package:muni_app/core/theme/app_colors.dart';
import 'package:muni_app/features/qr_sharing/providers/share_controller.dart';
import 'package:muni_app/features/qr_sharing/screens/share_qr_screen.dart';
import 'package:muni_app/features/qr_sharing/widgets/share_demo_banner.dart';
import 'package:muni_app/shared/widgets/app_button.dart';
import 'package:muni_app/shared/widgets/info_card.dart';

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

  CheckboxListTile _check(String text, bool value, ValueChanged<bool> set) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) => setState(() => set(v ?? false)),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ShareController>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Share with a professional')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.isDemo) ...[
                const ShareDemoBanner(),
                const SizedBox(height: 16),
              ],
              Text('Before you share', style: textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Sharing lets a registered mental health professional view '
                'this assessment when you show them your QR code.',
              ),
              const SizedBox(height: 16),
              _check(
                'I want to share this assessment with a registered mental '
                'health professional.',
                _wantsToShare,
                (v) => _wantsToShare = v,
              ),
              _check(
                'I understand the professional will see my 42 answers, my '
                'three scores, and their severity levels.',
                _understandsContent,
                (v) => _understandsContent = v,
              ),
              _check(
                'I understand the QR code works for 15 days, and I can stop '
                'sharing at any time.',
                _understandsExpiry,
                (v) => _understandsExpiry = v,
              ),
              const SizedBox(height: 12),
              const InfoCard(
                icon: Icons.lock_outline,
                title: 'Your privacy',
                child: Text(
                  'The QR code contains only a random link, not your answers, '
                  'scores, or name. Only registered professionals who sign in '
                  'can open it. Administrators cannot see shared assessments.',
                ),
              ),
              if (controller.activeShare != null) ...[
                const SizedBox(height: 12),
                Text(
                  'You already have an active shared assessment. Creating a '
                  'new QR code will stop the old one from working.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: 'Create QR code',
                icon: Icons.qr_code_2,
                isLoading: controller.isBusy,
                onPressed: _allChecked ? _create : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}