import 'package:prayer_times/core/base/base_presenter.dart';
import 'package:prayer_times/core/utility/utility.dart';
import 'package:prayer_times/data/services/hijri_date_service.dart';
import 'package:prayer_times/domain/entities/location_entity.dart';
import 'package:prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:prayer_times/domain/entities/ramadan_day_entity.dart';
import 'package:prayer_times/domain/usecases/get_location_usecase.dart';
import 'package:prayer_times/domain/usecases/get_prayer_times_usecase.dart';
import 'package:prayer_times/presentation/event/pesenter/ramadan_calendar_ui_state.dart';
import 'package:intl/intl.dart';

class RamadanCalendarPresenter extends BasePresenter<RamadanCalendarUiState> {
  final GetPrayerTimesUseCase _getPrayerTimesUseCase;
  final GetLocationUseCase _getLocationUseCase;
  final HijriDateService _hijriDateService;

  RamadanCalendarPresenter(
    this._getPrayerTimesUseCase,
    this._getLocationUseCase,
    this._hijriDateService,
  );

  final Obs<RamadanCalendarUiState> uiState = Obs(
    RamadanCalendarUiState.empty(),
  );
  RamadanCalendarUiState get currentUiState => uiState.value;

  /// Dynamically calculate Ramadan start date for a given year
  /// Ramadan is the 9th month in the Hijri calendar
  DateTime _calculateRamadanStartDate(int year) {
    DateTime checkDate = DateTime(year, 1, 1);
    final DateTime endDate = DateTime(year, 12, 31);

    while (checkDate.isBefore(endDate)) {
      final hijri = _hijriDateService.fromDate(checkDate);
      // Month 9 = Ramadan, Day 1 = First day of Ramadan
      if (hijri.hMonth == 9 && hijri.hDay == 1) {
        return checkDate;
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }

    // Fallback (should not reach here)
    return DateTime(year, 3, 1);
  }

  /// Get Ramadan start date dynamically based on current year
  DateTime get _ramadanStartDate =>
      _calculateRamadanStartDate(DateTime.now().year);

  /// Get current year
  int get currentYear => DateTime.now().year;

  /// Get Hijri year for current Ramadan
  int get hijriYear {
    final DateTime ramadanStart = _ramadanStartDate;
    return _hijriDateService.fromDate(ramadanStart).hYear;
  }

  // Calculate current Ramadan day based on today's date
  int getCurrentRamadanDay() {
    final DateTime now = DateTime.now();

    // If current date is before Ramadan
    if (now.isBefore(_ramadanStartDate)) {
      return -1; // Ramadan hasn't started
    }

    // If current date is after Ramadan
    final DateTime ramadanEndDate = _ramadanStartDate.add(Duration(days: 29));
    if (now.isAfter(ramadanEndDate)) {
      return 31; // Ramadan has ended
    }

    // Calculate which day of Ramadan
    return now.difference(_ramadanStartDate).inDays + 1;
  }

  @override
  void onInit() {
    super.onInit();
    loadRamadanCalendar();
  }

  @override
  Future<void> toggleLoading({required bool loading}) async {
    uiState.value = currentUiState.copyWith(isLoading: loading);
  }

  @override
  Future<void> addUserMessage(String message) async {
    uiState.value = currentUiState.copyWith(userMessage: message);
    showMessage(message: currentUiState.userMessage);
  }

  Future<void> loadRamadanCalendar() async {
    await executeTaskWithLoading(() async {
      await parseDataFromEitherWithUserMessage<LocationEntity>(
        task: () => _getLocationUseCase.execute(forceRemote: false),
        onDataLoaded: (LocationEntity location) async {
          final calendarData = await _generateRamadanCalendarData(location);
          uiState.value = currentUiState.copyWith(
            ramadanCalendar: calendarData,
            location: location,
            currentRamadanDay: getCurrentRamadanDay(),
            year: currentYear,
            hijriYear: hijriYear,
          );
        },
      );
    });
  }

  /// Generate data for 30 days of Ramadan
  Future<List<RamadanDayEntity>> _generateRamadanCalendarData(
    LocationEntity location,
  ) async {
    List<RamadanDayEntity> calendarData = [];

    DateTime startDate = _ramadanStartDate;

    // Generate 30 days of Ramadan calendar
    for (int i = 0; i < 30; i++) {
      final currentDate = startDate.add(Duration(days: i));
      final prayerTime = await _getPrayerTime(currentDate, location);

      if (prayerTime == null) {
        continue;
      }

      // Calculate Hijri date
      final hijriDate = _hijriDateService.fromDate(currentDate);

      // Ramadan day number
      final ramadanDay = (i + 1).toString();

      // Sehri time (start of Fajr)
      final sehriTime = getFormattedTime(prayerTime.startFajr);

      // Iftar time (start of Maghrib)
      final iftarTime = getFormattedTime(prayerTime.startMaghrib);

      // Format date in English
      final formattedDate = _formatDateInEnglish(currentDate);

      // Weekday in English
      final weekdayInEnglish = _getWeekdayInEnglish(currentDate.weekday);

      // Hijri date in English
      final hijriDateInEnglish = '${hijriDate.hDay} Ramadan';

      calendarData.add(
        RamadanDayEntity(
          day: ramadanDay,
          date: formattedDate,
          weekday: weekdayInEnglish,
          hijriDate: hijriDateInEnglish,
          sehriTime: sehriTime,
          iftarTime: iftarTime,
        ),
      );
    }

    return calendarData;
  }

  /// Get prayer time for specific date and location
  Future<PrayerTimeEntity?> _getPrayerTime(
    DateTime date,
    LocationEntity location,
  ) async {
    try {
      final result = await _getPrayerTimesUseCase.execute(
        latitude: location.latitude,
        longitude: location.longitude,
        date: date,
      );

      return result.fold((error) => null, (prayerTime) => prayerTime);
    } catch (e) {
      return null;
    }
  }

  /// Format date in English
  String _formatDateInEnglish(DateTime date) {
    // Example: 1 March
    final DateFormat formatter = DateFormat('d MMM');
    return formatter.format(date);
  }

  /// Get English weekday name
  String _getWeekdayInEnglish(int weekday) {
    const Map<int, String> englishWeekdays = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };

    return englishWeekdays[weekday] ?? '';
  }
}
