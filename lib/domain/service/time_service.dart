// lib/domain/service/time_service.dart

import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:prayer_times/domain/service/timezone_service.dart';

class TimeService {
  final TimezoneService _timezoneService;

  final BehaviorSubject<DateTime> _currentTime = BehaviorSubject<DateTime>();

  String? _currentTimezone;
  Timer? _timer;

  Stream<DateTime> get currentTimeStream => _currentTime.stream;
  DateTime get currentTime => _timezoneService.now(_currentTimezone);

  /// Get the currently configured timezone.
  String? get currentTimezone => _currentTimezone;

  TimeService(this._timezoneService) {
    _initializeTime();
  }

  void _initializeTime() {
    _emitCurrentTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _emitCurrentTime();
    });
  }

  void _emitCurrentTime() {
    _currentTime.add(_timezoneService.now(_currentTimezone));
  }

  /// Update the timezone for time calculations.
  /// Pass null to use device local timezone.
  void setTimezone(String? timezoneId) {
    _currentTimezone = timezoneId;
    _emitCurrentTime(); // Immediately emit new time
  }

  void dispose() {
    _timer?.cancel();
    _currentTime.close();
  }

  DateTime getCurrentDate() {
    final DateTime now = currentTime;
    return DateTime(now.year, now.month, now.day);
  }

  DateTime getCurrentTime() {
    return currentTime;
  }

  DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  bool isToday(DateTime date) {
    final DateTime now = currentTime;
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
