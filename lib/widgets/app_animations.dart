import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class AppMotion {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration medium = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 250);
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve standard = Curves.easeInOutCubic;

  static Duration stagger(int index, {int stepMs = 0, int maxSteps = 0}) =>
      Duration.zero;
}

class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.fast,
    this.offset = Offset.zero,
  });

  @override
  Widget build(BuildContext context) => child;
}

class AnimatedAmount extends StatelessWidget {
  final double value;
  final String currency;
  final String prefix;
  final TextStyle? style;
  final bool animateOnMount;
  final Duration duration;

  const AnimatedAmount({
    super.key,
    required this.value,
    required this.currency,
    this.prefix = '',
    this.style,
    this.animateOnMount = false,
    this.duration = AppMotion.fast,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (style ?? const TextStyle()).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Text(
      '$prefix${CurrencyFormatter.format(value, currency: currency)}',
      style: effectiveStyle,
    );
  }
}

class AnimatedProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color? trackColor;
  final double height;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.trackColor,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track =
        trackColor ??
        (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: track,
        color: color,
      ),
    );
  }
}

class FadeThroughIndexedStack extends StatelessWidget {
  final int index;
  final List<Widget> children;

  const FadeThroughIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: index,
      children: [
        for (final child in children) RepaintBoundary(child: child),
      ],
    );
  }
}

class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.fastOutSlowIn,
    );
    return FadeTransition(opacity: curved, child: child);
  }
}
