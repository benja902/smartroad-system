import 'package:flutter/material.dart';

/// Navy background, white text, min 56px touch target — uses the app's
/// ElevatedButtonTheme, defined once in AppTheme.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
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
