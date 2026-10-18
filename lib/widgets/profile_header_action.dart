import 'package:flutter/material.dart';

/// Shared presentation for the existing Profile action; callers own routing.
class ProfileHeaderAction extends StatelessWidget {
  const ProfileHeaderAction({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: 'Perfil',
    onPressed: onPressed,
    icon: const Icon(Icons.person_outline_rounded),
    style: IconButton.styleFrom(
      foregroundColor: const Color(0xFF031B3B),
      backgroundColor: const Color(0xFFE6F2F2),
      minimumSize: const Size(48, 48),
    ),
  );
}
