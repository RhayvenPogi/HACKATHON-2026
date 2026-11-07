import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:muni_app/core/theme/app_colors.dart';
import 'package:muni_app/features/facilities/data/facility.dart';
import 'package:muni_app/shared/widgets/app_button.dart';
import 'package:muni_app/shared/widgets/info_card.dart';

class FacilityDetailCard extends StatelessWidget {
  const FacilityDetailCard({super.key, required this.facility});

  final Facility facility;

  Future<void> _open(BuildContext context, Uri uri, String fallback) async {
    final messenger = ScaffoldMessenger.of(context);
    bool opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(fallback)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final f = facility;

    return InfoCard(
      icon: Icons.local_hospital_outlined,
      title: f.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (f.isSample) ...[
            Text(
              'Sample data: not a real facility',
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            f.type,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.place_outlined, text: f.address),
          if (f.hours != null) _InfoRow(icon: Icons.schedule, text: f.hours!),
          if (f.phone != null) _InfoRow(icon: Icons.call_outlined, text: f.phone!),
          if (f.sourceNote != null)
            _InfoRow(icon: Icons.verified_outlined, text: f.sourceNote!),
          const SizedBox(height: 16),
          AppButton(
            label: 'Directions',
            icon: Icons.directions,
            onPressed: () => _open(
              context,
              Uri.https('www.google.com', '/maps/dir/', {
                'api': '1',
                'destination':
                    '${f.location.latitude},${f.location.longitude}',
              }),
              'Could not open a maps app.',
            ),
          ),
          if (f.phone != null) ...[
            const SizedBox(height: 10),
            AppButton.secondary(
              label: 'Call',
              icon: Icons.call,
              onPressed: () => _open(
                context,
                Uri(scheme: 'tel', path: f.phone!.replaceAll(' ', '')),
                'Could not open the phone app. Please dial ${f.phone} manually.',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}