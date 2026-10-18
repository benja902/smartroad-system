import 'package:flutter/material.dart';

import '../../navigation/navigation_visual_preview.dart';
import '../home/home_visual_preview.dart';

/// Only main_dev installs this state. No auth, router or repositories here.
class DevNavigationReview extends StatefulWidget {
  const DevNavigationReview({super.key, required this.child});
  final Widget child;
  @override
  State<DevNavigationReview> createState() => _DevNavigationReviewState();
}

class _DevNavigationReviewState extends State<DevNavigationReview> {
  NavigationPreviewVariant _variant = NavigationPreviewVariant.defaultVariant;
  HomePreviewVariant _home = HomePreviewVariant.defaultVariant;
  GuardianArtwork _artwork = GuardianArtwork.defaultVariant;
  GuardianHeader _header = GuardianHeader.defaultVariant;
  bool _layoutDiagnostics = false;
  @override
  Widget build(BuildContext context) => NavigationVisualPreview(
    variant: _variant,
    reviewAction: MenuAnchor(
      menuChildren: [
        for (final variant in NavigationPreviewVariant.values)
          Semantics(
            selected: variant == _variant,
            child: MenuItemButton(
              onPressed: () => setState(() => _variant = variant),
              leadingIcon: Icon(
                variant == _variant ? Icons.check_rounded : null,
              ),
              child: Text(variant.label),
            ),
          ),
        const Divider(),
        for (final variant in HomePreviewVariant.values)
          MenuItemButton(
            key: ValueKey('dev-home-${variant.name}'),
            onPressed: () => setState(() => _home = variant),
            leadingIcon: Icon(_home == variant ? Icons.check_rounded : null),
            child: Semantics(
              selected: _home == variant,
              child: Text(variant.label),
            ),
          ),
        if (_home == HomePreviewVariant.routeStudio)
          CheckboxMenuButton(
            key: const ValueKey('dev-home-layout-diagnostics'),
            value: _layoutDiagnostics,
            onChanged: (value) =>
                setState(() => _layoutDiagnostics = value ?? false),
            child: const Text('Diagnóstico de tamaño · Bento'),
          ),
        if (_home == HomePreviewVariant.guardianDeck) ...[
          const Divider(),
          SubmenuButton(
            key: const ValueKey('dev-guardian-header-menu'),
            menuChildren: [
              for (final header in GuardianHeader.values)
                MenuItemButton(
                  key: ValueKey('dev-guardian-header-${header.name}'),
                  onPressed: () => setState(() => _header = header),
                  leadingIcon: Icon(
                    _header == header ? Icons.check_rounded : null,
                  ),
                  child: Text(header.label),
                ),
            ],
            child: const Text('Cabecera de Guardian'),
          ),
          for (final artwork in GuardianArtwork.values)
            MenuItemButton(
              key: ValueKey('dev-guardian-${artwork.name}'),
              onPressed: () => setState(() => _artwork = artwork),
              leadingIcon: Icon(
                _artwork == artwork ? Icons.check_rounded : null,
              ),
              child: Text(artwork.label),
            ),
        ],
      ],
      builder: (context, controller, child) => IconButton.filledTonal(
        key: const ValueKey('dev-nav-variant-menu'),
        tooltip: 'Comparar navegación: ${_variant.label}',
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: const Icon(Icons.tune_rounded),
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    ),
    child: HomeVisualPreview(
      variant: _home,
      artwork: _artwork,
      header: _header,
      layoutDiagnostics: _layoutDiagnostics,
      child: widget.child,
    ),
  );
}
