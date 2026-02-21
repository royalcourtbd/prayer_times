import 'package:get_it/get_it.dart';
import 'package:prayer_times/core/di/service_locator.dart';
import 'package:prayer_times/core/di/setup/setup_module.dart';
import 'package:prayer_times/data/repositories/calculation_method_repository_impl.dart';
import 'package:prayer_times/data/repositories/country_repository_impl.dart';
import 'package:prayer_times/data/repositories/event_repository_impl.dart';
import 'package:prayer_times/data/repositories/juristic_method_repository_impl.dart';
import 'package:prayer_times/data/repositories/location_repository_impl.dart';
import 'package:prayer_times/data/repositories/notification_repository_impl.dart';
import 'package:prayer_times/data/repositories/payment_repository_impl.dart';
import 'package:prayer_times/data/repositories/prayer_time_repository_impl.dart';
import 'package:prayer_times/data/repositories/prayer_tracker_repository_impl.dart';
import 'package:prayer_times/data/repositories/user_data_repository_impl.dart';
import 'package:prayer_times/data/repositories/device_token_repository_impl.dart';
import 'package:prayer_times/domain/repositories/calculation_method_repository.dart';
import 'package:prayer_times/domain/repositories/country_repository.dart';
import 'package:prayer_times/domain/repositories/juristic_method_repository.dart';
import 'package:prayer_times/domain/repositories/location_repository.dart';
import 'package:prayer_times/domain/repositories/notification_repository.dart';
import 'package:prayer_times/domain/repositories/payment_repository.dart';
import 'package:prayer_times/domain/repositories/prayer_time_repository.dart';
import 'package:prayer_times/domain/repositories/prayer_tracker_repository.dart';
import 'package:prayer_times/domain/repositories/user_data_repository.dart';
import 'package:prayer_times/domain/repositories/device_token_repository.dart';
import 'package:prayer_times/domain/repositories/event_repository.dart';

class RepositorySetup implements SetupModule {
  final GetIt _serviceLocator;
  RepositorySetup(this._serviceLocator);

  @override
  Future<void> setup() async {
    _serviceLocator
      ..registerLazySingleton<PrayerTimeRepository>(
        () => PrayerTimeRepositoryImpl(locate()),
      )
      ..registerLazySingleton<JuristicMethodRepository>(
        () => JuristicMethodRepositoryImpl(locate()),
      )
      ..registerLazySingleton<CalculationMethodRepository>(
        () => CalculationMethodRepositoryImpl(locate()),
      )
      ..registerLazySingleton<PrayerTrackerRepository>(
        () => PrayerTrackerRepositoryImpl(locate()),
      )
      ..registerLazySingleton<CountryRepository>(
        () => CountryRepositoryImpl(locate()),
      )
      ..registerLazySingleton<LocationRepository>(
        () => LocationRepositoryImpl(locate(), locate(), locate()),
      )
      ..registerLazySingleton<UserDataRepository>(
        () => UserDataRepositoryImpl(locate(), locate()),
      )
      ..registerLazySingleton<NotificationRepository>(
        () => NotificationRepositoryImpl(locate()),
      )
      ..registerLazySingleton<PaymentRepository>(
        () => PaymentRepositoryImpl(locate(), locate()),
      )
      ..registerLazySingleton<DeviceTokenRepository>(
        () => DeviceTokenRepositoryImpl(locate(), locate()),
      )
      ..registerLazySingleton<EventRepository>(
        () => EventRepositoryImpl(locate(), locate(), locate()),
      );
  }
}
