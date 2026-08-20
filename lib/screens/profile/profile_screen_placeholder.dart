import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../state/session_provider.dart';
import '../../widgets/coming_soon_view.dart';
import '../../widgets/ghost_button.dart';

/// The full Perfil screen isn't designed yet, but sign-out has to live
/// somewhere reachable so the auth flow is actually testable end to end.
class ProfileScreenPlaceholder extends StatelessWidget {
  const ProfileScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(child: ComingSoonView(title: 'Perfil', icon: Icons.person_outline)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.edgeMargin),
              child: GhostButton(
                label: 'Cerrar sesión',
                onPressed: () => context.read<SessionProvider>().signOut(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
