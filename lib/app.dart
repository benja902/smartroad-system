import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'navigation/dev_mode_flag.dart';
import 'navigation/dev_navigation_override.dart';
import 'state/event_provider.dart';
import 'state/session_provider.dart';
import 'state/access_context_provider.dart';

class UrbesApp extends StatefulWidget {
  final bool includeDevRoute;
  final TransitionBuilder? devBuilder;

  const UrbesApp({super.key, this.includeDevRoute = false, this.devBuilder});

  @override
  State<UrbesApp> createState() => _UrbesAppState();
}

class _UrbesAppState extends State<UrbesApp> {
  late final GoRouter _router;
  final _devOverride = DevNavigationOverride();

  @override
  void initState() {
    super.initState();
    _router = AppRouter.build(
      eventProvider: context.read<EventProvider?>(),
      accessProvider: context.read<AccessContextProvider?>(),
      sessionProvider: context.read<SessionProvider>(),
      devOverride: _devOverride,
      includeDevRoute: widget.includeDevRoute,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DevModeFlag>.value(value: DevModeFlag(widget.includeDevRoute)),
        Provider<DevNavigationOverride>.value(value: _devOverride),
      ],
      child: MaterialApp.router(
        title: 'URBES',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: widget.devBuilder,
        routerConfig: _router,
      ),
    );
  }
}
