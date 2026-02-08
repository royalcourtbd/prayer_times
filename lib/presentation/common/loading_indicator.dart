import 'package:flutter/material.dart';
import 'package:prayer_times/core/external_libs/loading_animation/ink_drop_loading_animation.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.ringColor, this.color});

  final Color? color;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkDropLoading(
        size: 30,
        ringColor: ringColor,
        color: color ?? Theme.of(context).primaryColor,
      ),
    );
  }
}
