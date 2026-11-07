import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary }

/// Full-width button with a built-in loading state.
/// While [isLoading] is true the button is disabled, which prevents
/// double submission.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.secondary;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;
    final bool showIcon = icon != null && !isLoading;

    final Widget content = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Theme.of(context).colorScheme.primary,
              semanticsLabel: 'Loading',
            ),
          )
        : Text(label);

    final Widget button = switch (variant) {
      AppButtonVariant.primary => showIcon
          ? FilledButton.icon(
              onPressed: effectiveOnPressed,
              icon: Icon(icon),
              label: Text(label),
            )
          : FilledButton(onPressed: effectiveOnPressed, child: content),
      AppButtonVariant.secondary => showIcon
          ? OutlinedButton.icon(
              onPressed: effectiveOnPressed,
              icon: Icon(icon),
              label: Text(label),
            )
          : OutlinedButton(onPressed: effectiveOnPressed, child: content),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}