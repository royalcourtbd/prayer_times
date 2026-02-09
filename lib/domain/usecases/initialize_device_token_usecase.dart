import 'package:fpdart/fpdart.dart';
import 'package:prayer_times/core/base/base_use_case.dart';
import 'package:prayer_times/domain/repositories/device_token_repository.dart';

class InitializeDeviceTokenUseCase extends BaseUseCase<String> {
  InitializeDeviceTokenUseCase(
    this._deviceTokenRepository,
    super.errorMessageHandler,
  );

  final DeviceTokenRepository _deviceTokenRepository;

  Future<Either<String, String>> execute() async {
    return mapResultToEither(() async {
      final Either<String, String> result = await _deviceTokenRepository
          .initializeDeviceToken();
      return result.getOrElse((l) => throw Exception(l));
    });
  }
}
