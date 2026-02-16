import 'package:flutter/material.dart';
import 'package:prayer_times/core/config/prayer_time_app_screen.dart';
import 'package:prayer_times/core/external_libs/presentable_widget_builder.dart';
import 'package:prayer_times/core/static/ui_const.dart';
import 'package:prayer_times/core/utility/utility.dart';
import 'package:prayer_times/presentation/common/custom_modal_sheet.dart';
import 'package:prayer_times/presentation/common/custom_switch.dart';
import 'package:prayer_times/presentation/home/presenter/home_presenter.dart';

class PrayerTimeAdjustmentBottomSheet extends StatelessWidget {
  const PrayerTimeAdjustmentBottomSheet({
    super.key,
    required this.presenter,
    this.bottomSheetTitle = 'Prayer Time Adjustment',
  });

  final HomePresenter presenter;
  final String bottomSheetTitle;

  static Future<void> show({
    required BuildContext context,
    required HomePresenter presenter,
    String bottomSheetTitle = 'Prayer Time Adjustment',
  }) async {
    final PrayerTimeAdjustmentBottomSheet bottomSheet = await Future.microtask(
      () => PrayerTimeAdjustmentBottomSheet(
        presenter: presenter,
        bottomSheetTitle: bottomSheetTitle,
      ),
    );

    if (context.mounted) {
      await context.showBottomSheet(bottomSheet, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return PresentableWidgetBuilder(
      presenter: presenter,
      builder: () {
        return CustomModalSheet(
          theme: theme,
          bottomSheetTitle: bottomSheetTitle,
          children: [
            gapH10,
            _buildSwitchRow(context, theme),
            gapH20,
            _buildSliderRow(context, theme),
            gapH20,
          ],
        );
      },
    );
  }

  Widget _buildSwitchRow(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Turn on Adjustment Time',
          style: theme.textTheme.bodyMedium!.copyWith(
            fontSize: fourteenPx,
            fontWeight: FontWeight.w400,
            color: context.color.titleColor,
          ),
        ),
        CustomSwitch(
          value: presenter.currentUiState.isAdjustmentEnabled,
          onChanged: presenter.onAdjustmentEnabledChanged,
        ),
      ],
    );
  }

  Widget _buildSliderRow(BuildContext context, ThemeData theme) {
    final bool isEnabled = presenter.currentUiState.isAdjustmentEnabled;
    final int adjustmentMinutes = presenter.currentUiState.adjustmentMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Prayer Time Adjustment',
              style: theme.textTheme.bodyMedium!.copyWith(
                fontSize: fourteenPx,
                fontWeight: FontWeight.w400,
                color: context.color.titleColor,
              ),
            ),
            Text(
              '$adjustmentMinutes min',
              style: theme.textTheme.bodyMedium!.copyWith(
                fontSize: fourteenPx,
                fontWeight: FontWeight.w400,
                color: context.color.subTitleColor,
              ),
            ),
          ],
        ),
        gapH12,
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 9,
                  activeTrackColor: context.color.primaryColor,
                  inactiveTrackColor: context.color.primaryColor200,
                  overlayColor: Colors.transparent,
                  thumbShape: CleanBorderThumb(
                    radius: 12,
                    borderColor: context.color.primaryColor,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 20,
                  ),
                  trackShape: const CenterOriginSliderTrackShape(),
                ),
                child: Slider(
                  value: adjustmentMinutes.toDouble(),
                  min: -15,
                  max: 15,
                  onChanged: isEnabled
                      ? presenter.onAdjustmentMinutesChanged
                      : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Custom track shape that draws active track from center to thumb position
/// - When value > 0: active track from center to right (towards thumb)
/// - When value < 0: active track from center to left (towards thumb)
class CenterOriginSliderTrackShape extends SliderTrackShape {
  const CenterOriginSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4;
    final double trackRadius = trackHeight / 2;

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? Colors.grey;

    final Paint activePaint = Paint()
      ..color = sliderTheme.activeTrackColor ?? Colors.blue;

    // Calculate center position of the track
    final double centerX = trackRect.left + trackRect.width / 2;

    // Draw the full inactive track first (background)
    final RRect fullTrack = RRect.fromRectAndRadius(
      trackRect,
      Radius.circular(trackRadius),
    );
    context.canvas.drawRRect(fullTrack, inactivePaint);

    // Draw active track from center to thumb position
    final double thumbX = thumbCenter.dx;

    if ((thumbX - centerX).abs() > 1) {
      // Only draw if thumb is not at center
      final double activeLeft = thumbX < centerX ? thumbX : centerX;
      final double activeRight = thumbX > centerX ? thumbX : centerX;

      final Rect activeRect = Rect.fromLTRB(
        activeLeft,
        trackRect.top,
        activeRight,
        trackRect.bottom,
      );

      final RRect activeTrack = RRect.fromRectAndRadius(
        activeRect,
        Radius.circular(trackRadius),
      );
      context.canvas.drawRRect(activeTrack, activePaint);
    }
  }
}

class CleanBorderThumb extends SliderComponentShape {
  final double radius;
  final Color borderColor;

  const CleanBorderThumb({this.radius = 12, required this.borderColor});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(radius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Smooth press animation scale
    final double scale = 1 + activationAnimation.value * 0.05;

    final double adjustedRadius = radius * scale;

    // White fill
    final Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, adjustedRadius, fillPaint);

    // 0.5px border
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, adjustedRadius, borderPaint);
  }
}
