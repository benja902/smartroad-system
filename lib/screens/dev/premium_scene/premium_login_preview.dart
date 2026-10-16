part of 'premium_scene.dart';

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

  Widget _buildReview(BuildContext context) {
    // Scaffold removes consumed viewInsets from its body MediaQuery.
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final original = Theme.of(context);
    final theme = original.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      colorScheme: original.colorScheme.copyWith(
        primary: const Color(0xFF031B3B),
      ),
      inputDecorationTheme: original.inputDecorationTheme.copyWith(
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFC5C6CE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF031B3B), width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF031B3B),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
    return ChangeNotifierProvider<SessionProvider>.value(
      value: _reviewSession,
      child: Theme(
        data: theme,
        child: Scaffold(
          body: SafeArea(
            maintainBottomViewPadding: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fullHeight = constraints.maxHeight + keyboardInset;
                final fit = math.min(
                  constraints.maxWidth / 390,
                  fullHeight / 844,
                );
                final dx = (constraints.maxWidth - 390 * fit) / 2,
                    dy = (fullHeight - 844 * fit) / 2;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: SingleChildScrollView(
                        key: const ValueKey('premium-login-scroll'),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: fullHeight),
                          child: Stack(
                            children: [
                              Positioned(
                                left: dx,
                                top: dy,
                                width: 390 * fit,
                                height: 844 * fit,
                                child: IgnorePointer(
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: PremiumClosureArtboard(
                                      progress: widget.progress,
                                      sceneProgress: widget.sceneProgress,
                                      vehicleProgress: widget.vehicleProgress,
                                      showDestinationLabel: false,
                                      finalSceneZoom: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: dy + 340 * fit),
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      dx + 24 * fit,
                                      0,
                                      dx + 24 * fit,
                                      24,
                                    ),
                                    child: ValueListenableBuilder<double>(
                                      valueListenable: widget.progress,
                                      // Do not mount the real form/its state before the handoff.
                                      builder: (context, value, child) =>
                                          value * 2600 >= 4090
                                          ? child!
                                          : const SizedBox.shrink(),
                                      child: LoginScreen(
                                        presentationBuilder: (context, parts) =>
                                            DevPremiumLoginForm(
                                              parts: parts,
                                              progress: widget.progress,
                                              translationScale: fit,
                                              submitted: _submitted,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 0,
                      child: ValueListenableBuilder<double>(
                        valueListenable: widget.progress,
                        builder: (context, value, _) {
                          final intro = value * 2600 < 4440;
                          return ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: TextButton(
                              onPressed: intro ? widget.onSkip : widget.onClose,
                              child: Text(
                                intro ? 'Omitir introducción' : 'Cerrar DEV',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Only presentation of slots created by LoginScreen, never a second form.
class DevPremiumLoginForm extends StatelessWidget {
  const DevPremiumLoginForm({
    super.key,
    required this.parts,
    required this.progress,
    required this.translationScale,
    this.submitted = false,
  });
  final LoginFormParts parts;
  final ValueListenable<double> progress;
  final double translationScale;
  final bool submitted;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      DevLoginEntrance(
        progress: progress,
        start: 4090,
        translationScale: translationScale,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bienvenido.',
              style: AppTypography.displayLg.copyWith(
                fontSize: 32,
                height: 1.3,
                color: const Color(0xFF031B3B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Consulta el estado de tu vehículo\ny sus alertas.',
              style: AppTypography.bodyMd.copyWith(
                fontSize: 15,
                height: 23 / 15,
                color: const Color(0xFF44474D),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 32),
      DevLoginEntrance(
        progress: progress,
        start: 4130,
        translationScale: translationScale,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            parts.email,
            const SizedBox(height: 12),
            parts.password,
            if (parts.error != null) ...[
              const SizedBox(height: 12),
              parts.error!,
            ],
          ],
        ),
      ),
      const SizedBox(height: 32),
      DevLoginEntrance(
        progress: progress,
        start: 4170,
        translationScale: translationScale,
        child: parts.submit,
      ),
      if (submitted) ...[
        const SizedBox(height: 16),
        const Text(
          'Acceso mock verificado. La sesión de la app no se ha cambiado.',
          style: TextStyle(fontSize: 13, color: Color(0xFF526078)),
        ),
      ],
    ],
  );
}

class DevLoginEntrance extends StatelessWidget {
  const DevLoginEntrance({
    super.key,
    required this.progress,
    required this.start,
    required this.translationScale,
    required this.child,
  });
  final ValueListenable<double> progress;
  final double start, translationScale;
  final Widget child;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: progress,
    child: child,
    builder: (context, value, child) {
      final p = PremiumClosureMotion.easeOut(
        PremiumClosureMotion.phase(value * 2600, start, start + 240),
      );
      return ExcludeFocus(
        excluding: p <= 0,
        child: IgnorePointer(
          ignoring: p <= 0,
          child: ExcludeSemantics(
            excluding: p <= 0,
            child: Transform.translate(
              offset: Offset(0, 6 * translationScale * (1 - p)),
              child: Opacity(opacity: p, child: child),
            ),
          ),
        ),
      );
    },
  );
}
