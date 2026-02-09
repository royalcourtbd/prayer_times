import 'package:fpdart/fpdart.dart';
import 'package:prayer_times/core/base/base_use_case.dart';
import 'package:prayer_times/domain/entities/app_update_entity.dart';
import 'package:prayer_times/domain/repositories/user_data_repository.dart';
import 'package:prayer_times/domain/service/error_message_handler.dart';

class GetAppUpdateInfoUseCase extends BaseUseCase<AppUpdateEntity> {
  final UserDataRepository _repository;

  GetAppUpdateInfoUseCase(
    this._repository,
    ErrorMessageHandler errorMessageHandler,
  ) : super(errorMessageHandler);

  Future<Either<String, AppUpdateEntity>> execute() async {
    return mapResultToEither(() async {
      final Either<String, AppUpdateEntity> result = await _repository
          .getAppUpdateInfo();
      return result.fold((l) => throw Exception(l), (r) => r);
    });
  }
}
