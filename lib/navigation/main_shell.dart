import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';
import 'dev_mode_flag.dart';

/// Single shared BottomNavigationBar for the 5 normal modules
/// (Home, Alertas, Vehículo, Historial, Perfil). Wraps go_router's
/// StatefulNavigationShell so each tab preserves its own navigation state.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const MainShell({super.key, required this.shell});

  static const _items = [
    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
    BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Alertas'),
    BottomNavigationBarItem(icon: Icon(Icons.directions_car_outlined), activeIcon: Icon(Icons.directions_car), label: 'Vehículo'),
    BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Historial'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
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
      bottomNavigationBar: BottomNavigationBar(
        items: _items,
        currentIndex: shell.currentIndex,
        onTap: (index) => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
      ),
    );
  }
}
