import 'package:fpdart/fpdart.dart';

abstract class DeviceTokenRepository {
  /// Initializes device token - gets token, saves locally, and stores to Firestore
  Future<Either<String, String>> initializeDeviceToken();

  /// Gets locally cached device token
  String? getCachedDeviceToken();
}
