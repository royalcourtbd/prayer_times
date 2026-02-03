import 'package:prayer_times/core/base/base_ui_state.dart';

class RamadanCountdownUiState extends BaseUiState {
  const RamadanCountdownUiState({
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.isRamadan,
    required this.shouldShow,
    this.currentRamadanDay,
    required super.isLoading,
    super.userMessage,
  });

  final int days;
  final int hours;
  final int minutes;
  final int seconds;
  final bool isRamadan;
  final bool shouldShow;
  final int? currentRamadanDay;

  factory RamadanCountdownUiState.empty() => const RamadanCountdownUiState(
        days: 0,
        hours: 0,
        minutes: 0,
        seconds: 0,
        isRamadan: false,
        shouldShow: false,
        currentRamadanDay: null,
        isLoading: false,
        userMessage: null,
      );

  RamadanCountdownUiState copyWith({
    int? days,
    int? hours,
    int? minutes,
    int? seconds,
    bool? isRamadan,
    bool? shouldShow,
    int? currentRamadanDay,
    bool? isLoading,
    String? userMessage,
  }) {
    return RamadanCountdownUiState(
      days: days ?? this.days,
      hours: hours ?? this.hours,
      minutes: minutes ?? this.minutes,
      seconds: seconds ?? this.seconds,
      isRamadan: isRamadan ?? this.isRamadan,
      shouldShow: shouldShow ?? this.shouldShow,
      currentRamadanDay: currentRamadanDay ?? this.currentRamadanDay,
      isLoading: isLoading ?? this.isLoading,
      userMessage: userMessage ?? this.userMessage,
    );
  }

  @override
  List<Object?> get props => [
        days,
        hours,
        minutes,
        seconds,
        isRamadan,
        shouldShow,
        currentRamadanDay,
        isLoading,
        userMessage,
      ];
}
