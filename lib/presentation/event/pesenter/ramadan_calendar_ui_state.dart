import 'package:prayer_times/core/base/base_ui_state.dart';
import 'package:prayer_times/domain/entities/location_entity.dart';
import 'package:prayer_times/domain/entities/ramadan_day_entity.dart';
import 'package:timezone/timezone.dart' as tz;

class RamadanCalendarUiState extends BaseUiState {
  final List<RamadanDayEntity> ramadanCalendar;
  final LocationEntity? location;
  final int currentRamadanDay;
  final int year;
  final int hijriYear;

  const RamadanCalendarUiState({
    required this.ramadanCalendar,
    this.location,
    required this.currentRamadanDay,
    required this.year,
    required this.hijriYear,
    required super.isLoading,
    required super.userMessage,
  });

  factory RamadanCalendarUiState.empty() {
    return RamadanCalendarUiState(
      ramadanCalendar: const [],
      location: null,
      currentRamadanDay: -1,
      year: DateTime.now().year,
      hijriYear: 0,
      isLoading: false,
      userMessage: null,
    );
  }

  RamadanCalendarUiState copyWith({
    List<RamadanDayEntity>? ramadanCalendar,
    LocationEntity? location,
    int? currentRamadanDay,
    int? year,
    int? hijriYear,
    bool? isLoading,
    String? userMessage,
  }) {
    return RamadanCalendarUiState(
      ramadanCalendar: ramadanCalendar ?? this.ramadanCalendar,
      location: location ?? this.location,
      currentRamadanDay: currentRamadanDay ?? this.currentRamadanDay,
      year: year ?? this.year,
      hijriYear: hijriYear ?? this.hijriYear,
      isLoading: isLoading ?? this.isLoading,
      userMessage: userMessage ?? this.userMessage,
    );
  }

  /// Get GMT offset string from location timezone (e.g., "GMT +6" or "GMT -5")
  String get gmtOffset {
    final timezoneId = location?.timezone;
    if (timezoneId == null || timezoneId.isEmpty) {
      return 'GMT +6'; // Default fallback for Dhaka
    }

    try {
      final tzLocation = tz.getLocation(timezoneId);
      final now = tz.TZDateTime.now(tzLocation);
      final offsetInHours = now.timeZoneOffset.inMinutes / 60;

      if (offsetInHours >= 0) {
        // Format: +6, +5:30, etc.
        if (offsetInHours == offsetInHours.truncate()) {
          return 'GMT +${offsetInHours.toInt()}';
        } else {
          final hours = offsetInHours.truncate();
          final minutes = ((offsetInHours - hours) * 60).toInt();
          return 'GMT +$hours:${minutes.toString().padLeft(2, '0')}';
        }
      } else {
        final absOffset = offsetInHours.abs();
        if (absOffset == absOffset.truncate()) {
          return 'GMT -${absOffset.toInt()}';
        } else {
          final hours = absOffset.truncate();
          final minutes = ((absOffset - hours) * 60).toInt();
          return 'GMT -$hours:${minutes.toString().padLeft(2, '0')}';
        }
      }
    } catch (e) {
      return 'GMT +6'; // Default fallback
    }
  }

  @override
  List<Object?> get props => [
    isLoading,
    userMessage,
    ramadanCalendar,
    location,
    currentRamadanDay,
    year,
    hijriYear,
  ];
}
