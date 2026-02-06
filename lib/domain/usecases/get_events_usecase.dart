import 'package:fpdart/fpdart.dart';
import 'package:prayer_times/core/base/base_use_case.dart';
import 'package:prayer_times/domain/entities/event_entity.dart';
import 'package:prayer_times/domain/repositories/event_repository.dart';
import 'package:prayer_times/domain/service/error_message_handler.dart';

class GetEventsUseCase extends BaseUseCase<List<EventEntity>> {
  final EventRepository _repository;

  GetEventsUseCase(
    this._repository,
    ErrorMessageHandler errorMessageHandler,
  ) : super(errorMessageHandler);

  Future<Either<String, List<EventEntity>>> execute({
    bool forceRefresh = false,
  }) async {
    return mapResultToEither(() async {
      final Either<String, List<EventEntity>> result =
          await _repository.getEvents(forceRefresh: forceRefresh);
      return result.fold((l) => throw Exception(l), (r) => r);
    });
  }
}
