import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:fpdart/fpdart.dart';
import 'package:prayer_times/core/utility/logger_utility.dart';
import 'package:prayer_times/core/utility/trial_utility.dart';
import 'package:prayer_times/data/datasources/local/device_token_local_data_source.dart';
import 'package:prayer_times/data/services/backend_as_a_service.dart';
import 'package:prayer_times/domain/repositories/device_token_repository.dart';

class DeviceTokenRepositoryImpl implements DeviceTokenRepository {
  DeviceTokenRepositoryImpl(this._backendService, this._localDataSource);

  final BackendAsAService _backendService;
  final DeviceTokenLocalDataSource _localDataSource;

  final Completer<String> _tokenCompleter = Completer<String>();
  bool _isInitialized = false;

  @override
  Future<Either<String, String>> initializeDeviceToken() async {
    if (_isInitialized) {
      final String? cachedToken = _localDataSource.getDeviceToken();
      if (cachedToken != null) {
        return right(cachedToken);
      }
    }

    try {
      await _backendService.listenToDeviceToken(
        onTokenFound: (String token) async {
          await _handleTokenFound(token);
        },
      );

      // Wait for the token to be found (with timeout)
      final String token = await _tokenCompleter.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          final String? cached = _localDataSource.getDeviceToken();
          if (cached != null) return cached;
          throw TimeoutException('FCM token retrieval timed out');
        },
      );

      _isInitialized = true;
      return right(token);
    } catch (e) {
      logErrorStatic(e, 'DeviceTokenRepositoryImpl');
      return left(e.toString());
    }
  }

  Future<void> _handleTokenFound(String token) async {
    // Save locally
    await _localDataSource.saveDeviceToken(token);

    // Get device info
    final _DeviceInfo? deviceInfo = await _getDeviceInfo();

    // Store to Firestore
    await _backendService.storeDeviceToken(
      token: token,
      platform: Platform.isIOS ? 'ios' : 'android',
      deviceModel: deviceInfo?.model,
      deviceId: deviceInfo?.id,
    );

    // Complete the completer if not already completed
    if (!_tokenCompleter.isCompleted) {
      _tokenCompleter.complete(token);
    }
  }

  Future<_DeviceInfo?> _getDeviceInfo() async {
    return await catchAndReturnFuture(() async {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return _DeviceInfo(
          model: iosInfo.model,
          id: iosInfo.identifierForVendor,
        );
      } else {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return _DeviceInfo(model: androidInfo.model, id: androidInfo.id);
      }
    });
  }

  @override
  String? getCachedDeviceToken() {
    return _localDataSource.getDeviceToken();
  }
}

class _DeviceInfo {
  final String? model;
  final String? id;

  _DeviceInfo({this.model, this.id});
}
