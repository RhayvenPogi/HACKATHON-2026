import 'package:flutter/material.dart';
import 'package:muni_app/shared/widgets/muni_ui.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({
    super.key,
    required this.onStartCheckIn,
    required this.onFindHelp,
    required this.onShare,
    this.onViewLatest,
    this.latestLabel,
    this.latestSub,
  });

  final VoidCallback onStartCheckIn;
  final VoidCallback onFindHelp;
  final VoidCallback onShare;
  final VoidCallback? onViewLatest;

  /// Null hides the "latest check-in" card.
  final String? latestLabel;
  final String? latestSub;

  Widget _trio(String title, String sub) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              Text(sub,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ),
      );

  Widget _tile({
    required Color color,
    required IconData icon,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) =>
      Expanded(
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 28, color: MuniColors.forest),
                  const SizedBox(height: 12),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: MuniColors.ink)),
                  const SizedBox(height: 4),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: MuniColors.muted)),
                ],
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      children: [
        Row(
          children: [
            Floating(
              child: Image.asset(
                'assets/img/muni-happy.png',
                width: 72,
                errorBuilder: (_, _, _) => const SizedBox(width: 72),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hi there, I\'m Muni.',
                      style: TextStyle(
                          fontSize: 23,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          color: MuniColors.ink)),
                  Text('How are you feeling today?',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: MuniColors.muted)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: MuniColors.chip,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 18, color: MuniColors.forest),
                SizedBox(width: 8),
                Text('Just for you · No sign-up needed',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: MuniColors.forest)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        MuniCard(
          color: MuniColors.leaf,
          radius: 28,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Check in with yourself',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              const SizedBox(height: 6),
              const Text(
                'A few gentle questions to help you understand how you\'ve '
                'been feeling.',
                style: TextStyle(
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _trio('Mood', 'Feeling low'),
                  const SizedBox(width: 8),
                  _trio('Worry', 'Stress, nerves'),
                  const SizedBox(width: 8),
                  _trio('Well-being', 'Overall'),
                ],
              ),
              const SizedBox(height: 14),
              MuniButton(
                label: 'Start check-in',
                variant: MuniButtonVariant.light,
                onPressed: onStartCheckIn,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
                IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tile(
                color: MuniColors.blue,
                icon: Icons.place_outlined,
                title: 'Find support',
                sub: 'Places near you in San Fernando',
                onTap: onFindHelp,
              ),
              const SizedBox(width: 12),
              _tile(
                color: MuniColors.lav,
                icon: Icons.qr_code_2_rounded,
                title: 'Share my result',
                sub: 'Show it to a counselor',
                onTap: onShare,
              ),
            ],
          ),
        ),
        if (latestLabel != null) ...[
          const SizedBox(height: 14),
          MuniCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your latest check-in',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: MuniColors.muted)),
                      const SizedBox(height: 2),
                      Text(latestLabel!,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: MuniColors.ink)),
                      if (latestSub != null)
                        Text(latestSub!,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: MuniColors.muted)),
                    ],
                  ),
                ),
                MuniButton(
                  label: 'View',
                  variant: MuniButtonVariant.outline,
                  expand: false,
                  onPressed: onViewLatest,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => showCrisisSheet(context),
            child: const Text(
              'Need someone to talk to right now?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: MuniColors.crisis,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'A gentle first step, not a medical diagnosis.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: MuniColors.muted),
        ),
      ],
    );
  }
}