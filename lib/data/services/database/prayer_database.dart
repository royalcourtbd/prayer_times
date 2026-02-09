// lib/data/services/database/prayer_database.dart

import 'package:drift/drift.dart';
import 'package:prayer_times/data/services/database/table/calculation_method_table.dart';
import 'package:prayer_times/data/services/database/table/juristic_method_table.dart';
import 'package:prayer_times/data/services/database/database_loader.dart';
import 'package:prayer_times/data/services/database/table/prayer_tracker_table.dart';
part 'prayer_database.g.dart';

@DriftDatabase(
  tables: [JuristicMethodTable, PrayerTrackerTable, CalculationMethodTable],
)
class PrayerDatabase extends _$PrayerDatabase {
  PrayerDatabase({QueryExecutor? queryExecutor})
    : super(queryExecutor ?? loadDatabase());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(calculationMethodTable);
        }
      },
    );
  }

  Future<String> getJuristicMethod() async {
    final result =
        await (select(juristicMethodTable)
              ..limit(1)
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
            .getSingleOrNull();
    return result?.method ?? 'Shafi';
  }

  Future<void> updateJuristicMethod(String method) async {
    await into(juristicMethodTable).insert(
      JuristicMethodTableCompanion.insert(
        method: method,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<String> getCalculationMethod() async {
    final result =
        await (select(calculationMethodTable)
              ..limit(1)
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
            .getSingleOrNull();
    return result?.method ?? 'karachi';
  }

  Future<void> updateCalculationMethod(String method) async {
    await into(calculationMethodTable).insert(
      CalculationMethodTableCompanion.insert(
        method: method,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> insertOrUpdatePrayerTrackerData(
    DateTime date,
    String trackerData,
  ) async {
    final existingEntry = await (select(
      prayerTrackerTable,
    )..where((tbl) => tbl.date.equals(date))).getSingleOrNull();

    if (existingEntry != null) {
      await update(prayerTrackerTable).replace(
        existingEntry.copyWith(
          trackerData: trackerData,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      await into(prayerTrackerTable).insert(
        PrayerTrackerTableCompanion.insert(
          date: date,
          trackerData: trackerData,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<String?> getPrayerTrackerData(DateTime date) async {
    final result = await (select(
      prayerTrackerTable,
    )..where((tbl) => tbl.date.equals(date))).getSingleOrNull();

    return result?.trackerData;
  }

  Future<List<PrayerTrackerTableData>> getAllPrayerTrackerData() async {
    final query = select(prayerTrackerTable)
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);

    return await query.get();
  }

  Future<void> clearAllPrayerTrackerData() async {
    await delete(prayerTrackerTable).go();
  }
}
