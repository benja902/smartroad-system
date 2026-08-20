import 'package:flutter/material.dart';

import '../../widgets/coming_soon_view.dart';

class VehicleScreenPlaceholder extends StatelessWidget {
  const VehicleScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehículo')),
      body: const ComingSoonView(title: 'Vehículo', icon: Icons.directions_car_outlined),
    );
  }
}
