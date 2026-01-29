import 'package:fpdart/fpdart.dart';
import 'package:prayer_times/domain/repositories/calculation_method_repository.dart';

class GetCalculationMethodUseCase {
  final CalculationMethodRepository _repository;

  GetCalculationMethodUseCase(this._repository);

  Future<Either<String, String>> execute() async {
    return await _repository.getCalculationMethod();
  }
}
