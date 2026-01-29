import 'package:flutter/material.dart';
import 'package:prayer_times/core/di/service_locator.dart';
import 'package:prayer_times/core/utility/utility.dart';
import 'package:prayer_times/presentation/common/custom_modal_sheet.dart';
import 'package:prayer_times/presentation/home/presenter/home_presenter.dart';
import 'package:prayer_times/presentation/settings/presenter/settings_page_presenter.dart';
import 'package:prayer_times/presentation/common/custom_radio_list_tile.dart';

class CalculationMethodBottomSheet extends StatelessWidget {
  CalculationMethodBottomSheet({super.key, required this.presenter});

  final SettingsPagePresenter presenter;

  static Future<void> show({
    required BuildContext context,
    required SettingsPagePresenter presenter,
  }) async {
    final CalculationMethodBottomSheet calculationMethodBottomSheet =
        await Future.microtask(
          () => CalculationMethodBottomSheet(presenter: presenter),
        );

    if (context.mounted) {
      await context.showBottomSheet(calculationMethodBottomSheet, context);
    }
  }

  late final HomePresenter homePresenter = locate<HomePresenter>();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return CustomModalSheet(
      theme: theme,
      bottomSheetTitle: 'Calculation Method',
      children: [
        CustomRadioListTile(
          title: 'Muslim World League (MWL)',
          isSelected: false,
          onTap: () {},
        ),
        CustomRadioListTile(
          title: 'Islamic Society of North America (ISNA)',
          isSelected: false,
          onTap: () {},
        ),
      ],
    );
  }
}
