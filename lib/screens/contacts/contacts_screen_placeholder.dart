import 'package:flutter/material.dart';

import '../../widgets/coming_soon_view.dart';

class ContactsScreenPlaceholder extends StatelessWidget {
  const ContactsScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contactos de emergencia')),
      body: const ComingSoonView(title: 'Contactos de emergencia', icon: Icons.contact_phone_outlined),
    );
  }
}
