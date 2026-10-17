import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../repositories/mock/mock_auth_repository.dart';
import '../../state/session_provider.dart';
import '../auth/login_screen.dart';
import '../auth/premium_login_presentation.dart';

/// Real LoginScreen, isolated mock session, live base router left untouched.
class DevPremiumLoginPreview extends StatefulWidget {
  const DevPremiumLoginPreview({
    super.key,
    required this.progress,
    required this.sceneProgress,
    required this.vehicleProgress,
    required this.onSkip,
    required this.onClose,
  });
  final ValueListenable<double> progress, sceneProgress, vehicleProgress;
  final VoidCallback onSkip, onClose;
  @override
  State<DevPremiumLoginPreview> createState() => _DevPremiumLoginPreviewState();
}

class _DevPremiumLoginPreviewState extends State<DevPremiumLoginPreview> {
  late final OverlayEntry _formOverlay = OverlayEntry(builder: _buildReview);
  late final SessionProvider _reviewSession = SessionProvider(
    MockAuthRepository(),
  )..addListener(_onSession);
  bool _seedSeen = false, _submitted = false;
  void _onSession() {
    if (!_seedSeen) {
      _seedSeen = true;
      return;
    }
    if (mounted) {
      _submitted = true;
      _formOverlay.markNeedsBuild();
    }
  }

  @override
  void initState() {
    super.initState();
    _reviewSession;
  }

  @override
  void dispose() {
    _reviewSession.removeListener(_onSession);
    _reviewSession.dispose();
    _formOverlay.remove();
    _formOverlay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: const ValueKey('premium-login-capture'),
    child: Overlay(initialEntries: [_formOverlay]),
  );

  @override
  void didUpdateWidget(covariant DevPremiumLoginPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _formOverlay.markNeedsBuild();
  }

  Widget _buildReview(
    BuildContext context,
  ) => ChangeNotifierProvider<SessionProvider>.value(
    value: _reviewSession,
    child: PremiumLoginTimeline(
      progress: widget.progress,
      sceneProgress: widget.sceneProgress,
      vehicleProgress: widget.vehicleProgress,
      headerAction: ValueListenableBuilder<double>(
        valueListenable: widget.progress,
        builder: (context, value, _) {
          final intro = value * 2600 < 4440;
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: TextButton(
              onPressed: intro ? widget.onSkip : widget.onClose,
              child: Text(intro ? 'Omitir introducción' : 'Cerrar DEV'),
            ),
          );
        },
      ),
      footer: _submitted
          ? const Text(
              'Acceso mock verificado. La sesión de la app no se ha cambiado.',
              style: TextStyle(fontSize: 13, color: Color(0xFF526078)),
            )
          : null,
      child: const LoginScreen(),
    ),
  );
}
