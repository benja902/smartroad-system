import 'package:flutter/material.dart';

import '../../widgets/coming_soon_view.dart';

class RegisterScreenPlaceholder extends StatelessWidget {
  const RegisterScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const ComingSoonView(title: 'Registro', icon: Icons.person_add_alt_outlined),
    );
  }
}
