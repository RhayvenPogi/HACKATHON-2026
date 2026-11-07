import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:muni_app/core/constants/support_contacts.dart';
import 'package:muni_app/core/theme/app_colors.dart';
import 'package:muni_app/shared/widgets/info_card.dart';

class CrisisSupportScreen extends StatelessWidget {
  const CrisisSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Get help now')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'You do not have to go through this alone.',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'If you are thinking about harming yourself or are in immediate '
              'danger, call 911 or go to the nearest hospital emergency room.',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            InfoCard(
              icon: Icons.support_agent,
              title: 'NCMH Crisis Hotline (free, 24/7)',
              child: Column(
                children: [
                  for (final contact in SupportContacts.ncmhCrisisHotline)
                    _ContactTile(contact: contact),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const InfoCard(
              icon: Icons.emergency_outlined,
              title: 'Emergency',
              child: _ContactTile(contact: SupportContacts.emergency),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact});

  final SupportContact contact;

  Future<void> _call(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    bool opened = false;
    try {
      opened = await launchUrl(Uri(scheme: 'tel', path: contact.dial));
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not open the phone app. Please dial '
            '${contact.display} manually.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        contact.display,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(contact.label),
      trailing: IconButton.filledTonal(
        icon: const Icon(Icons.call, color: AppColors.primary),
        tooltip: 'Call ${contact.display}',
        onPressed: () => _call(context),
      ),
      onTap: () => _call(context),
    );
  }
}