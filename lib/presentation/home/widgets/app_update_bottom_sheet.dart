import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:prayer_times/core/config/prayer_time_app_screen.dart';
import 'package:prayer_times/core/static/ui_const.dart';
import 'package:prayer_times/core/utility/utility.dart';
import 'package:prayer_times/domain/entities/app_update_entity.dart';
import 'package:prayer_times/presentation/common/custom_button.dart';
import 'package:prayer_times/presentation/common/custom_modal_sheet.dart';

class AppUpdateBottomSheet extends StatelessWidget {
  const AppUpdateBottomSheet({
    super.key,
    required this.appUpdateEntity,
    required this.onUpdate,
    required this.onLater,
  });

  final AppUpdateEntity appUpdateEntity;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;

  static Future<void> show({
    required BuildContext context,
    required AppUpdateEntity appUpdateEntity,
    required VoidCallback onUpdate,
    VoidCallback? onLater,
  }) async {
    final bool isForceUpdate = appUpdateEntity.forceUpdate;

    final AppUpdateBottomSheet bottomSheet = await Future.microtask(
      () => AppUpdateBottomSheet(
        appUpdateEntity: appUpdateEntity,
        onUpdate: onUpdate,
        onLater: onLater,
      ),
    );

    if (context.mounted) {
      await context.showBottomSheet(
        bottomSheet,
        context,
        isDismissible: !isForceUpdate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isForceUpdate = appUpdateEntity.forceUpdate;

    return PopScope(
      canPop: !isForceUpdate,
      child: CustomModalSheet(
        theme: theme,
        bottomSheetTitle: appUpdateEntity.title,
        children: [
          if (appUpdateEntity.changeLogs.isNotEmpty) ...[
            Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: 45.percentHeight),
              padding: padding12,
              decoration: BoxDecoration(
                color: context.color.primaryColor25,
                borderRadius: radius12,
              ),
              child: SingleChildScrollView(
                child: HtmlWidget(
                  appUpdateEntity.changeLogs,
                  textStyle: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: thirteenPx,
                    color: context.color.bodyColor,
                  ),
                ),
              ),
            ),
            gapH20,
          ],
          _buildVersionInfo(theme, context),
          gapH25,
          CustomButton(
            title: 'Update Now',
            onPressed: onUpdate,
            horizontalPadding: 0,
          ),
          if (!isForceUpdate) ...[
            gapH10,
            CustomButton(
              title: 'Later',
              onPressed: () {
                onLater?.call();
                context.navigatorPop();
              },
              horizontalPadding: 0,
              isPrimary: false,
            ),
          ],
          gapH10,
        ],
      ),
    );
  }

  Widget _buildVersionInfo(ThemeData theme, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: sixteenPx,
          color: context.color.primaryColor500,
        ),
        gapW8,
        Text(
          'Latest version: v${appUpdateEntity.latestVersion}',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: twelvePx,
            color: context.color.subTitleColor,
          ),
        ),
      ],
    );
  }
}
