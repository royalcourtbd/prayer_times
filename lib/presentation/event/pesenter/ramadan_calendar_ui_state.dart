import 'package:prayer_times/core/base/base_ui_state.dart';
import 'package:prayer_times/domain/entities/location_entity.dart';
import 'package:prayer_times/domain/entities/ramadan_day_entity.dart';

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
