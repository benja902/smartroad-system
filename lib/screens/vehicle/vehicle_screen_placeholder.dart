import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../navigation/dev_mode_flag.dart';
import '../../widgets/profile_header_action.dart';

import '../../widgets/coming_soon_view.dart';

class VehicleScreenPlaceholder extends StatelessWidget {
  const VehicleScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehículo'),
        actions: context.watch<DevModeFlag>().enabled
            ? [
                ProfileHeaderAction(
                  onPressed: () => context.push(AppRoutes.profile),
                ),
              ]
            : null,
      ),
      body: const ComingSoonView(
        title: 'Vehículo',
        icon: Icons.directions_car_outlined,
      ),
    );
  }
}
