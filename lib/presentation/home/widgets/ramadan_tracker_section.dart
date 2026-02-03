import 'package:flutter/material.dart';
import 'package:prayer_times/core/config/prayer_time_app_screen.dart';
import 'package:prayer_times/core/static/ui_const.dart';
import 'package:prayer_times/core/utility/utility.dart';
import 'package:prayer_times/presentation/home/presenter/home_presenter.dart';
import 'dart:math' as math;

class RamadanTrackerSection extends StatelessWidget {
  const RamadanTrackerSection({
    super.key,
    required this.theme,
    required this.homePresenter,
  });

  final ThemeData theme;
  final HomePresenter homePresenter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding12,
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: context.color.primaryColor.withOpacityInt(0.05),
        borderRadius: radius18,
        border: Border.all(
          color: context.color.primaryColor.withOpacityInt(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                SizedBox(
                  width: 340,
                  height: 120,
                  child: CustomPaint(
                    painter: SunArcPainter(
                      homePresenter.currentUiState.fastingProgress,
                      homePresenter.currentUiState.fastingProgress,
                      context.color.primaryColor,
                    ),
                  ),
                ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Remaining ${homePresenter.currentUiState.fastingState.displayName}',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: context.color.subTitleColor,
                        fontSize: thirteenPx,
                      ),
                    ),
                    Text(
                      homePresenter.getFormattedFastingRemainingTime(),
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontSize: twentySevenPx,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 300,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sehri',
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: context.color.subTitleColor,
                          fontSize: thirteenPx,
                        ),
                      ),
                      Text(
                        'Iftar',
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: context.color.subTitleColor,
                          fontSize: thirteenPx,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(color: context.color.primaryColor.withOpacityInt(0.1)),
          _buildTimingsRow(context),
        ],
      ),
    );
  }

  Row _buildTimingsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTimeColumn(
          context: context,
          title: 'Suhoor',
          time: homePresenter.getSehriTime(),
        ),
        _buildTimeColumn(
          context: context,
          title: 'Iftar',
          time: homePresenter.getIftarTime(),
        ),
      ],
    );
  }

  Expanded _buildTimeColumn({
    required BuildContext context,
    required String title,
    required String time,
  }) {
    return Expanded(
      child: Container(
        padding: padding10,
        decoration: BoxDecoration(),
        child: Column(
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: context.color.subTitleColor,
                fontSize: thirteenPx,
              ),
            ),
            Text(
              time,
              style: theme.textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: fifteenPx,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

mixin SunIconMixin {
  void drawSunIcon(Canvas canvas, Offset center, Color color) {
    final Paint sunPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Core
    canvas.drawCircle(center, 5, sunPaint);

    // Rays
    double rayLength = 10.0;
    double innerRadius = 7.0;
    for (int i = 0; i < 8; i++) {
      double angle = (i * 45) * (math.pi / 180);
      double startX = center.dx + innerRadius * math.cos(angle);
      double startY = center.dy + innerRadius * math.sin(angle);
      double endX = center.dx + rayLength * math.cos(angle);
      double endY = center.dy + rayLength * math.sin(angle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        sunPaint..strokeWidth = 2,
      );
    }
  }
}

// ---------------- SunArcPainter ----------------
class SunArcPainter extends CustomPainter with SunIconMixin {
  final double progress; // countdown progress
  final double animValue; // 0-1 continuous sun animation
  final Color activeColor;

  SunArcPainter(this.progress, this.animValue, this.activeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // SVG-like smooth cubic curve (LEFT to RIGHT: Suhur to Iftar)
    final path = Path()
      ..moveTo(0, height) // Start from LEFT (Suhur)
      ..cubicTo(width * 0.06, height * 0.43, width * 0.26, 0, width * 0.5, 0)
      ..cubicTo(
        width * 0.74,
        0,
        width * 0.94,
        height * 0.43,
        width,
        height,
      ); // End at RIGHT (Iftar)

    final basePaint = Paint()
      ..color = activeColor.withOpacityInt(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = height * 0.02
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = height * 0.02
      ..strokeCap = StrokeCap.round;

    // Dashed progress along path
    final metric = path.computeMetrics().first;
    double distance = 0.0;
    final double dashWidth = height * 0.05;
    final double gapWidth = height * 0.09;
    final double activeLength = metric.length * progress;

    while (distance < metric.length) {
      final bool isActive = distance < activeLength;

      canvas.drawPath(
        metric.extractPath(distance, distance + dashWidth),
        isActive ? progressPaint : basePaint,
      );

      distance += dashWidth + gapWidth;
    }

    // Moving sun along path (continuous animation)
    final tangent = metric.getTangentForOffset(metric.length * animValue);
    if (tangent != null) {
      final sunPos = tangent.position;

      // Outer glow
      canvas.drawCircle(sunPos, height * 0.12, Paint()..color = Colors.white);

      // Inner circle
      canvas.drawCircle(sunPos, height * 0.04, Paint()..color = activeColor);
      drawSunIcon(canvas, sunPos, activeColor);
    }
  }

  @override
  bool shouldRepaint(covariant SunArcPainter oldDelegate) => true;
}
