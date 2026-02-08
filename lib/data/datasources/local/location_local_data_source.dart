import 'dart:convert';

import 'package:prayer_times/data/models/location_model.dart';
import 'package:prayer_times/data/services/local_cache_service.dart';
import 'package:prayer_times/domain/entities/location_entity.dart';

abstract class LocationLocalDataSource {
  Future<LocationEntity?> getCachedLocation();
  Future<void> cacheLocation(LocationEntity location);
  Future<void> cacheLocationPreference({
    required bool isManual,
    required String country,
    required String city,
  });
  ({bool isManual, String country, String city})? getCachedLocationPreference();
}

class LocationLocalDataSourceImpl implements LocationLocalDataSource {
  final LocalCacheService _localCacheService;

  LocationLocalDataSourceImpl(this._localCacheService);

  @override
  Future<void> cacheLocation(LocationEntity location) async {
    final LocationModel locationModel = LocationModel.fromEntity(location);
    final String jsonString = jsonEncode(locationModel.toJson());

    await _localCacheService.saveData(
      key: CacheKeys.location,
      value: jsonString,
    );
  }

  @override
  Future<LocationEntity?> getCachedLocation() async {
    final String? jsonString = _localCacheService.getData(
      key: CacheKeys.location,
    );
    if (jsonString == null) {
      return null;
    }

    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final LocationModel locationModel = LocationModel.fromJson(json);
      return locationModel;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheLocationPreference({
    required bool isManual,
    required String country,
    required String city,
  }) async {
    await _localCacheService.saveData(
      key: CacheKeys.isManualLocation,
      value: isManual,
    );
    await _localCacheService.saveData(
      key: CacheKeys.manualLocationCountry,
      value: country,
    );
    await _localCacheService.saveData(
      key: CacheKeys.manualLocationCity,
      value: city,
    );
  }

  @override
  ({bool isManual, String country, String city})? getCachedLocationPreference() {
    final bool? isManual = _localCacheService.getData<bool>(
      key: CacheKeys.isManualLocation,
    );
    if (isManual == null) return null;

    final String? country = _localCacheService.getData<String>(
      key: CacheKeys.manualLocationCountry,
    );
    final String? city = _localCacheService.getData<String>(
      key: CacheKeys.manualLocationCity,
    );

    return (
      isManual: isManual,
      country: country ?? '',
      city: city ?? '',
    );
  }
}
