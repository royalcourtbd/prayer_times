import 'package:flutter/material.dart';
import 'package:prayer_times/core/config/prayer_time_app_screen.dart';
import 'package:prayer_times/core/static/ui_const.dart';
import 'package:prayer_times/core/utility/utility.dart';
import 'package:prayer_times/presentation/common/custom_modal_sheet.dart';
import 'package:prayer_times/presentation/common/custom_switch.dart';

class PrayerTimeAdjustmentBottomSheet extends StatefulWidget {
  const PrayerTimeAdjustmentBottomSheet({
    super.key,
    this.isAdjustmentEnabled = false,
    this.adjustmentMinutes = 0,
    this.onAdjustmentEnabledChanged,
    this.onAdjustmentMinutesChanged,
  });

  final bool isAdjustmentEnabled;
  final int adjustmentMinutes;
  final ValueChanged<bool>? onAdjustmentEnabledChanged;
  final ValueChanged<int>? onAdjustmentMinutesChanged;

  static Future<void> show({
    required BuildContext context,
    bool isAdjustmentEnabled = false,
    int adjustmentMinutes = 0,
    ValueChanged<bool>? onAdjustmentEnabledChanged,
    ValueChanged<int>? onAdjustmentMinutesChanged,
  }) async {
    final PrayerTimeAdjustmentBottomSheet bottomSheet = await Future.microtask(
      () => PrayerTimeAdjustmentBottomSheet(
        isAdjustmentEnabled: isAdjustmentEnabled,
        adjustmentMinutes: adjustmentMinutes,
        onAdjustmentEnabledChanged: onAdjustmentEnabledChanged,
        onAdjustmentMinutesChanged: onAdjustmentMinutesChanged,
      ),
    );

    if (context.mounted) {
      await context.showBottomSheet(bottomSheet, context);
    }
  }

  @override
  State<PrayerTimeAdjustmentBottomSheet> createState() =>
      _PrayerTimeAdjustmentBottomSheetState();
}

class _PrayerTimeAdjustmentBottomSheetState
    extends State<PrayerTimeAdjustmentBottomSheet> {
  late bool _isAdjustmentEnabled;
  late double _adjustmentMinutes;

  @override
  void initState() {
    super.initState();
    _isAdjustmentEnabled = widget.isAdjustmentEnabled;
    _adjustmentMinutes = widget.adjustmentMinutes.toDouble();
  }

  void _onSwitchChanged(bool value) {
    setState(() {
      _isAdjustmentEnabled = value;
    });
    widget.onAdjustmentEnabledChanged?.call(value);
  }

  void _onSliderChanged(double value) {
    setState(() {
      _adjustmentMinutes = value;
    });
    widget.onAdjustmentMinutesChanged?.call(value.toInt());
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return CustomModalSheet(
      theme: theme,
      bottomSheetTitle: 'Prayer Time Adjustment',
      children: [
        gapH10,
        // Switch Row
        _buildSwitchRow(context, theme),
        gapH20,
        // Slider Row
        _buildSliderRow(context, theme),
        gapH20,
      ],
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
        CustomSwitch(value: _isAdjustmentEnabled, onChanged: _onSwitchChanged),
      ],
    );
  }

  Widget _buildSliderRow(BuildContext context, ThemeData theme) {
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
              '${_adjustmentMinutes.toInt()} min',
              style: theme.textTheme.bodyMedium!.copyWith(
                fontSize: fourteenPx,
                fontWeight: FontWeight.w400,
                color: context.color.subTitleColor,
              ),
            ),
          ],
        ),
        gapH12,
        // Slider with labels
        Row(
          children: [
            Text(
              '-15',
              style: theme.textTheme.bodySmall!.copyWith(
                fontSize: twelvePx,
                color: context.color.subTitleColor,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 6,
                  activeTrackColor: context.color.primaryColor,
                  inactiveTrackColor: context.color.primaryColor200,
                  thumbColor: context.color.primaryColor,
                  overlayColor: context.color.primaryColor.withOpacityInt(0.2),

                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 20,
                  ),
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  value: _adjustmentMinutes,
                  min: -15,
                  max: 15,
                  divisions: 30,
                  onChanged: _isAdjustmentEnabled ? _onSliderChanged : null,
                ),
              ),
            ),
            Text(
              '+15',
              style: theme.textTheme.bodySmall!.copyWith(
                fontSize: twelvePx,
                color: context.color.subTitleColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
