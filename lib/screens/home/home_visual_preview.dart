import 'package:flutter/material.dart';

enum GuardianArtwork {
  lineArt('A · Ilustración lineal'),
  isometric('B · Ilustración 2.5D');

  const GuardianArtwork(this.label);
  final String label;
}

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
    this.artwork = GuardianArtwork.lineArt,
    required super.child,
  });
  final HomePreviewVariant variant;
  final GuardianArtwork artwork;
  static GuardianArtwork artworkOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<HomeVisualPreview>()
          ?.artwork ??
      GuardianArtwork.lineArt;

  static HomePreviewVariant of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<HomeVisualPreview>()
          ?.variant ??
      HomePreviewVariant.current;

  @override
  bool updateShouldNotify(HomeVisualPreview oldWidget) =>
      oldWidget.variant != variant || oldWidget.artwork != artwork;
}
