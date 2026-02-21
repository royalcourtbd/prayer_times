import 'package:flutter/material.dart';
import 'package:prayer_times/core/static/ui_const.dart';
import 'package:prayer_times/core/utility/utility.dart';
import 'package:prayer_times/domain/entities/notification_entity.dart';
import 'package:prayer_times/presentation/common/custom_app_bar.dart';

class NotificationDetailsPage extends StatelessWidget {
  const NotificationDetailsPage({super.key, required this.notification});
  final NotificationEntity notification;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Notification Details',
        theme: theme,
      ),
      body: SingleChildScrollView(
        padding: padding15,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: theme.textTheme.titleLarge!.copyWith(
                color: context.color.titleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            gapH8,
            Text(
              _getFormattedTime(notification.timestamp),
              style: theme.textTheme.bodySmall!.copyWith(
                color: context.color.captionColor,
              ),
            ),
            gapH16,
            Text(
              notification.description,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: context.color.subTitleColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
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
}
