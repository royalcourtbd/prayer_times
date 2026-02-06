import 'package:hijri/hijri_calendar.dart';
import 'package:prayer_times/data/models/event_model.dart';

class IslamicEventService {
  static const String _islamicColor = '#FF4CAF50';

  List<EventModel> generateIslamicEvents(int year) {
    final List<EventModel> events = [];

    // Shab e-Barat: 15 Sha'ban (month 8, day 15)
    final shabEBarat = _findGregorianDate(year, 8, 15);
    if (shabEBarat != null) {
      events.add(EventModel(
        title: 'Shab e-Barat',
        description: 'Islamic holy night of forgiveness',
        holidayType: 'Holiday in Bangladesh',
        date: _formatDate(shabEBarat),
        colorHex: _islamicColor,
      ));
    }

    // Eid ul-Fitr: 1 Shawwal (month 10, day 1)
    final eidUlFitr = _findGregorianDate(year, 10, 1);
    if (eidUlFitr != null) {
      // Laylat al-Qadr: 27 Ramadan (month 9, day 27)
      final laylatAlQadr = _findGregorianDate(year, 9, 27);
      if (laylatAlQadr != null) {
        events.add(EventModel(
          title: 'Laylat al-Qadr',
          description: 'Islamic night of power and destiny',
          holidayType: 'Holiday in Bangladesh',
          date: _formatDate(laylatAlQadr),
          colorHex: _islamicColor,
        ));
      }

      // Jumatul Bidah: Last Friday of Ramadan
      DateTime jumatulBidah = eidUlFitr.subtract(const Duration(days: 1));
      while (jumatulBidah.weekday != DateTime.friday) {
        jumatulBidah = jumatulBidah.subtract(const Duration(days: 1));
      }
      events.add(EventModel(
        title: 'Jumatul Bidah',
        description: 'The last Friday of Ramadan',
        holidayType: 'Holiday in Bangladesh',
        date: _formatDate(jumatulBidah),
        colorHex: _islamicColor,
      ));

      // 2 days before Eid ul-Fitr
      for (int i = 2; i >= 1; i--) {
        events.add(EventModel(
          title: 'Eid ul-Fitr Holiday',
          description: 'Holiday before Eid ul-Fitr',
          holidayType: 'Islamic Festival in Bangladesh',
          date: _formatDate(eidUlFitr.subtract(Duration(days: i))),
          colorHex: _islamicColor,
        ));
      }

      // Eid ul-Fitr main day
      events.add(EventModel(
        title: 'Eid ul-Fitr',
        description: 'Islamic festival marking the end of Ramadan',
        holidayType: 'Islamic Festival in Bangladesh',
        date: _formatDate(eidUlFitr),
        colorHex: _islamicColor,
      ));

      // 2 days after Eid ul-Fitr
      final List<String> fitrAfterDescriptions = [
        'Second day of Eid ul-Fitr celebrations',
        'Third day of Eid ul-Fitr celebrations',
      ];
      for (int i = 1; i <= 2; i++) {
        events.add(EventModel(
          title: 'Eid ul-Fitr Holiday',
          description: fitrAfterDescriptions[i - 1],
          holidayType: 'Islamic Festival in Bangladesh',
          date: _formatDate(eidUlFitr.add(Duration(days: i))),
          colorHex: _islamicColor,
        ));
      }
    }

    // Eid ul-Adha: 10 Dhul Hijjah (month 12, day 10)
    final eidUlAdha = _findGregorianDate(year, 12, 10);
    if (eidUlAdha != null) {
      // 2 days before
      for (int i = 2; i >= 1; i--) {
        events.add(EventModel(
          title: 'Eid ul-Adha Holiday',
          description: 'Holiday before Eid ul-Adha',
          holidayType: 'Islamic Festival in Bangladesh',
          date: _formatDate(eidUlAdha.subtract(Duration(days: i))),
          colorHex: _islamicColor,
        ));
      }

      // Main day
      events.add(EventModel(
        title: 'Eid ul-Adha',
        description: 'Islamic festival of sacrifice',
        holidayType: 'Islamic Festival in Bangladesh',
        date: _formatDate(eidUlAdha),
        colorHex: _islamicColor,
      ));

      // 3 days after
      final List<String> adhaAfterDescriptions = [
        'Second day of Eid ul-Adha celebrations',
        'Third day of Eid ul-Adha celebrations',
        'Fourth day of Eid ul-Adha celebrations',
      ];
      for (int i = 1; i <= 3; i++) {
        events.add(EventModel(
          title: 'Eid ul-Adha Holiday',
          description: adhaAfterDescriptions[i - 1],
          holidayType: 'Islamic Festival in Bangladesh',
          date: _formatDate(eidUlAdha.add(Duration(days: i))),
          colorHex: _islamicColor,
        ));
      }
    }

    // Ashura: 10 Muharram (month 1, day 10)
    final ashura = _findGregorianDate(year, 1, 10);
    if (ashura != null) {
      events.add(EventModel(
        title: 'Ashura',
        description: 'Islamic day of remembrance',
        holidayType: 'Holiday in Bangladesh',
        date: _formatDate(ashura),
        colorHex: _islamicColor,
      ));
    }

    // Eid-e-Milad un-Nabi: 12 Rabi ul-Awal (month 3, day 12)
    final eideMilad = _findGregorianDate(year, 3, 12);
    if (eideMilad != null) {
      events.add(EventModel(
        title: 'Eid-e-Milad un-Nabi',
        description: 'Celebration of Prophet Muhammad\'s birthday',
        holidayType: 'Islamic Festival in Bangladesh',
        date: _formatDate(eideMilad),
        colorHex: _islamicColor,
      ));
    }

    return events;
  }

  /// Find the Gregorian date for a given Hijri month/day within a Gregorian year.
  /// Same pattern as RamadanCalendarPresenter._calculateRamadanStartDate
  DateTime? _findGregorianDate(int gregorianYear, int hijriMonth, int hijriDay) {
    DateTime checkDate = DateTime(gregorianYear, 1, 1);
    final DateTime endDate = DateTime(gregorianYear, 12, 31);

    while (checkDate.isBefore(endDate) || checkDate.isAtSameMomentAs(endDate)) {
      final HijriCalendar hijri = HijriCalendar.fromDate(checkDate);
      if (hijri.hMonth == hijriMonth && hijri.hDay == hijriDay) {
        return checkDate;
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
