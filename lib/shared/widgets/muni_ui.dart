import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class MuniColors {
  static const forest = Color(0xFF285943);
  static const leaf = Color(0xFF4F8A65);
  static const fresh = Color(0xFF79A982);
  static const mint = Color(0xFFEAF4EC);
  static const off = Color(0xFFF7F9F6);
  static const blue = Color(0xFFD3E4F2);
  static const lav = Color(0xFFDFD9F0);
  static const ink = Color(0xFF1E3A2D);
  static const muted = Color(0xFF5F7A6B);
  static const crisis = Color(0xFF9B3B3B);
  static const chip = Color(0xFFD9EBDD);
  static const line = Color(0xFFDCEBE0);
}

enum MuniButtonVariant { dark, light, outline, ghost }

class MuniButton extends StatelessWidget {
  const MuniButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = MuniButtonVariant.dark,
    this.large = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final MuniButtonVariant variant;
  final bool large;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, side) = switch (variant) {
      MuniButtonVariant.dark => (MuniColors.forest, Colors.white, BorderSide.none),
      MuniButtonVariant.light => (MuniColors.off, MuniColors.forest, BorderSide.none),
      MuniButtonVariant.outline => (
          Colors.white,
          MuniColors.forest,
          const BorderSide(color: MuniColors.mint, width: 2),
        ),
      MuniButtonVariant.ghost => (Colors.transparent, MuniColors.muted, BorderSide.none),
    };
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg.withValues(alpha: 0.45),
        disabledForegroundColor: fg.withValues(alpha: 0.45),
        side: side,
        elevation: 0,
        shape: const StadiumBorder(),
        minimumSize: Size(expand ? double.infinity : 0, 0),
        padding: EdgeInsets.symmetric(
          horizontal: expand ? 20 : 22,
          vertical: large ? 20 : (expand ? 16 : 10),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: large ? 20 : 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class MuniCard extends StatelessWidget {
  const MuniCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.radius = 24,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final Color color;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      );
}

/// Gentle up-and-down bob, like the prototype's `float` animation.
class Floating extends StatefulWidget {
  const Floating({
    super.key,
    required this.child,
    this.amplitude = 9,
    this.duration = const Duration(milliseconds: 4200),
  });

  final Widget child;
  final double amplitude;
  final Duration duration;

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration ~/ 2,
  )..repeat(reverse: true);
  late final Animation<double> _v =
      CurvedAnimation(parent: _c, curve: Curves.easeInOut);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _v,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -widget.amplitude * _v.value),
          child: child,
        ),
      );
}

class MuniBottomNav extends StatelessWidget {
  const MuniBottomNav({super.key, required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.assignment_outlined, Icons.assignment_rounded, 'Check-in'),
    (Icons.place_outlined, Icons.place_rounded, 'Find help'),
    (Icons.qr_code_2_rounded, Icons.qr_code_2_rounded, 'Share'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE1ECE4))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => onTap(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: i == index ? MuniColors.chip : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              i == index ? _items[i].$2 : _items[i].$1,
                              size: 24,
                              color: i == index
                                  ? MuniColors.forest
                                  : MuniColors.muted,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _items[i].$3,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: i == index
                                    ? MuniColors.forest
                                    : MuniColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _call(String number) =>
    launchUrl(Uri(scheme: 'tel', path: number));

/// "Need someone to talk to right now?" sheet.
Future<void> showCrisisSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCFDCD3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "You don't have to carry this alone",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: MuniColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'If you may be in danger, please reach out City Health Office '
              '(San Fernando City, La Union)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: MuniColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            MuniButton(
              label: 'Call (072) 888-6915',
              onPressed: () => _call('0728886915'),
            ),
            const SizedBox(height: 10),
            MuniButton(
              label: 'Call 0921-765-2129',
              variant: MuniButtonVariant.outline,
              onPressed: () => _call('09217652129'),
            ),
            const SizedBox(height: 10),
            MuniButton(
              label: 'Call 0915-359-7859',
              variant: MuniButtonVariant.outline,
              onPressed: () => _call('09153597859'),
            ),
            const SizedBox(height: 12),
            const Text(
              'In immediate danger? Call 911.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: MuniColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            MuniButton(
              label: 'Close',
              variant: MuniButtonVariant.ghost,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}