import 'package:prayer_times/core/utility/logger_utility.dart';
import 'package:prayer_times/data/models/event_model.dart';
import 'package:prayer_times/data/services/backend_as_a_service.dart';

abstract class EventRemoteDataSource {
  Future<List<EventModel>> getEvents(int year);
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final BackendAsAService _backendAsAService;

  EventRemoteDataSourceImpl(this._backendAsAService);

  @override
  Future<List<EventModel>> getEvents(int year) async {
    try {
      return await _backendAsAService.getEvents(year);
    } catch (error) {
      logError('Error fetching events: $error');
      return <EventModel>[];
    }
  }
}
