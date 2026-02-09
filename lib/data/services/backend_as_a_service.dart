import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:prayer_times/core/utility/logger_utility.dart';
import 'package:prayer_times/core/utility/trial_utility.dart';
import 'package:prayer_times/data/models/event_model.dart';
import 'package:prayer_times/data/models/payment_model.dart';
import 'package:synchronized/synchronized.dart';

/// By separating the Firebase code into its own class, we can make it easier to
/// replace Firebase with another backend-as-a-service provider in the future.
///
/// This is because the rest of the app only depends on the public interface of
/// the `BackendAsAService` class, and not on the specific implementation details
/// of Firebase.
/// Therefore, if we decide to switch to a different backend-as-a-service
/// provider, we can simply create a new class that implements the same public
/// interface and use that instead.
///
/// This can help improve the flexibility of the app and make it easier to adapt
/// to changing business requirements or market conditions.
/// It also reduces the risk of vendor lock-in, since we are not tightly
/// coupling our app to a specific backend-as-a-service provider.
///
/// Overall, separating Firebase code into its own class can help make our app
/// more future-proof and adaptable to changing needs.
class BackendAsAService {
  BackendAsAService() {
    _initAnalytics();
  }
  late final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  late final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  late final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final Lock _listenToDeviceTokenLock = Lock();
  String? _inMemoryDeviceToken;

  static const String noticeCollection = 'notice';
  static const String noticeDoc = 'notice-bn';
  static const String settingsCollection = 'settings';
  static const String appUpdateDoc = 'app_update';
  static const String deviceTokensCollection = 'device_tokens';
  static const String paymentsCollection = 'payments';
  static const String eventsCollection = 'events';
  static const String paymentType = 'payment_type';
  static const String isActive = 'is_active';

  void _initAnalytics() {
    catchVoid(() {
      _analytics
          .setAnalyticsCollectionEnabled(true)
          .then((_) => _analytics.logAppOpen());
    });
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await catchFutureOrVoid(() async {
      await _analytics.logEvent(name: name, parameters: parameters);
    });
  }

  Future<void> getRemoteNotice({
    required void Function(Map<String, Object?>) onNotification,
  }) async {
    await catchFutureOrVoid(() async {
      _fireStore.collection(noticeCollection).doc(noticeDoc).snapshots().listen(
        (docSnapshot) {
          onNotification(docSnapshot.data() ?? {});
        },
      );
    });
  }

  Future<Map<String, dynamic>> getAppUpdateInfo() async {
    Map<String, dynamic>? appUpdateInfo = {};
    appUpdateInfo = await catchAndReturnFuture(() async {
      final DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await _fireStore
              .collection(settingsCollection)
              .doc(appUpdateDoc)
              .get();
      return docSnapshot.data();
    });
    return appUpdateInfo ?? {};
  }

  Future<void> listenToDeviceToken({
    required void Function(String) onTokenFound,
  }) async => catchFutureOrVoid(
    () async => await _listenToDeviceToken(onTokenFound: onTokenFound),
  );

  Future<void> _listenToDeviceToken({
    required void Function(String) onTokenFound,
  }) async {
    // prevents this function to be called multiple times in short period
    await _listenToDeviceTokenLock.synchronized(() async {
      catchFutureOrVoid(() async {
        _inMemoryDeviceToken ??= await _messaging.getToken();
        logDebug("Device token refreshed -> $_inMemoryDeviceToken");
        if (_inMemoryDeviceToken != null) onTokenFound(_inMemoryDeviceToken!);

        _messaging.onTokenRefresh.listen((String? token) {
          logDebug("Device token refreshed -> $token");
          if (token != null) onTokenFound(token);
        });
      });
    });
  }

  /// Stores the FCM device token to Firestore with device metadata
  /// Uses deviceId as document ID so reinstalls update existing document
  Future<void> storeDeviceToken({
    required String token,
    required String platform,
    String? deviceModel,
    String? deviceId,
  }) async {
    await catchFutureOrVoid(() async {
      // deviceId কে document ID হিসেবে ব্যবহার করি
      // যদি deviceId না থাকে তাহলে token ব্যবহার করি (fallback)
      final String docId = deviceId ?? token;

      final docRef = _fireStore.collection(deviceTokensCollection).doc(docId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Document exists - update token and updated_at only
        await docRef.update({
          'token': token,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        // New device - create new document
        await docRef.set({
          'token': token,
          'platform': platform,
          'device_model': deviceModel,
          'device_id': deviceId,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Stream<List<BankPaymentModel>> getBankPaymentsStream() {
    return _fireStore
        .collection(paymentsCollection)
        .where(paymentType, isEqualTo: 'bank')
        .where(isActive, isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => catchAndReturn<BankPaymentModel>(() {
                  return BankPaymentModel.fromFirestore(doc.data());
                }),
              )
              .where((model) => model != null)
              .cast<BankPaymentModel>()
              .toList();
        })
        .handleError((error) {
          logError('Error in bank payments stream: $error');
          return <BankPaymentModel>[];
        });
  }

  Future<List<EventModel>> getEvents(int year) async {
    final List<EventModel>? events = await catchAndReturnFuture(() async {
      final snapshot = await _fireStore
          .collection(eventsCollection)
          .where(isActive, isEqualTo: true)
          .where('year', isEqualTo: year)
          .get();

      final mappedEvents = snapshot.docs
          .map((doc) {
            return catchAndReturn<EventModel>(
              () => EventModel.fromFirestore(doc.data()),
            );
          })
          .where((model) => model != null)
          .cast<EventModel>()
          .toList();

      return mappedEvents;
    });

    final result = events ?? [];

    return result;
  }

  Stream<List<MobilePaymentModel>> getMobilePaymentsStream() {
    return _fireStore
        .collection(paymentsCollection)
        .where(paymentType, isEqualTo: 'mobile')
        .where(isActive, isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => catchAndReturn<MobilePaymentModel>(() {
                  return MobilePaymentModel.fromFirestore(doc.data());
                }),
              )
              .where((model) => model != null)
              .cast<MobilePaymentModel>()
              .toList();
        })
        .handleError((error) {
          return <MobilePaymentModel>[];
        });
  }
}
