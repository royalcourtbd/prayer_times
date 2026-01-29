// lib/data/datasources/prayer_time_datasource.dart

import 'package:adhan_dart/adhan_dart.dart';
import 'package:fpdart/fpdart.dart';
import 'package:prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:prayer_times/domain/repositories/juristic_method_repository.dart';
import 'package:prayer_times/domain/service/timezone_service.dart';

abstract class PrayerTimeDataSource {
  Future<PrayerTimeEntity> getPrayerTimes({
    required double latitude,
    required double longitude,
    DateTime? date,
    String? timezone,
  });
}

class PrayerTimeDataSourceImpl implements PrayerTimeDataSource {
  final JuristicMethodRepository _juristicMethodRepository;
  final TimezoneService _timezoneService;

  PrayerTimeDataSourceImpl(
    this._juristicMethodRepository,
    this._timezoneService,
  );

  @override
  Future<PrayerTimeEntity> getPrayerTimes({
    required double latitude,
    required double longitude,
    DateTime? date,
    String? timezone,
  }) async {
    final Either<String, String> methodResult =
        await _juristicMethodRepository.getJuristicMethod();

    return methodResult.fold((error) => throw Exception(error), (method) async {
      final Coordinates coordinates = Coordinates(latitude, longitude);
      final CalculationParameters params = CalculationMethodParameters.karachi()
        ..madhab = method == 'Hanafi' ? Madhab.hanafi : Madhab.shafi;

      // Use the provided date or fallback to current date in target timezone
      final DateTime prayerDate = date ?? _timezoneService.now(timezone);
      final PrayerTimes prayerTimes = PrayerTimes(
        coordinates: coordinates,
        date: prayerDate,
        calculationParameters: params,
        precision: true,
      );

      // Helper function to convert UTC to location timezone
      DateTime convertToTimezone(DateTime utcTime) {
        return _timezoneService.convertFromUtc(utcTime, timezone);
      }

      // adhan_dart returns UTC times, convert to location timezone
      return PrayerTimeEntity(
        startFajr: convertToTimezone(prayerTimes.fajr),
        fajrEnd: convertToTimezone(prayerTimes.sunrise),
        sunrise: convertToTimezone(prayerTimes.sunrise),
        duhaStart: convertToTimezone(prayerTimes.sunrise).add(const Duration(minutes: 15)),
        duhaEnd: convertToTimezone(prayerTimes.dhuhr),
        startDhuhr: convertToTimezone(prayerTimes.dhuhr),
        dhuhrEnd: convertToTimezone(prayerTimes.asr),
        startAsr: convertToTimezone(prayerTimes.asr),
        asrEnd: convertToTimezone(prayerTimes.maghrib),
        startMaghrib: convertToTimezone(prayerTimes.maghrib),
        maghribEnd: convertToTimezone(prayerTimes.isha),
        startIsha: convertToTimezone(prayerTimes.isha),
        ishaEnd: convertToTimezone(prayerTimes.fajr).add(const Duration(days: 1)),
      );
    });
  }
}
