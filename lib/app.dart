import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'navigation/dev_mode_flag.dart';
import 'state/event_provider.dart';
import 'state/session_provider.dart';

class UrbesApp extends StatefulWidget {
  final bool includeDevRoute;

  const UrbesApp({super.key, this.includeDevRoute = false});

  @override
  State<UrbesApp> createState() => _UrbesAppState();
}

class _UrbesAppState extends State<UrbesApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.build(
      eventProvider: context.read<EventProvider>(),
      sessionProvider: context.read<SessionProvider>(),
      includeDevRoute: widget.includeDevRoute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Provider<DevModeFlag>.value(
      value: DevModeFlag(widget.includeDevRoute),
      child: MaterialApp.router(
        title: 'URBES',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
