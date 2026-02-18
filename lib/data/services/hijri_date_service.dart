import 'package:hijri/hijri_calendar.dart';
import 'package:prayer_times/data/services/local_cache_service.dart';

class HijriDateService {
  final LocalCacheService _cacheService;

  /// Current day's Maghrib time, updated by HomePresenter when prayer times load.
  DateTime? _currentMaghribTime;

  HijriDateService(this._cacheService);

  int get dayAdjustment =>
      _cacheService.getData<int>(key: CacheKeys.hijriDayAdjustment) ?? 0;

  Future<void> saveDayAdjustment(int value) async {
    await _cacheService.saveData(
      key: CacheKeys.hijriDayAdjustment,
      value: value,
    );
  }

  /// Update the current day's Maghrib time so that [now] can return
  /// the Maghrib-aware Hijri date automatically.
  void updateMaghribTime(DateTime? maghribTime) {
    _currentMaghribTime = maghribTime;
  }

  /// Standard Gregorian-to-Hijri conversion (without Maghrib consideration).
  /// Used for calendar views and event calculations.
  HijriCalendar fromDate(DateTime date) {
    return HijriCalendar.fromDate(date.add(Duration(days: dayAdjustment)));
  }

  /// Convert a DateTime to Hijri considering that the Islamic day begins at
  /// Maghrib. If [currentTime] is at or after [maghribTime], the next day's
  /// Hijri date is returned.
  HijriCalendar fromDateConsideringMaghrib(
    DateTime currentTime,
    DateTime maghribTime,
  ) {
    final bool isAfterMaghrib = !currentTime.isBefore(maghribTime);
    final DateTime dateForConversion =
        isAfterMaghrib ? currentTime.add(const Duration(days: 1)) : currentTime;
    return HijriCalendar.fromDate(
      dateForConversion.add(Duration(days: dayAdjustment)),
    );
  }

  /// Returns the current Hijri date. If Maghrib time has been set via
  /// [updateMaghribTime] and the current time is on the same day, the
  /// Maghrib-aware conversion is used.
  HijriCalendar now() {
    final DateTime currentTime = DateTime.now();
    if (_currentMaghribTime != null &&
        _isSameDay(currentTime, _currentMaghribTime!)) {
      return fromDateConsideringMaghrib(currentTime, _currentMaghribTime!);
    }
    return fromDate(currentTime);
  }

  /// Exposes the stored Maghrib time for other services.
  DateTime? get currentMaghribTime => _currentMaghribTime;

  DateTime hijriToGregorian(int year, int month, int day) {
    final hijri = HijriCalendar();
    return hijri
        .hijriToGregorian(year, month, day)
        .subtract(Duration(days: dayAdjustment));
  }

  /// Adjusts a Gregorian date (returned by [hijriToGregorian]) to the actual
  /// start of the Islamic day — Maghrib of the previous evening.
  ///
  /// [hijriToGregorian] returns midnight (00:00) of the Gregorian day, but the
  /// Islamic day actually begins at Maghrib the evening before. This method
  /// shifts the date back to that Maghrib time using the currently stored
  /// Maghrib time as an approximation.
  DateTime adjustToMaghribStart(DateTime gregorianDate) {
    if (_currentMaghribTime == null) return gregorianDate;
    final previousDay = gregorianDate.subtract(const Duration(days: 1));
    return DateTime(
      previousDay.year,
      previousDay.month,
      previousDay.day,
      _currentMaghribTime!.hour,
      _currentMaghribTime!.minute,
      _currentMaghribTime!.second,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
