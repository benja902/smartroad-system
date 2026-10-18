import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// Optional presentation only. Production never installs this DEV review scope.
enum NavigationPreviewVariant {
  current('Actual'),
  underline('A · Underline'),
  pillActive('B · Pill Active');

  const NavigationPreviewVariant(this.label);
  static const defaultVariant = NavigationPreviewVariant.pillActive;
  final String label;
}

class NavigationVisualPreview extends InheritedWidget {
  const NavigationVisualPreview({
    super.key,
    required this.variant,
    required this.reviewAction,
    required super.child,
  });
  final NavigationPreviewVariant variant;
  final Widget reviewAction;
  static NavigationVisualPreview? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavigationVisualPreview>();
  @override
  bool updateShouldNotify(NavigationVisualPreview oldWidget) =>
      variant != oldWidget.variant || reviewAction != oldWidget.reviewAction;
}

/// Approved Pill Active presentation; global Design System still unconsolidated.
abstract final class NavigationPreviewStyle {
  static const navy = Color(0xFF031B3B);
  static const teal = Color(0xFF006D68);
  static const activeSurface = Color(0xFFCCF7F3);
  static const duration = Duration(milliseconds: 180);
  static const feedbackDuration = Duration(milliseconds: 90);
}

/// Five real destinations, callbacks owned by the existing MainShell.
class PremiumNavigationPreviewBar extends StatelessWidget {
  const PremiumNavigationPreviewBar({
    super.key,
    required this.variant,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });
  final NavigationPreviewVariant variant;
  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final duration = reduced ? Duration.zero : NavigationPreviewStyle.duration;
    final labelStyle = AppTypography.bodyMd.copyWith(
      fontSize: 12,
      height: 1.3,
      fontWeight: FontWeight.w700,
      color: NavigationPreviewStyle.navy,
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F031B3B),
                    blurRadius: 20,
                    offset: Offset(0, 5),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE0E6EB)),
              ),
              child: Material(
                key: const ValueKey('premium-nav-container'),
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final slot =
                        (constraints.maxWidth - 16) / destinations.length;
                    // Five labels measured on layout/configuration changes, never
                    // inside animation ticks. Large text grows the whole surface.
                    double labelHeight = 0;
                    for (final destination in destinations) {
                      final painter = TextPainter(
                        text: TextSpan(
                          text: destination.label,
                          style: labelStyle,
                        ),
                        textScaler: MediaQuery.textScalerOf(context),
                        textDirection: Directionality.of(context),
                      )..layout(maxWidth: math.max(1, slot - 8));
                      labelHeight = math.max(labelHeight, painter.height);
                      painter.dispose();
                    }
                    final itemHeight = math.max(
                      64.0,
                      24 + 6 + labelHeight + 16,
                    );
                    final pill = variant == NavigationPreviewVariant.pillActive;
                    final visualIndex =
                        Directionality.of(context) == TextDirection.rtl
                        ? destinations.length - 1 - selectedIndex
                        : selectedIndex;
                    final indicatorWidth = pill ? slot - 4 : 28.0;
                    return SizedBox(
                      height: itemHeight + 16,
                      child: Stack(
                        children: [
                          KeyedSubtree(
                            key: ValueKey(reduced),
                            child: AnimatedPositioned(
                              key: const ValueKey('premium-nav-indicator'),
                              duration: duration,
                              curve: Curves.easeOutCubic,
                              left:
                                  8 +
                                  slot * visualIndex +
                                  (slot - indicatorWidth) / 2,
                              top: pill ? 8 : itemHeight + 8 - 3,
                              width: indicatorWidth,
                              height: pill ? itemHeight : 3,
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: pill
                                        ? NavigationPreviewStyle.activeSurface
                                        : NavigationPreviewStyle.teal,
                                    borderRadius: BorderRadius.circular(
                                      pill ? 18 : 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var i = 0; i < destinations.length; i++)
                                  Expanded(
                                    child: _NavigationPreviewItem(
                                      key: ValueKey('premium-nav-item-$i'),
                                      destination: destinations[i],
                                      selected: selectedIndex == i,
                                      labelStyle: labelStyle,
                                      reduced: reduced,
                                      onTap: () => onDestinationSelected(i),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationPreviewItem extends StatefulWidget {
  const _NavigationPreviewItem({
    super.key,
    required this.destination,
    required this.selected,
    required this.labelStyle,
    required this.reduced,
    required this.onTap,
  });
  final NavigationDestination destination;
  final bool selected, reduced;
  final TextStyle labelStyle;
  final VoidCallback onTap;
  @override
  State<_NavigationPreviewItem> createState() => _NavigationPreviewItemState();
}

class _NavigationPreviewItemState extends State<_NavigationPreviewItem> {
  bool _pressed = false, _focused = false;
  @override
  Widget build(BuildContext context) {
    final duration = widget.reduced
        ? Duration.zero
        : NavigationPreviewStyle.duration;
    final feedback = widget.reduced
        ? Duration.zero
        : NavigationPreviewStyle.feedbackDuration;
    return Semantics(
      container: true,
      button: true,
      selected: widget.selected,
      inMutuallyExclusiveGroup: true,
      label: widget.destination.label,
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            enableFeedback: true,
            excludeFromSemantics: true,
            borderRadius: BorderRadius.circular(18),
            focusColor: NavigationPreviewStyle.activeSurface,
            hoverColor: NavigationPreviewStyle.teal.withValues(alpha: .06),
            splashColor: NavigationPreviewStyle.teal.withValues(alpha: .12),
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onFocusChange: (value) => setState(() => _focused = value),
            child: AnimatedContainer(
              duration: feedback,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _focused
                      ? NavigationPreviewStyle.teal
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: !widget.reduced && _pressed ? .94 : 1,
                    duration: feedback,
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(widget.reduced),
                      tween: Tween(end: widget.selected ? 1 : 0),
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      child: IconTheme(
                        data: IconThemeData(
                          size: 24,
                          color: widget.selected
                              ? NavigationPreviewStyle.navy
                              : AppColors.onSurfaceVariant,
                        ),
                        child: widget.selected
                            ? widget.destination.selectedIcon ??
                                  widget.destination.icon
                            : widget.destination.icon,
                      ),
                      builder: (context, value, child) => widget.reduced
                          ? child!
                          : Transform.translate(
                              offset: Offset(0, -2 * value),
                              child: Transform.scale(
                                scale: 1 + .04 * value,
                                child: child,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedDefaultTextStyle(
                    duration: duration,
                    style: widget.labelStyle.copyWith(
                      color: widget.selected
                          ? NavigationPreviewStyle.navy
                          : AppColors.onSurfaceVariant,
                      fontWeight: widget.selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    child: Text(widget.destination.label, softWrap: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One retained shell throughout tab switches: no outgoing Navigator clone,
/// AnimatedSwitcher key, delayed routing or intercepted gestures.
class NavigationPreviewContentMotion extends StatefulWidget {
  const NavigationPreviewContentMotion({
    super.key,
    required this.index,
    required this.enabled,
    required this.child,
  });
  final int index;
  final bool enabled;
  final Widget child;
  @override
  State<NavigationPreviewContentMotion> createState() =>
      _NavigationPreviewContentMotionState();
}

class _NavigationPreviewContentMotionState
    extends State<NavigationPreviewContentMotion>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: NavigationPreviewStyle.duration,
    value: 1,
  );
  double _direction = 1;
  bool get _reduced => MediaQuery.disableAnimationsOf(context);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduced) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant NavigationPreviewContentMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled || _reduced) {
      _controller.value = 1;
    } else if (widget.index != oldWidget.index) {
      _direction = widget.index > oldWidget.index ? 1 : -1;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final p = Curves.easeOutCubic.transform(_controller.value);
      final direction = Directionality.of(context) == TextDirection.rtl
          ? -_direction
          : _direction;
      return Transform.translate(
        key: const ValueKey('premium-nav-content-motion'),
        offset: Offset(6 * direction * (1 - p), 0),
        child: Opacity(
          opacity: .94 + .06 * p,
          alwaysIncludeSemantics: true,
          child: child,
        ),
      );
    },
  );
}
