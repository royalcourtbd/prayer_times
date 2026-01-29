import 'package:fpdart/fpdart.dart';
import 'package:prayer_times/data/services/database/prayer_database.dart';
import 'package:prayer_times/domain/repositories/calculation_method_repository.dart';

class CalculationMethodRepositoryImpl implements CalculationMethodRepository {
  final PrayerDatabase _database;

  CalculationMethodRepositoryImpl(this._database);

  @override
  Future<Either<String, String>> getCalculationMethod() async {
    try {
      final String method = await _database.getCalculationMethod();
      return right(method);
    } catch (e) {
      return left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> updateCalculationMethod(String method) async {
    try {
      await _database.updateCalculationMethod(method);
      return right(null);
    } catch (e) {
      return left(e.toString());
    }
  }
}
