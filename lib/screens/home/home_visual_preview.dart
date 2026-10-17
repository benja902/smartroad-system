import 'package:flutter/material.dart';

enum HomePreviewVariant {
  current('Inicio actual'),
  vehicleFocus('A · Vehicle Focus'),
  contextualFocus('B · Contextual Focus'),
  guardianDeck('C · Guardian Deck'),
  signalFlow('D · Signal Flow');

  const HomePreviewVariant(this.label);
  final String label;
}

/// Installed by the existing DEV review host; Home also checks DevModeFlag.
class HomeVisualPreview extends InheritedWidget {
  const HomeVisualPreview({
    super.key,
    required this.variant,
    required super.child,
  });
  final HomePreviewVariant variant;

  static HomePreviewVariant of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<HomeVisualPreview>()
          ?.variant ??
      HomePreviewVariant.current;

  @override
  bool updateShouldNotify(HomeVisualPreview oldWidget) =>
      oldWidget.variant != variant;
}
