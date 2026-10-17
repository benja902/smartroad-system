import 'package:flutter/material.dart';

/// Navy background, white text, min 56px touch target — uses the app's
/// ElevatedButtonTheme, defined once in AppTheme.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ElevatedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  // A static progress mark keeps the busy state in reduced motion.
                  value: MediaQuery.disableAnimationsOf(context) ? .75 : null,
                  color: Theme.of(context)
                      .elevatedButtonTheme
                      .style
                      ?.foregroundColor
                      ?.resolve({WidgetState.disabled}),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(child: Text(label)),
          ],
        ),
      );
    }
    if (icon == null) {
      return ElevatedButton(onPressed: onPressed, child: Text(label));
    }
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
