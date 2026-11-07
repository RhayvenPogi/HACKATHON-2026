import 'package:flutter/material.dart';
import 'package:muni_app/models/severity.dart';

class SeverityStyle {
  const SeverityStyle({
    required this.foreground,
    required this.background,
    required this.icon,
  });

  final Color foreground;
  final Color background;
  final IconData icon;
}

extension SeverityPresentation on Severity {
  /// Muted, non-alarming palette. Each foreground meets 4.5:1 on its
  /// background. Never rely on color alone: always show the label too.
  SeverityStyle get style => switch (this) {
        Severity.normal => const SeverityStyle(
            foreground: Color(0xFF166534),
            background: Color(0xFFDCFCE7),
            icon: Icons.check_circle_outline,
          ),
        Severity.mild => const SeverityStyle(
            foreground: Color(0xFF1E40AF),
            background: Color(0xFFDBEAFE),
            icon: Icons.info_outline,
          ),
        Severity.moderate => const SeverityStyle(
            foreground: Color(0xFF92400E),
            background: Color(0xFFFEF3C7),
            icon: Icons.info_outline,
          ),
        Severity.severe => const SeverityStyle(
            foreground: Color(0xFF9A3412),
            background: Color(0xFFFFEDD5),
            icon: Icons.info_outline,
          ),
        Severity.extremelySevere => const SeverityStyle(
            foreground: Color(0xFF9F1239),
            background: Color(0xFFFFE4E6),
            icon: Icons.info_outline,
          ),
      };

  bool get isElevated => index >= Severity.moderate.index;
}

class SeverityChip extends StatelessWidget {
  const SeverityChip({super.key, required this.severity});

  final Severity severity;

  @override
  Widget build(BuildContext context) {
    final style = severity.style;

    return Semantics(
      label: 'Severity: ${severity.apiValue}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: 16, color: style.foreground),
            const SizedBox(width: 6),
            Text(
              severity.apiValue,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: style.foreground,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}