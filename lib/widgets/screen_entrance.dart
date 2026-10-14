import 'package:flutter/material.dart';

/// One finite timeline per mounted screen, shared by its visual sections.
/// Provider rebuilds, keyboard changes and retained tabs never restart it.
class ScreenEntrance extends StatefulWidget {
  const ScreenEntrance({super.key, required this.builder});

  static const duration = Duration(milliseconds: 240);
  final Widget Function(BuildContext, Animation<double>) builder;

  @override
  State<ScreenEntrance> createState() => _ScreenEntranceState();
}

class _ScreenEntranceState extends State<ScreenEntrance>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: ScreenEntrance.duration,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}

/// Small translation in logical pixels; content and actions stay available.
/// Only introductory content opts into opacity; status stays fully legible.
class EntranceSection extends StatelessWidget {
  const EntranceSection({
    super.key,
    required this.animation,
    required this.child,
    this.start = 0,
    this.fade = false,
  });

  final Animation<double> animation;
  final Widget child;
  final double start;
  final bool fade;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final progress = Interval(
          start,
          1,
          curve: Curves.easeOutCubic,
        ).transform(animation.value);
        return Transform.translate(
          offset: Offset(0, 8 * (1 - progress)),
          child: fade
              ? Opacity(
                  opacity: 0.85 + 0.15 * progress,
                  alwaysIncludeSemantics: true,
                  child: child,
                )
              : child,
        );
      },
    );
  }
}
