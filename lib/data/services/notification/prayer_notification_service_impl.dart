import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prayer_times/core/config/prayer_time_app_color.dart';
import 'package:prayer_times/core/utility/logger_utility.dart';
import 'package:prayer_times/core/utility/trial_utility.dart';
import 'package:prayer_times/data/services/local_cache_service.dart';
import 'package:prayer_times/data/services/notification/notification_service_information.dart';
import 'package:prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:prayer_times/domain/service/prayer_notification_service.dart';
import 'package:prayer_times/presentation/home/models/waqt.dart';

// Prayer notification channel (Adhan sound, high importance)
const String _channelKey = 'prayer_time_channel';
const String _channelName = 'Prayer Time Notifications';
const String _channelDescription = 'Adhan notifications for daily prayer times';
const String _soundSource = 'resource://raw/hayya_ala_salah';

// Silent channel — midnight reset trigger (user দেখবে না/শুনবে না)
const String _silentChannelKey = 'midnight_reset_channel';
const String _silentChannelName = 'Background Updates';
const String _silentChannelDescription = 'Silent background task — no user visibility';

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
      await AwesomeNotifications().initialize(notificationIconSource, [
        // Prayer notification channel — Adhan sound + vibration
        NotificationChannel(
          channelKey: _channelKey,
          channelName: _channelName,
          channelDescription: _channelDescription,
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Public,
          soundSource: _soundSource,
          playSound: true,
          enableVibration: true,
          defaultColor: PrayerTimeAppColor.primaryColor500,
        ),
        // Silent channel — midnight reset trigger, user দেখবে না
        NotificationChannel(
          channelKey: _silentChannelKey,
          channelName: _silentChannelName,
          channelDescription: _silentChannelDescription,
          importance: NotificationImportance.Min,
          playSound: false,
          enableVibration: false,
          enableLights: false,
          defaultPrivacy: NotificationPrivacy.Private,
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
    await catchFutureOrVoid(() async {
      // Notification এ tap করলে app open হবে (default behavior)
    });
  }

  /// Notification display handler — midnight reset এ prayer notifications reschedule
  @pragma('vm:entry-point')
  static Future<void> _onNotificationDisplayed(
    ReceivedNotification notification,
  ) async {
    await catchFutureOrVoid(() async {
      if (notification.id != _midnightResetId) return;

      // Silent notification তাৎক্ষণিক dismiss — user notification drawer-এ দেখবে না
      await AwesomeNotifications().dismiss(_midnightResetId);

      // Cache থেকে prayer times ও settings লোড করে reschedule
      await _rescheduleFromCache();
    });
  }

  /// Cache থেকে prayer time ও adjustment settings লোড করে সব notification reschedule করে।
  /// App foreground/background উভয় ক্ষেত্রে কাজ করে।
  static Future<void> _rescheduleFromCache() async {
    await catchFutureOrVoid(() async {
      LocalCacheService cacheService;

      if (GetIt.instance.isRegistered<LocalCacheService>()) {
        // App চালু আছে — service locator থেকে সরাসরি নাও
        cacheService = GetIt.instance.get<LocalCacheService>();
      } else {
        // Background isolate — Hive manually initialize করো
        final dir = await getApplicationDocumentsDirectory();
        Hive.init(dir.path);
        if (!Hive.isBoxOpen(LocalCacheService.boxName)) {
          await Hive.openBox<dynamic>(LocalCacheService.boxName);
        }
        cacheService = LocalCacheService();
      }

      final String? enabledJson = cacheService.getData<String>(
        key: CacheKeys.adjustmentEnabled,
      );
      final String? minutesJson = cacheService.getData<String>(
        key: CacheKeys.adjustmentMinutes,
      );
      final String? prayerJson = cacheService.getData<String>(
        key: CacheKeys.prayerTimeJson,
      );

      if (enabledJson == null || prayerJson == null) {
        logDebugStatic('Midnight reset: cache-এ data নেই, skip', 'MidnightReset');
        return;
      }

      final Map<WaqtType, bool> enabledMap = _parseEnabledMap(enabledJson);
      final Map<WaqtType, int> minutesMap =
          minutesJson != null ? _parseMinutesMap(minutesJson) : {};
      final PrayerTimeEntity? entity = _parsePrayerEntity(prayerJson);

      if (entity == null) {
        logDebugStatic('Midnight reset: prayer entity parse হয়নি, skip', 'MidnightReset');
        return;
      }

      final service = PrayerNotificationServiceImpl();
      await service.rescheduleAll(
        prayerTimeEntity: entity,
        enabledMap: enabledMap,
        minutesMap: minutesMap,
      );

      logDebugStatic('Midnight reset: সব prayer notification reschedule হয়েছে', 'MidnightReset');
    });
  }

  static Map<WaqtType, bool> _parseEnabledMap(String json) {
    return catchAndReturn<Map<WaqtType, bool>>(() {
      final Map<String, dynamic> decoded = jsonDecode(json);
      final Map<WaqtType, bool> map = {};
      for (final entry in decoded.entries) {
        final idx = WaqtType.values.indexWhere((e) => e.name == entry.key);
        if (idx == -1) continue;
        map[WaqtType.values[idx]] = entry.value as bool;
      }
      return map;
    }) ?? {};
  }

  static Map<WaqtType, int> _parseMinutesMap(String json) {
    return catchAndReturn<Map<WaqtType, int>>(() {
      final Map<String, dynamic> decoded = jsonDecode(json);
      final Map<WaqtType, int> map = {};
      for (final entry in decoded.entries) {
        final idx = WaqtType.values.indexWhere((e) => e.name == entry.key);
        if (idx == -1) continue;
        map[WaqtType.values[idx]] = entry.value as int;
      }
      return map;
    }) ?? {};
  }

  static PrayerTimeEntity? _parsePrayerEntity(String json) {
    return catchAndReturn<PrayerTimeEntity>(() {
      final Map<String, dynamic> m = jsonDecode(json);
      return PrayerTimeEntity(
        startFajr: DateTime.parse(m['startFajr']),
        fajrEnd: DateTime.parse(m['fajrEnd']),
        sunrise: DateTime.parse(m['sunrise']),
        duhaStart: DateTime.parse(m['duhaStart']),
        duhaEnd: DateTime.parse(m['duhaEnd']),
        startDhuhr: DateTime.parse(m['startDhuhr']),
        dhuhrEnd: DateTime.parse(m['dhuhrEnd']),
        startAsr: DateTime.parse(m['startAsr']),
        asrEnd: DateTime.parse(m['asrEnd']),
        startMaghrib: DateTime.parse(m['startMaghrib']),
        maghribEnd: DateTime.parse(m['maghribEnd']),
        startIsha: DateTime.parse(m['startIsha']),
        ishaEnd: DateTime.parse(m['ishaEnd']),
      );
    });
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
          color: PrayerTimeAppColor.primaryColor500,
          largeIcon: notificationIconSource,
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

      // রাত ১২:০১ AM-এ silent trigger — user দেখবে না, শুনবে না
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _midnightResetId,
          channelKey: _silentChannelKey,
          title: '',
          body: '',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Service,
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

      logDebug('Silent midnight reset scheduled at 00:01');
    });
  }

  @override
  Future<void> checkAndRequestExactAlarmPermission() async {
    await catchFutureOrVoid(() async {
      final List<NotificationPermission> allowed = await AwesomeNotifications()
          .checkPermissionList(
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
    return catchAndReturn<DateTime?>(() {
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
    });
  }

  /// Notification body তৈরি adjustment অনুযায়ী
  static String _buildNotificationBody(WaqtType type, int adjustmentMinutes) {
    return catchAndReturn<String>(() {
      if (adjustmentMinutes == 0) {
        return 'It is time for ${type.displayName} prayer.';
      } else if (adjustmentMinutes > 0) {
        return '${type.displayName} prayer was $adjustmentMinutes minutes ago.';
      } else {
        return '${type.displayName} prayer is in ${adjustmentMinutes.abs()} minutes.';
      }
    }) ?? '';
  }
}
