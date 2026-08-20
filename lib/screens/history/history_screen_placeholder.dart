import 'package:flutter/material.dart';

import '../../widgets/coming_soon_view.dart';

class HistoryScreenPlaceholder extends StatelessWidget {
  const HistoryScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: const ComingSoonView(title: 'Historial', icon: Icons.history_outlined),
    );
  }
}
