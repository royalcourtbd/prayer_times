import 'package:flutter/material.dart';
import 'package:prayer_times/core/di/service_locator.dart';
import 'package:prayer_times/core/external_libs/presentable_widget_builder.dart';
import 'package:prayer_times/core/utility/utility.dart';
import 'package:prayer_times/domain/entities/calculation_method_entity.dart';
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
    final List<CalculationMethodEntity> methods =
        CalculationMethodEntity.allMethods;

    return PresentableWidgetBuilder(
      presenter: presenter,
      builder: () {
        return CustomModalSheet(
          theme: theme,
          bottomSheetTitle: 'Calculation Method',
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: methods.map((method) {
                    return CustomRadioListTile(
                      title: method.displayName,
                      subtitle: method.subtitle,
                      isSelected: presenter
                              .currentUiState
                              .selectedCalculationMethod ==
                          method.id,
                      onTap: () async {
                        await presenter.onCalculationMethodChanged(
                          method: method.id,
                          onPrayerTimeUpdateRequired: () =>
                              homePresenter.refreshLocationAndPrayerTimes(),
                        );
                        if (context.mounted) {
                          context.navigatorPop();
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
