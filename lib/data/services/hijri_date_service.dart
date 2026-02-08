import 'package:hijri/hijri_calendar.dart';
import 'package:prayer_times/data/services/local_cache_service.dart';

class HijriDateService {
  final LocalCacheService _cacheService;

  HijriDateService(this._cacheService);

  int get dayAdjustment =>
      _cacheService.getData<int>(key: CacheKeys.hijriDayAdjustment) ?? 0;

  Future<void> saveDayAdjustment(int value) async {
    await _cacheService.saveData(
        key: CacheKeys.hijriDayAdjustment, value: value);
  }

  HijriCalendar fromDate(DateTime date) {
    return HijriCalendar.fromDate(date.add(Duration(days: dayAdjustment)));
  }

  HijriCalendar now() {
    return fromDate(DateTime.now());
  }

  DateTime hijriToGregorian(int year, int month, int day) {
    final hijri = HijriCalendar();
    return hijri
        .hijriToGregorian(year, month, day)
        .subtract(Duration(days: dayAdjustment));
  }
}
