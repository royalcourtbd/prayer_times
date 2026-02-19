import 'package:prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:prayer_times/presentation/home/models/waqt.dart';

/// Local notification scheduling service for daily prayer times.
abstract class PrayerNotificationService {
  /// Initialize the notification plugin and channels.
  Future<void> initialize();

  /// Schedule a notification for a specific prayer.
  /// [adjustmentMinutes]: negative=before, 0=exact, positive=after prayer time.
  Future<void> scheduleForPrayer({
    required WaqtType waqtType,
    required DateTime prayerTime,
    required int adjustmentMinutes,
  });

  /// Cancel notification for a specific prayer type.
  Future<void> cancelForPrayer(WaqtType waqtType);

  /// Cancel all scheduled prayer notifications.
  Future<void> cancelAll();

  /// Reschedule all enabled prayers based on current settings.
  Future<void> rescheduleAll({
    required PrayerTimeEntity prayerTimeEntity,
    required Map<WaqtType, bool> enabledMap,
    required Map<WaqtType, int> minutesMap,
  });

  /// Schedule a daily midnight reset trigger.
  Future<void> scheduleMidnightReset();

  /// Check and request precise alarm permission (Android 12+).
  /// Required for SCHEDULE_EXACT_ALARM to work correctly.
  Future<void> checkAndRequestExactAlarmPermission();
}
