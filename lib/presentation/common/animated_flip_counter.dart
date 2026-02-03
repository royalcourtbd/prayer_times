import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// An animated counter widget that displays numbers with a vertical flip animation.
/// When the value changes, digits smoothly scroll to show the new value.
class AnimatedFlipCounter extends StatelessWidget {
  const AnimatedFlipCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.linear,
    this.textStyle,
    this.prefix,
    this.suffix,
    this.fractionDigits = 0,
    this.wholeDigits = 1,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.padding = EdgeInsets.zero,
  });

  /// The value of this counter.
  final num value;

  /// Animation duration for the value to change.
  final Duration duration;

  /// The curve to apply when animating the value of this counter.
  final Curve curve;

  /// If non-null, the style to use for the counter text.
  final TextStyle? textStyle;

  /// Optional text to display before the counter.
  final String? prefix;

  /// Optional text to display after the counter.
  final String? suffix;

  /// How many digits to display after the decimal point.
  final int fractionDigits;

  /// How many digits to display before the decimal point.
  final int wholeDigits;

  /// How the digits should be placed.
  final MainAxisAlignment mainAxisAlignment;

  /// Add padding for every digit.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(textStyle).merge(
          const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
        );

    final prototypeDigit = TextPainter(
      text: TextSpan(text: '0', style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();

    final Color color = style.color ?? const Color(0xffff0000);

    final int intValue = (value * math.pow(10, fractionDigits)).round();

    List<int> digits = intValue == 0 ? [0] : [];
    int v = intValue.abs();
    while (v > 0) {
      digits.add(v);
      v = v ~/ 10;
    }
    while (digits.length < wholeDigits + fractionDigits) {
      digits.add(0);
    }
    digits = digits.reversed.toList(growable: false);

    final integerWidgets = <Widget>[];
    for (int i = 0; i < digits.length - fractionDigits; i++) {
      final digit = _SingleDigitFlipCounter(
        key: ValueKey(digits.length - i),
        value: digits[i].toDouble(),
        duration: duration,
        curve: curve,
        size: prototypeDigit.size,
        color: color,
        padding: padding,
      );
      integerWidgets.add(digit);
    }

    return DefaultTextStyle.merge(
      style: style,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: mainAxisAlignment,
        textDirection: TextDirection.ltr,
        children: [
          if (prefix != null) Text(prefix!),
          ...integerWidgets,
          if (fractionDigits != 0) const Text('.'),
          for (int i = digits.length - fractionDigits; i < digits.length; i++)
            _SingleDigitFlipCounter(
              key: ValueKey('decimal$i'),
              value: digits[i].toDouble(),
              duration: duration,
              curve: curve,
              size: prototypeDigit.size,
              color: color,
              padding: padding,
            ),
          if (suffix != null) Text(suffix!),
        ],
      ),
    );
  }
}

class _SingleDigitFlipCounter extends StatelessWidget {
  const _SingleDigitFlipCounter({
    super.key,
    required this.value,
    required this.duration,
    required this.curve,
    required this.size,
    required this.color,
    required this.padding,
  });

  final double value;
  final Duration duration;
  final Curve curve;
  final Size size;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween(end: value),
      duration: duration,
      curve: curve,
      builder: (_, double value, _) {
        final whole = value ~/ 1;
        final decimal = value - whole;
        final w = size.width + padding.horizontal;
        final h = size.height + padding.vertical;

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: <Widget>[
              _buildSingleDigit(
                digit: whole % 10,
                offset: h * decimal,
                opacity: 1 - decimal,
                h: h,
              ),
              _buildSingleDigit(
                digit: (whole + 1) % 10,
                offset: h * decimal - h,
                opacity: decimal,
                h: h,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSingleDigit({
    required int digit,
    required double offset,
    required double opacity,
    required double h,
  }) {
    final Widget child;
    if (color.a == 1.0) {
      child = Text(
        '$digit',
        textAlign: TextAlign.center,
        style: TextStyle(color: color.withValues(alpha: opacity.clamp(0, 1))),
      );
    } else {
      child = Opacity(
        opacity: opacity.clamp(0, 1),
        child: Text('$digit', textAlign: TextAlign.center),
      );
    }
    return Positioned(
      left: 0,
      right: 0,
      bottom: offset + padding.bottom,
      child: child,
    );
  }
}
