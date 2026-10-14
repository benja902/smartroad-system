import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';
import 'dev_mode_flag.dart';

/// Single shared Material NavigationBar for the 5 normal modules
/// (Home, Alertas, Vehículo, Historial, Perfil). Wraps go_router's
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

    return Scaffold(
      body: shell,
      floatingActionButton: devModeEnabled
          ? FloatingActionButton.small(
              heroTag: 'dev-panel-fab',
              tooltip: 'Panel de desarrollo',
              onPressed: () => context.push(AppRoutes.dev),
              child: const Icon(Icons.build_outlined),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        animationDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        destinations: _items,
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
      ),
    );
  }
}
