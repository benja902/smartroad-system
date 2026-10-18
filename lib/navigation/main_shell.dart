import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';
import 'dev_mode_flag.dart';
import 'navigation_visual_preview.dart';

/// MAIN keeps five branches; DEV reviews four with Profile outside the shell.
/// Wraps go_router's
/// StatefulNavigationShell so each tab preserves its own navigation state.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const MainShell({super.key, required this.shell});

  static const _items = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Inicio',
    ),
    NavigationDestination(
      icon: Icon(Icons.notifications_outlined),
      selectedIcon: Icon(Icons.notifications),
      label: 'Alertas',
    ),
    NavigationDestination(
      icon: Icon(Icons.directions_car_outlined),
      selectedIcon: Icon(Icons.directions_car),
      label: 'Vehículo',
    ),
    NavigationDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history),
      label: 'Historial',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final devModeEnabled = context.watch<DevModeFlag>().enabled;
    final preview = devModeEnabled
        ? NavigationVisualPreview.maybeOf(context)
        : null;
    final variant = preview?.variant ?? NavigationPreviewVariant.defaultVariant;
    final premium = variant != NavigationPreviewVariant.current;
    final destinations = devModeEnabled ? _items.take(4).toList() : _items;
    void select(int index) =>
        shell.goBranch(index, initialLocation: index == shell.currentIndex);

    return Scaffold(
      body: NavigationPreviewContentMotion(
        index: shell.currentIndex,
        enabled: premium,
        child: shell,
      ),
      floatingActionButton: devModeEnabled
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (preview != null) ...[
                  preview.reviewAction,
                  const SizedBox(height: 8),
                ],
                FloatingActionButton.small(
                  heroTag: 'dev-panel-fab',
                  tooltip: 'Panel de desarrollo',
                  onPressed: () => context.push(AppRoutes.dev),
                  child: const Icon(Icons.build_outlined),
                ),
              ],
            )
          : null,
      bottomNavigationBar: premium
          ? PremiumNavigationPreviewBar(
              variant: variant,
              destinations: destinations,
              selectedIndex: shell.currentIndex,
              onDestinationSelected: select,
            )
          : NavigationBar(
              animationDuration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              destinations: destinations,
              selectedIndex: shell.currentIndex,
              onDestinationSelected: select,
            ),
    );
  }
}
