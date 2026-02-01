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
      padding: padding15,
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: context.color.primaryColor.withOpacityInt(0.05),
        borderRadius: radius18,
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                SizedBox(
                  width: 310,
                  height: 120,
                  child: CustomPaint(
                    painter: ArcPainter(
                      progress: homePresenter.currentUiState.fastingProgress,
                      activeColor: context.color.primaryColor,
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

class ArcPainter extends CustomPainter {
  final double progress;
  final Color activeColor;

  ArcPainter({required this.progress, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;

    final Paint activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final Paint inactivePaint = Paint()
      ..color = activeColor.withOpacityInt(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final double startAngle = math.pi;
    final double sweepAngle = math.pi;

    Path path = Path();
    path.addArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
    );

    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      double dashWidth = 6.0;
      double gapWidth = 6.0;
      final double activeLength = pathMetric.length * progress;

      while (distance < pathMetric.length) {
        final bool isActive = distance < activeLength;
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          isActive ? activePaint : inactivePaint,
        );
        distance += (dashWidth + gapWidth);
      }
    }

    double currentAngle = math.pi + (progress * math.pi);

    double sunX = center.dx + radius * math.cos(currentAngle);
    double sunY = center.dy + radius * math.sin(currentAngle);
    Offset sunPos = Offset(sunX, sunY);

    Paint sunBgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      sunPos,
      18,
      Paint()
        ..color = activeColor.withOpacityInt(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    canvas.drawCircle(sunPos, 14, sunBgPaint);

    _drawSunIcon(canvas, sunPos);
  }

  void _drawSunIcon(Canvas canvas, Offset center) {
    final Paint sunPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 5, sunPaint);

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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
