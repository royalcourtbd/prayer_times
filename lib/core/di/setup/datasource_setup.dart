import 'package:get_it/get_it.dart';
import 'package:prayer_times/core/di/service_locator.dart';
import 'package:prayer_times/core/di/setup/setup_module.dart';
import 'package:prayer_times/data/datasources/local/country_local_data_source.dart';
import 'package:prayer_times/data/datasources/local/location_local_data_source.dart';
import 'package:prayer_times/data/datasources/local/user_data_local_data_source.dart';
import 'package:prayer_times/data/datasources/remote/location_remote_data_source.dart';
import 'package:prayer_times/data/datasources/remote/prayer_time_datasource.dart';
import 'package:prayer_times/data/datasources/remote/payment_remote_data_source.dart';
import 'package:prayer_times/data/services/timezone_lookup_service.dart';
import 'package:prayer_times/domain/service/timezone_service.dart';

class DatasourceSetup implements SetupModule {
  final GetIt _serviceLocator;
  DatasourceSetup(this._serviceLocator);

  @override
  Future<void> setup() async {
    _serviceLocator
      ..registerLazySingleton<PrayerTimeDataSource>(
        () => PrayerTimeDataSourceImpl(
          locate(),
          locate(),
          locate<TimezoneService>(),
        ),
      )
      ..registerLazySingleton(() => CountryLocalDataSource())
      ..registerLazySingleton<LocationLocalDataSource>(
        () => LocationLocalDataSourceImpl(locate()),
      )
      ..registerLazySingleton<LocationRemoteDataSource>(
        () => LocationRemoteDataSourceImpl(locate<TimezoneLookupService>()),
      )
      ..registerLazySingleton(() => UserDataLocalDataSource(locate()))
      ..registerLazySingleton<PaymentRemoteDataSource>(
        () => PaymentRemoteDataSourceImpl(locate()),
      );
  }
}
