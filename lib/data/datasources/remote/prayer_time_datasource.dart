// lib/data/datasources/prayer_time_datasource.dart

import 'package:adhan_dart/adhan_dart.dart';
import 'package:fpdart/fpdart.dart';
import 'package:prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:prayer_times/domain/repositories/juristic_method_repository.dart';

abstract class PrayerTimeDataSource {
  Future<PrayerTimeEntity> getPrayerTimes({
    required double latitude,
    required double longitude,
    DateTime? date,
  });
}

class PrayerTimeDataSourceImpl implements PrayerTimeDataSource {
  final JuristicMethodRepository _juristicMethodRepository;

  PrayerTimeDataSourceImpl(this._juristicMethodRepository);

  @override
  Future<PrayerTimeEntity> getPrayerTimes({
    required double latitude,
    required double longitude,
    DateTime? date,
  }) async {
    final Either<String, String> methodResult =
        await _juristicMethodRepository.getJuristicMethod();

    return methodResult.fold((error) => throw Exception(error), (method) async {
      final Coordinates coordinates = Coordinates(latitude, longitude);
      final CalculationParameters params = CalculationMethodParameters.karachi()
        ..madhab = method == 'Hanafi' ? Madhab.hanafi : Madhab.shafi;

      // Use the provided date or fallback to current date
      final DateTime prayerDate = date ?? DateTime.now();
      final PrayerTimes prayerTimes = PrayerTimes(
        coordinates: coordinates,
        date: prayerDate,
        calculationParameters: params,
        precision: true,
      );

      // adhan_dart returns UTC times, convert to local timezone
      return PrayerTimeEntity(
        startFajr: prayerTimes.fajr.toLocal(),
        fajrEnd: prayerTimes.sunrise.toLocal(),
        sunrise: prayerTimes.sunrise.toLocal(),
        duhaStart: prayerTimes.sunrise.toLocal().add(const Duration(minutes: 15)),
        duhaEnd: prayerTimes.dhuhr.toLocal(),
        startDhuhr: prayerTimes.dhuhr.toLocal(),
        dhuhrEnd: prayerTimes.asr.toLocal(),
        startAsr: prayerTimes.asr.toLocal(),
        asrEnd: prayerTimes.maghrib.toLocal(),
        startMaghrib: prayerTimes.maghrib.toLocal(),
        maghribEnd: prayerTimes.isha.toLocal(),
        startIsha: prayerTimes.isha.toLocal(),
        ishaEnd: prayerTimes.fajr.toLocal().add(const Duration(days: 1)),
      );
    });
  }
}
