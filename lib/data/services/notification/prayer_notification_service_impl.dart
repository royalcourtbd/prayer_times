import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:prayer_times/core/utility/logger_utility.dart';
import 'package:prayer_times/core/utility/trial_utility.dart';
import 'package:prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:prayer_times/domain/service/prayer_notification_service.dart';
import 'package:prayer_times/presentation/home/models/waqt.dart';

const String _channelKey = 'prayer_time_channel';
const String _channelName = 'Prayer Time Notifications';
const String _channelDescription = 'Adhan notifications for daily prayer times';
const String _soundSource = 'resource://raw/hayya_ala_salah';

const int _midnightResetId = 1000;

/// Schedulable prayer types (excludes sunrise and duha).
const List<WaqtType> _schedulableTypes = [
  WaqtType.fajr,
  WaqtType.dhuhr,
  WaqtType.asr,
  WaqtType.maghrib,
  WaqtType.isha,
];

class PrayerNotificationServiceImpl implements PrayerNotificationService {
  /// Deterministic notification ID for each prayer.
  static int _notificationId(WaqtType type, {int dayOffset = 0}) {
    final int baseId;
    switch (type) {
      case WaqtType.fajr:
        baseId = 1001;
      case WaqtType.dhuhr:
        baseId = 1002;
      case WaqtType.asr:
        baseId = 1003;
      case WaqtType.maghrib:
        baseId = 1004;
      case WaqtType.isha:
        baseId = 1005;
      default:
        return 0;
    }
    return baseId + (dayOffset * 10);
  }

  @override
  Future<void> initialize() async {
    await catchFutureOrVoid(() async {
      await AwesomeNotifications()
          .initialize('resource://drawable/notification', [
            NotificationChannel(
              channelKey: _channelKey,
              channelName: _channelName,
              channelDescription: _channelDescription,
              importance: NotificationImportance.High,
              defaultPrivacy: NotificationPrivacy.Public,
              soundSource: _soundSource,
              playSound: true,
              enableVibration: true,
              defaultColor: const Color(0xFF4D7AEB),
            ),
          ], debug: false);

      // Listeners সেট করা — static methods দরকার
      await AwesomeNotifications().setListeners(
        onActionReceivedMethod: _onActionReceived,
        onNotificationDisplayedMethod: _onNotificationDisplayed,
      );

      logDebug('PrayerNotificationService initialized');
    });
  }

  /// Notification tap action handler
  @pragma('vm:entry-point')
  static Future<void> _onActionReceived(ReceivedAction action) async {
    // Notification এ tap করলে app open হবে (default behavior)
  }

  /// Notification display handler
  @pragma('vm:entry-point')
  static Future<void> _onNotificationDisplayed(
    ReceivedNotification notification,
  ) async {
    // Notification display হলে log করা
  }

  @override
  Future<void> scheduleForPrayer({
    required WaqtType waqtType,
    required DateTime prayerTime,
    required int adjustmentMinutes,
  }) async {
    await catchFutureOrVoid(() async {
      if (!_schedulableTypes.contains(waqtType)) return;

      final DateTime scheduledTime = prayerTime.add(
        Duration(minutes: adjustmentMinutes),
      );

      // সময় পার হয়ে গেলে schedule করার দরকার নেই
      if (scheduledTime.isBefore(DateTime.now())) return;

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _notificationId(waqtType),
          channelKey: _channelKey,
          title: '${waqtType.displayName} Prayer Time',
          body: _buildNotificationBody(waqtType, adjustmentMinutes),
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          payload: {'waqtType': waqtType.name},
          autoDismissible: true,
          color: const Color(0xFF4D7AEB),
          largeIcon: 'resource://mipmap/ic_launcher',
        ),
        schedule: NotificationCalendar.fromDate(
          date: scheduledTime,
          allowWhileIdle: true,
          preciseAlarm: true,
          repeats: false,
        ),
      );

      logDebug(
        'Scheduled ${waqtType.displayName} notification at $scheduledTime '
        '(adjustment: ${adjustmentMinutes}min)',
      );
    });
  }

  @override
  Future<void> cancelForPrayer(WaqtType waqtType) async {
    await catchFutureOrVoid(() async {
      if (!_schedulableTypes.contains(waqtType)) return;

      // Cancel today + future days (7 days worth)
      for (int day = 0; day < 7; day++) {
        await AwesomeNotifications().cancel(
          _notificationId(waqtType, dayOffset: day),
        );
      }
      logDebug('Cancelled ${waqtType.displayName} notifications');
    });
  }

  @override
  Future<void> cancelAll() async {
    await catchFutureOrVoid(() async {
      await AwesomeNotifications().cancelAllSchedules();
      logDebug('Cancelled all prayer notifications');
    });
  }

  @override
  Future<void> rescheduleAll({
    required PrayerTimeEntity prayerTimeEntity,
    required Map<WaqtType, bool> enabledMap,
    required Map<WaqtType, int> minutesMap,
  }) async {
    await catchFutureOrVoid(() async {
      // সব existing prayer notifications cancel (midnight reset বাদে)
      for (final type in _schedulableTypes) {
        await cancelForPrayer(type);
      }

      // Enabled prayer গুলোর notification schedule
      for (final type in _schedulableTypes) {
        final bool isEnabled = enabledMap[type] ?? false;
        if (!isEnabled) continue;

        final DateTime? time = _getTimeForType(type, prayerTimeEntity);
        if (time == null) continue;

        final int minutes = minutesMap[type] ?? 0;

        await scheduleForPrayer(
          waqtType: type,
          prayerTime: time,
          adjustmentMinutes: minutes,
        );
      }

      logDebug('Rescheduled all prayer notifications');
    });
  }

  @override
  Future<void> scheduleMidnightReset() async {
    await catchFutureOrVoid(() async {
      // আগের midnight reset cancel
      await AwesomeNotifications().cancel(_midnightResetId);

      // রাত ১২:০১ AM-এ daily repeating notification
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _midnightResetId,
          channelKey: _channelKey,
          title: 'Prayer Times Updated',
          body: 'Your prayer notifications have been refreshed for today.',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
        ),
        schedule: NotificationCalendar(
          hour: 0,
          minute: 1,
          second: 0,
          allowWhileIdle: true,
          preciseAlarm: true,
          repeats: true,
        ),
      );

      logDebug('Midnight reset notification scheduled at 00:01');
    });
  }

  @override
  Future<void> checkAndRequestExactAlarmPermission() async {
    await catchFutureOrVoid(() async {
      final List<NotificationPermission> allowed =
          await AwesomeNotifications().checkPermissionList(
            permissions: [NotificationPermission.PreciseAlarms],
          );

      if (allowed.contains(NotificationPermission.PreciseAlarms)) {
        logDebug('Precise alarm permission already granted');
        return;
      }

      // Android 12+ এ এটি "Alarms & Reminders" settings-এ নিয়ে যাবে
      await AwesomeNotifications().requestPermissionToSendNotifications(
        permissions: [NotificationPermission.PreciseAlarms],
      );
      logDebug('Requested precise alarm permission');
    });
  }

  /// Prayer time entity থেকে নির্দিষ্ট prayer-এর সময় বের করা
  DateTime? _getTimeForType(WaqtType type, PrayerTimeEntity entity) {
    switch (type) {
      case WaqtType.fajr:
        return entity.startFajr;
      case WaqtType.dhuhr:
        return entity.startDhuhr;
      case WaqtType.asr:
        return entity.startAsr;
      case WaqtType.maghrib:
        return entity.startMaghrib;
      case WaqtType.isha:
        return entity.startIsha;
      default:
        return null;
    }
  }

  /// Notification body তৈরি adjustment অনুযায়ী
  static String _buildNotificationBody(WaqtType type, int adjustmentMinutes) {
    if (adjustmentMinutes == 0) {
      return 'It is time for ${type.displayName} prayer.';
    } else if (adjustmentMinutes > 0) {
      return '${type.displayName} prayer was $adjustmentMinutes minutes ago.';
    } else {
      return '${type.displayName} prayer is in ${adjustmentMinutes.abs()} minutes.';
    }
  }
}
