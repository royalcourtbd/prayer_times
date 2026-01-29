import 'package:drift/drift.dart';

class CalculationMethodTable extends Table {
  TextColumn get method => text()();
  DateTimeColumn get updatedAt => dateTime()();
}
