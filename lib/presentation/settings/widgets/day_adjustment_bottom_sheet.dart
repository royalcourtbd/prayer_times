import 'package:flutter/material.dart';
import 'package:prayer_times/core/config/prayer_time_app_screen.dart';
import 'package:prayer_times/core/static/ui_const.dart';
import 'package:prayer_times/core/utility/utility.dart';
import 'package:prayer_times/presentation/common/custom_modal_sheet.dart';
import 'package:prayer_times/presentation/settings/presenter/settings_page_presenter.dart';

class DayAdjustmentBottomSheet extends StatelessWidget {
  const DayAdjustmentBottomSheet({super.key, required this.presenter});

  final SettingsPagePresenter presenter;
  static const List<int> adjustmentValues = [-3, -2, -1, 0, 1, 2, 3];
  static Future<void> show({
    required BuildContext context,
    required SettingsPagePresenter presenter,
  }) async {
    final DayAdjustmentBottomSheet bottomSheet = await Future.microtask(
      () => DayAdjustmentBottomSheet(presenter: presenter),
    );

    if (context.mounted) {
      await context.showBottomSheet(bottomSheet, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return CustomModalSheet(
      theme: theme,
      bottomSheetTitle: 'Day Adjustment',
      children: [
        Text(
          'Shown only for Moon Calculation. Default is 0 (no adjustment).',
          style: theme.textTheme.bodyMedium!.copyWith(
            fontSize: fourteenPx,
            color: context.color.subTitleColor,
          ),
          textAlign: TextAlign.center,
        ),
        gapH20,
        SizedBox(
          height: fortyFivePx,
          child: Row(
            children: adjustmentValues.map((value) {
              final isSelected =
                  presenter.currentUiState.selectedDayAdjustment == value;
              final String label = value > 0 ? '+$value' : '$value';
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: fourPx),
                  child: GestureDetector(
                    onTap: () async {
                      await presenter.onDayAdjustmentChanged(value: value);
                      if (context.mounted) {
                        context.navigatorPop();
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: twelvePx,
                        vertical: tenPx,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.color.primaryColor
                            : context.color.blackColor100,
                        borderRadius: radius8,
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            fontSize: fourteenPx,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? context.color.whiteColor
                                : context.color.titleColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        gapH20,
        Text(
          'Match your local/community sighting by shifting the calculated date.',
          style: theme.textTheme.bodySmall!.copyWith(
            fontSize: twelvePx,
            color: context.color.subTitleColor,
          ),
          textAlign: TextAlign.center,
        ),
        gapH10,
      ],
    );
  }
}
