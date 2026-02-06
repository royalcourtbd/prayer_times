import 'package:fpdart/fpdart.dart';
import 'package:prayer_times/domain/entities/event_entity.dart';

abstract class EventRepository {
  Future<Either<String, List<EventEntity>>> getEvents({
    bool forceRefresh = false,
  });
}
