import 'package:flutter/material.dart';

import '../../widgets/coming_soon_view.dart';

class IncidentDetailScreenPlaceholder extends StatelessWidget {
  final String eventId;

  const IncidentDetailScreenPlaceholder({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de incidente')),
      body: const ComingSoonView(title: 'Detalle de incidente', icon: Icons.description_outlined),
    );
  }
}
