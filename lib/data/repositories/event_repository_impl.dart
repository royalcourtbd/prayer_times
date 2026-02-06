import 'package:fpdart/fpdart.dart';
import 'package:prayer_times/data/datasources/local/event_local_data_source.dart';
import 'package:prayer_times/data/datasources/remote/event_remote_data_source.dart';
import 'package:prayer_times/data/models/event_model.dart';
import 'package:prayer_times/data/services/islamic_event_service.dart';
import 'package:prayer_times/domain/entities/event_entity.dart';
import 'package:prayer_times/domain/repositories/event_repository.dart';

class EventRepositoryImpl implements EventRepository {
  final EventLocalDataSource _localDataSource;
  final EventRemoteDataSource _remoteDataSource;
  final IslamicEventService _islamicEventService;

  EventRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._islamicEventService,
  );

  @override
  Future<Either<String, List<EventEntity>>> getEvents({
    bool forceRefresh = false,
  }) async {
    try {
      final int currentYear = DateTime.now().year;

      // Part A: Fixed-date events (always generated)
      final List<EventModel> fixedDateEvents =
          _generateFixedDateEvents(currentYear);

      // Part B: Islamic events (always calculated from Hijri)
      final List<EventModel> islamicEvents =
          _islamicEventService.generateIslamicEvents(currentYear);

      // Part C: Firebase events (cache-first from Hive)
      final List<EventEntity> firebaseEvents = await _getFirebaseEvents(
        currentYear,
        forceRefresh: forceRefresh,
      );

      final List<EventEntity> allEvents = [
        ...fixedDateEvents,
        ...islamicEvents,
        ...firebaseEvents,
      ];

      return right(allEvents);
    } catch (e) {
      return left('Failed to load events: ${e.toString()}');
    }
  }

  List<EventModel> _generateFixedDateEvents(int year) {
    return [
      EventModel(
        title: 'Shaheed Day',
        description: 'Day commemorating language martyrs',
        holidayType: 'Cultural Festival in Bangladesh',
        date: '$year-02-21',
        colorHex: '#FF2196F3',
      ),
      EventModel(
        title: 'Independence Day',
        description: 'Celebration of national independence',
        holidayType: 'National Holiday in Bangladesh',
        date: '$year-03-26',
        colorHex: '#FF2196F3',
      ),
      EventModel(
        title: 'Bengali New Year',
        description: 'Bengali New Year celebration',
        holidayType: 'Cultural Festival in Bangladesh',
        date: '$year-04-14',
        colorHex: '#FF2196F3',
      ),
      EventModel(
        title: 'May Day',
        description: 'International Workers\' Day',
        holidayType: 'National Holiday in Bangladesh',
        date: '$year-05-01',
        colorHex: '#FF2196F3',
      ),
      EventModel(
        title: 'National Mourning Day',
        description: 'Day commemorating national tragedy',
        holidayType: 'National Holiday in Bangladesh',
        date: '$year-08-15',
        colorHex: '#FF2196F3',
      ),
      EventModel(
        title: 'Victory Day',
        description: 'Celebration of victory in the Liberation War',
        holidayType: 'National Holiday in Bangladesh',
        date: '$year-12-16',
        colorHex: '#FF2196F3',
      ),
      EventModel(
        title: 'Christmas Day',
        description: 'Christian festival celebrating the birth of Jesus',
        holidayType: 'Holiday in Bangladesh',
        date: '$year-12-25',
        colorHex: '#FFF44336',
      ),
    ];
  }

  Future<List<EventEntity>> _getFirebaseEvents(
    int currentYear, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final int? cachedYear = _localDataSource.getCachedYear();
      if (cachedYear != null && cachedYear == currentYear) {
        final List<EventEntity>? cachedEvents =
            await _localDataSource.getCachedEvents();
        if (cachedEvents != null && cachedEvents.isNotEmpty) {
          return cachedEvents;
        }
      }
    }

    final List<EventModel> remoteEvents =
        await _remoteDataSource.getEvents(currentYear);

    if (remoteEvents.isNotEmpty) {
      await _localDataSource.cacheEvents(remoteEvents);
      await _localDataSource.cacheYear(currentYear);
    }

    return remoteEvents;
  }
}
