import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muni_app/features/professional/professional_navigation.dart';
import 'package:muni_app/features/professional/providers/professional_controller.dart';
import 'package:muni_app/features/professional/screens/professional_login_screen.dart';
import 'package:muni_app/features/professional/screens/scan_share_screen.dart';
import 'package:muni_app/features/professional/screens/shared_assessment_screen.dart';
import 'package:muni_app/shared/widgets/app_button.dart';
import 'package:muni_app/shared/widgets/info_card.dart';

class ProfessionalHomeScreen extends StatelessWidget {
  const ProfessionalHomeScreen({super.key});

  Future<void> _enterManually(BuildContext context) async {
    String input = '';
    final String? raw = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter share code'),
        content: TextField(
          autofocus: true,
          onChanged: (value) => input = value,
          decoration: const InputDecoration(hintText: 'muni://share/… or code'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, input),
            child: const Text('Open'),
          ),
        ],
      ),
    );
    if (raw == null || raw.trim().isEmpty || !context.mounted) return;

    final view = await fetchSharedAssessment(context, raw);
    if (view != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => SharedAssessmentScreen(view: view),
        ),
      );
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final navigator = Navigator.of(context);
    await context.read<ProfessionalController>().signOut();
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfessionalController>();
    final session = controller.session;
    final textTheme = Theme.of(context).textTheme;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Professional')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Your session has ended.'),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Sign in again',
                  expand: false,
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfessionalLoginScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final localizations = MaterialLocalizations.of(context);
    final expires = session.expiresAt.toLocal();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional'),
        actions: [
          TextButton(
            onPressed: () => _signOut(context),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(session.fullName, style: textTheme.headlineSmall),
            Text(session.profession, style: textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text(
              'Signed in until '
              '${localizations.formatMediumDate(expires)}, '
              '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(expires))}',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            InfoCard(
              icon: Icons.qr_code_scanner,
              title: 'Open a shared assessment',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scan the QR code a citizen shows you from their Muni app.',
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Scan QR code',
                    icon: Icons.qr_code_scanner,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const ScanShareScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppButton.secondary(
                    label: 'Enter code manually',
                    icon: Icons.keyboard,
                    onPressed: () => _enterManually(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const InfoCard(
              icon: Icons.lock_outline,
              title: 'Confidentiality',
              child: Text(
                'Shared assessments are shown only while open and are never '
                'saved on this phone. Each opening is recorded.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}