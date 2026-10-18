import 'package:flutter/material.dart';

enum GuardianHeader {
  editorial('A · Editorial Minimal'),
  signature('B · Signature Header');

  const GuardianHeader(this.label);
  final String label;
  static const defaultVariant = GuardianHeader.editorial;
}

enum GuardianArtwork {
  lineArt('A · Ilustración lineal'),
  isometric('B · Ilustración 2.5D');

  const GuardianArtwork(this.label);
  final String label;
  static const defaultVariant = GuardianArtwork.lineArt;
}

enum HomePreviewVariant {
  current('Inicio actual'),
  vehicleFocus('A · Vehicle Focus'),
  contextualFocus('B · Contextual Focus'),
  guardianDeck('C · Guardian Deck'),
  signalFlow('D · Signal Flow');

  const HomePreviewVariant(this.label);
  final String label;
  static const defaultVariant = HomePreviewVariant.guardianDeck;
}

/// Installed by the existing DEV review host; Home also checks DevModeFlag.
class HomeVisualPreview extends InheritedWidget {
  const HomeVisualPreview({
    super.key,
    required this.variant,
    this.artwork = GuardianArtwork.defaultVariant,
    this.header = GuardianHeader.defaultVariant,
    required super.child,
  });
  final HomePreviewVariant variant;
  final GuardianArtwork artwork;
  final GuardianHeader header;
  static GuardianHeader headerOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeVisualPreview>()?.header ??
      GuardianHeader.defaultVariant;
  static GuardianArtwork artworkOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<HomeVisualPreview>()
          ?.artwork ??
      GuardianArtwork.defaultVariant;

  static HomePreviewVariant of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<HomeVisualPreview>()
          ?.variant ??
      HomePreviewVariant.defaultVariant;

  @override
  bool updateShouldNotify(HomeVisualPreview oldWidget) =>
      oldWidget.variant != variant ||
      oldWidget.artwork != artwork ||
      oldWidget.header != header;
}
