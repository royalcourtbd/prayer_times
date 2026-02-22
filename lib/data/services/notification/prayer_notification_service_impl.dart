import 'dart:convert';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:prayer_times/core/config/prayer_time_app_color.dart';
import 'package:prayer_times/core/utility/logger_utility.dart';
import 'package:prayer_times/core/utility/trial_utility.dart';
import 'package:prayer_times/data/models/location_model.dart';
import 'package:prayer_times/data/services/local_cache_service.dart';
import 'package:prayer_times/data/services/notification/notification_service_information.dart';
import 'package:prayer_times/domain/entities/calculation_method_entity.dart';
import 'package:prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:flutter/cupertino.dart';
import 'package:prayer_times/domain/service/prayer_notification_service.dart';
import 'package:prayer_times/presentation/home/models/waqt.dart';
import 'package:prayer_times/presentation/notification/ui/notification_page.dart';
import 'package:prayer_times/presentation/prayer_times.dart' as app;

// Prayer notification channel (Adhan sound, high importance)
const String _channelKey = 'prayer_time_channel';
const String _channelName = 'Prayer Time Notifications';
const String _channelDescription = 'Adhan notifications for daily prayer times';
const String _soundSource = 'resource://raw/hayya_ala_salah';

// Silent channel — midnight reset trigger (user দেখবে না/শুনবে না)
const String _silentChannelKey = 'midnight_reset_channel';
const String _silentChannelName = 'Background Updates';
const String _silentChannelDescription =
    'Silent background task — no user visibility';

const int _midnightResetId = 1000;

/// Multi-day scheduling: 7 দিন আগে থেকে notifications schedule করা হবে
const int _daysToScheduleAhead = 7;

/// Schedulable prayer types (excludes sunrise and duha).
const List<WaqtType> _schedulableTypes = [
  WaqtType.fajr,
  WaqtType.dhuhr,
  WaqtType.asr,
  WaqtType.maghrib,
  WaqtType.isha,
];

class PrayerNotificationServiceImpl implements PrayerNotificationService {
  /// Deterministic notification ID for each prayer (legacy - single day).
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

  /// Date-based unique notification ID - প্রতিটি দিনের প্রতিটি prayer-এর জন্য আলাদা ID
  /// Format: YYYYMMDD * 10 + prayerBaseId
  /// Example: 20260222 * 10 + 1 = 202602221 (Fajr on Feb 22, 2026)
  static int _notificationIdForDate(WaqtType type, DateTime date) {
    final int baseId;
    switch (type) {
      case WaqtType.fajr:
        baseId = 1;
      case WaqtType.dhuhr:
        baseId = 2;
      case WaqtType.asr:
        baseId = 3;
      case WaqtType.maghrib:
        baseId = 4;
      case WaqtType.isha:
        baseId = 5;
      default:
        return 0;
    }
    final dateComponent = date.year * 10000 + date.month * 100 + date.day;
    return dateComponent * 10 + baseId;
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
        // Push notification channel — FCM foreground push
        NotificationChannel(
          channelKey: pushNotificationChannelKey,
          channelName: pushNotificationChannelName,
          channelDescription: pushNotificationChannelDescription,
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Public,
          playSound: true,
          enableVibration: true,
          defaultColor: PrayerTimeAppColor.primaryColor500,
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

  /// Notification tap action handler — NotificationPage-এ navigate
  @pragma('vm:entry-point')
  static Future<void> _onActionReceived(ReceivedAction action) async {
    await catchFutureOrVoid(() async {
      final NavigatorState? navigatorState =
          app.PrayerTimes.navigatorKey.currentState;
      if (navigatorState == null) return;

      // UI thread-এ navigate করতে হবে — slight delay দিয়ে ensure
      Future.delayed(const Duration(milliseconds: 300), () {
        navigatorState.push(
          CupertinoPageRoute(builder: (_) => NotificationPage()),
        );
      });
    });
  }

  /// Notification display handler — midnight reset এ reschedule + prayer notification store
  @pragma('vm:entry-point')
  static Future<void> _onNotificationDisplayed(
    ReceivedNotification notification,
  ) async {
    await catchFutureOrVoid(() async {
      if (notification.id == _midnightResetId) {
        // Silent notification তাৎক্ষণিক dismiss — user notification drawer-এ দেখবে না
        await AwesomeNotifications().dismiss(_midnightResetId);

        // Cache থেকে prayer times ও settings লোড করে reschedule
        await _rescheduleFromCache();
        return;
      }

      // শুধু prayer time channel-এর notification store করো
      // Push notification channel-এর গুলো HomePresenter-এ onMessageReceived-এ store হয়
      if (notification.channelKey != _channelKey) return;

      // Prayer notification displayed — Hive-তে save করো
      await _storePrayerNotification(notification);
    });
  }

  /// adhan_dart দিয়ে আজকের prayer times fresh calculate করে সব notification reschedule করে।
  /// App foreground/background উভয় ক্ষেত্রে কাজ করে।
  static Future<void> _rescheduleFromCache() async {
    await catchFutureOrVoid(() async {
      LocalCacheService cacheService;

      if (GetIt.instance.isRegistered<LocalCacheService>()) {
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

      // Adjustment settings লোড
      final String? enabledJson = cacheService.getData<String>(
        key: CacheKeys.adjustmentEnabled,
      );
      final String? minutesJson = cacheService.getData<String>(
        key: CacheKeys.adjustmentMinutes,
      );

      // Location লোড — ছাড়া calculation সম্ভব না
      final String? locationJson = cacheService.getData<String>(
        key: CacheKeys.location,
      );

      if (enabledJson == null || locationJson == null) {
        logDebugStatic(
          'Midnight reset: cache-এ data নেই, skip',
          'MidnightReset',
        );
        return;
      }

      final LocationModel? location = _parseLocation(locationJson);
      if (location == null) {
        logDebugStatic(
          'Midnight reset: location parse হয়নি, skip',
          'MidnightReset',
        );
        return;
      }

      // Calculation/juristic method — cache থেকে, default fallback সহ
      final String calculationMethodId =
          cacheService.getData<String>(key: CacheKeys.calculationMethodId) ??
          'karachi';
      final String juristicMethod =
          cacheService.getData<String>(key: CacheKeys.juristicMethod) ??
          'Shafi';

      // adhan_dart দিয়ে আজকের prayer times calculate
      final PrayerTimeEntity entity = _calculatePrayerTimes(
        latitude: location.latitude,
        longitude: location.longitude,
        timezone: location.timezone,
        calculationMethodId: calculationMethodId,
        juristicMethod: juristicMethod,
      );

      final Map<WaqtType, bool> enabledMap = _parseEnabledMap(enabledJson);
      final Map<WaqtType, int> minutesMap = minutesJson != null
          ? _parseMinutesMap(minutesJson)
          : {};

      final service = PrayerNotificationServiceImpl();
      await service.rescheduleAll(
        prayerTimeEntity: entity,
        enabledMap: enabledMap,
        minutesMap: minutesMap,
      );

      logDebugStatic(
        'Midnight reset: সব prayer notification reschedule হয়েছে',
        'MidnightReset',
      );
    });
  }

  /// Prayer notification display হলে Hive-তে save — background isolate safe
  static Future<void> _storePrayerNotification(
    ReceivedNotification notification,
  ) async {
    await catchFutureOrVoid(() async {
      LocalCacheService cacheService;

      if (GetIt.instance.isRegistered<LocalCacheService>()) {
        cacheService = GetIt.instance.get<LocalCacheService>();
      } else {
        // Background isolate — Hive manually initialize
        final dir = await getApplicationDocumentsDirectory();
        Hive.init(dir.path);
        if (!Hive.isBoxOpen(LocalCacheService.boxName)) {
          await Hive.openBox<dynamic>(LocalCacheService.boxName);
        }
        cacheService = LocalCacheService();
      }

      // Existing notifications load
      final String? existingJson = cacheService.getData<String>(
        key: CacheKeys.notifications,
      );

      List<Map<String, dynamic>> notificationsList = [];
      if (existingJson != null) {
        final decoded = jsonDecode(existingJson) as List<dynamic>;
        notificationsList = decoded
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      // New notification add
      final Map<String, dynamic> newNotification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': notification.title ?? '',
        'description': notification.body ?? '',
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'prayer_time',
        'isRead': false,
        'imageUrl': null,
        'actionUrl': null,
      };

      notificationsList.insert(0, newNotification);

      // 7 দিনের পুরনো notification মুছে ফেলো
      final DateTime cutoff = DateTime.now().subtract(const Duration(days: 7));
      notificationsList.removeWhere((n) {
        final timestamp = DateTime.tryParse(n['timestamp'] ?? '');
        return timestamp != null && timestamp.isBefore(cutoff);
      });

      await cacheService.saveData<String>(
        key: CacheKeys.notifications,
        value: jsonEncode(notificationsList),
      );

      logDebugStatic('Prayer notification stored', 'NotificationStore');
    });
  }

  /// Cached location JSON parse
  static LocationModel? _parseLocation(String json) {
    return catchAndReturn<LocationModel>(() {
      final Map<String, dynamic> m = jsonDecode(json);
      return LocationModel.fromJson(m);
    });
  }

  /// adhan_dart দিয়ে prayer times calculate — কোনো API call নেই
  /// [date] parameter দিলে সেই নির্দিষ্ট দিনের prayer times calculate হবে
  static PrayerTimeEntity _calculatePrayerTimes({
    required double latitude,
    required double longitude,
    required String? timezone,
    required String calculationMethodId,
    required String juristicMethod,
    DateTime? date,
  }) {
    tz_data.initializeTimeZones();

    final coordinates = Coordinates(latitude, longitude);
    final method = CalculationMethodEntity.getById(calculationMethodId);
    final params = method.getParams()
      ..madhab = juristicMethod == 'Hanafi' ? Madhab.hanafi : Madhab.shafi;

    // Target date — timezone অনুযায়ী
    DateTime targetDate = date ?? DateTime.now();
    if (timezone != null && timezone.isNotEmpty) {
      try {
        if (date != null) {
          // নির্দিষ্ট date-এর জন্য timezone adjust
          targetDate = tz.TZDateTime(
            tz.getLocation(timezone),
            date.year,
            date.month,
            date.day,
            12, // midday to avoid DST issues
          );
        } else {
          targetDate = tz.TZDateTime.now(tz.getLocation(timezone));
        }
      } catch (_) {
        // fallback to local time
      }
    }

    final prayerTimes = PrayerTimes(
      coordinates: coordinates,
      date: targetDate,
      calculationParameters: params,
      precision: true,
    );

    // UTC → location timezone convert helper
    DateTime toLocal(DateTime utc) {
      if (timezone != null && timezone.isNotEmpty) {
        try {
          return tz.TZDateTime.from(utc, tz.getLocation(timezone));
        } catch (_) {
          return utc.toLocal();
        }
      }
      return utc.toLocal();
    }

    return PrayerTimeEntity(
      startFajr: toLocal(prayerTimes.fajr),
      fajrEnd: toLocal(prayerTimes.sunrise),
      sunrise: toLocal(prayerTimes.sunrise),
      duhaStart: toLocal(prayerTimes.sunrise).add(const Duration(minutes: 15)),
      duhaEnd: toLocal(prayerTimes.dhuhr),
      startDhuhr: toLocal(prayerTimes.dhuhr),
      dhuhrEnd: toLocal(prayerTimes.asr),
      startAsr: toLocal(prayerTimes.asr),
      asrEnd: toLocal(prayerTimes.maghrib),
      startMaghrib: toLocal(prayerTimes.maghrib),
      maghribEnd: toLocal(prayerTimes.isha),
      startIsha: toLocal(prayerTimes.isha),
      ishaEnd: toLocal(prayerTimes.fajr).add(const Duration(days: 1)),
    );
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
        }) ??
        {};
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
        }) ??
        {};
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
          repeats: true,
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
  Future<void> scheduleForMultipleDays({
    required double latitude,
    required double longitude,
    required String? timezone,
    required Map<WaqtType, bool> enabledMap,
    required Map<WaqtType, int> minutesMap,
    required String calculationMethodId,
    required String juristicMethod,
  }) async {
    await catchFutureOrVoid(() async {
      // সব existing scheduled notifications cancel (midnight reset বাদে)
      for (final type in _schedulableTypes) {
        await _cancelMultipleDaysForPrayer(type);
      }

      final DateTime now = DateTime.now();

      // 7 দিনের জন্য notifications schedule
      for (int dayOffset = 0; dayOffset < _daysToScheduleAhead; dayOffset++) {
        final DateTime targetDate = now.add(Duration(days: dayOffset));

        // এই দিনের prayer times calculate
        final PrayerTimeEntity prayerTimeEntity = _calculatePrayerTimes(
          latitude: latitude,
          longitude: longitude,
          timezone: timezone,
          calculationMethodId: calculationMethodId,
          juristicMethod: juristicMethod,
          date: targetDate,
        );

        // প্রতিটি enabled prayer-এর জন্য notification schedule
        for (final type in _schedulableTypes) {
          final bool isEnabled = enabledMap[type] ?? false;
          if (!isEnabled) continue;

          final DateTime? prayerTime = _getTimeForType(type, prayerTimeEntity);
          if (prayerTime == null) continue;

          final int adjustmentMinutes = minutesMap[type] ?? 0;
          final DateTime scheduledTime = prayerTime.add(
            Duration(minutes: adjustmentMinutes),
          );

          // অতীতের time skip
          if (scheduledTime.isBefore(DateTime.now())) continue;

          // Date-based unique ID দিয়ে schedule
          await _scheduleNotificationWithId(
            notificationId: _notificationIdForDate(type, targetDate),
            waqtType: type,
            scheduledTime: scheduledTime,
            adjustmentMinutes: adjustmentMinutes,
          );
        }
      }

      logDebug(
        'Scheduled notifications for $_daysToScheduleAhead days ahead',
      );
    });
  }

  /// Multi-day scheduling-এর জন্য notification schedule করা
  Future<void> _scheduleNotificationWithId({
    required int notificationId,
    required WaqtType waqtType,
    required DateTime scheduledTime,
    required int adjustmentMinutes,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
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
        repeats: false, // One-time per day, multi-day scheduled
      ),
    );
  }

  /// Multi-day notifications cancel করা
  Future<void> _cancelMultipleDaysForPrayer(WaqtType waqtType) async {
    final DateTime now = DateTime.now();
    // 14 দিনের notifications cancel (safety margin)
    for (int dayOffset = 0; dayOffset < 14; dayOffset++) {
      final DateTime targetDate = now.add(Duration(days: dayOffset));
      await AwesomeNotifications().cancel(
        _notificationIdForDate(waqtType, targetDate),
      );
    }
  }

  @override
  Future<bool> shouldReschedule() async {
    // Check if we have less than 3 days of notifications scheduled
    // এই method app resume-এ call হবে
    final List<NotificationModel> scheduled =
        await AwesomeNotifications().listScheduledNotifications();

    // Prayer notifications count করো (midnight reset বাদে)
    final int prayerNotificationCount = scheduled
        .where((n) => n.content?.channelKey == _channelKey)
        .length;

    // যদি 10 টার কম notification থাকে, reschedule দরকার
    // (5 prayers * 2 days = 10 minimum)
    return prayerNotificationCount < 10;
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
        }) ??
        '';
  }
}
