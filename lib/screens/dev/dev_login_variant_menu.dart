import 'package:flutter/material.dart';

import '../auth/login_visual_style.dart';

/// Small review control in the existing Login header. Never a production action.
class DevLoginVariantMenu extends StatelessWidget {
  const DevLoginVariantMenu({
    super.key,
    required this.variant,
    required this.onSelected,
  });
  final LoginVisualVariant variant;
  final ValueChanged<LoginVisualVariant> onSelected;

  @override
  Widget build(BuildContext context) => MenuAnchor(
    // The isolated preview owns an Overlay, not a Navigator. This Material 3
    // menu uses that existing Overlay without introducing a review route.
    menuChildren: [
      for (final value in LoginVisualVariant.values)
        Semantics(
          selected: value == variant,
          child: MenuItemButton(
            onPressed: () => onSelected(value),
            leadingIcon: Icon(value == variant ? Icons.check_rounded : null),
            child: Text(value.label),
          ),
        ),
    ],
    builder: (context, controller, child) => IconButton(
      key: const ValueKey('dev-login-variant-menu'),
      tooltip: 'Comparar Login: ${variant.label}',
      onPressed: () =>
          controller.isOpen ? controller.close() : controller.open(),
      icon: const Icon(Icons.tune_rounded),
    ),
  );
}
