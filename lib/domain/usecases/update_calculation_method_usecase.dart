import 'package:fpdart/fpdart.dart';
import 'package:prayer_times/domain/repositories/calculation_method_repository.dart';

class UpdateCalculationMethodUseCase {
  final CalculationMethodRepository _repository;

  UpdateCalculationMethodUseCase(this._repository);

  Future<Either<String, void>> execute({required String method}) async {
    return await _repository.updateCalculationMethod(method);
  }
}
