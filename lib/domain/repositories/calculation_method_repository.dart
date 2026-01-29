import 'package:fpdart/fpdart.dart';

abstract class CalculationMethodRepository {
  Future<Either<String, String>> getCalculationMethod();
  Future<Either<String, void>> updateCalculationMethod(String method);
}
