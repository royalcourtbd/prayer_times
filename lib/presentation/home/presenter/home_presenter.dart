import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:prayer_times/core/utility/trial_utility.dart';
import 'package:get/get.dart';
import 'package:prayer_times/core/base/base_presenter.dart';
import 'package:prayer_times/data/services/hijri_date_service.dart';
import 'package:prayer_times/core/config/prayer_time_app_screen.dart';
import 'package:prayer_times/core/di/service_locator.dart';
import 'package:prayer_times/core/utility/utility.dart';
import 'package:prayer_times/domain/entities/location_entity.dart';
import 'package:prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:prayer_times/domain/service/prayer_notification_service.dart';
import 'package:prayer_times/domain/service/time_service.dart';
import 'package:prayer_times/domain/service/waqt_calculation_service.dart';
import 'package:prayer_times/domain/usecases/check_notification_permission_usecase.dart';
import 'package:prayer_times/domain/usecases/get_active_waqt_usecase.dart';
import 'package:prayer_times/domain/usecases/get_location_usecase.dart';
import 'package:prayer_times/domain/usecases/get_prayer_times_usecase.dart';
import 'package:prayer_times/domain/usecases/get_remaining_time_usecase.dart';
import 'package:prayer_times/domain/usecases/request_notification_permission_usecase.dart';
import 'package:prayer_times/domain/usecases/initialize_device_token_usecase.dart';
import 'package:prayer_times/presentation/common/notification_denied_dialog.dart';
import 'package:prayer_times/presentation/event/pesenter/event_presenter.dart';
import 'package:prayer_times/presentation/main/presenter/main_presenter.dart';
import 'package:prayer_times/presentation/home/models/fasting_state.dart';
import 'package:prayer_times/presentation/home/models/waqt.dart';
import 'package:prayer_times/presentation/home/presenter/home_ui_state.dart';
import 'package:prayer_times/presentation/prayer_tracker/presenter/prayer_tracker_presenter.dart';
import 'package:prayer_times/data/services/in_app_review_service.dart';
import 'package:prayer_times/data/services/local_cache_service.dart';
import 'package:prayer_times/domain/entities/app_update_entity.dart';
import 'package:prayer_times/domain/usecases/get_app_update_info_usecase.dart';
import 'package:prayer_times/presentation/home/widgets/app_update_bottom_sheet.dart';
import 'package:prayer_times/presentation/settings/widgets/select_location_bottomsheet.dart';
import 'package:prayer_times/domain/service/notification_service.dart';
import 'package:prayer_times/domain/usecases/get_notifications_usecase.dart';
import 'package:prayer_times/data/models/notification_model.dart';

class HomePresenter extends BasePresenter<HomeUiState> {
  final GetLocationUseCase _getLocationUseCase;
  final GetPrayerTimesUseCase _getPrayerTimesUseCase;
  final GetActiveWaqtUseCase _getActiveWaqtUseCase;
  final GetRemainingTimeUseCase _getRemainingTimeUseCase;
  final TimeService _timeService;
  final WaqtCalculationService _waqtCalculationService;
  final RequestNotificationPermissionUsecase
  _requestNotificationPermissionUsecase;
  final CheckNotificationPermissionUsecase _checkNotificationPermissionUsecase;
  final InitializeDeviceTokenUseCase _initializeDeviceTokenUseCase;
  final GetAppUpdateInfoUseCase _getAppUpdateInfoUseCase;
  final LocalCacheService _cacheService;
  final HijriDateService _hijriDateService;
  final PrayerNotificationService _prayerNotificationService;
  final NotificationService _notificationService;
  final GetNotificationsUseCase _getNotificationsUseCase;
  StreamSubscription<DateTime>? _timeSubscription;

  final ScrollController prayerTimesScrollController = ScrollController();

  bool _userScrolled = false;

  HomePresenter(
    this._getLocationUseCase,
    this._getPrayerTimesUseCase,
    this._getActiveWaqtUseCase,
    this._getRemainingTimeUseCase,
    this._timeService,
    this._waqtCalculationService,
    this._requestNotificationPermissionUsecase,
    this._checkNotificationPermissionUsecase,
    this._initializeDeviceTokenUseCase,
    this._getAppUpdateInfoUseCase,
    this._cacheService,
    this._hijriDateService,
    this._prayerNotificationService,
    this._notificationService,
    this._getNotificationsUseCase,
  );

  final Obs<HomeUiState> uiState = Obs<HomeUiState>(HomeUiState.empty());
  HomeUiState get currentUiState => uiState.value;

  late final PrayerTrackerPresenter prayerTrackerPresenter =
      locate<PrayerTrackerPresenter>();

  late final MainPresenter mainPresenter = locate<MainPresenter>();

  @override
  void onInit() {
    super.onInit();
    _startTimer();
    _loadAdjustmentSettings();
    checkNotificationPermission();
    _prayerNotificationService.checkAndRequestExactAlarmPermission();
    _syncEventsInBackground();
    _trackLaunchAndRequestReview();
    _checkForAppUpdate();
    _prayerNotificationService.scheduleMidnightReset();
    _setupFCMListeners();
    _checkInitialNotification();

    prayerTimesScrollController.addListener(_onUserScroll);
  }

  Future<void> _trackLaunchAndRequestReview() async {
    final inAppReviewService = locate<InAppReviewService>();
    await inAppReviewService.trackAppLaunch();
    await inAppReviewService.requestReviewIfEligible();
  }

  Future<void> _checkForAppUpdate() async {
    await parseDataFromEitherWithUserMessage<AppUpdateEntity>(
      task: () => _getAppUpdateInfoUseCase.execute(),
      showLoading: false,
      onDataLoaded: (AppUpdateEntity appUpdate) async {
        if (appUpdate.latestVersion.isEmpty) return;

        final String currentVersion = await currentAppVersion;
        final bool isUpdateAvailable = _isVersionNewer(
          appUpdate.latestVersion,
          currentVersion,
        );

        if (!isUpdateAvailable) return;

        final bool isForceUpdate =
            appUpdate.forceUpdate ||
            _isBelowMinSupported(currentVersion, appUpdate.minSupportedVersion);

        // force update না হলে, user আগে dismiss করে থাকলে আবার দেখাবে না
        if (!isForceUpdate) {
          final String? dismissedVersion = _cacheService.getData<String>(
            key: CacheKeys.dismissedUpdateVersion,
          );
          if (dismissedVersion == appUpdate.latestVersion) return;
        }

        // UI ready হওয়ার জন্য সামান্য delay
        await Future.delayed(const Duration(seconds: 2));

        final BuildContext? context = Get.context;
        if (context == null || !context.mounted) return;

        await AppUpdateBottomSheet.show(
          context: context,
          appUpdateEntity: isForceUpdate
              ? AppUpdateEntity(
                  changeLogs: appUpdate.changeLogs,
                  forceUpdate: true,
                  latestVersion: appUpdate.latestVersion,
                  minSupportedVersion: appUpdate.minSupportedVersion,
                  title: appUpdate.title,
                  storeUrl: appUpdate.storeUrl,
                  iosStoreUrl: appUpdate.iosStoreUrl,
                )
              : appUpdate,
          onUpdate: () => openUrl(url: suitableAppStoreUrl),
          onLater: () {
            _cacheService.saveData<String>(
              key: CacheKeys.dismissedUpdateVersion,
              value: appUpdate.latestVersion,
            );
          },
        );
      },
    );
  }

  /// latestVersion > currentVersion কিনা check করে
  bool _isVersionNewer(String latest, String current) {
    final List<int> latestParts = _parseVersion(latest);
    final List<int> currentParts = _parseVersion(current);

    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  /// currentVersion < minSupported কিনা check করে
  bool _isBelowMinSupported(String current, String minSupported) {
    if (minSupported.isEmpty) return false;
    return _isVersionNewer(minSupported, current);
  }

  List<int> _parseVersion(String version) {
    return version.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  }

  Future<void> _syncEventsInBackground() async {
    // Silent sync - user কে loading দেখাবে না
    final eventPresenter = locate<EventPresenter>();
    await eventPresenter.loadEvents(forceRefresh: true);
  }

  @override
  void onClose() {
    prayerTimesScrollController.removeListener(_onUserScroll);
    prayerTimesScrollController.dispose();
    _timeSubscription?.cancel();
    super.onClose();
  }

  Future<void> checkNotificationPermission() async {
    await parseDataFromEitherWithUserMessage<bool>(
      task: () => _checkNotificationPermissionUsecase.execute(),
      showLoading: false,
      onDataLoaded: (bool hasPermission) {
        if (!hasPermission) {
          log('requestNotificationPermission');
          requestNotificationPermission();
        } else {
          log('hasPermission: $hasPermission');

          _initializeDeviceToken();
        }
      },
    );
  }

  Future<void> requestNotificationPermission() async {
    await parseDataFromEitherWithUserMessage<void>(
      task: () => _requestNotificationPermissionUsecase.execute(
        onGrantedOrSkippedForNow: () {
          // পারমিশন দেওয়া হয়েছে
          log('onGrantedOrSkippedForNow');
          // FCM token initialize করুন
          _initializeDeviceToken();
        },
        onDenied: () {
          // পারমিশন দেওয়া হয়নি
          log('onDenied ');
          NotificationDeniedDialog.show(
            context: Get.context!,
            onSubmit: () async {
              openNotificationSettings();
            },
          );
          // FCM token permission ছাড়াও কাজ করে, তাই initialize করুন
          _initializeDeviceToken();
        },
      ),
      showLoading: false,
      onDataLoaded: (_) {
        // এখানে কিছু করার দরকার নেই
      },
    );
  }

  Future<void> _initializeDeviceToken() async {
    await parseDataFromEitherWithUserMessage<String>(
      task: () => _initializeDeviceTokenUseCase.execute(),
      showLoading: false,
      onDataLoaded: (String token) {
        log('Device token initialized: ${token.substring(0, 20)}...');
      },
    );
  }

  void openNotificationSettings() {
    AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  Future<void> loadLocationAndPrayerTimes() async {
    await _fetchLocationAndPrayerTimes(forceRemote: false);
  }

  Future<void> refreshLocationAndPrayerTimes() async {
    try {
      await toggleLoading(loading: true);

      bool isConnected = await checkInternetConnection();
      if (!isConnected) {
        await toggleLoading(loading: false);
        showMessage(message: 'No internet connection');
        return;
      }

      await _fetchLocationAndPrayerTimes(forceRemote: true);
    } catch (e) {
      log('error in refreshLocationAndPrayerTimes: $e');
      await toggleLoading(loading: false);
    } finally {
      await toggleLoading(loading: false);
    }
  }

  void _loadAdjustmentSettings() {
    final String? enabledJson = _cacheService.getData<String>(
      key: CacheKeys.adjustmentEnabled,
    );
    final String? minutesJson = _cacheService.getData<String>(
      key: CacheKeys.adjustmentMinutes,
    );

    if (enabledJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(enabledJson);
      final Map<WaqtType, bool> map = {};
      for (final entry in decoded.entries) {
        final waqtType = WaqtType.values.firstWhereOrNull(
          (e) => e.name == entry.key,
        );
        if (waqtType != null) map[waqtType] = entry.value as bool;
      }
      uiState.value = currentUiState.copyWith(adjustmentEnabledMap: map);
    }

    if (minutesJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(minutesJson);
      final Map<WaqtType, int> map = {};
      for (final entry in decoded.entries) {
        final waqtType = WaqtType.values.firstWhereOrNull(
          (e) => e.name == entry.key,
        );
        if (waqtType != null) map[waqtType] = entry.value as int;
      }
      uiState.value = currentUiState.copyWith(adjustmentMinutesMap: map);
    }
  }

  void _saveAdjustmentEnabledMap(Map<WaqtType, bool> map) {
    final jsonMap = map.map((key, value) => MapEntry(key.name, value));
    _cacheService.saveData<String>(
      key: CacheKeys.adjustmentEnabled,
      value: jsonEncode(jsonMap),
    );
  }

  void _saveAdjustmentMinutesMap(Map<WaqtType, int> map) {
    final jsonMap = map.map((key, value) => MapEntry(key.name, value));
    _cacheService.saveData<String>(
      key: CacheKeys.adjustmentMinutes,
      value: jsonEncode(jsonMap),
    );
  }

  void onAdjustmentEnabledChanged(WaqtType type, bool value) {
    final map = Map<WaqtType, bool>.from(currentUiState.adjustmentEnabledMap);
    map[type] = value;
    uiState.value = currentUiState.copyWith(adjustmentEnabledMap: map);
    _saveAdjustmentEnabledMap(map);
    _updateNotificationForPrayer(type);
  }

  void onAdjustmentMinutesChanged(WaqtType type, double value) {
    final map = Map<WaqtType, int>.from(currentUiState.adjustmentMinutesMap);
    map[type] = value.toInt();
    uiState.value = currentUiState.copyWith(adjustmentMinutesMap: map);
    _saveAdjustmentMinutesMap(map);
    _updateNotificationForPrayer(type);
  }

  /// Shows the select location bottom sheet
  void showSelectLocationBottomSheet(BuildContext context) {
    SelectLocationBottomsheet.show(context: context);
  }

  Future<void> _fetchLocationAndPrayerTimes({required bool forceRemote}) async {
    await executeTaskWithLoading(() async {
      await parseDataFromEitherWithUserMessage<LocationEntity>(
        task: () => _getLocationUseCase.execute(forceRemote: forceRemote),
        onDataLoaded: (LocationEntity location) async {
          // Update TimeService timezone when location changes
          _timeService.setTimezone(location.timezone);
          await getPrayerTimes(location: location);
        },
      );
    });
  }

  Future<void> getPrayerTimes({required LocationEntity location}) async {
    await executeTaskWithLoading(() async {
      await parseDataFromEitherWithUserMessage<PrayerTimeEntity>(
        task: () => _getPrayerTimesUseCase.execute(
          latitude: location.latitude,
          longitude: location.longitude,
          date: _timeService.getCurrentTime(),
          timezone: location.timezone,
        ),
        onDataLoaded: (PrayerTimeEntity data) {
          uiState.value = currentUiState.copyWith(
            prayerTime: data,
            location: location,
          );

          // Update TimeService timezone
          _timeService.setTimezone(location.timezone);

          // Update Maghrib time so Hijri date transitions at Maghrib
          _hijriDateService.updateMaghribTime(data.startMaghrib);

          _updateAllStates();
          initializeTracker();
          _rescheduleAllNotifications(data);
        },
      );
    });
  }

  void _updateNotificationForPrayer(WaqtType type) {
    final bool isEnabled =
        currentUiState.adjustmentEnabledMap[type] ?? false;
    final prayerTime = currentUiState.prayerTime;

    if (!isEnabled || prayerTime == null) {
      _prayerNotificationService.cancelForPrayer(type);
      return;
    }

    final int minutes = currentUiState.adjustmentMinutesMap[type] ?? 0;
    final DateTime? time =
        _waqtCalculationService.getWaqtTime(type, prayerTime);

    if (time != null) {
      _prayerNotificationService.scheduleForPrayer(
        waqtType: type,
        prayerTime: time,
        adjustmentMinutes: minutes,
      );
    }
  }

  void onAdjustmentBottomSheetDismissed(WaqtType type) {
    final bool isEnabled =
        currentUiState.adjustmentEnabledMap[type] ?? false;

    if (!isEnabled) return;

    final prayerTime = currentUiState.prayerTime;
    if (prayerTime == null) return;

    final DateTime? time =
        _waqtCalculationService.getWaqtTime(type, prayerTime);
    if (time == null) return;

    final int minutes = currentUiState.adjustmentMinutesMap[type] ?? 0;
    final DateTime scheduledTime = time.add(Duration(minutes: minutes));
    final String formattedTime = getFormattedTime(scheduledTime);
    final String amPm = scheduledTime.hour < 12 ? 'AM' : 'PM';

    showMessage(
      message: '${type.displayName} notification set at $formattedTime $amPm',
    );
  }

  /// সব notifications reschedule করা - 7 দিনের জন্য আগে থেকে schedule
  Future<void> _rescheduleAllNotifications(PrayerTimeEntity prayerTime) async {
    final location = currentUiState.location;
    if (location == null) {
      // Fallback to single-day reschedule if location not available
      _prayerNotificationService.rescheduleAll(
        prayerTimeEntity: prayerTime,
        enabledMap: currentUiState.adjustmentEnabledMap,
        minutesMap: currentUiState.adjustmentMinutesMap,
      );
      return;
    }

    // Cache থেকে calculation settings নিয়ে আসা
    final String calculationMethodId =
        _cacheService.getData<String>(key: CacheKeys.calculationMethodId) ??
            'karachi';
    final String juristicMethod =
        _cacheService.getData<String>(key: CacheKeys.juristicMethod) ?? 'Shafi';

    // 7 দিনের জন্য notifications schedule
    await _prayerNotificationService.scheduleForMultipleDays(
      latitude: location.latitude,
      longitude: location.longitude,
      timezone: location.timezone,
      enabledMap: currentUiState.adjustmentEnabledMap,
      minutesMap: currentUiState.adjustmentMinutesMap,
      calculationMethodId: calculationMethodId,
      juristicMethod: juristicMethod,
    );
  }

  /// App resume হলে check করে notifications ঠিক আছে কিনা
  /// যদি কম থাকে, 7 দিনের জন্য আবার schedule করে
  Future<void> ensureNotificationsScheduled() async {
    await catchFutureOrVoid(() async {
      final bool needsReschedule =
          await _prayerNotificationService.shouldReschedule();

      if (!needsReschedule) return;

      final location = currentUiState.location;
      if (location == null) return;

      // Cache থেকে calculation settings নিয়ে আসা
      final String calculationMethodId =
          _cacheService.getData<String>(key: CacheKeys.calculationMethodId) ??
              'karachi';
      final String juristicMethod =
          _cacheService.getData<String>(key: CacheKeys.juristicMethod) ??
              'Shafi';

      await _prayerNotificationService.scheduleForMultipleDays(
        latitude: location.latitude,
        longitude: location.longitude,
        timezone: location.timezone,
        enabledMap: currentUiState.adjustmentEnabledMap,
        minutesMap: currentUiState.adjustmentMinutesMap,
        calculationMethodId: calculationMethodId,
        juristicMethod: juristicMethod,
      );

      log('Notifications rescheduled for 7 days on app resume');
    });
  }

  /// FCM foreground/background listener সেটআপ
  Future<void> _setupFCMListeners() async {
    await catchFutureOrVoid(() async {
      await _notificationService.setupFCMListeners(
        onMessageReceived: (data, title, body) async {
          // FCM push notification received — locally store করো
          if (title == null && body == null) return;
          final notification = NotificationModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title ?? '',
            description: body ?? '',
            timestamp: DateTime.now(),
            type: data['type'] as String? ?? 'push',
            isRead: false,
            imageUrl: data['imageUrl'] as String?,
            actionUrl: data['actionUrl'] as String?,
          );
          await _getNotificationsUseCase.addNotification(notification);
        },
        onNotificationTapped: (data, title, body) async {
          // FCM notification tap — আগে store করো, তারপর navigate
          await _storeAndNavigateFromNotification(data, title, body);
        },
      );
    });
  }

  /// App terminated অবস্থায় notification tap থেকে open হলে চেক
  Future<void> _checkInitialNotification() async {
    await catchFutureOrVoid(() async {
      final data = await _notificationService.getInitialMessage();
      if (data != null) {
        // App terminated ছিল, user notification tap করে open করেছে
        // _title ও _body extract করো — getInitialMessage() এ inject করা হয়েছে
        final String? title = data.remove('_title') as String?;
        final String? body = data.remove('_body') as String?;

        // Navigation stack ready হওয়ার জন্য delay
        Future.delayed(const Duration(seconds: 2), () {
          _storeAndNavigateFromNotification(data, title, body);
        });
      }
    });
  }

  /// FCM notification tap (background/terminated) — store করো এবং navigate করো
  Future<void> _storeAndNavigateFromNotification(
    Map<String, dynamic> data,
    String? title,
    String? body,
  ) async {
    await catchFutureOrVoid(() async {
      // Notification locally store করো — যাতে NotificationPage-এ দেখা যায়
      if (title != null || body != null) {
        final notification = NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title ?? '',
          description: body ?? '',
          timestamp: DateTime.now(),
          type: data['type'] as String? ?? 'push',
          isRead: false,
          imageUrl: data['imageUrl'] as String?,
          actionUrl: data['actionUrl'] as String?,
        );
        await _getNotificationsUseCase.addNotification(notification);
      }

      // NotificationPage-এ navigate
      await _notificationService.onOpenedFromNotification();
    });
  }

  void _updateAllStates() {
    _updateActiveWaqt();
    _updateRemainingTime();
    _updateFastingState();
  }

  void _startTimer() {
    _timeSubscription = _timeService.currentTimeStream.listen((now) {
      uiState.value = currentUiState.copyWith(
        nowTime: now,
        hijriDate: _getHijriDate(now),
      );
      _updateAllStates();
    });
  }

  String _getHijriDate(DateTime date) {
    final maghribTime = currentUiState.prayerTime?.startMaghrib;
    final hijri = maghribTime != null
        ? _hijriDateService.fromDateConsideringMaghrib(date, maghribTime)
        : _hijriDateService.fromDate(date);
    return '${hijri.format(hijri.hYear, hijri.hMonth, hijri.hDay, 'dd MMMM yyyy')} H';
  }

  List<WaqtViewModel> get waqtList {
    final List<WaqtViewModel> list = [];
    if (currentUiState.prayerTime == null) return list;

    for (final type in WaqtType.values) {
      list.add(
        WaqtViewModel(
          type: type,
          time: _waqtCalculationService.getWaqtTime(
            type,
            currentUiState.prayerTime!,
          ),
          isActive: type == currentUiState.activeWaqtType,
        ),
      );
    }

    return list;
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '--:--';

    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String getFormattedRemainingTime() =>
      _formatDuration(currentUiState.remainingDuration);

  String getRemainingTimeText() {
    if (currentUiState.activeWaqtType == null) return '';
    return currentUiState.activeWaqtType?.displayName ?? '';
  }

  String getFormattedFastingRemainingTime() =>
      _formatDuration(currentUiState.fastingRemainingDuration);

  String getFastingTitle() => currentUiState.fastingState.displayName;

  double getFastingProgress() => currentUiState.fastingProgress;

  String getSehriTime() =>
      getFormattedTimeForFasting(currentUiState.prayerTime?.startFajr);

  String getIftarTime() =>
      getFormattedTimeForFasting(currentUiState.prayerTime?.startMaghrib);

  String getCurrentTime() => getFormattedTime(_getCurrentDateTime());

  DateTime _getCurrentDateTime() =>
      currentUiState.nowTime ?? _timeService.getCurrentTime();

  /// প্রার্থনা সময় আপডেট করে, অ্যাক্টিভ প্রার্থনা কোনটি সেটি নির্ধারণ করতে
  Future<void> _updateActiveWaqt() async {
    if (currentUiState.prayerTime == null) return;

    await parseDataFromEitherWithUserMessage(
      task: () => _getActiveWaqtUseCase.execute(
        prayerTime: currentUiState.prayerTime!,
        currentTime: _getCurrentDateTime(),
      ),
      onDataLoaded: (result) {
        if (result.activeWaqt != currentUiState.activeWaqtType ||
            result.nextWaqt != currentUiState.nextWaqtType) {
          uiState.value = currentUiState.copyWith(
            activeWaqtType: result.activeWaqt,
            nextWaqtType: result.nextWaqt,
          );

          // অ্যাক্টিভ প্রার্থনা পরিবর্তন হয়েছে, সুতরাং forceScroll=true দিয়ে স্ক্রোল করা
          scrollToActiveWaqt(null, true);
        }
      },
    );
  }

  Future<void> _updateRemainingTime() async {
    if (currentUiState.activeWaqtType == null ||
        currentUiState.nextWaqtType == null) {
      _resetRemainingTime();
      return;
    }

    final DateTime? currentWaqtTime = _waqtCalculationService.getWaqtTime(
      currentUiState.activeWaqtType!,
      currentUiState.prayerTime!,
    );
    final DateTime? nextWaqtTime = _waqtCalculationService.getWaqtTime(
      currentUiState.nextWaqtType!,
      currentUiState.prayerTime!,
    );

    if (currentWaqtTime == null || nextWaqtTime == null) {
      _resetRemainingTime();
      return;
    }

    await parseDataFromEitherWithUserMessage(
      task: () => _getRemainingTimeUseCase.execute(
        currentWaqtTime: currentWaqtTime,
        nextWaqtTime: nextWaqtTime,
        currentTime: _getCurrentDateTime(),
      ),
      onDataLoaded: (result) {
        uiState.value = currentUiState.copyWith(
          remainingDuration: result.remainingDuration,
          totalDuration: result.totalDuration,
          remainingTimeProgress: result.progress,
        );
      },
    );
  }

  void _resetRemainingTime() {
    uiState.value = currentUiState.copyWith(
      remainingDuration: const Duration(),
      totalDuration: const Duration(),
      remainingTimeProgress: 0,
    );
  }

  void _updateFastingState() {
    if (currentUiState.prayerTime == null || currentUiState.nowTime == null) {
      uiState.value = currentUiState.copyWith(
        fastingRemainingDuration: const Duration(),
        fastingTotalDuration: const Duration(),
        fastingProgress: 0,
        fastingState: FastingState.none,
      );
      return;
    }

    final DateTime now = currentUiState.nowTime!;
    final DateTime sehri = currentUiState.prayerTime!.startFajr;
    final DateTime iftar = currentUiState.prayerTime!.startMaghrib;

    Duration remainingDuration;
    Duration totalDuration;
    FastingState state;

    if (now.isAfter(sehri) && now.isBefore(iftar)) {
      remainingDuration = iftar.difference(now);
      totalDuration = iftar.difference(sehri);
      state = FastingState.fasting;
    } else if (now.isAfter(iftar)) {
      final DateTime nextSehri = sehri.add(const Duration(days: 1));
      remainingDuration = nextSehri.difference(now);
      totalDuration = nextSehri.difference(iftar);
      state = FastingState.sehri;
    } else {
      remainingDuration = sehri.difference(now);
      totalDuration = sehri.difference(
        sehri.subtract(const Duration(hours: 8)),
      );
      state = FastingState.sehri;
    }

    final double progress = _calculateProgress(
      totalDuration,
      remainingDuration,
    );

    uiState.value = currentUiState.copyWith(
      fastingRemainingDuration: remainingDuration,
      fastingTotalDuration: totalDuration,
      fastingProgress: progress,
      fastingState: state,
    );
  }

  double _calculateProgress(Duration total, Duration remaining) {
    if (total.inSeconds == 0) return 0;
    final elapsed = total.inSeconds - remaining.inSeconds;
    return (elapsed / total.inSeconds).clamp(0.0, 1.0);
  }

  void initializeTracker() {
    if (currentUiState.prayerTime != null) {
      prayerTrackerPresenter.initializePrayerTracker(
        prayerTimeEntity: currentUiState.prayerTime!,
      );
    }
  }

  @override
  Future<void> addUserMessage(String message) async {
    uiState.value = currentUiState.copyWith(userMessage: message);
    showMessage(message: currentUiState.userMessage);
  }

  @override
  Future<void> toggleLoading({required bool loading}) async {
    uiState.value = currentUiState.copyWith(isLoading: loading);
  }

  /// Scroll to the active waqt in the center of the screen
  void scrollToActiveWaqt([BuildContext? context, bool forceScroll = false]) {
    try {
      // If the user is scrolling and forceScroll is not true, do not scroll
      if (_userScrolled && !forceScroll) return;

      if (waqtList.isEmpty || !prayerTimesScrollController.hasClients) return;

      // Find the active waqt
      int activeIndex = waqtList.indexWhere((waqt) => waqt.isActive);
      if (activeIndex == -1) return;

      // Get the actual screen width
      double screenWidth =
          prayerTimesScrollController.position.viewportDimension;

      // If BuildContext is provided, use the correct screen width
      if (context != null) {
        screenWidth = MediaQuery.of(context).size.width;
      }

      // Create the position of each item
      double offset = 0;
      double leftPadding = twentyPx; // ListView এর padding
      double rightMargin = twelvePx; // আইটেমের right margin

      // Calculate the position and width of each item
      List<double> itemPositions = [];
      List<double> itemWidths = [];

      // Add padding at the beginning
      offset += leftPadding;

      // Calculate the position of each item
      for (int i = 0; i < waqtList.length; i++) {
        if (waqtList[i].type == WaqtType.duha) continue; // duha স্কিপ করা

        bool isSpecial = waqtList[i].type == WaqtType.sunrise;
        // Instead of calculating directly, use percentWidth
        double widthPercentage = isSpecial ? 25 : 43;
        double width = (screenWidth * widthPercentage) / 100;

        itemPositions.add(offset);
        itemWidths.add(width);

        offset += width + rightMargin;
      }

      // Check if the active item is within the bounds
      int visibleActiveIndex = activeIndex;
      // duha আইটেম সরিয়ে দেওয়ার কারণে কিছু ইনডেক্স বদলাতে পারে
      for (int i = 0; i < activeIndex; i++) {
        if (waqtList[i].type == WaqtType.duha) {
          visibleActiveIndex--;
        }
      }

      // Check if the active item is within the bounds
      if (visibleActiveIndex >= itemPositions.length) return;

      double activePosition = itemPositions[visibleActiveIndex];
      double activeWidth = itemWidths[visibleActiveIndex];

      // Calculate the scroll position to center the active item
      double scrollTo = activePosition - (screenWidth / 2) + (activeWidth / 2);

      // Check if the scroll is within the bounds
      scrollTo = scrollTo.clamp(
        0.0,
        prayerTimesScrollController.position.maxScrollExtent,
      );

      // Smooth scroll to the active waqt
      prayerTimesScrollController.animateTo(
        scrollTo,
        duration: Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
      );
    } catch (e) {
      log('Error in scrollToActiveWaqt: $e');
    }
  }

  // When user goes to other page and comes back to this page, scroll to the active waqt
  void scrollToActiveWaqtWithDelay([BuildContext? context]) {
    // If the user is scrolling, set the userScrolled to true
    _userScrolled = false;

    // After the UI is rendered, scroll to the active waqt
    Future.delayed(Duration(milliseconds: 500), () {
      if (context != null && !context.mounted) return;
      scrollToActiveWaqt(context);
    });
  }

  // If the user is scrolling, set the userScrolled to true
  void _onUserScroll() {
    // If the user is scrolling, set the userScrolled to true
    if (prayerTimesScrollController.position.isScrollingNotifier.value) {
      _userScrolled = true;
    }
  }

  // When user goes to other page and comes back to this page, reset the user scroll
  void resetUserScroll() {
    _userScrolled = false;
  }
}
