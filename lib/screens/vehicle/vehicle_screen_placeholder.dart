import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../navigation/dev_mode_flag.dart';
import '../../widgets/pinned_profile_header.dart';

import '../../widgets/coming_soon_view.dart';

class VehicleScreenPlaceholder extends StatelessWidget {
  const VehicleScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final dev = context.watch<DevModeFlag>().enabled;
    const content = ComingSoonView(
      title: 'Vehículo',
      icon: Icons.directions_car_outlined,
    );
    return Scaffold(
      appBar: dev ? null : AppBar(title: const Text('Vehículo')),
      body: dev
          ? SafeArea(
              child: CustomScrollView(
                slivers: [
                  PinnedProfileHeader(
                    title: const Text('Vehículo'),
                    onOpenProfile: () => context.push(AppRoutes.profile),
                  ),
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: content,
                  ),
                ],
              ),
            )
          : content,
    );
  }
}
