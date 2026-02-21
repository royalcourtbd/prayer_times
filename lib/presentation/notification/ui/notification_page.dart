import 'package:flutter/material.dart';
import 'package:prayer_times/core/config/prayer_time_app_screen.dart';
import 'package:prayer_times/core/di/service_locator.dart';
import 'package:prayer_times/core/external_libs/presentable_widget_builder.dart';
import 'package:prayer_times/core/external_libs/svg_image.dart';
import 'package:prayer_times/core/static/svg_path.dart';
import 'package:prayer_times/core/static/ui_const.dart';
import 'package:prayer_times/core/utility/utility.dart';
import 'package:prayer_times/presentation/common/custom_app_bar.dart';
import 'package:prayer_times/presentation/common/custom_button.dart';
import 'package:prayer_times/presentation/notification/presenter/notification_presenter.dart';
import 'package:prayer_times/presentation/notification/presenter/notification_ui_state.dart';
import 'package:prayer_times/domain/entities/notification_entity.dart';
import 'package:prayer_times/presentation/notification/ui/notification_details_page.dart';

class NotificationPage extends StatelessWidget {
  final NotificationPresenter _presenter = locate<NotificationPresenter>();

  NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return PresentableWidgetBuilder(
      presenter: _presenter,
      onInit: () {},
      builder: () {
        final NotificationUiState currentUiState = _presenter.currentUiState;
        final bool isSelectionMode = currentUiState.isSelectionMode;
        final int selectedCount = currentUiState.selectedIds.length;

        return Scaffold(
          appBar: CustomAppBar(
            title: isSelectionMode
                ? '$selectedCount Selected'
                : 'Notifications',
            theme: theme,
            actions: _buildActions(context, currentUiState, theme),
          ),
          body: currentUiState.notifications.isEmpty
              ? _buildEmptyState(theme, context)
              : _buildNotificationList(currentUiState, theme, context),
        );
      },
    );
  }

  /// AppBar actions — selection mode অনুযায়ী পরিবর্তন হবে
  List<Widget> _buildActions(
    BuildContext context,
    NotificationUiState state,
    ThemeData theme,
  ) {
    if (state.notifications.isEmpty) return [];

    if (state.isSelectionMode) {
      return [
        // সব select করা
        IconButton(
          onPressed: () => _presenter.selectAll(),
          icon: Icon(Icons.select_all_rounded, color: context.color.titleColor),
          tooltip: 'Select All',
        ),
        // Delete selected
        IconButton(
          onPressed: state.selectedIds.isEmpty
              ? null
              : () => _presenter.deleteSelected(),
          icon: Icon(
            Icons.delete_outline_rounded,
            color: state.selectedIds.isEmpty
                ? context.color.captionColor
                : context.color.errorColor500,
          ),
          tooltip: 'Delete',
        ),
        // Cancel selection
        IconButton(
          onPressed: () => _presenter.toggleSelectionMode(),
          icon: Icon(Icons.close_rounded, color: context.color.titleColor),
          tooltip: 'Cancel',
        ),
      ];
    }

    return [
      // Selection mode চালু করার button
      IconButton(
        onPressed: () => _presenter.toggleSelectionMode(),
        icon: Icon(Icons.checklist_rounded, color: context.color.titleColor),
        tooltip: 'Select',
      ),
    ];
  }

  Widget _buildEmptyState(ThemeData theme, BuildContext context) {
    return Center(
      child: Padding(
        padding: paddingH20,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SvgImage(SvgPath.icNotificationOutline),
            gapH16,
            Text(
              'No Notifications Yet',
              style: theme.textTheme.titleMedium!.copyWith(
                color: context.color.titleColor,
              ),
            ),
            gapH8,
            Text(
              'You\'ll receive notifications about prayer times and updates here',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: context.color.subTitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(
    NotificationUiState state,
    ThemeData theme,
    BuildContext context,
  ) {
    final List<NotificationEntity> notifications = state.notifications;

    return ListView.separated(
      padding: padding15,
      itemCount: notifications.length,
      separatorBuilder: (_, _) => gapH16,
      itemBuilder: (context, index) {
        final NotificationEntity notification = notifications[index];
        final bool isSelected = state.selectedIds.contains(notification.id);

        return InkWell(
          borderRadius: radius15,
          onTap: () {
            if (state.isSelectionMode) {
              _presenter.toggleSelection(notification.id);
            } else {
              _presenter.markAsRead(notification.id);
              context.navigatorPush(
                NotificationDetailsPage(notification: notification),
              );
            }
          },
          onLongPress: () {
            if (!state.isSelectionMode) {
              _presenter.toggleSelectionMode();
              _presenter.toggleSelection(notification.id);
            }
          },
          child: Container(
            padding: padding15,
            decoration: BoxDecoration(
              color: isSelected
                  ? context.color.primaryColor25
                  : notification.isRead
                  ? context.color.scaffoldBachgroundColor
                  : context.color.primaryColor25,
              borderRadius: radius10,
              border: isSelected
                  ? Border.all(color: context.color.primaryColor, width: 1.5)
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selection mode-এ checkbox, না হলে avatar
                if (state.isSelectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) =>
                        _presenter.toggleSelection(notification.id),
                    activeColor: context.color.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(fourPx),
                    ),
                  ),
                ] else ...[
                  CircleAvatar(
                    radius: twentyTwoPx,
                    backgroundColor: generateAvatarColor(index: index),
                    child: SvgImage(
                      SvgPath.icNotificationOutline,
                      color: context.color.whiteColor,
                    ),
                  ),
                ],
                gapW14,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium!.copyWith(
                          color: context.color.titleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      gapH8,
                      Text(
                        notification.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: context.color.subTitleColor,
                        ),
                      ),
                      gapH8,
                      if (notification.actionUrl != null &&
                          !state.isSelectionMode) ...[
                        gapH8,
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            height: fortyTwoPx,
                            width: 42.percentWidth,
                            child: CustomButton(
                              key: UniqueKey(),
                              horizontalPadding: 0,
                              title: 'View',
                              onPressed: () =>
                                  openUrl(url: notification.actionUrl!),
                              liftIconPath: SvgPath.icLovelyOutline,
                            ),
                          ),
                        ),
                        gapH16,
                      ],
                      Text(
                        _getFormattedTime(notification.timestamp),
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: context.color.captionColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getFormattedTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} Days Ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} Hours Ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} Minutes Ago';
    } else {
      return 'Just Now';
    }
  }

  Color generateAvatarColor({
    required int index,
    Color baseColor = const Color(0xFF417360),
  }) {
    // বেস কালার থেকে HSL ভ্যালু নিয়ে নতুন কালার জেনারেট করা
    final HSLColor hslColor = HSLColor.fromColor(baseColor);

    // প্রতি ইনডেক্সে হিউ ভ্যালু পরিবর্তন (30 ডিগ্রি করে)
    final double newHue = (hslColor.hue + (index * 30)) % 360;

    // স্যাচুরেশন এবং লাইটনেস মডিফাই করা
    final double saturation = 0.3 + (index % 3) * 0.2; // 0.3 থেকে 0.7 এর মধ্যে
    final double lightness = 0.4 + (index % 2) * 0.1; // 0.4 থেকে 0.5 এর মধ্যে

    // নতুন HSL কালার তৈরি
    final HSLColor newHslColor = HSLColor.fromAHSL(
      1.0,
      newHue,
      saturation,
      lightness,
    );

    return newHslColor.toColor();
  }
}
