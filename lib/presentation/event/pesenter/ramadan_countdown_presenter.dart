import 'dart:async';

import 'package:prayer_times/core/base/base_presenter.dart';
import 'package:prayer_times/core/utility/utility.dart';
import 'package:prayer_times/data/services/hijri_date_service.dart';
import 'package:prayer_times/presentation/event/pesenter/ramadan_countdown_ui_state.dart';

class RamadanCountdownPresenter extends BasePresenter<RamadanCountdownUiState> {
  final HijriDateService _hijriDateService;
  Timer? _timer;

  RamadanCountdownPresenter(this._hijriDateService);

  final Obs<RamadanCountdownUiState> uiState = Obs(
    RamadanCountdownUiState.empty(),
  );

  RamadanCountdownUiState get currentUiState => uiState.value;

  @override
  void onInit() {
    super.onInit();
    _calculateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateCountdown();
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    _timer = null;
    super.onClose();
  }

  void _calculateCountdown() {
    final now = DateTime.now();
    final hijri = _hijriDateService.now();

    // Check if currently Ramadan (Hijri month 9)
    final isRamadan = hijri.hMonth == 9;

    // Get Ramadan dates
    final ramadanStart = _getRamadanStartDate(hijri);
    final ramadanEnd = _getRamadanEndDate(hijri);

    // Calculate visibility (show 60 days before, hide 3 days after)
    final daysUntilStart = ramadanStart.difference(now).inDays;
    final daysSinceEnd = now.difference(ramadanEnd).inDays;
    final shouldShow = daysUntilStart <= 60 && daysSinceEnd <= 3;

    // Calculate remaining time
    Duration remainingTime;
    if (isRamadan) {
      // During Ramadan: countdown to end
      remainingTime = ramadanEnd.difference(now);
    } else if (now.isBefore(ramadanStart)) {
      // Before Ramadan: countdown to start
      remainingTime = ramadanStart.difference(now);
    } else {
      // After Ramadan: countdown to next year's Ramadan
      final nextRamadanStart = _getNextRamadanStartDate(hijri);
      remainingTime = nextRamadanStart.difference(now);
    }

    if (remainingTime.isNegative) {
      remainingTime = Duration.zero;
    }

    // Get current Ramadan day if applicable
    final currentDay = isRamadan ? hijri.hDay : null;

    uiState.value = currentUiState.copyWith(
      days: remainingTime.inDays,
      hours: remainingTime.inHours % 24,
      minutes: remainingTime.inMinutes % 60,
      seconds: remainingTime.inSeconds % 60,
      isRamadan: isRamadan,
      shouldShow: shouldShow,
      currentRamadanDay: currentDay,
    );
  }

  DateTime _getRamadanStartDate(dynamic hijri) {
    int targetYear = hijri.hYear;

    // If we're past Ramadan this year, target next year
    if (hijri.hMonth > 9) {
      targetYear++;
    }

    return _hijriDateService.hijriToGregorian(targetYear, 9, 1);
  }

  DateTime _getRamadanEndDate(dynamic hijri) {
    int targetYear = hijri.hYear;

    // If we're past Ramadan this year, target next year
    if (hijri.hMonth > 9) {
      targetYear++;
    }

    // Ramadan is typically 29 or 30 days, use start of Shawwal minus 1
    final shawwalStart = _hijriDateService.hijriToGregorian(targetYear, 10, 1);
    return shawwalStart.subtract(const Duration(days: 1));
  }

  DateTime _getNextRamadanStartDate(dynamic hijri) {
    return _hijriDateService.hijriToGregorian(hijri.hYear + 1, 9, 1);
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
}
