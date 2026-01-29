import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class TimezoneService {
  static bool _initialized = false;

  /// Initialize the timezone database. Call this once at app startup.
  static Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    _initialized = true;
  }

  /// Get the timezone location from an IANA timezone identifier.
  /// Returns null if the timezone is invalid or not found.
  tz.Location? getLocation(String? timezoneId) {
    if (timezoneId == null || timezoneId.isEmpty) return null;
    try {
      return tz.getLocation(timezoneId);
    } catch (e) {
      return null;
    }
  }

  /// Convert a UTC DateTime to the specified timezone.
  /// If timezone is null or invalid, returns the original DateTime converted to local.
  DateTime convertFromUtc(DateTime utcTime, String? timezoneId) {
    final location = getLocation(timezoneId);
    if (location == null) {
      return utcTime.toLocal();
    }
    return tz.TZDateTime.from(utcTime, location);
  }

  /// Get the current time in a specific timezone.
  /// If timezone is null or invalid, returns DateTime.now() in local timezone.
  DateTime now(String? timezoneId) {
    final location = getLocation(timezoneId);
    if (location == null) {
      return DateTime.now();
    }
    return tz.TZDateTime.now(location);
  }

  /// Check if a timezone ID is valid.
  bool isValidTimezone(String? timezoneId) {
    return getLocation(timezoneId) != null;
  }
}
