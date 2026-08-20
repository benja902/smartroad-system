import 'package:flutter/material.dart';

/// Navy outline, transparent center — for secondary/settings actions, and
/// for "Cancelar alerta" during Nivel 2.
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const GhostButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}
