import 'package:adhan_dart/adhan_dart.dart';

class CalculationMethodEntity {
  final String id;
  final String displayName;
  final String? subtitle;
  final CalculationParameters Function() getParams;

  const CalculationMethodEntity({
    required this.id,
    required this.displayName,
    this.subtitle,
    required this.getParams,
  });

  static List<CalculationMethodEntity> get allMethods => [
    CalculationMethodEntity(
      id: 'muslimWorldLeague',
      displayName: 'Muslim World League',
      subtitle: 'Fajr: 18°, Isha: 17°',
      getParams: CalculationMethodParameters.muslimWorldLeague,
    ),
    CalculationMethodEntity(
      id: 'egyptian',
      displayName: 'Egyptian General Authority',
      subtitle: 'Fajr: 19.5°, Isha: 17.5°',
      getParams: CalculationMethodParameters.egyptian,
    ),
    CalculationMethodEntity(
      id: 'karachi',
      displayName: 'University of Islamic Sciences, Karachi',
      subtitle: 'Fajr: 18°, Isha: 18°',
      getParams: CalculationMethodParameters.karachi,
    ),
    CalculationMethodEntity(
      id: 'ummAlQura',
      displayName: 'Umm al-Qura University, Makkah',
      subtitle: 'Fajr: 18.5°, Isha: 90 min after Maghrib',
      getParams: CalculationMethodParameters.ummAlQura,
    ),
    CalculationMethodEntity(
      id: 'dubai',
      displayName: 'Dubai',
      subtitle: 'Fajr: 18.2°, Isha: 18.2°',
      getParams: CalculationMethodParameters.dubai,
    ),
    CalculationMethodEntity(
      id: 'qatar',
      displayName: 'Qatar',
      subtitle: 'Fajr: 18°, Isha: 90 min after Maghrib',
      getParams: CalculationMethodParameters.qatar,
    ),
    CalculationMethodEntity(
      id: 'kuwait',
      displayName: 'Kuwait',
      subtitle: 'Fajr: 18°, Isha: 17.5°',
      getParams: CalculationMethodParameters.kuwait,
    ),
    CalculationMethodEntity(
      id: 'moonsightingCommittee',
      displayName: 'Moonsighting Committee',
      subtitle: 'Fajr: 18°, Isha: 18°',
      getParams: CalculationMethodParameters.moonsightingCommittee,
    ),
    CalculationMethodEntity(
      id: 'singapore',
      displayName: 'Singapore',
      subtitle: 'Fajr: 20°, Isha: 18°',
      getParams: CalculationMethodParameters.singapore,
    ),
    CalculationMethodEntity(
      id: 'turkey',
      displayName: 'Turkey / Turkiye',
      subtitle: 'Fajr: 18°, Isha: 17°',
      getParams: CalculationMethodParameters.turkiye,
    ),
    CalculationMethodEntity(
      id: 'tehran',
      displayName: 'Tehran',
      subtitle: 'Fajr: 17.7°, Isha: 14°',
      getParams: CalculationMethodParameters.tehran,
    ),
    CalculationMethodEntity(
      id: 'northAmerica',
      displayName: 'Islamic Society of North America (ISNA)',
      subtitle: 'Fajr: 15°, Isha: 15°',
      getParams: CalculationMethodParameters.northAmerica,
    ),
    CalculationMethodEntity(
      id: 'morocco',
      displayName: 'Morocco',
      subtitle: 'Fajr: 19°, Isha: 17°',
      getParams: CalculationMethodParameters.morocco,
    ),
    CalculationMethodEntity(
      id: 'other',
      displayName: 'Other / Custom',
      subtitle: 'Default calculation',
      getParams: CalculationMethodParameters.other,
    ),
  ];

  static CalculationMethodEntity getById(String id) {
    return allMethods.firstWhere(
      (m) => m.id == id,
      orElse: () => allMethods.firstWhere((m) => m.id == 'karachi'),
    );
  }
}
