import 'package:prayer_times/data/services/local_cache_service.dart';

class DeviceTokenLocalDataSource {
  DeviceTokenLocalDataSource(this._localCacheService);

  final LocalCacheService _localCacheService;

  Future<void> saveDeviceToken(String token) async {
    await _localCacheService.saveData(
      key: CacheKeys.fcmDeviceToken,
      value: token,
    );
  }

  String? getDeviceToken() {
    return _localCacheService.getData<String>(
      key: CacheKeys.fcmDeviceToken,
    );
  }

  Future<void> deleteDeviceToken() async {
    await _localCacheService.deleteData(key: CacheKeys.fcmDeviceToken);
  }
}
